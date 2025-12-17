import 'package:car_maintenance_system_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Use case to check authentication status and get current user
class CheckAuthStatusUseCase {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  Future<UserEntity?> call() async {
    final firebaseUser = repository.getCurrentUser();
    if (firebaseUser != null) {
      return await repository.getUserProfile(firebaseUser.uid);
    }
    return null;
  }
}

