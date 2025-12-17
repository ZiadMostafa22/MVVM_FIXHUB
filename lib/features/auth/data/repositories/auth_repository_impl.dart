import 'package:firebase_auth/firebase_auth.dart';
import 'package:car_maintenance_system_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';
import 'package:car_maintenance_system_new/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:car_maintenance_system_new/features/auth/data/models/user_dto.dart';

/// Implementation of AuthRepository
/// Implements the domain repository interface using data sources
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  User? getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  bool isAuthenticated() {
    return remoteDataSource.getCurrentUser() != null;
  }

  @override
  Future<UserEntity?> getUserProfile(String userId) async {
    final data = await remoteDataSource.getUserDocument(userId);
    if (data == null) return null;
    final dto = UserDto.fromFirestore(data, userId);
    return dto.toEntity();
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await remoteDataSource.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await remoteDataSource.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
  }

  @override
  Future<void> deleteUser() async {
    await remoteDataSource.deleteUser();
  }

  @override
  Future<Map<String, dynamic>?> validateInviteCode(String inviteCode) async {
    return await remoteDataSource.validateInviteCode(inviteCode);
  }

  @override
  Future<void> markInviteCodeAsUsed({
    required String inviteCodeDocId,
    required String userId,
  }) async {
    await remoteDataSource.markInviteCodeAsUsed(
      inviteCodeDocId: inviteCodeDocId,
      userId: userId,
    );
  }

  @override
  Future<void> createUserProfile({
    required String userId,
    required UserEntity userEntity,
  }) async {
    final dto = UserDto.fromEntity(userEntity);
    await remoteDataSource.createUserDocument(
      userId: userId,
      data: dto.toFirestore(),
    );
  }
}

