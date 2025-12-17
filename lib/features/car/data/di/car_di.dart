import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/car/data/datasources/car_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/car/data/repositories/car_repository_impl.dart';
import 'package:car_maintenance_system_new/features/car/domain/repositories/car_repository.dart';

/// Car Remote Data Source Provider
final carRemoteDataSourceProvider = Provider<CarRemoteDataSource>((ref) {
  return CarRemoteDataSource();
});

/// Car Repository Provider (binds interface to implementation)
final carRepositoryProvider = Provider<CarRepository>((ref) {
  final remoteDataSource = ref.watch(carRemoteDataSourceProvider);
  return CarRepositoryImpl(remoteDataSource);
});

