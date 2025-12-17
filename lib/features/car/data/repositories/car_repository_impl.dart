import 'package:car_maintenance_system_new/features/car/domain/repositories/car_repository.dart';
import 'package:car_maintenance_system_new/features/car/domain/entities/car_entity.dart';
import 'package:car_maintenance_system_new/features/car/data/datasources/car_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/car/data/models/car_dto.dart';

/// Implementation of CarRepository
class CarRepositoryImpl implements CarRepository {
  final CarRemoteDataSource remoteDataSource;

  CarRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<CarEntity>> loadCars(String userId) async {
    final dataList = await remoteDataSource.loadCars(userId);

    var entities = dataList
        .map((data) => CarDto.fromFirestore(
              data,
              data['id'] as String,
            ).toEntity())
        .toList();

    // Sort in memory if we used where clause
    if (userId.isNotEmpty) {
      entities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return entities;
  }

  @override
  Future<CarEntity?> getCarById(String carId) async {
    final data = await remoteDataSource.getCarById(carId);
    if (data == null) return null;
    return CarDto.fromFirestore(data, carId).toEntity();
  }

  @override
  Future<String> createCar(CarEntity car) async {
    final dto = CarDto.fromEntity(car);
    return await remoteDataSource.createCar(dto.toFirestore());
  }

  @override
  Future<void> updateCar(
    String carId,
    Map<String, dynamic> updates,
  ) async {
    await remoteDataSource.updateCar(carId, updates);
  }

  @override
  Future<void> deleteCar(String carId) async {
    await remoteDataSource.deleteCar(carId);
  }
}

