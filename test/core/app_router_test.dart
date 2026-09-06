import 'package:car_rental_app/core/router/app_router.dart';
import 'package:car_rental_app/core/theme/app_theme.dart';
import 'package:car_rental_app/core/theme/theme_cubit.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/usecases/get_cars.dart';
import 'package:car_rental_app/injection_container.dart';
import 'package:car_rental_app/presentation/bloc/booking/booking_cubit.dart';
import 'package:car_rental_app/presentation/bloc/booking/my_bookings_cubit.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/pages/car_details_page.dart';
import 'package:car_rental_app/presentation/pages/car_list_screen.dart';
import 'package:car_rental_app/presentation/pages/maps_detail_page.dart';
import 'package:car_rental_app/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fakes.dart';

const _tesla = Car(
  id: 'tesla-model-3',
  model: 'Tesla Model 3',
  distance: 491,
  fuelCapacity: 60,
  pricePerDay: 89,
  seats: 5,
  fuelType: FuelType.electric,
  latitude: 32.49,
  longitude: 74.54,
);

const _bmw = Car(
  id: 'bmw-m4',
  model: 'BMW M4',
  distance: 520,
  fuelCapacity: 59,
  pricePerDay: 175,
  seats: 4,
);

/// Pumps the real router over fake data, so route resolution is exercised
/// rather than mocked.
Future<CarBloc> _pump(
  WidgetTester tester, {
  required String at,
  List<Car> cars = const [_tesla, _bmw],
  bool load = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final bloc = CarBloc(
    getCars: GetCars(FakeCarRepository.returning(cars)),
    favourites: FakeFavourites(),
    auth: FakeAuth(),
    location: FakeLocation(),
  );
  addTearDown(bloc.close);

  if (load) bloc.add(LoadCars());

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>(create: (_) => ThemeCubit(prefs)),
        BlocProvider<CarBloc>.value(value: bloc),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: buildRouter(initialLocation: at),
      ),
    ),
  );

  // The skeleton shimmers on a repeating animation, so settle only once the
  // cars have arrived.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  if (load) await tester.pumpAndSettle();

  return bloc;
}

void main() {
  // The /bookings routes resolve their cubit from the DI container, so it has
  // to hold something. Without this, the route builder throws and the error is
  // attributed to whichever test happens to run next.
  setUp(() {
    getIt.registerFactory<MyBookingsCubit>(
      () => MyBookingsCubit(bookings: FakeBookings(), auth: FakeAuth()),
    );
    getIt.registerFactoryParam<BookingCubit, Car, void>(
      (car, _) => BookingCubit(
        car: car,
        bookings: FakeBookings(),
        auth: FakeAuth(),
      ),
    );
  });

  tearDown(getIt.reset);

  group('paths', () {
    test('build from a car id', () {
      expect(Routes.carDetailsFor('tesla-model-3'), '/cars/tesla-model-3');
      expect(Routes.carMapFor('tesla-model-3'), '/cars/tesla-model-3/map');
    });

    test('encode an id that would otherwise break the path', () {
      expect(Routes.carDetailsFor('a/b'), '/cars/a%2Fb');
    });
  });

  group('deep links', () {
    testWidgets('the root shows onboarding', (tester) async {
      await _pump(tester, at: Routes.onboarding);

      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('/cars shows the list', (tester) async {
      await _pump(tester, at: Routes.cars);

      expect(find.byType(CarListScreen), findsOneWidget);
    });

    testWidgets('a car id resolves to that car', (tester) async {
      await _pump(tester, at: '/cars/tesla-model-3');

      expect(find.byType(CarDetailsPage), findsOneWidget);
      expect(find.text('Tesla Model 3'), findsOneWidget);
    });

    testWidgets('the map sub-route resolves to the same car', (tester) async {
      await _pump(tester, at: '/cars/tesla-model-3/map');

      expect(find.byType(MapsDetailPage), findsOneWidget);
    });

    testWidgets('an unknown car id says so instead of crashing',
        (tester) async {
      await _pump(tester, at: '/cars/does-not-exist');

      expect(find.text('Car not found'), findsOneWidget);
      expect(find.byType(CarDetailsPage), findsNothing);
    });

    testWidgets('an unmatched path shows the error page', (tester) async {
      await _pump(tester, at: '/nope/nowhere');

      expect(find.text('That page does not exist'), findsOneWidget);
    });

    testWidgets('a cold link waits for the load rather than 404ing',
        (tester) async {
      // Nothing has been fetched yet: the bloc is still in its loading state.
      await _pump(tester, at: '/cars/tesla-model-3', load: false);

      expect(find.text('Car not found'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('the confirmation route falls back without a booking',
        (tester) async {
      // A receipt has nothing to show on a cold link.
      await _pump(tester, at: Routes.bookingConfirmed);

      expect(find.text('Booking confirmed'), findsNothing);
    });
  });

  group('navigation', () {
    testWidgets('tapping a card pushes the car route', (tester) async {
      await _pump(tester, at: Routes.cars);

      await tester.tap(find.text('Tesla Model 3'));
      await tester.pumpAndSettle();

      expect(find.byType(CarDetailsPage), findsOneWidget);
    });

    testWidgets('back returns to the list', (tester) async {
      await _pump(tester, at: Routes.cars);

      await tester.tap(find.text('Tesla Model 3'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(CarListScreen), findsOneWidget);
    });

    testWidgets('onboarding leads to the list', (tester) async {
      await _pump(tester, at: Routes.onboarding);

      await tester.tap(find.text("Let's go"));
      await tester.pumpAndSettle();

      expect(find.byType(CarListScreen), findsOneWidget);
    });

    testWidgets('the map opens from the details page', (tester) async {
      await _pump(tester, at: '/cars/tesla-model-3');

      // The preview sits under the sticky booking bar at this viewport size,
      // so it has to be scrolled clear before it can be tapped.
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();

      await tester.tap(
        find
            .ancestor(
              of: find.text('Tap to view on the map'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(MapsDetailPage), findsOneWidget);
    });
  });
}
