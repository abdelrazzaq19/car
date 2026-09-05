import 'package:car_rental_app/core/error/failure_message.dart';
import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:car_rental_app/domain/repositories/auth_repository.dart';
import 'package:car_rental_app/domain/repositories/booking_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

sealed class MyBookingsState extends Equatable {
  const MyBookingsState();

  @override
  List<Object?> get props => [];
}

class MyBookingsLoading extends MyBookingsState {
  const MyBookingsLoading();
}

class MyBookingsLoaded extends MyBookingsState {
  final List<Booking> upcoming;
  final List<Booking> past;

  const MyBookingsLoaded({required this.upcoming, required this.past});

  bool get isEmpty => upcoming.isEmpty && past.isEmpty;

  @override
  List<Object?> get props => [upcoming, past];
}

class MyBookingsError extends MyBookingsState {
  final String message;

  const MyBookingsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MyBookingsCubit extends Cubit<MyBookingsState> {
  final BookingRepository bookings;
  final AuthRepository auth;
  final DateTime Function() clock;

  MyBookingsCubit({
    required this.bookings,
    required this.auth,
    DateTime Function()? clock,
  })  : clock = clock ?? DateTime.now,
        super(const MyBookingsLoading());

  Future<void> load() async {
    emit(const MyBookingsLoading());

    try {
      final userId = await auth.ensureSignedIn();
      emit(_split(await bookings.forUser(userId)));
    } catch (error) {
      emit(
        MyBookingsError(
          failureMessage(error, action: 'loading your bookings'),
        ),
      );
    }
  }

  Future<void> cancel(String bookingId) async {
    final current = state;
    if (current is! MyBookingsLoaded) return;

    try {
      await bookings.cancel(bookingId);
      await load();
    } catch (error) {
      emit(
        MyBookingsError(
          failureMessage(error, action: 'cancelling your booking'),
        ),
      );
    }
  }

  /// A booking is upcoming while it has not ended and has not been cancelled.
  /// Everything else, cancelled bookings included, belongs in the history.
  MyBookingsLoaded _split(List<Booking> all) {
    final today = RentalPeriod.dateOnly(clock());
    final upcoming = <Booking>[];
    final past = <Booking>[];

    for (final booking in all) {
      final stillRunning = !booking.end.isBefore(today);

      if (booking.status.isCancellable && stillRunning) {
        upcoming.add(booking);
      } else {
        past.add(booking);
      }
    }

    upcoming.sort((a, b) => a.start.compareTo(b.start));
    past.sort((a, b) => b.start.compareTo(a.start));

    return MyBookingsLoaded(upcoming: upcoming, past: past);
  }
}
