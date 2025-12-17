import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:car_maintenance_system_new/features/auth/domain/repositories/auth_repository.dart';

/// Auth Remote Data Source Provider
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

/// Auth Repository Provider (binds interface to implementation)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  return AuthRepositoryImpl(remoteDataSource);
});

