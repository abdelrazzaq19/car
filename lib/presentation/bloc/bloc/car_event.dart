import 'package:car_rental_app/domain/entities/car_query.dart';

sealed class CarEvent {}

class LoadCars extends CarEvent {}

/// Replaces the whole query. The screen builds the new value from the old one,
/// so search, filters and sort never overwrite each other.
class QueryChanged extends CarEvent {
  final CarQuery query;

  QueryChanged(this.query);
}

class ClearFilters extends CarEvent {}

class ToggleFavourite extends CarEvent {
  final String carId;

  ToggleFavourite(this.carId);
}

/// Requests the device position, for sorting by distance.
class RequestLocation extends CarEvent {}
