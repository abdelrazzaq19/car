import 'package:equatable/equatable.dart';

/// Why a period was rejected. Kept as a type rather than a string so the UI
/// decides the wording and tests do not assert on copy.
enum RentalPeriodError {
  endBeforeStart,
  tooShort,
  startsInThePast,
  tooLong;

  String get message => switch (this) {
        RentalPeriodError.endBeforeStart =>
          'The return date must be after the pick-up date.',
        RentalPeriodError.tooShort => 'The minimum rental is one day.',
        RentalPeriodError.startsInThePast =>
          'The pick-up date cannot be in the past.',
        RentalPeriodError.tooLong =>
          'The maximum rental is ${RentalPeriod.maxDays} days.',
      };
}

/// A validated pick-up to return window.
///
/// Days are counted on calendar dates, not on elapsed hours, which is how car
/// rental is actually billed: picking up Monday and returning Tuesday is one
/// day whatever the clock says.
class RentalPeriod extends Equatable {
  static const int maxDays = 90;

  final DateTime start;
  final DateTime end;

  const RentalPeriod._(this.start, this.end);

  /// Returns a validated period, or the reason it is not valid.
  static ({RentalPeriod? period, RentalPeriodError? error}) validate({
    required DateTime start,
    required DateTime end,
    DateTime? now,
  }) {
    final startDay = dateOnly(start);
    final endDay = dateOnly(end);
    final today = dateOnly(now ?? DateTime.now());

    if (startDay.isBefore(today)) {
      return (period: null, error: RentalPeriodError.startsInThePast);
    }
    if (endDay.isBefore(startDay)) {
      return (period: null, error: RentalPeriodError.endBeforeStart);
    }
    if (endDay.isAtSameMomentAs(startDay)) {
      return (period: null, error: RentalPeriodError.tooShort);
    }
    if (endDay.difference(startDay).inDays > maxDays) {
      return (period: null, error: RentalPeriodError.tooLong);
    }

    return (period: RentalPeriod._(startDay, endDay), error: null);
  }

  /// Builds a period without the "not in the past" rule, for reading a booking
  /// back out of storage after its start date has passed.
  factory RentalPeriod.stored({
    required DateTime start,
    required DateTime end,
  }) {
    return RentalPeriod._(dateOnly(start), dateOnly(end));
  }

  /// Strips the time so day maths is not thrown off by hours, and so daylight
  /// saving cannot turn a 3-day rental into 2 days and 23 hours.
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  int get days => end.difference(start).inDays;

  bool overlaps(RentalPeriod other) {
    // Touching ends do not overlap: one rental may end the day the next begins.
    return start.isBefore(other.end) && other.start.isBefore(end);
  }

  @override
  List<Object?> get props => [start, end];
}
