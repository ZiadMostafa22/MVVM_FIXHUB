import 'package:car_maintenance_system_new/features/car/domain/repositories/car_repository.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

/// Use case to add a new car
class AddCarUseCase {
  final CarRepository repository;

  AddCarUseCase(this.repository);

  Future<String> call(CarEntity car) async {
    return await repository.createCar(car);
  }
}

