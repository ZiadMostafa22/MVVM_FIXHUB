import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/user/data/di/user_di.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart' as entities;

/// ViewModel for Admin Users Management
class AdminUsersViewModel {
  final userRepository;

  AdminUsersViewModel({required this.userRepository});

  /// Stream all users
  Stream<List<entities.UserEntity>> watchAllUsers() {
    return userRepository.watchAllUsers();
  }

  /// Get user by ID
  Future<entities.UserEntity?> getUserById(String userId) async {
    return await userRepository.getUserById(userId);
  }

  /// Update user active status
  Future<void> updateUserActiveStatus(String userId, bool isActive) async {
    await userRepository.updateUserActiveStatus(userId, isActive);
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    await userRepository.deleteUser(userId);
  }
}

/// Provider for AdminUsersViewModel
final adminUsersViewModelProvider = Provider<AdminUsersViewModel>((ref) {
  return AdminUsersViewModel(
    userRepository: ref.watch(userRepositoryProvider),
  );
});

