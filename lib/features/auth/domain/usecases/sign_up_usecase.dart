import 'package:car_maintenance_system_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Use case to sign up a new user
class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<UserEntity> call({
    required String email,
    required String password,
    required String name,
    required String phone,
    required UserRole role,
    String? inviteCode,
  }) async {
    // Validate invite code if needed
    UserRole validatedRole = role;
    String? inviteCodeDocId;
    
    if (role == UserRole.technician || role == UserRole.admin || role == UserRole.cashier) {
      if (inviteCode == null || inviteCode.isEmpty) {
        validatedRole = UserRole.customer;
      } else {
        final inviteResult = await repository.validateInviteCode(inviteCode);
        if (inviteResult == null) {
          throw Exception('Invalid or expired invite code. Please contact the administrator.');
        }

        final inviteData = inviteResult['data'] as Map<String, dynamic>;
        final inviteRoleString = inviteData['role'] as String;

        // Verify role matches invite code
        final expectedRoleString = role.toString().split('.').last;
        if (inviteRoleString != expectedRoleString) {
          throw Exception('This invite code is for $inviteRoleString accounts, not $expectedRoleString accounts.');
        }

        // Check if invite code has usage limit
        final usedCount = (inviteData['usedCount'] ?? 0) as int;
        final maxUses = (inviteData['maxUses'] ?? 1) as int;

        if (usedCount >= maxUses) {
          throw Exception('This invite code has reached its usage limit. Please contact the administrator.');
        }

        inviteCodeDocId = inviteResult['id'] as String;
      }
    }

    // Create user in Firebase Auth
    final userCredential = await repository.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (userCredential.user == null) {
      throw Exception('Registration failed: No user returned');
    }

    // Mark invite code as used if needed
    if (validatedRole != UserRole.customer && inviteCode != null && inviteCode.isNotEmpty && inviteCodeDocId != null) {
      await repository.markInviteCodeAsUsed(
        inviteCodeDocId: inviteCodeDocId,
        userId: userCredential.user!.uid,
      );
    }

    // Create user entity
    final userEntity = UserEntity(
      id: userCredential.user!.uid,
      name: name,
      email: email,
      phone: phone,
      role: validatedRole,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      inviteCodeId: inviteCodeDocId,
      inviteCode: inviteCode,
    );

    // Create user profile in Firestore
    await repository.createUserProfile(
      userId: userCredential.user!.uid,
      userEntity: userEntity,
    );

    return userEntity;
  }
}

