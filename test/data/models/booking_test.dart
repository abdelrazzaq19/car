import 'package:car_rental_app/data/models/booking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 9, 6);
  final end = DateTime(2026, 9, 9);

  Booking build({String id = 'b1'}) => Booking(
        id: id,
        carId: 'car-1',
        carModel: 'Tesla Model 3',
        userId: 'u1',
        start: start,
        end: end,
        totalCents: 19000,
        depositCents: 20000,
        status: BookingStatus.confirmed,
        createdAt: DateTime(2026, 9, 5),
      );

  group('fromMap', () {
    test('reads Firestore timestamps', () {
      final booking = Booking.fromMap({
        'carId': 'car-1',
        'carModel': 'Tesla Model 3',
        'userId': 'u1',
        'start': Timestamp.fromDate(start),
        'end': Timestamp.fromDate(end),
        'totalCents': 19000,
        'depositCents': 20000,
        'status': 'confirmed',
        'createdAt': Timestamp.fromDate(DateTime(2026, 9, 5)),
      }, id: 'b1');

      expect(booking.start, start);
      expect(booking.days, 3);
      expect(booking.status, BookingStatus.confirmed);
    });

    test('defaults an unknown status to pending rather than throwing', () {
      final booking = Booking.fromMap({'status': 'nonsense'}, id: 'b1');

      expect(booking.status, BookingStatus.pending);
    });

    test('survives a document with missing fields', () {
      final booking = Booking.fromMap(const {}, id: 'b1');

      expect(booking.carModel, 'Unknown car');
      expect(booking.totalCents, 0);
    });

    test('round-trips through toMap', () {
      final restored = Booking.fromMap(build().toMap(), id: 'b1');

      expect(restored, equals(build()));
    });
  });

  group('status rules', () {
    test('cancelled and completed do not block availability', () {
      expect(BookingStatus.cancelled.blocksAvailability, isFalse);
      expect(BookingStatus.completed.blocksAvailability, isFalse);
      expect(BookingStatus.confirmed.blocksAvailability, isTrue);
      expect(BookingStatus.pending.blocksAvailability, isTrue);
      expect(BookingStatus.active.blocksAvailability, isTrue);
    });

    test('only pending and confirmed can be cancelled', () {
      expect(BookingStatus.pending.isCancellable, isTrue);
      expect(BookingStatus.confirmed.isCancellable, isTrue);
      expect(BookingStatus.active.isCancellable, isFalse);
      expect(BookingStatus.completed.isCancellable, isFalse);
      expect(BookingStatus.cancelled.isCancellable, isFalse);
    });

    test('every status has a label', () {
      for (final status in BookingStatus.values) {
        expect(status.label, isNotEmpty);
      }
    });
  });

  group('reference', () {
    test('is stable for the same booking', () {
      expect(build().reference, build().reference);
    });

    test('differs between bookings', () {
      expect(build(id: 'b1').reference, isNot(build(id: 'b2').reference));
    });

    test('has the expected shape', () {
      expect(build().reference, matches(RegExp(r'^CR-[0-9A-F]{6}$')));
    });
  });

  test('copyWith changes only the status', () {
    final cancelled = build().copyWith(status: BookingStatus.cancelled);

    expect(cancelled.status, BookingStatus.cancelled);
    expect(cancelled.id, build().id);
    expect(cancelled.start, build().start);
  });
}
