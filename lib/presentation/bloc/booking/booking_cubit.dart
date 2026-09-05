import 'package:car_rental_app/core/error/failure_message.dart';
import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/price_quote.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:car_rental_app/domain/repositories/auth_repository.dart';
import 'package:car_rental_app/domain/repositories/booking_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

/// No dates chosen yet.
class BookingIdle extends BookingState {
  const BookingIdle();
}

/// Dates chosen and priced, ready to confirm.
class BookingQuoted extends BookingState {
  final RentalPeriod period;
  final PriceQuote quote;

  const BookingQuoted(this.period, this.quote);

  @override
  List<Object?> get props => [period, quote];
}

/// The chosen dates are not valid.
class BookingInvalid extends BookingState {
  final String message;

  const BookingInvalid(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingSubmitting extends BookingState {
  const BookingSubmitting();
}

class BookingConfirmed extends BookingState {
  final Booking booking;

  const BookingConfirmed(this.booking);

  @override
  List<Object?> get props => [booking];
}

class BookingFailed extends BookingState {
  final String message;

  /// Set when the failure was a date clash, so the UI can offer to re-pick.
  final bool datesTaken;

  const BookingFailed(this.message, {this.datesTaken = false});

  @override
  List<Object?> get props => [message, datesTaken];
}

/// Drives one car's booking flow: pick dates, see the price, confirm.
class BookingCubit extends Cubit<BookingState> {
  final Car car;
  final BookingRepository bookings;
  final AuthRepository auth;
  final DateTime Function() clock;

  BookingCubit({
    required this.car,
    required this.bookings,
    required this.auth,
    DateTime Function()? clock,
  })  : clock = clock ?? DateTime.now,
        super(const BookingIdle());

  void selectDates({required DateTime start, required DateTime end}) {
    final result = RentalPeriod.validate(start: start, end: end, now: clock());

    final error = result.error;
    if (error != null) {
      emit(BookingInvalid(error.message));
      return;
    }

    final period = result.period!;
    emit(
      BookingQuoted(
        period,
        PriceQuote.forPeriod(period: period, pricePerDay: car.pricePerDay),
      ),
    );
  }

  void clearDates() => emit(const BookingIdle());

  Future<void> confirm() async {
    final current = state;
    if (current is! BookingQuoted) return;

    emit(const BookingSubmitting());

    try {
      final userId = await auth.ensureSignedIn();

      final booking = await bookings.create(
        carId: car.id,
        carModel: car.model,
        userId: userId,
        period: current.period,
        totalCents: current.quote.totalCents,
        depositCents: current.quote.depositCents,
      );

      emit(BookingConfirmed(booking));
    } on CarUnavailableException {
      emit(
        const BookingFailed(
          'Those dates were just taken. Please choose another window.',
          datesTaken: true,
        ),
      );
    } catch (error) {
      emit(
        BookingFailed(
          failureMessage(error, action: 'confirming your booking'),
        ),
      );
    }
  }
}
