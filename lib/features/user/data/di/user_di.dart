import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/user/data/datasources/user_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/user/data/repositories/user_repository_impl.dart';
import 'package:car_maintenance_system_new/features/user/domain/repositories/user_repository.dart';

/// User Remote Data Source Provider
final userRemoteDataSourceProvider = Provider<UserRemoteDataSource>((ref) {
  return UserRemoteDataSource();
});

/// User Repository Provider (binds interface to implementation)
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final remoteDataSource = ref.watch(userRemoteDataSourceProvider);
  return UserRepositoryImpl(remoteDataSource);
});

