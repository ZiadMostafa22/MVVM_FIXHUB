import 'package:car_maintenance_system_new/features/car/domain/repositories/car_repository.dart';

/// Use case to update a car
class UpdateCarUseCase {
  final CarRepository repository;

  UpdateCarUseCase(this.repository);

  Future<void> call(
    String carId,
    Map<String, dynamic> updates,
  ) async {
    await repository.updateCar(carId, updates);
  }
}

