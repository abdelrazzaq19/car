import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';

/// Raised when the requested dates are already taken.
class CarUnavailableException implements Exception {
  final RentalPeriod conflict;

  const CarUnavailableException(this.conflict);
}

abstract class BookingRepository {
  /// Creates a booking, refusing dates that clash with an existing one.
  ///
  /// Throws [CarUnavailableException] when the car is already booked.
  Future<Booking> create({
    required String carId,
    required String carModel,
    required String userId,
    required RentalPeriod period,
    required int totalCents,
    required int depositCents,
  });

  Future<List<Booking>> forUser(String userId);

  Future<void> cancel(String bookingId);
}
