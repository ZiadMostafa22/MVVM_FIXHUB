import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_system_new/features/auth/data/di/auth_di.dart';
import 'package:car_maintenance_system_new/features/auth/domain/usecases/check_auth_status_usecase.dart';
import 'package:car_maintenance_system_new/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:car_maintenance_system_new/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:car_maintenance_system_new/features/auth/domain/usecases/sign_out_usecase.dart';

/// Check Auth Status Use Case Provider
final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return CheckAuthStatusUseCase(repository);
});

/// Sign In Use Case Provider
final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInUseCase(repository);
});

/// Sign Up Use Case Provider
final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpUseCase(repository);
});

/// Sign Out Use Case Provider
final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignOutUseCase(repository);
});

