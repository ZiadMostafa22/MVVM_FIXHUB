import 'package:car_maintenance_system_new/features/car/domain/repositories/car_repository.dart';

/// Use case to delete a car
class DeleteCarUseCase {
  final CarRepository repository;

  DeleteCarUseCase(this.repository);

  Future<void> call(String carId) async {
    await repository.deleteCar(carId);
  }
}

