import 'package:car_rental_app/data/datasources/firebase_booking_data_source.dart';
import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:car_rental_app/domain/repositories/booking_repository.dart';

class BookingRepositoryImpl implements BookingRepository {
  final FirebaseBookingDataSource dataSource;

  /// Injected so tests can pin "now" instead of depending on the wall clock.
  final DateTime Function() clock;

  BookingRepositoryImpl(this.dataSource, {DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  @override
  Future<Booking> create({
    required String carId,
    required String carModel,
    required String userId,
    required RentalPeriod period,
    required int totalCents,
    required int depositCents,
  }) async {
    final conflict = await _findConflict(carId: carId, period: period);

    if (conflict != null) throw CarUnavailableException(conflict.period);

    final booking = Booking(
      id: '',
      carId: carId,
      carModel: carModel,
      userId: userId,
      start: period.start,
      end: period.end,
      totalCents: totalCents,
      depositCents: depositCents,
      status: BookingStatus.confirmed,
      createdAt: clock(),
    );

    return dataSource.create(booking);
  }

  /// Note: the check and the write are two operations, so a simultaneous
  /// booking of the same car could still slip through. Closing that fully
  /// needs a server-side transaction (a Cloud Function or a security rule);
  /// this guards the case that actually happens in practice, a user booking
  /// dates another user already took.
  Future<Booking?> _findConflict({
    required String carId,
    required RentalPeriod period,
  }) async {
    final existing = await dataSource.blockingForCar(
      carId: carId,
      from: period.start,
    );

    for (final booking in existing) {
      if (booking.period.overlaps(period)) return booking;
    }

    return null;
  }

  @override
  Future<List<Booking>> forUser(String userId) => dataSource.forUser(userId);

  @override
  Future<void> cancel(String bookingId) => dataSource.cancel(bookingId);
}
