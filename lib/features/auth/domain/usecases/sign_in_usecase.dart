import 'package:car_maintenance_system_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Use case to sign in a user
class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<UserEntity?> call({
    required String email,
    required String password,
  }) async {
    final userCredential = await repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) {
      throw Exception('Login failed: No user returned');
    }

    final userEntity = await repository.getUserProfile(userCredential.user!.uid);
    
    if (userEntity == null) {
      await repository.signOut();
      throw Exception('Your account profile was not found. The user data may have been deleted. Please contact the administrator to restore your account or delete this account from Firebase Authentication and re-register.');
    }

    if (!userEntity.isActive) {
      await repository.signOut();
      throw Exception('Your account has been disabled by the administrator. Please contact support for assistance.');
    }

    return userEntity;
  }
}

