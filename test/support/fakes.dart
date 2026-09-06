import 'package:car_rental_app/core/location/location_service.dart';
import 'package:car_rental_app/data/models/booking.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/rental_period.dart';
import 'package:car_rental_app/domain/repositories/auth_repository.dart';
import 'package:car_rental_app/domain/repositories/booking_repository.dart';
import 'package:car_rental_app/domain/repositories/car_repository.dart';
import 'package:car_rental_app/domain/repositories/favourites_repository.dart';

/// Shared test doubles, so a signature change lands in one file.

class FakeAuth implements AuthRepository {
  final String uid;
  final Object? error;
  int signInCalls = 0;

  FakeAuth({this.uid = 'u1', this.error});

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

class FakeFavourites implements FavouritesRepository {
  Set<String> saved;
  final Object? error;
  final List<String> toggled = [];

  FakeFavourites({Set<String>? saved, this.error}) : saved = saved ?? {};

  @override
  Future<Set<String>> forUser(String userId) async {
    if (error != null) throw error!;
    return saved;
  }

  @override
  Future<bool> toggle({required String userId, required String carId}) async {
    if (error != null) throw error!;

    toggled.add(carId);

    if (saved.contains(carId)) {
      saved.remove(carId);
      return false;
    }
    saved.add(carId);
    return true;
  }
}

class FakeCarRepository implements CarRepository {
  final List<Car>? cars;
  final Object? error;

  FakeCarRepository.returning(this.cars) : error = null;
  FakeCarRepository.failing(this.error) : cars = null;

  @override
  Future<List<Car>> fetchCars() async {
    if (error != null) throw error!;
    return cars!;
  }
}

/// Straight-line distance on a flat plane. Exact geodesics do not matter for
/// asserting an ordering, and this keeps the tests off the platform channel.
class FakeLocation implements LocationService {
  final UserPosition? position;
  final LocationFailure? failure;
  int calls = 0;

  FakeLocation({this.position, this.failure});

  @override
  Future<({UserPosition? position, LocationFailure? failure})> current() async {
    calls++;
    return (position: position, failure: failure);
  }

  @override
  double distanceKm({
    required UserPosition from,
    required double latitude,
    required double longitude,
  }) {
    final dLat = latitude - from.latitude;
    final dLon = longitude - from.longitude;
    return (dLat * dLat + dLon * dLon) * 100;
  }
}

class FakeBookings implements BookingRepository {
  List<Booking> stored;
  final Object? loadError;
  final Object? createError;
  final List<String> cancelled = [];
  RentalPeriod? receivedPeriod;
  int? receivedTotal;

  FakeBookings({
    List<Booking>? stored,
    this.loadError,
    this.createError,
  }) : stored = stored ?? [];

  @override
  Future<Booking> create({
    required String carId,
    required String carModel,
    required String userId,
    required RentalPeriod period,
    required int totalCents,
    required int depositCents,
  }) async {
    if (createError != null) throw createError!;

    receivedPeriod = period;
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
      createdAt: DateTime(2026, 9, 5),
    );
  }

  @override
  Future<List<Booking>> forUser(String userId) async {
    if (loadError != null) throw loadError!;
    return stored;
  }

  @override
  Future<void> cancel(String bookingId) async {
    cancelled.add(bookingId);
    stored = stored
        .map((b) =>
            b.id == bookingId ? b.copyWith(status: BookingStatus.cancelled) : b)
        .toList();
  }
}
