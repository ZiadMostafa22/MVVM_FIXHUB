import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';

/// Repository interface for car operations
abstract class CarRepository {
  /// Load cars for a user or all cars if userId is empty
  Future<List<CarEntity>> loadCars(String userId);

  /// Get a single car by ID
  Future<CarEntity?> getCarById(String carId);

  /// Create a new car
  Future<String> createCar(CarEntity car);

  /// Update a car
  Future<void> updateCar(
    String carId,
    Map<String, dynamic> updates,
  );

  /// Delete a car
  Future<void> deleteCar(String carId);
}

