import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:car_rental_app/presentation/pages/booking_confirmation_page.dart';
import 'package:car_rental_app/presentation/pages/car_details_page.dart';
import 'package:car_rental_app/presentation/pages/car_list_screen.dart';
import 'package:car_rental_app/presentation/pages/maps_detail_page.dart';
import 'package:car_rental_app/presentation/pages/my_bookings_page.dart';
import 'package:car_rental_app/presentation/pages/onboarding_page.dart';
import 'package:car_rental_app/presentation/widgets/status_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Route paths and names in one place, so no call site spells a path by hand.
abstract final class Routes {
  static const onboarding = '/';
  static const cars = '/cars';

  /// Car detail and its map are addressed by car id, not by a `Car` object, so
  /// a link survives a cold start when nothing is in memory yet.
  static const carDetails = '/cars/:carId';
  static const carMap = '/cars/:carId/map';
  static const bookings = '/bookings';
  static const bookingConfirmed = '/bookings/confirmed';

  static String carDetailsFor(String carId) =>
      '/cars/${Uri.encodeComponent(carId)}';
  static String carMapFor(String carId) =>
      '/cars/${Uri.encodeComponent(carId)}/map';
}

GoRouter buildRouter({String initialLocation = Routes.onboarding}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: Routes.cars,
        builder: (context, state) => const CarListScreen(),
        routes: [
          GoRoute(
            path: ':carId',
            builder: (context, state) => _CarRoute(
              carId: state.pathParameters['carId'] ?? '',
              builder: (car) => CarDetailsPage(car: car),
            ),
            routes: [
              GoRoute(
                path: 'map',
                builder: (context, state) => _CarRoute(
                  carId: state.pathParameters['carId'] ?? '',
                  builder: (car) => MapsDetailPage(car: car),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.bookings,
        builder: (context, state) => const MyBookingsPage(),
        routes: [
          GoRoute(
            path: 'confirmed',
            builder: (context, state) {
              final booking = state.extra;

              // A confirmation screen is the result of an action, so it has
              // nothing to show on a cold link. Fall back to the list rather
              // than rendering an empty receipt.
              if (booking is! Booking) return const MyBookingsPage();

              return BookingConfirmationPage(booking: booking);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: StatusView(
        icon: Icons.explore_off_outlined,
        title: 'That page does not exist',
        body: 'The link "${state.uri}" did not match anything in the app.',
        actionLabel: 'Browse cars',
        actionIcon: Icons.directions_car_outlined,
        onRetry: () => context.go(Routes.cars),
      ),
    ),
  );
}

/// Resolves a car id against the loaded list.
///
/// On a cold deep link the bloc has not fetched anything yet, so this triggers
/// the load and waits, rather than showing "not found" for a car that exists.
class _CarRoute extends StatelessWidget {
  final String carId;
  final Widget Function(Car car) builder;

  const _CarRoute({required this.carId, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CarBloc, CarState>(
      builder: (context, state) {
        switch (state) {
          case CarsLoading():
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );

          case CarsError(:final message):
            return Scaffold(
              appBar: AppBar(),
              body: StatusView(
                icon: Icons.wifi_off_outlined,
                title: 'Could not load this car',
                body: message,
                onRetry: () => context.read<CarBloc>().add(LoadCars()),
              ),
            );

          case CarsLoaded(:final all):
            final car = all.where((candidate) => candidate.id == carId);

            if (car.isEmpty) {
              return Scaffold(
                appBar: AppBar(),
                body: StatusView(
                  icon: Icons.car_crash_outlined,
                  title: 'Car not found',
                  body: 'This listing may have been removed.',
                  actionLabel: 'Browse cars',
                  actionIcon: Icons.directions_car_outlined,
                  onRetry: () => context.go(Routes.cars),
                ),
              );
            }

            return builder(car.first);
        }
      },
    );
  }
}
