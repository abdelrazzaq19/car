import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/repositories/car_repository.dart';
import 'package:car_rental_app/domain/usecases/get_cars.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements CarRepository {
  final List<Car>? cars;
  final Object? error;

  _FakeRepository.returning(this.cars) : error = null;
  _FakeRepository.failing(this.error) : cars = null;

  @override
  Future<List<Car>> fetchCars() async {
    if (error != null) throw error!;
    return cars!;
  }
}

void main() {
  const car = Car(
    model: 'Tesla Model 3',
    distance: 320,
    fuelCapacity: 54,
    pricePerDay: 89,
  );

  test('starts in the loading state', () {
    final bloc = CarBloc(getCars: GetCars(_FakeRepository.returning([car])));

    expect(bloc.state, isA<CarsLoading>());

    bloc.close();
  });

  test('emits loading then loaded on success', () async {
    final bloc = CarBloc(getCars: GetCars(_FakeRepository.returning([car])));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([isA<CarsLoading>(), isA<CarsLoaded>()]),
    );

    bloc.add(LoadCars());
    await states;

    final loaded = bloc.state as CarsLoaded;
    expect(loaded.cars, hasLength(1));
    expect(loaded.cars.single.model, 'Tesla Model 3');

    await bloc.close();
  });

  test('emits loading then error on failure', () async {
    final bloc = CarBloc(
      getCars: GetCars(_FakeRepository.failing(Exception('network down'))),
    );

    final states = expectLater(
      bloc.stream,
      emitsInOrder([isA<CarsLoading>(), isA<CarsError>()]),
    );

    bloc.add(LoadCars());
    await states;

    final message = (bloc.state as CarsError).message;
    // The raw exception must never reach the user.
    expect(message, isNot(contains('Exception')));
    expect(message, isNot(contains('network down')));
    expect(message, 'Something went wrong while loading cars. Please try again.');

    await bloc.close();
  });

  test('emits an empty loaded state rather than an error for no cars', () async {
    final bloc = CarBloc(getCars: GetCars(_FakeRepository.returning([])));

    final states = expectLater(
      bloc.stream,
      emitsInOrder([isA<CarsLoading>(), isA<CarsLoaded>()]),
    );

    bloc.add(LoadCars());
    await states;

    expect((bloc.state as CarsLoaded).cars, isEmpty);

    await bloc.close();
  });
}
