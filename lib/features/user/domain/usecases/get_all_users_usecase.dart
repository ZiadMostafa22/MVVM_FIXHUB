import 'package:car_maintenance_system_new/features/user/domain/repositories/user_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Use case to get all users
class GetAllUsersUseCase {
  final UserRepository repository;

  GetAllUsersUseCase(this.repository);

  Future<List<UserEntity>> call() async {
    return await repository.getAllUsers();
  }
}

