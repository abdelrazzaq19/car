import 'package:car_rental_app/core/location/location_service.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/car_query.dart';
import 'package:equatable/equatable.dart';

/// Sealed so `switch` over the state is exhaustive: a new state is a compile
/// error at every call site rather than a silently blank screen.
sealed class CarState extends Equatable {
  const CarState();

  @override
  List<Object?> get props => [];
}

class CarsLoading extends CarState {
  const CarsLoading();
}

class CarsLoaded extends CarState {
  /// Everything fetched, before filtering. Kept so clearing a filter does not
  /// need a network round-trip.
  final List<Car> all;

  /// [all] with the query applied, in display order.
  final List<Car> cars;

  final CarQuery query;
  final Set<String> favourites;

  /// Null until the user grants location; distance sorting needs it.
  final UserPosition? position;

  /// Set when a location request failed, so the UI can explain why distance
  /// sorting is unavailable instead of silently doing nothing.
  final LocationFailure? locationFailure;

  const CarsLoaded(
    this.cars, {
    this.all = const [],
    this.query = CarQuery.empty,
    this.favourites = const {},
    this.position,
    this.locationFailure,
  });

  bool get isFiltered => query.hasFilters;

  /// True when cars exist but the filters hide them all — a different message
  /// from having no cars at all.
  bool get filteredToNothing => cars.isEmpty && all.isNotEmpty;

  bool isFavourite(String carId) => favourites.contains(carId);

  List<Car> get favouriteCars =>
      all.where((car) => favourites.contains(car.id)).toList();

  CarsLoaded copyWith({
    List<Car>? cars,
    List<Car>? all,
    CarQuery? query,
    Set<String>? favourites,
    UserPosition? position,
    LocationFailure? locationFailure,
    bool clearLocationFailure = false,
  }) {
    return CarsLoaded(
      cars ?? this.cars,
      all: all ?? this.all,
      query: query ?? this.query,
      favourites: favourites ?? this.favourites,
      position: position ?? this.position,
      locationFailure: clearLocationFailure
          ? null
          : (locationFailure ?? this.locationFailure),
    );
  }

  @override
  List<Object?> get props => [
        cars,
        all,
        query,
        favourites,
        position?.latitude,
        position?.longitude,
        locationFailure,
      ];
}

class CarsError extends CarState {
  /// A message already phrased for the user; never a raw `toString()`.
  final String message;

  const CarsError(this.message);

  @override
  List<Object?> get props => [message];
}
