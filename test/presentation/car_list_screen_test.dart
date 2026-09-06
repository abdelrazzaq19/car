import 'package:car_rental_app/core/location/location_service.dart';
import 'package:car_rental_app/core/theme/app_theme.dart';
import 'package:car_rental_app/core/theme/theme_cubit.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/car_query.dart';
import 'package:car_rental_app/domain/usecases/get_cars.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:car_rental_app/presentation/pages/car_list_screen.dart';
import 'package:car_rental_app/presentation/pages/filter_sheet.dart';
import 'package:car_rental_app/presentation/widgets/car_card.dart';
import 'package:car_rental_app/presentation/widgets/car_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

const _tesla = Car(
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

const _bmw = Car(
  id: 'b',
  model: 'BMW M4',
  distance: 520,
  fuelCapacity: 59,
  pricePerDay: 175,
  seats: 4,
  transmission: Transmission.manual,
  fuelType: FuelType.petrol,
);

/// A real CarBloc over fakes, so the screen is exercised against the genuine
/// filtering path rather than a hand-written stand-in.
CarBloc _bloc({
  List<Car> cars = const [_tesla, _bmw],
  FakeFavourites? favourites,
  FakeLocation? location,
}) {
  return CarBloc(
    getCars: GetCars(FakeCarRepository.returning(cars)),
    favourites: favourites ?? FakeFavourites(),
    auth: FakeAuth(),
    location: location ?? FakeLocation(),
  );
}

Future<CarBloc> _pump(
  WidgetTester tester, {
  CarBloc? bloc,
  bool load = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final carBloc = bloc ?? _bloc();

  // Awaiting `bloc.close()` inside a testWidgets body never returns: the
  // fake-async zone does not drain bloc's internal stream teardown. A teardown
  // callback runs outside that zone, so the bloc is still disposed.
  addTearDown(carBloc.close);

  if (load) carBloc.add(LoadCars());

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(prefs)),
        BlocProvider<CarBloc>.value(value: carBloc),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const CarListScreen(),
      ),
    ),
  );

  // The loading skeleton shimmers on a repeating animation, so pumpAndSettle
  // would never return while it is on screen. Pump fixed frames instead, and
  // settle only once the cars have arrived.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));

  if (load) await tester.pumpAndSettle();

  return carBloc;
}

void main() {
  testWidgets('shows skeletons while loading', (tester) async {
    await _pump(tester, load: false);

    expect(find.byType(CarCardSkeleton), findsWidgets);
    expect(find.byType(CarCard), findsNothing);
  });

  testWidgets('shows a card per car once loaded', (tester) async {
    await _pump(tester);

    expect(find.byType(CarCard), findsNWidgets(2));
    expect(find.text('Tesla Model 3'), findsOneWidget);
    expect(find.textContaining('\$89', findRichText: true), findsOneWidget);
    expect(find.textContaining('/h', findRichText: true), findsNothing);
  });

  testWidgets('shows the electric capacity unit', (tester) async {
    await _pump(tester, bloc: _bloc(cars: const [_tesla]));

    expect(find.text('60 kWh'), findsOneWidget);
    expect(find.text('491 km'), findsOneWidget);
    expect(find.text('5 seats'), findsOneWidget);
  });

  group('search', () {
    testWidgets('narrows the list after the debounce', (tester) async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'bmw');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('BMW M4'), findsOneWidget);
      expect(find.text('Tesla Model 3'), findsNothing);
    });

    testWidgets('a no-match search offers to clear the filters',
        (tester) async {
      await _pump(tester);

      await tester.enterText(find.byType(TextField), 'lamborghini');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('No cars match those filters'), findsOneWidget);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(find.byType(CarCard), findsNWidgets(2));
    });

    testWidgets('an empty source list says so, not "no match"',
        (tester) async {
      await _pump(tester, bloc: _bloc(cars: const []));

      expect(find.text('No cars available'), findsOneWidget);
      expect(find.text('No cars match those filters'), findsNothing);
    });
  });

  group('filters', () {
    testWidgets('the sheet applies a sort and the badge counts filters',
        (tester) async {
      final bloc = await _pump(tester);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Price: high to low'));
      await tester.pumpAndSettle();

      // The switch sits below the fold, and two scrollables are on screen, so
      // the sheet's own scroll view has to be named.
      await tester.dragUntilVisible(
        find.byType(SwitchListTile),
        find.descendant(
          of: find.byType(FilterSheet),
          matching: find.byType(SingleChildScrollView),
        ),
        const Offset(0, -80),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      final state = bloc.state as CarsLoaded;
      expect(state.query.sort, CarSort.priceHighToLow);
      expect(state.cars.first.model, 'BMW M4');
      // One filter active: sorting alone does not count.
      expect(state.query.activeFilterCount, 1);
    });

    testWidgets('backing out of the sheet changes nothing', (tester) async {
      final bloc = await _pump(tester);
      final before = (bloc.state as CarsLoaded).query;

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Price: low to high'));
      await tester.pumpAndSettle();

      // Dismiss without applying.
      Navigator.of(tester.element(find.text('Apply'))).pop();
      await tester.pumpAndSettle();

      expect((bloc.state as CarsLoaded).query, before);
    });

    testWidgets('choosing nearest requests the location', (tester) async {
      final location = FakeLocation(position: const UserPosition(1, 1));
      await _pump(tester, bloc: _bloc(location: location));

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nearest to me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(location.calls, 1);
    });

    testWidgets('a blocked location is explained, with no pointless retry',
        (tester) async {
      await _pump(
        tester,
        bloc: _bloc(
          location: FakeLocation(failure: LocationFailure.deniedForever),
        ),
      );

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nearest to me'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();

      expect(find.textContaining('blocked'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('favourites', () {
    testWidgets('the heart saves a car and it appears under Saved',
        (tester) async {
      await _pump(tester);

      await tester.tap(find.byIcon(Icons.favorite_border).first);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.favorite), findsOneWidget);

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.byType(CarCard), findsOneWidget);
      expect(find.text('Tesla Model 3'), findsOneWidget);
    });

    testWidgets('the Saved tab explains itself when empty', (tester) async {
      await _pump(tester);

      await tester.tap(find.text('Saved'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing saved yet'), findsOneWidget);
    });

    testWidgets('previously saved cars come back filled in', (tester) async {
      await _pump(
        tester,
        bloc: _bloc(favourites: FakeFavourites(saved: {'a'})),
      );

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('accessibility and layout', () {
    testWidgets('the heart meets the 48dp minimum tap target', (tester) async {
      await _pump(tester);

      final heart = tester.getSize(
        find
            .ancestor(
              of: find.byIcon(Icons.favorite_border).first,
              matching: find.byType(IconButton),
            )
            .first,
      );

      expect(heart.width, greaterThanOrEqualTo(48));
      expect(heart.height, greaterThanOrEqualTo(48));
    });

    testWidgets('icon-only controls carry semantic labels', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      // These controls announce themselves through a tooltip, which is a
      // separate semantics field from `label`.
      expect(find.byTooltip('Save this car'), findsWidgets);
      expect(find.byTooltip('My bookings'), findsOneWidget);
      expect(find.byTooltip('Filter and sort'), findsOneWidget);

      // The card itself is still a labelled button, and the heart is reachable
      // separately rather than being swallowed by it.
      expect(
        find.bySemanticsLabel(RegExp(r'Tesla Model 3, \$89 per day')),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets('does not overflow on a small screen', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('does not overflow at text scale 2.0', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await _pump(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the theme toggle cycles system, light then dark',
        (tester) async {
      await _pump(tester);

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
  });
}
