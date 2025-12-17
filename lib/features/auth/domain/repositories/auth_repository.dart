import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Repository interface for authentication operations
/// This is in the domain layer and defines the contract
abstract class AuthRepository {
  /// Get current authenticated user from Firebase Auth
  User? getCurrentUser();

  /// Check if user is authenticated
  bool isAuthenticated();

  /// Get user profile from Firestore
  Future<UserEntity?> getUserProfile(String userId);

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out current user
  Future<void> signOut();

  /// Delete current user account
  Future<void> deleteUser();

  /// Validate invite code
  Future<Map<String, dynamic>?> validateInviteCode(String inviteCode);

  /// Mark invite code as used
  Future<void> markInviteCodeAsUsed({
    required String inviteCodeDocId,
    required String userId,
  });

  /// Create user profile in Firestore
  Future<void> createUserProfile({
    required String userId,
    required UserEntity userEntity,
  });
}

