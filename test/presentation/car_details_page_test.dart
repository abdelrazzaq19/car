import 'package:car_rental_app/core/theme/app_theme.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:car_rental_app/presentation/pages/car_details_page.dart';
import 'package:car_rental_app/presentation/widgets/more_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubCarBloc extends Bloc<CarEvent, CarState> implements CarBloc {
  _StubCarBloc(super.initialState) {
    on<LoadCars>((event, emit) {});
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _tesla = Car(
  id: 'a',
  model: 'Tesla Model 3',
  distance: 491,
  fuelCapacity: 60,
  pricePerDay: 89,
  seats: 5,
  fuelType: FuelType.electric,
);

const _audi = Car(
  id: 'b',
  model: 'Audi A5',
  distance: 610,
  fuelCapacity: 58,
  pricePerDay: 120,
  seats: 5,
  fuelType: FuelType.diesel,
);

const _unavailable = Car(
  id: 'c',
  model: 'Ford Ranger',
  distance: 700,
  fuelCapacity: 80,
  pricePerDay: 140,
  available: false,
);

Future<void> _pump(
  WidgetTester tester,
  Car car, {
  List<Car> all = const [],
}) async {
  await tester.pumpWidget(
    BlocProvider<CarBloc>(
      create: (_) => _StubCarBloc(CarsLoaded(all)),
      child: MaterialApp(
        theme: AppTheme.light(),
        home: CarDetailsPage(car: car),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows the car and a booking bar', (tester) async {
    await _pump(tester, _tesla);

    expect(find.text('Tesla Model 3'), findsOneWidget);
    expect(find.text('Book now'), findsOneWidget);
  });

  testWidgets('disables booking for an unavailable car', (tester) async {
    await _pump(tester, _unavailable);

    expect(find.text('Unavailable'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Unavailable'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('lists real similar cars, never fabricated ones',
      (tester) async {
    await _pump(tester, _tesla, all: [_tesla, _audi]);

    // The section sits below the fold, and the list builds lazily.
    await tester.scrollUntilVisible(find.byType(MoreCard), 200);
    await tester.pump();

    expect(find.byType(MoreCard), findsOneWidget);
    expect(find.text('Audi A5'), findsOneWidget);
    // The old version invented entries by suffixing the model name.
    expect(find.textContaining('Tesla Model 3-'), findsNothing);
  });

  testWidgets('hides the similar section when it is the only car',
      (tester) async {
    await _pump(tester, _tesla, all: [_tesla]);

    expect(find.byType(MoreCard), findsNothing);
    expect(find.text('Similar cars'), findsNothing);
  });

  testWidgets('scrolls instead of overflowing on a small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, _tesla, all: [_tesla, _audi]);

    expect(tester.takeException(), isNull);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing the page mid-animation does not throw',
      (tester) async {
    await _pump(tester, _tesla, all: [_tesla, _audi]);

    // Reproduces the crash path: leave the page before any animation settles.
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.pump(const Duration(seconds: 4));

    expect(tester.takeException(), isNull);
  });
}
