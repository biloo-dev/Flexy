import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'authorization_service.dart';

enum _GuardType { single, any, all, role, superAdmin, admin }

/// Declarative widget to conditionally display or hide UI components based on permissions or roles.
class PermissionGuard extends StatelessWidget {
  final String? permission;
  final List<String>? permissions;
  final String? role;
  final _GuardType _type;
  final Widget child;
  final Widget fallback;

  /// Guard by a single permission string
  const PermissionGuard({
    super.key,
    required String this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : permissions = null,
        role = null,
        _type = _GuardType.single;

  /// Guard by ANY permission in the list
  const PermissionGuard.any({
    super.key,
    required List<String> this.permissions,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : permission = null,
        role = null,
        _type = _GuardType.any;

  /// Guard by ALL permissions in the list
  const PermissionGuard.all({
    super.key,
    required List<String> this.permissions,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : permission = null,
        role = null,
        _type = _GuardType.all;

  /// Guard by specific role
  const PermissionGuard.role({
    super.key,
    required String this.role,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : permission = null,
        permissions = null,
        _type = _GuardType.role;

  /// Guard for Super Admin only
  const PermissionGuard.superAdmin({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : permission = null,
        permissions = null,
        role = null,
        _type = _GuardType.superAdmin;

  /// Guard for Admin / Super Admin
  const PermissionGuard.admin({
    super.key,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  })  : permission = null,
        permissions = null,
        role = null,
        _type = _GuardType.admin;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthorizationService>(
      builder: (context, authService, _) {
        bool isAllowed = false;

        switch (_type) {
          case _GuardType.single:
            isAllowed = permission != null && authService.can(permission!);
            break;
          case _GuardType.any:
            isAllowed = permissions != null && authService.canAny(permissions!);
            break;
          case _GuardType.all:
            isAllowed = permissions != null && authService.canAll(permissions!);
            break;
          case _GuardType.role:
            isAllowed = role != null && authService.canAccessRole(role!);
            break;
          case _GuardType.superAdmin:
            isAllowed = authService.isSuperAdmin();
            break;
          case _GuardType.admin:
            isAllowed = authService.isAdmin();
            break;
        }

        if (isAllowed) {
          return child;
        }
        return fallback;
      },
    );
  }
}
