import 'package:car_maintenance_system_new/features/user/domain/repositories/user_repository.dart';

/// Use case to update a user
class UpdateUserUseCase {
  final UserRepository repository;

  UpdateUserUseCase(this.repository);

  Future<void> call(String userId, Map<String, dynamic> updates) async {
    await repository.updateUser(userId, updates);
  }
}

