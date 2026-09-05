import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 5);

  RentalPeriod build(int startOffset, int endOffset) {
    final result = RentalPeriod.validate(
      start: now.add(Duration(days: startOffset)),
      end: now.add(Duration(days: endOffset)),
      now: now,
    );
    return result.period!;
  }

  group('validate', () {
    test('accepts a normal window and counts calendar days', () {
      final result = RentalPeriod.validate(
        start: DateTime(2026, 9, 6),
        end: DateTime(2026, 9, 9),
        now: now,
      );

      expect(result.error, isNull);
      expect(result.period!.days, 3);
    });

    test('counts one day for consecutive dates', () {
      expect(build(0, 1).days, 1);
    });

    test('ignores the time of day', () {
      final result = RentalPeriod.validate(
        start: DateTime(2026, 9, 6, 23, 59),
        end: DateTime(2026, 9, 9, 0, 1),
        now: now,
      );

      expect(result.period!.days, 3);
    });

    test('rejects an end before the start', () {
      final result = RentalPeriod.validate(
        start: DateTime(2026, 9, 9),
        end: DateTime(2026, 9, 6),
        now: now,
      );

      expect(result.period, isNull);
      expect(result.error, RentalPeriodError.endBeforeStart);
    });

    test('rejects a same-day return as too short', () {
      final result = RentalPeriod.validate(
        start: DateTime(2026, 9, 6),
        end: DateTime(2026, 9, 6),
        now: now,
      );

      expect(result.error, RentalPeriodError.tooShort);
    });

    test('rejects a start in the past', () {
      final result = RentalPeriod.validate(
        start: DateTime(2026, 9, 4),
        end: DateTime(2026, 9, 9),
        now: now,
      );

      expect(result.error, RentalPeriodError.startsInThePast);
    });

    test('accepts a start earlier today', () {
      final result = RentalPeriod.validate(
        start: DateTime(2026, 9, 5, 8),
        end: DateTime(2026, 9, 7),
        now: DateTime(2026, 9, 5, 20),
      );

      expect(result.error, isNull);
    });

    test('rejects a rental longer than the maximum', () {
      final result = RentalPeriod.validate(
        start: now,
        end: now.add(const Duration(days: RentalPeriod.maxDays + 1)),
        now: now,
      );

      expect(result.error, RentalPeriodError.tooLong);
    });

    test('accepts exactly the maximum', () {
      final result = RentalPeriod.validate(
        start: now,
        end: now.add(const Duration(days: RentalPeriod.maxDays)),
        now: now,
      );

      expect(result.error, isNull);
    });

    test('every error carries a message', () {
      for (final error in RentalPeriodError.values) {
        expect(error.message, isNotEmpty);
      }
    });
  });

  group('overlaps', () {
    test('detects a contained range', () {
      expect(build(1, 10).overlaps(build(3, 5)), isTrue);
    });

    test('detects a partial overlap from either side', () {
      expect(build(1, 5).overlaps(build(3, 8)), isTrue);
      expect(build(3, 8).overlaps(build(1, 5)), isTrue);
    });

    test('detects an identical range', () {
      expect(build(1, 5).overlaps(build(1, 5)), isTrue);
    });

    test('treats touching ends as free', () {
      // One rental ends the same day the next begins: the car is handed over.
      expect(build(1, 5).overlaps(build(5, 9)), isFalse);
      expect(build(5, 9).overlaps(build(1, 5)), isFalse);
    });

    test('treats separated ranges as free', () {
      expect(build(1, 3).overlaps(build(7, 9)), isFalse);
    });
  });

  test('stored skips the past-date rule', () {
    final period = RentalPeriod.stored(
      start: DateTime(2020, 1, 1),
      end: DateTime(2020, 1, 4),
    );

    expect(period.days, 3);
  });

  test('compares by value', () {
    expect(build(1, 4), equals(build(1, 4)));
    expect(build(1, 4), isNot(equals(build(1, 5))));
  });
}
