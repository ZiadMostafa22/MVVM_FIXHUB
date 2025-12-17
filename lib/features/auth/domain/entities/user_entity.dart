/// User entity - pure domain model without external dependencies
enum UserRole { customer, technician, admin, cashier }

class UserEntity {
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

  UserEntity({
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

  UserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserRole? role,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    Map<String, dynamic>? preferences,
    String? inviteCodeId,
    String? inviteCode,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      inviteCodeId: inviteCodeId ?? this.inviteCodeId,
      inviteCode: inviteCode ?? this.inviteCode,
    );
  }
}

