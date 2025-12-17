import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/car/data/di/car_di.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/get_cars_usecase.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/get_car_by_id_usecase.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/add_car_usecase.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/update_car_usecase.dart';
import 'package:car_maintenance_system_new/features/car/domain/usecases/delete_car_usecase.dart';

/// Get Cars Use Case Provider
final getCarsUseCaseProvider = Provider<GetCarsUseCase>((ref) {
  final repository = ref.watch(carRepositoryProvider);
  return GetCarsUseCase(repository);
});

/// Get Car By ID Use Case Provider
final getCarByIdUseCaseProvider = Provider<GetCarByIdUseCase>((ref) {
  final repository = ref.watch(carRepositoryProvider);
  return GetCarByIdUseCase(repository);
});

/// Add Car Use Case Provider
final addCarUseCaseProvider = Provider<AddCarUseCase>((ref) {
  final repository = ref.watch(carRepositoryProvider);
  return AddCarUseCase(repository);
});

/// Update Car Use Case Provider
final updateCarUseCaseProvider = Provider<UpdateCarUseCase>((ref) {
  final repository = ref.watch(carRepositoryProvider);
  return UpdateCarUseCase(repository);
});

/// Delete Car Use Case Provider
final deleteCarUseCaseProvider = Provider<DeleteCarUseCase>((ref) {
  final repository = ref.watch(carRepositoryProvider);
  return DeleteCarUseCase(repository);
});

