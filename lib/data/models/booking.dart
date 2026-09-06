import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum BookingStatus {
  pending,
  confirmed,
  active,
  completed,
  cancelled;

  static BookingStatus parse(Object? value) {
    return BookingStatus.values.firstWhere(
      (status) => status.name == value?.toString().toLowerCase(),
      orElse: () => BookingStatus.pending,
    );
  }

  String get label => switch (this) {
        BookingStatus.pending => 'Pending',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.active => 'In progress',
        BookingStatus.completed => 'Completed',
        BookingStatus.cancelled => 'Cancelled',
      };

  /// A cancelled or finished booking frees its dates, so it must not block a
  /// rebooking.
  bool get blocksAvailability =>
      this != BookingStatus.cancelled && this != BookingStatus.completed;

  bool get isCancellable =>
      this == BookingStatus.pending || this == BookingStatus.confirmed;

  /// True once the booking is over, whether it ran or was called off.
  bool get isFinished =>
      this == BookingStatus.completed || this == BookingStatus.cancelled;
}

class Booking extends Equatable {
  final String id;
  final String carId;
  final String carModel;
  final String userId;
  final DateTime start;
  final DateTime end;
  final int totalCents;
  final int depositCents;
  final BookingStatus status;
  final DateTime createdAt;

  const Booking({
    required this.id,
    required this.carId,
    required this.carModel,
    required this.userId,
    required this.start,
    required this.end,
    required this.totalCents,
    required this.depositCents,
    required this.status,
    required this.createdAt,
  });

  factory Booking.fromMap(Map<String, dynamic> map, {required String id}) {
    return Booking(
      id: id,
      carId: _string(map['carId']),
      carModel: _string(map['carModel'], fallback: 'Unknown car'),
      userId: _string(map['userId']),
      start: _date(map['start']),
      end: _date(map['end']),
      totalCents: _int(map['totalCents']),
      depositCents: _int(map['depositCents']),
      status: BookingStatus.parse(map['status']),
      createdAt: _date(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'carId': carId,
      'carModel': carModel,
      'userId': userId,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'totalCents': totalCents,
      'depositCents': depositCents,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  RentalPeriod get period => RentalPeriod.stored(start: start, end: end);

  int get days => period.days;

  /// The status as it actually stands today.
  ///
  /// Nothing writes `active` or `completed` — there is no server job moving
  /// bookings along — so those are derived from the dates. Without this, a
  /// rental that finished last year still reads "Confirmed" and keeps holding
  /// its dates against a rebooking.
  BookingStatus statusAt(DateTime now) {
    if (status.isFinished) return status;

    final today = RentalPeriod.dateOnly(now);

    if (!end.isAfter(today)) return BookingStatus.completed;
    if (!start.isAfter(today)) return BookingStatus.active;

    return status;
  }

  /// Whether this booking still holds its dates as of [now].
  bool blocksAvailabilityAt(DateTime now) => statusAt(now).blocksAvailability;

  /// Cancellation is only offered before the car has been picked up.
  bool isCancellableAt(DateTime now) => statusAt(now).isCancellable;

  bool isUpcomingAt(DateTime now) => isCancellableAt(now);

  /// Short human-quotable code, e.g. "CR-4F2A9B". Derived from the document id
  /// so it needs no separate counter and cannot collide.
  String get reference {
    final source = id.isEmpty ? carId : id;
    final digest = source.codeUnits
        .fold<int>(7, (acc, unit) => (acc * 31 + unit) & 0xFFFFFF);
    return 'CR-${digest.toRadixString(16).toUpperCase().padLeft(6, '0')}';
  }

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      carId: carId,
      carModel: carModel,
      userId: userId,
      start: start,
      end: end,
      totalCents: totalCents,
      depositCents: depositCents,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value is String && value.isNotEmpty) return value;
    return fallback;
  }

  static int _int(Object? value) {
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    return DateTime(1970);
  }

  @override
  List<Object?> get props => [
        id,
        carId,
        carModel,
        userId,
        start,
        end,
        totalCents,
        depositCents,
        status,
        createdAt,
      ];
}
