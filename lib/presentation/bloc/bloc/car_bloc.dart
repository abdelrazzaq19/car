import 'package:bloc/bloc.dart';
import 'package:car_rental_app/core/error/failure_message.dart';
import 'package:car_rental_app/core/location/location_service.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/domain/entities/car_query.dart';
import 'package:car_rental_app/domain/repositories/auth_repository.dart';
import 'package:car_rental_app/domain/repositories/favourites_repository.dart';
import 'package:car_rental_app/domain/usecases/get_cars.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';

class CarBloc extends Bloc<CarEvent, CarState> {
  final GetCars getCars;
  final FavouritesRepository favourites;
  final AuthRepository auth;
  final LocationService location;

  CarBloc({
    required this.getCars,
    required this.favourites,
    required this.auth,
    required this.location,
  }) : super(const CarsLoading()) {
    on<LoadCars>(_onLoad);
    on<QueryChanged>(_onQueryChanged);
    on<ClearFilters>(_onClearFilters);
    on<ToggleFavourite>(_onToggleFavourite);
    on<RequestLocation>(_onRequestLocation);
  }

  Future<void> _onLoad(LoadCars event, Emitter<CarState> emit) async {
    // Keep the current query across a refresh, so pulling to refresh does not
    // silently drop the user's filters.
    final previous = state;
    final query = previous is CarsLoaded ? previous.query : CarQuery.empty;
    final position = previous is CarsLoaded ? previous.position : null;

    emit(const CarsLoading());

    try {
      final cars = await getCars.call();
      final saved = await _loadFavourites();

      emit(
        CarsLoaded(
          query.apply(cars, distanceTo: _distanceUsing(position)),
          all: cars,
          query: query,
          favourites: saved,
          position: position,
        ),
      );
    } catch (error) {
      emit(CarsError(failureMessage(error)));
    }
  }

  /// Favourites are a nicety: failing to read them must not fail the car list.
  Future<Set<String>> _loadFavourites() async {
    try {
      return await favourites.forUser(await auth.ensureSignedIn());
    } catch (_) {
      return const {};
    }
  }

  void _onQueryChanged(QueryChanged event, Emitter<CarState> emit) {
    final current = state;
    if (current is! CarsLoaded) return;

    emit(_reapply(current, event.query));
  }

  void _onClearFilters(ClearFilters event, Emitter<CarState> emit) {
    final current = state;
    if (current is! CarsLoaded) return;

    emit(_reapply(current, current.query.cleared()));
  }

  CarsLoaded _reapply(CarsLoaded current, CarQuery query) {
    return current.copyWith(
      query: query,
      cars: query.apply(
        current.all,
        distanceTo: _distanceUsing(current.position),
      ),
    );
  }

  Future<void> _onToggleFavourite(
    ToggleFavourite event,
    Emitter<CarState> emit,
  ) async {
    final current = state;
    if (current is! CarsLoaded) return;

    final updated = Set<String>.from(current.favourites);
    final wasFavourite = updated.contains(event.carId);

    // Optimistic: the heart responds immediately, and is put back if the
    // write fails.
    wasFavourite ? updated.remove(event.carId) : updated.add(event.carId);
    emit(current.copyWith(favourites: updated));

    try {
      await favourites.toggle(
        userId: await auth.ensureSignedIn(),
        carId: event.carId,
      );
    } catch (_) {
      emit(current.copyWith(favourites: current.favourites));
    }
  }

  Future<void> _onRequestLocation(
    RequestLocation event,
    Emitter<CarState> emit,
  ) async {
    final current = state;
    if (current is! CarsLoaded) return;

    final result = await location.current();
    final position = result.position;

    if (position == null) {
      emit(current.copyWith(locationFailure: result.failure));
      return;
    }

    emit(
      current.copyWith(
        position: position,
        clearLocationFailure: true,
        cars: current.query.apply(
          current.all,
          distanceTo: _distanceUsing(position),
        ),
      ),
    );
  }

  double? Function(Car)? _distanceUsing(UserPosition? position) {
    if (position == null) return null;

    return (car) {
      if (!car.hasLocation) return null;
      return location.distanceKm(
        from: position,
        latitude: car.latitude!,
        longitude: car.longitude!,
      );
    };
  }
}
