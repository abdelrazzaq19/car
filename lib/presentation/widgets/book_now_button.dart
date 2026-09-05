import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/injection_container.dart';
import 'package:car_rental_app/presentation/bloc/booking/booking_cubit.dart';
import 'package:car_rental_app/presentation/pages/booking_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the booking sheet for a car. Shared by the details page and the map,
/// so the two cannot drift apart.
class BookNowButton extends StatelessWidget {
  final Car car;

  const BookNowButton({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: car.available ? () => openBookingSheet(context, car) : null,
      child: Text(car.available ? 'Book now' : 'Unavailable'),
    );
  }
}

Future<void> openBookingSheet(BuildContext context, Car car) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => BlocProvider(
      create: (_) => getIt<BookingCubit>(param1: car),
      child: BookingSheet(car: car),
    ),
  );
}
