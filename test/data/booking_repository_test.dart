import 'package:car_rental_app/data/datasources/firebase_booking_data_source.dart';
import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/data/repositories/booking_repository_impl.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:car_rental_app/domain/repositories/booking_repository.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 5);

RentalPeriod period(int startOffset, int endOffset) {
  return RentalPeriod.validate(
    start: _now.add(Duration(days: startOffset)),
    end: _now.add(Duration(days: endOffset)),
    now: _now,
  ).period!;
}

Booking booking({
  required int startOffset,
  required int endOffset,
  String carId = 'car-1',
  BookingStatus status = BookingStatus.confirmed,
  String id = 'b1',
}) {
  return Booking(
    id: id,
    carId: carId,
    carModel: 'Tesla Model 3',
    userId: 'u1',
    start: _now.add(Duration(days: startOffset)),
    end: _now.add(Duration(days: endOffset)),
    totalCents: 15000,
    depositCents: 20000,
    status: status,
    createdAt: _now,
  );
}

/// In-memory stand-in for Firestore. Mirrors the real data source's contract:
/// it narrows on `end` and only returns bookings that block availability.
class _FakeDataSource implements FirebaseBookingDataSource {
  final List<Booking> stored;
  int createCalls = 0;

  _FakeDataSource(this.stored);

  @override
  Future<List<Booking>> blockingForCar({
    required String carId,
    required DateTime from,
  }) async {
    return stored
        .where((b) => b.carId == carId)
        .where((b) => b.end.isAfter(from))
        .where((b) => b.status.blocksAvailability)
        .toList();
  }

  @override
  Future<Booking> create(Booking booking) async {
    createCalls++;
    final saved = Booking(
      id: 'generated-id',
      carId: booking.carId,
      carModel: booking.carModel,
      userId: booking.userId,
      start: booking.start,
      end: booking.end,
      totalCents: booking.totalCents,
      depositCents: booking.depositCents,
      status: booking.status,
      createdAt: booking.createdAt,
    );
    stored.add(saved);
    return saved;
  }

  @override
  Future<List<Booking>> forUser(String userId) async =>
      stored.where((b) => b.userId == userId).toList();

  @override
  Future<void> cancel(String bookingId) async {
    final index = stored.indexWhere((b) => b.id == bookingId);
    stored[index] = stored[index].copyWith(status: BookingStatus.cancelled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BookingRepositoryImpl repositoryWith(List<Booking> stored) {
  return BookingRepositoryImpl(_FakeDataSource(stored), clock: () => _now);
}

Future<Booking> book(
  BookingRepositoryImpl repository,
  RentalPeriod window, {
  String carId = 'car-1',
}) {
  return repository.create(
    carId: carId,
    carModel: 'Tesla Model 3',
    userId: 'u1',
    period: window,
    totalCents: 15000,
    depositCents: 20000,
  );
}

void main() {
  group('availability', () {
    test('books a free window', () async {
      final repository = repositoryWith([]);

      final result = await book(repository, period(1, 4));

      expect(result.id, 'generated-id');
      expect(result.status, BookingStatus.confirmed);
    });

    test('rejects an exactly overlapping window', () async {
      final repository = repositoryWith([booking(startOffset: 1, endOffset: 4)]);

      expect(
        () => book(repository, period(1, 4)),
        throwsA(isA<CarUnavailableException>()),
      );
    });

    test('rejects a partially overlapping window', () async {
      final repository = repositoryWith([booking(startOffset: 1, endOffset: 5)]);

      expect(
        () => book(repository, period(3, 8)),
        throwsA(isA<CarUnavailableException>()),
      );
    });

    test('rejects a window that swallows an existing booking', () async {
      final repository = repositoryWith([booking(startOffset: 3, endOffset: 5)]);

      expect(
        () => book(repository, period(1, 10)),
        throwsA(isA<CarUnavailableException>()),
      );
    });

    test('allows a window starting the day another ends', () async {
      final repository = repositoryWith([booking(startOffset: 1, endOffset: 4)]);

      await expectLater(book(repository, period(4, 7)), completes);
    });

    test('allows a clashing window on a different car', () async {
      final repository = repositoryWith([
        booking(startOffset: 1, endOffset: 4, carId: 'car-2'),
      ]);

      await expectLater(book(repository, period(1, 4)), completes);
    });

    test('a cancelled booking does not block its dates', () async {
      final repository = repositoryWith([
        booking(
          startOffset: 1,
          endOffset: 4,
          status: BookingStatus.cancelled,
        ),
      ]);

      await expectLater(book(repository, period(1, 4)), completes);
    });

    test('a completed booking does not block its dates', () async {
      final repository = repositoryWith([
        booking(
          startOffset: 1,
          endOffset: 4,
          status: BookingStatus.completed,
        ),
      ]);

      await expectLater(book(repository, period(1, 4)), completes);
    });

    test('does not write when the dates are taken', () async {
      final source = _FakeDataSource([booking(startOffset: 1, endOffset: 4)]);
      final repository = BookingRepositoryImpl(source, clock: () => _now);

      await expectLater(
        repository.create(
          carId: 'car-1',
          carModel: 'Tesla Model 3',
          userId: 'u1',
          period: period(1, 4),
          totalCents: 15000,
          depositCents: 20000,
        ),
        throwsA(isA<CarUnavailableException>()),
      );

      expect(source.createCalls, 0);
    });

    test('the exception carries the clashing window', () async {
      final repository = repositoryWith([booking(startOffset: 1, endOffset: 4)]);

      try {
        await book(repository, period(2, 3));
        fail('expected a CarUnavailableException');
      } on CarUnavailableException catch (error) {
        expect(error.conflict.start, _now.add(const Duration(days: 1)));
        expect(error.conflict.end, _now.add(const Duration(days: 4)));
      }
    });
  });

  group('cancel then rebook', () {
    test('frees the dates for a new booking', () async {
      final source = _FakeDataSource([booking(startOffset: 1, endOffset: 4)]);
      final repository = BookingRepositoryImpl(source, clock: () => _now);

      await expectLater(
        book(repository, period(1, 4)),
        throwsA(isA<CarUnavailableException>()),
      );

      await repository.cancel('b1');

      await expectLater(book(repository, period(1, 4)), completes);
    });
  });
}
