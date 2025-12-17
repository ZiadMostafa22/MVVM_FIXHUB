import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:car_maintenance_system_new/features/auth/domain/entities/user_entity.dart';

/// Data Transfer Object for User
/// Handles conversion between domain entities and Firestore data
class UserDto {
  final String id;
  final String email;
  final String name;
  final String phone;
  final UserRole role;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic>? preferences;
  final String? inviteCodeId;
  final String? inviteCode;

  UserDto({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.role,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.preferences,
    this.inviteCodeId,
    this.inviteCode,
  });

  /// Convert from Firestore document to DTO
  factory UserDto.fromFirestore(Map<String, dynamic> data, String id) {
    return UserDto(
      id: id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.customer,
      ),
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      preferences: data['preferences'],
      inviteCodeId: data['inviteCodeId'],
      inviteCode: data['inviteCode'],
    );
  }

  /// Convert DTO to domain entity
  UserEntity toEntity() {
    return UserEntity(
      id: id,
      email: email,
      name: name,
      phone: phone,
      role: role,
      profileImageUrl: profileImageUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
      preferences: preferences,
      inviteCodeId: inviteCodeId,
      inviteCode: inviteCode,
    );
  }

  /// Convert domain entity to DTO
  factory UserDto.fromEntity(UserEntity entity) {
    return UserDto(
      id: entity.id,
      email: entity.email,
      name: entity.name,
      phone: entity.phone,
      role: entity.role,
      profileImageUrl: entity.profileImageUrl,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
      preferences: entity.preferences,
      inviteCodeId: entity.inviteCodeId,
      inviteCode: entity.inviteCode,
    );
  }

  /// Convert DTO to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'role': role.toString().split('.').last,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'preferences': preferences,
      'inviteCodeId': inviteCodeId,
      'inviteCode': inviteCode,
    };
  }
}

