import 'package:flutter_test/flutter_test.dart';
import 'package:flexy_flutter/core/authorization/app_permissions.dart';
import 'package:flexy_flutter/core/authorization/authorization_service.dart';
import 'package:flexy_flutter/models/user_model.dart';

void main() {
  group('AuthorizationService Tests', () {
    late AuthorizationService authService;

    setUp(() {
      authService = AuthorizationService.instance;
      authService.setCurrentUser(null);
    });

    test('Unauthenticated user has no permissions', () {
      expect(authService.isAuthenticated, isFalse);
      expect(authService.can(AppPermissions.customersView), isFalse);
      expect(authService.can(AppPermissions.transactionsCreate), isFalse);
      expect(authService.isSuperAdmin(), isFalse);
    });

    test('Super Admin has full access to all permissions wildcard', () {
      final superAdmin = UserModel(
        id: 1,
        email: 'admin@flexy.com',
        fullName: 'Super Admin',
        password: 'hash',
        roleName: 'super_admin',
        roleDisplayName: 'Super Admin',
        isActive: true,
      );

      authService.setCurrentUser(superAdmin);

      expect(authService.isAuthenticated, isTrue);
      expect(authService.isSuperAdmin(), isTrue);
      expect(authService.isAdmin(), isTrue);
      expect(authService.can(AppPermissions.customersView), isTrue);
      expect(authService.can(AppPermissions.customersDelete), isTrue);
      expect(authService.can(AppPermissions.rolesDelete), isTrue);
      expect(authService.can('custom.wildcard.action'), isTrue); // Super admin has true for all actions
    });

    test('Seller user can only perform allowed permissions', () {
      final seller = UserModel(
        id: 2,
        email: 'seller@flexy.com',
        fullName: 'Seller Agent',
        password: 'hash',
        roleName: 'seller',
        roleDisplayName: 'Vendeur',
        isActive: true,
        permissions: [
          AppPermissions.dashboardView,
          AppPermissions.transactionsView,
          AppPermissions.transactionsCreate,
          AppPermissions.customersView,
          AppPermissions.customersCreate,
          AppPermissions.debtsView,
          AppPermissions.debtsPay,
        ],
      );

      authService.setCurrentUser(seller);

      expect(authService.isAuthenticated, isTrue);
      expect(authService.isSuperAdmin(), isFalse);
      expect(authService.can(AppPermissions.transactionsCreate), isTrue);
      expect(authService.can(AppPermissions.customersView), isTrue);
      expect(authService.can(AppPermissions.debtsPay), isTrue);

      // Forbidden for Seller
      expect(authService.can(AppPermissions.customersDelete), isFalse);
      expect(authService.can(AppPermissions.transactionsDelete), isFalse);
      expect(authService.can(AppPermissions.usersView), isFalse);
      expect(authService.can(AppPermissions.rolesView), isFalse);
      expect(authService.can(AppPermissions.settingsUpdate), isFalse);
    });

    test('canAny and canAll evaluate correctly', () {
      final cashier = UserModel(
        id: 3,
        email: 'cashier@flexy.com',
        fullName: 'Cashier User',
        password: 'hash',
        roleName: 'cashier',
        permissions: [
          AppPermissions.transactionsView,
          AppPermissions.debtsView,
        ],
      );

      authService.setCurrentUser(cashier);

      // canAny
      expect(
        authService.canAny([AppPermissions.transactionsView, AppPermissions.usersDelete]),
        isTrue,
      );
      expect(
        authService.canAny([AppPermissions.usersCreate, AppPermissions.rolesDelete]),
        isFalse,
      );

      // canAll
      expect(
        authService.canAll([AppPermissions.transactionsView, AppPermissions.debtsView]),
        isTrue,
      );
      expect(
        authService.canAll([AppPermissions.transactionsView, AppPermissions.usersCreate]),
        isFalse,
      );
    });

    test('Inactive user is treated as unauthorized', () {
      final disabledUser = UserModel(
        id: 4,
        email: 'disabled@flexy.com',
        fullName: 'Disabled User',
        password: 'hash',
        roleName: 'super_admin',
        isActive: false,
      );

      authService.setCurrentUser(disabledUser);

      expect(authService.isAuthenticated, isFalse);
      expect(authService.can(AppPermissions.customersView), isFalse);
      expect(authService.isSuperAdmin(), isFalse);
    });
  });
}
