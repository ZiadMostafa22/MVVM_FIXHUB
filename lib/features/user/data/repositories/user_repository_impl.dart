import 'dart:async';
import 'package:car_maintenance_system_new/features/user/domain/repositories/user_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';
import 'package:car_maintenance_system_new/features/user/data/datasources/user_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/auth/data/models/user_dto.dart';

/// Implementation of UserRepository
class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> getUserById(String userId) async {
    final data = await remoteDataSource.getUserDocument(userId);
    if (data == null) return null;
    final dto = UserDto.fromFirestore(data, userId);
    return dto.toEntity();
  }

  @override
  Future<List<UserEntity>> getAllUsers() async {
    final dataList = await remoteDataSource.getAllUsers();
    return dataList
        .map((data) => UserDto.fromFirestore(data, data['id'] as String).toEntity())
        .toList();
  }

  @override
  Future<List<UserEntity>> getUsersByRole(UserRole role) async {
    final roleString = role.toString().split('.').last;
    final dataList = await remoteDataSource.getUsersByRole(roleString);
    return dataList
        .map((data) => UserDto.fromFirestore(data, data['id'] as String).toEntity())
        .toList();
  }

  @override
  Stream<List<UserEntity>> watchAllUsers() {
    return remoteDataSource.watchAllUsers().map((dataList) {
      return dataList
          .map((data) => UserDto.fromFirestore(data, data['id'] as String).toEntity())
          .toList();
    });
  }

  @override
  Stream<List<UserEntity>> watchUsersByRole(UserRole role) {
    final roleString = role.toString().split('.').last;
    return remoteDataSource.watchUsersByRole(roleString).map((dataList) {
      return dataList
          .map((data) => UserDto.fromFirestore(data, data['id'] as String).toEntity())
          .toList();
    });
  }

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    await remoteDataSource.updateUser(userId, updates);
  }

  @override
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    await updateUser(userId, {'isActive': isActive});
  }

  @override
  Future<void> deleteUser(String userId) async {
    await remoteDataSource.deleteUser(userId);
  }
}

