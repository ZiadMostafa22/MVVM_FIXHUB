import 'dart:async';
import 'package:car_maintenance_system_new/features/user/domain/repositories/user_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Use case to watch all users in real-time
class WatchUsersUseCase {
  final UserRepository repository;

  WatchUsersUseCase(this.repository);

  Stream<List<UserEntity>> call() {
    return repository.watchAllUsers();
  }
}

