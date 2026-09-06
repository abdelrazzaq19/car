import 'package:car_rental_app/core/location/location_service.dart';
import 'package:car_rental_app/data/datasources/firebase_booking_data_source.dart';
import 'package:car_rental_app/data/datasources/firebase_car_data_source.dart';
import 'package:car_rental_app/data/models/car.dart';
import 'package:car_rental_app/data/repositories/auth_repository_impl.dart';
import 'package:car_rental_app/data/repositories/booking_repository_impl.dart';
import 'package:car_rental_app/data/repositories/favourites_repository_impl.dart';
import 'package:car_rental_app/data/repositories/car_repository_impl.dart';
import 'package:car_rental_app/domain/repositories/auth_repository.dart';
import 'package:car_rental_app/domain/repositories/booking_repository.dart';
import 'package:car_rental_app/domain/repositories/car_repository.dart';
import 'package:car_rental_app/domain/repositories/favourites_repository.dart';
import 'package:car_rental_app/domain/usecases/get_cars.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_bloc.dart';
import 'package:car_rental_app/presentation/bloc/booking/booking_cubit.dart';
import 'package:car_rental_app/presentation/bloc/booking/my_bookings_cubit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

GetIt getIt = GetIt.instance;

/// Registers the object graph.
///
/// Idempotent: a hot restart re-runs this, and get_it throws on a duplicate
/// registration, so every entry is guarded.
void initInjection() {
  _lazy<FirebaseFirestore>(() => FirebaseFirestore.instance);
  _lazy<FirebaseAuth>(() => FirebaseAuth.instance);

  _lazy<FirebaseCarDataSource>(
    () => FirebaseCarDataSource(firestore: getIt<FirebaseFirestore>()),
  );
  _lazy<FirebaseBookingDataSource>(
    () => FirebaseBookingDataSource(firestore: getIt<FirebaseFirestore>()),
  );

  _lazy<CarRepository>(
    () => CarRepositoryImpl(getIt<FirebaseCarDataSource>()),
  );
  _lazy<BookingRepository>(
    () => BookingRepositoryImpl(getIt<FirebaseBookingDataSource>()),
  );
  _lazy<AuthRepository>(() => AuthRepositoryImpl(getIt<FirebaseAuth>()));
  _lazy<FavouritesRepository>(
    () => FavouritesRepositoryImpl(getIt<FirebaseFirestore>()),
  );
  _lazy<LocationService>(() => const GeolocatorLocationService());

  _lazy<GetCars>(() => GetCars(getIt<CarRepository>()));

  _factory<CarBloc>(
    () => CarBloc(
      getCars: getIt<GetCars>(),
      favourites: getIt<FavouritesRepository>(),
      auth: getIt<AuthRepository>(),
      location: getIt<LocationService>(),
    ),
  );
  _factory<MyBookingsCubit>(
    () => MyBookingsCubit(
      bookings: getIt<BookingRepository>(),
      auth: getIt<AuthRepository>(),
    ),
  );

  // Parameterised by the car being booked.
  if (!getIt.isRegistered<BookingCubit>()) {
    getIt.registerFactoryParam<BookingCubit, Car, void>(
      (car, _) => BookingCubit(
        car: car,
        bookings: getIt<BookingRepository>(),
        auth: getIt<AuthRepository>(),
      ),
    );
  }
}

void _lazy<T extends Object>(T Function() create) {
  if (!getIt.isRegistered<T>()) getIt.registerLazySingleton<T>(create);
}

void _factory<T extends Object>(T Function() create) {
  if (!getIt.isRegistered<T>()) getIt.registerFactory<T>(create);
}
