import 'package:car_maintenance_system_new/features/car/domain/repositories/car_repository.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

/// Use case to get a car by ID
class GetCarByIdUseCase {
  final CarRepository repository;

  GetCarByIdUseCase(this.repository);

  Future<CarEntity?> call(String carId) async {
    return await repository.getCarById(carId);
  }
}

