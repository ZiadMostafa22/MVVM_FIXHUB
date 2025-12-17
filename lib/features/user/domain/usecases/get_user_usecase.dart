import 'package:car_maintenance_system_new/features/user/domain/repositories/user_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Use case to get a user by ID
class GetUserUseCase {
  final UserRepository repository;

  GetUserUseCase(this.repository);

  Future<UserEntity?> call(String userId) async {
    return await repository.getUserById(userId);
  }
}

