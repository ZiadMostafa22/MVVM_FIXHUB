import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/user/data/di/user_di.dart';
import 'package:car_maintenance_system_new/features/user/domain/usecases/get_user_usecase.dart';
import 'package:car_maintenance_system_new/features/user/domain/usecases/get_all_users_usecase.dart';
import 'package:car_maintenance_system_new/features/user/domain/usecases/watch_users_usecase.dart';
import 'package:car_maintenance_system_new/features/user/domain/usecases/update_user_usecase.dart';

/// Get User Use Case Provider
final getUserUseCaseProvider = Provider<GetUserUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetUserUseCase(repository);
});

/// Get All Users Use Case Provider
final getAllUsersUseCaseProvider = Provider<GetAllUsersUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return GetAllUsersUseCase(repository);
});

/// Watch Users Use Case Provider
final watchUsersUseCaseProvider = Provider<WatchUsersUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return WatchUsersUseCase(repository);
});

/// Update User Use Case Provider
final updateUserUseCaseProvider = Provider<UpdateUserUseCase>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UpdateUserUseCase(repository);
});

