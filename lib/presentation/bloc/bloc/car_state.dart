import 'package:car_rental_app/data/models/car.dart';
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
  final List<Car> cars;

  const CarsLoaded(this.cars);

  @override
  List<Object?> get props => [cars];
}

class CarsError extends CarState {
  /// A message already phrased for the user; never a raw `toString()`.
  final String message;

  const CarsError(this.message);

  @override
  List<Object?> get props => [message];
}
