import 'package:car_maintenance_system_new/features/car/domain/repositories/car_repository.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

/// Use case to get cars
class GetCarsUseCase {
  final CarRepository repository;

  GetCarsUseCase(this.repository);

  Future<List<CarEntity>> call(String userId) async {
    return await repository.loadCars(userId);
  }
}

