import 'package:car_rental_app/core/location/location_service.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/car_query.dart';
import 'package:car_rental_app/domain/usecases/get_cars.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

const _tesla = Car(
  id: 'a',
  model: 'Tesla Model 3',
  distance: 491,
  fuelCapacity: 60,
  pricePerDay: 89,
  seats: 5,
  transmission: Transmission.automatic,
  fuelType: FuelType.electric,
  rating: 4.8,
  latitude: 1,
  longitude: 1,
);

const _bmw = Car(
  id: 'b',
  model: 'BMW M4',
  distance: 520,
  fuelCapacity: 59,
  pricePerDay: 175,
  seats: 4,
  transmission: Transmission.manual,
  fuelType: FuelType.petrol,
  rating: 4.2,
  latitude: 5,
  longitude: 5,
);

CarBloc build({
  List<Car> cars = const [_tesla, _bmw],
  FakeFavourites? favourites,
  FakeAuth? auth,
  FakeLocation? location,
  Object? loadError,
}) {
  return CarBloc(
    getCars: GetCars(
      loadError != null
          ? FakeCarRepository.failing(loadError)
          : FakeCarRepository.returning(cars),
    ),
    favourites: favourites ?? FakeFavourites(),
    auth: auth ?? FakeAuth(),
    location: location ?? FakeLocation(),
  );
}

Future<CarsLoaded> loaded(CarBloc bloc) async {
  bloc.add(LoadCars());
  await bloc.stream.firstWhere((state) => state is CarsLoaded);
  return bloc.state as CarsLoaded;
}

void main() {
  test('starts in the loading state', () {
    final bloc = build();

    expect(bloc.state, isA<CarsLoading>());

    bloc.close();
  });

  group('loading', () {
    test('emits loading then loaded on success', () async {
      final bloc = build();

      final state = await loaded(bloc);

      expect(state.all, hasLength(2));
      expect(state.cars, hasLength(2));

      await bloc.close();
    });

    test('emits an error with a friendly message on failure', () async {
      final bloc = build(loadError: Exception('network down'));

      bloc.add(LoadCars());
      await bloc.stream.firstWhere((state) => state is CarsError);

      final message = (bloc.state as CarsError).message;
      expect(message, isNot(contains('network down')));

      await bloc.close();
    });

    test('emits an empty loaded state rather than an error for no cars',
        () async {
      final bloc = build(cars: const []);

      final state = await loaded(bloc);

      expect(state.cars, isEmpty);
      expect(state.filteredToNothing, isFalse);

      await bloc.close();
    });

    test('loads saved favourites', () async {
      final bloc = build(favourites: FakeFavourites(saved: {'a'}));

      final state = await loaded(bloc);

      expect(state.isFavourite('a'), isTrue);
      expect(state.isFavourite('b'), isFalse);

      await bloc.close();
    });

    test('a favourites failure does not fail the car list', () async {
      final bloc = build(
        favourites: FakeFavourites(error: Exception('permission denied')),
      );

      final state = await loaded(bloc);

      expect(state.cars, hasLength(2));
      expect(state.favourites, isEmpty);

      await bloc.close();
    });

    test('keeps the query across a refresh', () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(QueryChanged(const CarQuery(search: 'tesla')));
      await bloc.stream.first;

      bloc.add(LoadCars());
      await bloc.stream.firstWhere((s) => s is CarsLoaded);

      final state = bloc.state as CarsLoaded;
      expect(state.query.search, 'tesla');
      expect(state.cars, hasLength(1));

      await bloc.close();
    });
  });

  group('filtering', () {
    test('search narrows the list', () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(QueryChanged(const CarQuery(search: 'bmw')));
      await bloc.stream.first;

      final state = bloc.state as CarsLoaded;
      expect(state.cars.single.model, 'BMW M4');
      expect(state.all, hasLength(2), reason: 'the source list is kept');

      await bloc.close();
    });

    test('reports when filters hide everything', () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(QueryChanged(const CarQuery(search: 'lamborghini')));
      await bloc.stream.first;

      final state = bloc.state as CarsLoaded;
      expect(state.cars, isEmpty);
      expect(state.filteredToNothing, isTrue);

      await bloc.close();
    });

    test('clearing filters restores the list but keeps the sort', () async {
      final bloc = build();
      await loaded(bloc);

      bloc.add(
        QueryChanged(
          const CarQuery(search: 'bmw', sort: CarSort.priceHighToLow),
        ),
      );
      await bloc.stream.first;

      bloc.add(ClearFilters());
      await bloc.stream.first;

      final state = bloc.state as CarsLoaded;
      expect(state.cars, hasLength(2));
      expect(state.query.sort, CarSort.priceHighToLow);
      expect(state.query.hasFilters, isFalse);

      await bloc.close();
    });

    test('ignores a query change before the cars load', () async {
      final bloc = build();

      bloc.add(QueryChanged(const CarQuery(search: 'bmw')));

      expect(bloc.state, isA<CarsLoading>());

      await bloc.close();
    });
  });

  group('favourites', () {
    test('toggling saves and persists', () async {
      final favourites = FakeFavourites();
      final bloc = build(favourites: favourites);
      await loaded(bloc);

      bloc.add(ToggleFavourite('a'));
      await bloc.stream.first;

      expect((bloc.state as CarsLoaded).isFavourite('a'), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(favourites.toggled, ['a']);

      await bloc.close();
    });

    test('toggling twice removes it', () async {
      final bloc = build(favourites: FakeFavourites(saved: {'a'}));
      await loaded(bloc);

      bloc.add(ToggleFavourite('a'));
      await bloc.stream.first;

      expect((bloc.state as CarsLoaded).isFavourite('a'), isFalse);

      await bloc.close();
    });

    test('rolls the heart back when the write fails', () async {
      final bloc = build();
      await loaded(bloc);

      // Fails only on toggle, so the initial load still succeeds.
      final failing = build(
        favourites: FakeFavourites(error: Exception('offline')),
      );
      await loaded(failing);

      failing.add(ToggleFavourite('a'));
      await failing.stream.firstWhere(
        (s) => s is CarsLoaded && !s.isFavourite('a'),
      );

      expect((failing.state as CarsLoaded).isFavourite('a'), isFalse);

      await bloc.close();
      await failing.close();
    });

    test('favouriteCars lists the saved cars', () async {
      final bloc = build(favourites: FakeFavourites(saved: {'b'}));
      final state = await loaded(bloc);

      expect(state.favouriteCars.single.model, 'BMW M4');

      await bloc.close();
    });
  });

  group('location', () {
    test('sorts nearest first once a position is known', () async {
      final bloc = build(
        location: FakeLocation(position: const UserPosition(1, 1)),
      );
      await loaded(bloc);

      bloc.add(QueryChanged(const CarQuery(sort: CarSort.nearest)));
      await bloc.stream.first;
      bloc.add(RequestLocation());
      await bloc.stream.firstWhere(
        (s) => s is CarsLoaded && s.position != null,
      );

      final state = bloc.state as CarsLoaded;
      // Tesla is at the user's position, BMW is further away.
      expect(state.cars.first.model, 'Tesla Model 3');

      await bloc.close();
    });

    test('records the failure and leaves the order alone when denied',
        () async {
      final bloc = build(
        location: FakeLocation(failure: LocationFailure.deniedForever),
      );
      await loaded(bloc);

      bloc.add(RequestLocation());
      await bloc.stream.firstWhere(
        (s) => s is CarsLoaded && s.locationFailure != null,
      );

      final state = bloc.state as CarsLoaded;
      expect(state.locationFailure, LocationFailure.deniedForever);
      expect(state.position, isNull);
      // Degrades to the existing order rather than an arbitrary one.
      expect(state.cars, hasLength(2));

      await bloc.close();
    });

    test('does not request a position unless asked', () async {
      final location = FakeLocation(position: const UserPosition(1, 1));
      final bloc = build(location: location);
      await loaded(bloc);

      expect(location.calls, 0);

      await bloc.close();
    });
  });
}
