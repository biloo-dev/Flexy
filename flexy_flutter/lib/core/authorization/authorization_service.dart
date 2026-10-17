import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
import 'app_permissions.dart';

/// Central Authorization Service for RBAC (Role-Based Access Control)
abstract class IAuthorizationService {
  bool can(String permission);
  bool canAny(List<String> permissions);
  bool canAll(List<String> permissions);
  bool canAccessRole(String role);
  bool isSuperAdmin();
  bool isAdmin();
  bool get isAuthenticated;
  UserModel? get currentUser;
  Set<String> get currentPermissions;
}

class AuthorizationService with ChangeNotifier implements IAuthorizationService {
  static final AuthorizationService instance = AuthorizationService._internal();

  UserModel? _currentUser;
  final Set<String> _permissionCache = <String>{};

  AuthorizationService._internal();

  factory AuthorizationService() => instance;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  bool get isAuthenticated => _currentUser != null && _currentUser!.isActive;

  @override
  Set<String> get currentPermissions => Set.unmodifiable(_permissionCache);

  /// Sets the currently active user and updates permission cache
  void setCurrentUser(UserModel? user) {
    _currentUser = user;
    _rebuildCache();
    notifyListeners();
  }

  void _rebuildCache() {
    _permissionCache.clear();
    if (_currentUser != null && _currentUser!.isActive) {
      // If Super Admin, grant all permissions wildcard
      if (_currentUser!.isSuperAdmin) {
        for (final perm in AppPermissions.allPermissions) {
          _permissionCache.add(perm.code);
        }
      } else {
        _permissionCache.addAll(_currentUser!.permissions);
      }
    }
  }

  /// Checks if current authenticated user has a specific permission
  @override
  bool can(String permission) {
    if (_currentUser == null || !_currentUser!.isActive) {
      return false;
    }
    if (_currentUser!.isSuperAdmin) {
      return true;
    }
    return _permissionCache.contains(permission);
  }

  /// Checks if current authenticated user has at least one of the given permissions
  @override
  bool canAny(List<String> permissions) {
    if (permissions.isEmpty) return true;
    if (_currentUser == null || !_currentUser!.isActive) return false;
    if (_currentUser!.isSuperAdmin) return true;

    for (final perm in permissions) {
      if (_permissionCache.contains(perm)) return true;
    }
    return false;
  }

  /// Checks if current authenticated user has all of the given permissions
  @override
  bool canAll(List<String> permissions) {
    if (permissions.isEmpty) return true;
    if (_currentUser == null || !_currentUser!.isActive) return false;
    if (_currentUser!.isSuperAdmin) return true;

    for (final perm in permissions) {
      if (!_permissionCache.contains(perm)) return false;
    }
    return true;
  }

  /// Checks if current user has a specific role name
  @override
  bool canAccessRole(String role) {
    if (_currentUser == null || !_currentUser!.isActive) return false;
    if (_currentUser!.isSuperAdmin) return true;
    return _currentUser!.roleName == role;
  }

  @override
  bool isSuperAdmin() {
    return _currentUser != null && _currentUser!.isActive && _currentUser!.isSuperAdmin;
  }

  @override
  bool isAdmin() {
    return _currentUser != null && _currentUser!.isActive && _currentUser!.isAdmin;
  }
}
