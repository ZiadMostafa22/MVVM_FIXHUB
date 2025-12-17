import 'package:car_maintenance_system_new/features/auth/domain/repositories/auth_repository.dart';

/// Use case to sign out the current user
class SignOutUseCase {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  Future<void> call() async {
    await repository.signOut();
  }
}

