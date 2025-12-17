import 'dart:async';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Repository interface for user operations
abstract class UserRepository {
  /// Get user by ID
  Future<UserEntity?> getUserById(String userId);

  /// Get all users
  Future<List<UserEntity>> getAllUsers();

  /// Get users by role
  Future<List<UserEntity>> getUsersByRole(UserRole role);

  /// Stream all users
  Stream<List<UserEntity>> watchAllUsers();

  /// Stream users by role
  Stream<List<UserEntity>> watchUsersByRole(UserRole role);

  /// Update user profile
  Future<void> updateUser(String userId, Map<String, dynamic> updates);

  /// Update user active status
  Future<void> updateUserActiveStatus(String userId, bool isActive);

  /// Delete user
  Future<void> deleteUser(String userId);
}

