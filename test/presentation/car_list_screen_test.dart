import 'package:car_rental_app/core/theme/app_theme.dart';
import 'package:car_rental_app/core/theme/theme_cubit.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:car_rental_app/presentation/pages/car_list_screen.dart';
import 'package:car_rental_app/presentation/widgets/car_card.dart';
import 'package:car_rental_app/presentation/widgets/car_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the screen directly, without the use case or Firestore behind it.
class _StubCarBloc extends Bloc<CarEvent, CarState> implements CarBloc {
  int loadCount = 0;

  _StubCarBloc(super.initialState) {
    on<LoadCars>((event, emit) => loadCount++);
  }

  @override
  Never get getCars => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, CarState state) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(prefs)),
        BlocProvider<CarBloc>(create: (_) => _StubCarBloc(state)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const CarListScreen(),
      ),
    ),
  );
  await tester.pump();
}

const _car = Car(
  id: 'a',
  model: 'Tesla Model 3',
  distance: 491,
  fuelCapacity: 60,
  pricePerDay: 89,
  seats: 5,
  transmission: Transmission.automatic,
  fuelType: FuelType.electric,
  rating: 4.8,
);

void main() {
  testWidgets('shows skeletons while loading', (tester) async {
    await _pump(tester, const CarsLoading());

    expect(find.byType(CarCardSkeleton), findsWidgets);
    expect(find.byType(CarCard), findsNothing);
  });

  testWidgets('shows a card per car when loaded', (tester) async {
    await _pump(tester, const CarsLoaded([_car]));

    expect(find.byType(CarCard), findsOneWidget);
    expect(find.text('Tesla Model 3'), findsOneWidget);
    // Price is labelled per day everywhere, never per hour. The price is a
    // rich span, so the finder has to look inside it.
    expect(
      find.textContaining('\$89', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('/ day', findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('/h', findRichText: true), findsNothing);
  });

  testWidgets('shows the electric capacity unit', (tester) async {
    await _pump(tester, const CarsLoaded([_car]));

    expect(find.text('60 kWh'), findsOneWidget);
    expect(find.text('491 km'), findsOneWidget);
    expect(find.text('5 seats'), findsOneWidget);
  });

  testWidgets('shows an empty state with a retry action', (tester) async {
    await _pump(tester, const CarsLoaded([]));

    expect(find.text('No cars available'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('shows the error message and a retry action', (tester) async {
    await _pump(tester, const CarsError('You appear to be offline.'));

    expect(find.text('Could not load cars'), findsOneWidget);
    expect(find.text('You appear to be offline.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('retry dispatches LoadCars', (tester) async {
    await _pump(tester, const CarsError('boom'));

    await tester.tap(find.text('Try again'));
    await tester.pump();

    final bloc =
        tester.element(find.byType(CarListScreen)).read<CarBloc>() as _StubCarBloc;
    expect(bloc.loadCount, 1);
  });

  testWidgets('the theme toggle cycles system, light then dark',
      (tester) async {
    await _pump(tester, const CarsLoaded([_car]));

    final cubit =
        tester.element(find.byType(CarListScreen)).read<ThemeCubit>();
    expect(cubit.state, ThemeMode.system);

    await tester.tap(find.byIcon(Icons.brightness_auto_outlined));
    await tester.pumpAndSettle();
    expect(cubit.state, ThemeMode.light);

    await tester.tap(find.byIcon(Icons.light_mode_outlined));
    await tester.pumpAndSettle();
    expect(cubit.state, ThemeMode.dark);
  });

  testWidgets('does not overflow on a small screen', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, const CarsLoaded([_car, _car, _car]));

    expect(tester.takeException(), isNull);
  });

  testWidgets('does not overflow at text scale 2.0', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pump(tester, const CarsLoaded([_car]));

    expect(tester.takeException(), isNull);
  });
}
