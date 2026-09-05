import 'package:car_rental_app/core/theme/app_theme.dart';
import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:car_rental_app/domain/repositories/auth_repository.dart';
import 'package:car_rental_app/domain/repositories/booking_repository.dart';
import 'package:car_rental_app/presentation/bloc/booking/my_bookings_cubit.dart';
import 'package:car_rental_app/presentation/pages/my_bookings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 5);

Booking booking({
  required String id,
  required int startOffset,
  required int endOffset,
  BookingStatus status = BookingStatus.confirmed,
  String model = 'Tesla Model 3',
}) {
  return Booking(
    id: id,
    carId: 'car-1',
    carModel: model,
    userId: 'u1',
    start: _now.add(Duration(days: startOffset)),
    end: _now.add(Duration(days: endOffset)),
    totalCents: 15000,
    depositCents: 20000,
    status: status,
    createdAt: _now,
  );
}

class _FakeAuth implements AuthRepository {
  @override
  String? get currentUserId => 'u1';

  @override
  Future<String> ensureSignedIn() async => 'u1';

  @override
  Stream<String?> get userIdChanges => Stream.value('u1');
}

class _FakeBookings implements BookingRepository {
  List<Booking> stored;
  final Object? loadError;
  final List<String> cancelled = [];

  _FakeBookings(this.stored, {this.loadError});

  @override
  Future<List<Booking>> forUser(String userId) async {
    if (loadError != null) throw loadError!;
    return stored;
  }

  @override
  Future<void> cancel(String bookingId) async {
    cancelled.add(bookingId);
    stored = stored
        .map((b) => b.id == bookingId
            ? b.copyWith(status: BookingStatus.cancelled)
            : b)
        .toList();
  }

  @override
  Future<Booking> create({
    required String carId,
    required String carModel,
    required String userId,
    required RentalPeriod period,
    required int totalCents,
    required int depositCents,
  }) =>
      throw UnimplementedError();
}

MyBookingsCubit _cubitWith(_FakeBookings bookings) {
  return MyBookingsCubit(
    bookings: bookings,
    auth: _FakeAuth(),
    clock: () => _now,
  );
}

Future<void> _pumpView(WidgetTester tester, MyBookingsCubit cubit) async {
  await tester.pumpWidget(
    BlocProvider.value(
      value: cubit,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const MyBookingsView(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('splitting', () {
    test('a future confirmed booking is upcoming', () async {
      final cubit = _cubitWith(
        _FakeBookings([booking(id: 'b1', startOffset: 1, endOffset: 4)]),
      );

      await cubit.load();

      final state = cubit.state as MyBookingsLoaded;
      expect(state.upcoming, hasLength(1));
      expect(state.past, isEmpty);
    });

    test('a finished booking is past', () async {
      final cubit = _cubitWith(
        _FakeBookings([booking(id: 'b1', startOffset: -10, endOffset: -5)]),
      );

      await cubit.load();

      final state = cubit.state as MyBookingsLoaded;
      expect(state.upcoming, isEmpty);
      expect(state.past, hasLength(1));
    });

    test('a cancelled future booking is past, not upcoming', () async {
      final cubit = _cubitWith(
        _FakeBookings([
          booking(
            id: 'b1',
            startOffset: 1,
            endOffset: 4,
            status: BookingStatus.cancelled,
          ),
        ]),
      );

      await cubit.load();

      final state = cubit.state as MyBookingsLoaded;
      expect(state.upcoming, isEmpty);
      expect(state.past, hasLength(1));
    });

    test('a booking running right now is upcoming', () async {
      final cubit = _cubitWith(
        _FakeBookings([booking(id: 'b1', startOffset: -1, endOffset: 2)]),
      );

      await cubit.load();

      expect((cubit.state as MyBookingsLoaded).upcoming, hasLength(1));
    });

    test('upcoming is soonest first, past is most recent first', () async {
      final cubit = _cubitWith(
        _FakeBookings([
          booking(id: 'far', startOffset: 20, endOffset: 22),
          booking(id: 'soon', startOffset: 2, endOffset: 4),
          booking(id: 'old', startOffset: -30, endOffset: -28),
          booking(id: 'recent', startOffset: -5, endOffset: -3),
        ]),
      );

      await cubit.load();

      final state = cubit.state as MyBookingsLoaded;
      expect(state.upcoming.map((b) => b.id), ['soon', 'far']);
      expect(state.past.map((b) => b.id), ['recent', 'old']);
    });

    test('reports a friendly message on failure', () async {
      final cubit = _cubitWith(
        _FakeBookings([], loadError: Exception('boom')),
      );

      await cubit.load();

      final state = cubit.state as MyBookingsError;
      expect(state.message, isNot(contains('boom')));
      expect(state.message, contains('loading your bookings'));
    });

    test('cancelling reloads and moves the booking to past', () async {
      final repository =
          _FakeBookings([booking(id: 'b1', startOffset: 1, endOffset: 4)]);
      final cubit = _cubitWith(repository);

      await cubit.load();
      await cubit.cancel('b1');

      expect(repository.cancelled, ['b1']);
      final state = cubit.state as MyBookingsLoaded;
      expect(state.upcoming, isEmpty);
      expect(state.past.single.status, BookingStatus.cancelled);
    });
  });

  group('view', () {
    testWidgets('shows a booking with its reference and status',
        (tester) async {
      final cubit = _cubitWith(
        _FakeBookings([booking(id: 'b1', startOffset: 1, endOffset: 4)]),
      );
      await cubit.load();
      await _pumpView(tester, cubit);

      expect(find.text('Tesla Model 3'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.textContaining('CR-'), findsOneWidget);
      expect(find.textContaining('3 days'), findsOneWidget);
    });

    testWidgets('shows an empty state when there is nothing', (tester) async {
      final cubit = _cubitWith(_FakeBookings([]));
      await cubit.load();
      await _pumpView(tester, cubit);

      expect(find.text('No upcoming bookings'), findsOneWidget);
    });

    testWidgets('cancelling asks first and can be declined', (tester) async {
      final repository =
          _FakeBookings([booking(id: 'b1', startOffset: 1, endOffset: 4)]);
      final cubit = _cubitWith(repository);
      await cubit.load();
      await _pumpView(tester, cubit);

      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();

      expect(find.text('Cancel this booking?'), findsOneWidget);

      await tester.tap(find.text('Keep it'));
      await tester.pumpAndSettle();

      expect(repository.cancelled, isEmpty);
    });

    testWidgets('confirming the dialog cancels the booking', (tester) async {
      final repository =
          _FakeBookings([booking(id: 'b1', startOffset: 1, endOffset: 4)]);
      final cubit = _cubitWith(repository);
      await cubit.load();
      await _pumpView(tester, cubit);

      await tester.tap(find.text('Cancel booking'));
      await tester.pumpAndSettle();

      // The dialog's confirm button, not the card's.
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel booking'));
      await tester.pumpAndSettle();

      expect(repository.cancelled, ['b1']);
      expect(find.text('No upcoming bookings'), findsOneWidget);
    });

    testWidgets('a completed booking offers no cancel action', (tester) async {
      final cubit = _cubitWith(
        _FakeBookings([
          booking(
            id: 'b1',
            startOffset: -10,
            endOffset: -5,
            status: BookingStatus.completed,
          ),
        ]),
      );
      await cubit.load();
      await _pumpView(tester, cubit);

      expect(find.text('Cancel booking'), findsNothing);
    });

    testWidgets('does not overflow on a small screen', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final cubit = _cubitWith(
        _FakeBookings([
          booking(
            id: 'b1',
            startOffset: 1,
            endOffset: 4,
            model: 'Mercedes-Benz E-Class All-Terrain Estate',
          ),
        ]),
      );
      await cubit.load();
      await _pumpView(tester, cubit);

      expect(tester.takeException(), isNull);
    });
  });
}
