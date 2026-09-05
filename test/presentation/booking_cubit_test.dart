import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:car_rental_app/domain/repositories/auth_repository.dart';
import 'package:car_rental_app/domain/repositories/booking_repository.dart';
import 'package:car_rental_app/presentation/bloc/booking/booking_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 5);

const _car = Car(
  id: 'car-1',
  model: 'Tesla Model 3',
  distance: 491,
  fuelCapacity: 60,
  pricePerDay: 50,
);

class _FakeAuth implements AuthRepository {
  static const uid = 'u1';

  final Object? error;
  int signInCalls = 0;

  _FakeAuth({this.error});

  @override
  String? get currentUserId => uid;


  @override
  Future<String> ensureSignedIn() async {
    signInCalls++;
    if (error != null) throw error!;
    return uid;
  }

  @override
  Stream<String?> get userIdChanges => Stream.value(uid);
}

class _FakeBookings implements BookingRepository {
  final Object? throwOnCreate;
  RentalPeriod? received;
  int? receivedTotal;

  _FakeBookings({this.throwOnCreate});

  @override
  Future<Booking> create({
    required String carId,
    required String carModel,
    required String userId,
    required RentalPeriod period,
    required int totalCents,
    required int depositCents,
  }) async {
    if (throwOnCreate != null) throw throwOnCreate!;

    received = period;
    receivedTotal = totalCents;

    return Booking(
      id: 'b1',
      carId: carId,
      carModel: carModel,
      userId: userId,
      start: period.start,
      end: period.end,
      totalCents: totalCents,
      depositCents: depositCents,
      status: BookingStatus.confirmed,
      createdAt: _now,
    );
  }

  @override
  Future<List<Booking>> forUser(String userId) async => [];

  @override
  Future<void> cancel(String bookingId) async {}
}

BookingCubit build({
  BookingRepository? bookings,
  AuthRepository? auth,
}) {
  return BookingCubit(
    car: _car,
    bookings: bookings ?? _FakeBookings(),
    auth: auth ?? _FakeAuth(),
    clock: () => _now,
  );
}

void main() {
  group('selectDates', () {
    test('quotes a valid window', () {
      final cubit = build();

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 4)),
      );

      final state = cubit.state as BookingQuoted;
      expect(state.period.days, 3);
      // 50 a day for 3 days.
      expect(state.quote.subtotalCents, 15000);
    });

    test('rejects an end before the start', () {
      final cubit = build();

      cubit.selectDates(
        start: _now.add(const Duration(days: 4)),
        end: _now.add(const Duration(days: 1)),
      );

      expect(cubit.state, isA<BookingInvalid>());
      expect(
        (cubit.state as BookingInvalid).message,
        RentalPeriodError.endBeforeStart.message,
      );
    });

    test('rejects a start in the past', () {
      final cubit = build();

      cubit.selectDates(
        start: _now.subtract(const Duration(days: 1)),
        end: _now.add(const Duration(days: 4)),
      );

      expect(cubit.state, isA<BookingInvalid>());
    });

    test('re-quotes when the dates change', () {
      final cubit = build();

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 3)),
      );
      final first = (cubit.state as BookingQuoted).quote.totalCents;

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 6)),
      );
      final second = (cubit.state as BookingQuoted).quote.totalCents;

      expect(second, greaterThan(first));
    });

    test('clearDates returns to idle', () {
      final cubit = build();

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 4)),
      );
      cubit.clearDates();

      expect(cubit.state, isA<BookingIdle>());
    });
  });

  group('confirm', () {
    test('does nothing without a quote', () async {
      final cubit = build();

      await cubit.confirm();

      expect(cubit.state, isA<BookingIdle>());
    });

    test('signs in and writes the booking', () async {
      final auth = _FakeAuth();
      final bookings = _FakeBookings();
      final cubit = build(auth: auth, bookings: bookings);

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 4)),
      );
      await cubit.confirm();

      expect(auth.signInCalls, 1);
      expect(bookings.received!.days, 3);
      // The total written matches the total quoted, deposit excluded.
      expect(bookings.receivedTotal, 15000 + 1500 + 2500);
      expect(cubit.state, isA<BookingConfirmed>());
      expect((cubit.state as BookingConfirmed).booking.id, 'b1');
    });

    test('reports taken dates distinctly so the UI can offer a re-pick',
        () async {
      final cubit = build(
        bookings: _FakeBookings(
          throwOnCreate: CarUnavailableException(
            RentalPeriod.stored(start: _now, end: _now.add(const Duration(days: 2))),
          ),
        ),
      );

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 4)),
      );
      await cubit.confirm();

      final state = cubit.state as BookingFailed;
      expect(state.datesTaken, isTrue);
      expect(state.message, contains('just taken'));
    });

    test('never leaks a raw exception into the message', () async {
      final cubit = build(
        bookings: _FakeBookings(
          throwOnCreate: FirebaseException(
            plugin: 'cloud_firestore',
            code: 'internal',
          ),
        ),
      );

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 4)),
      );
      await cubit.confirm();

      final state = cubit.state as BookingFailed;
      expect(state.datesTaken, isFalse);
      expect(state.message, isNot(contains('cloud_firestore')));
      expect(state.message, contains('confirming your booking'));
    });

    test('surfaces a sign-in failure without writing', () async {
      final bookings = _FakeBookings();
      final cubit = build(
        auth: _FakeAuth(error: StateError('no user')),
        bookings: bookings,
      );

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 4)),
      );
      await cubit.confirm();

      expect(cubit.state, isA<BookingFailed>());
      expect(bookings.received, isNull);
    });

    test('passes through submitting on the way to confirmed', () async {
      final cubit = build();
      final seen = <BookingState>[];
      final subscription = cubit.stream.listen(seen.add);

      cubit.selectDates(
        start: _now.add(const Duration(days: 1)),
        end: _now.add(const Duration(days: 4)),
      );
      await cubit.confirm();
      // Stream delivery is a microtask behind the emit.
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen.whereType<BookingSubmitting>(), hasLength(1));
      expect(seen.last, isA<BookingConfirmed>());
      expect(cubit.state, isA<BookingConfirmed>());
    });
  });
}
