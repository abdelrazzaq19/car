import 'package:bloc/bloc.dart';
import 'package:car_rental_app/core/error/failure_message.dart';
import 'package:car_rental_app/domain/usecases/get_cars.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_event.dart';
import 'package:car_rental_app/presentation/bloc/bloc/car_state.dart';

class CarBloc extends Bloc<CarEvent, CarState> {
  final GetCars getCars;

  CarBloc({required this.getCars}) : super(const CarsLoading()) {
    on<LoadCars>((event, emit) async {
      emit(const CarsLoading());
      try {
        emit(CarsLoaded(await getCars.call()));
      } catch (error) {
        emit(CarsError(failureMessage(error)));
      }
    });
  }
}
