import 'role_model.dart';

class UserModel {
  final int? id;
  final String email;
  final String fullName;
  final String password;
  final int? roleId;
  final String? roleName;
  final String? roleDisplayName;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;
  final String? lastLoginAt;
  final List<String> permissions;

  UserModel({
    this.id,
    required this.email,
    required this.fullName,
    required this.password,
    this.roleId,
    this.roleName,
    this.roleDisplayName,
    this.isActive = true,
    String? createdAt,
    this.updatedAt,
    this.lastLoginAt,
    this.permissions = const [],
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  bool get isSuperAdmin => roleName == 'super_admin';
  bool get isAdmin => roleName == 'super_admin' || roleName == 'admin';

  UserModel copyWith({
    int? id,
    String? email,
    String? fullName,
    String? password,
    int? roleId,
    String? roleName,
    String? roleDisplayName,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
    String? lastLoginAt,
    List<String>? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      roleId: roleId ?? this.roleId,
      roleName: roleName ?? this.roleName,
      roleDisplayName: roleDisplayName ?? this.roleDisplayName,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      permissions: permissions ?? this.permissions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'email': email,
      'fullName': fullName,
      'password': password,
      'roleId': roleId,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  factory UserModel.fromMap(
    Map<String, dynamic> map, {
    List<String> permissions = const [],
    RoleModel? role,
  }) {
    return UserModel(
      id: map['id'] as int?,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      password: map['password'] as String? ?? '',
      roleId: map['roleId'] as int?,
      roleName: role?.name ?? map['roleName'] as String?,
      roleDisplayName: role?.displayName ?? map['roleDisplayName'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt: map['updatedAt'] as String?,
      lastLoginAt: map['lastLoginAt'] as String?,
      permissions: permissions.isNotEmpty ? permissions : (role?.permissions ?? const []),
    );
  }
}
