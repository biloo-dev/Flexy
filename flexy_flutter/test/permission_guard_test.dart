import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flexy_flutter/core/authorization/app_permissions.dart';
import 'package:flexy_flutter/core/authorization/authorization_service.dart';
import 'package:flexy_flutter/core/authorization/permission_guard.dart';
import 'package:flexy_flutter/models/user_model.dart';

void main() {
  group('PermissionGuard Widget Tests', () {
    testWidgets('Renders child when user has required permission', (tester) async {
      final authService = AuthorizationService.instance;
      authService.setCurrentUser(UserModel(
        id: 1,
        email: 'seller@flexy.com',
        fullName: 'Seller',
        password: 'pass',
        roleName: 'seller',
        permissions: [AppPermissions.customersCreate],
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthorizationService>.value(
          value: authService,
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGuard(
                permission: AppPermissions.customersCreate,
                fallback: Text('FALLBACK_TEXT'),
                child: Text('CHILD_BUTTON'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('CHILD_BUTTON'), findsOneWidget);
      expect(find.text('FALLBACK_TEXT'), findsNothing);
    });

    testWidgets('Renders fallback when user lacks required permission', (tester) async {
      final authService = AuthorizationService.instance;
      authService.setCurrentUser(UserModel(
        id: 2,
        email: 'viewer@flexy.com',
        fullName: 'Viewer',
        password: 'pass',
        roleName: 'viewer',
        permissions: [AppPermissions.customersView],
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthorizationService>.value(
          value: authService,
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGuard(
                permission: AppPermissions.customersDelete,
                fallback: Text('FALLBACK_TEXT'),
                child: Text('DELETE_BUTTON'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('DELETE_BUTTON'), findsNothing);
      expect(find.text('FALLBACK_TEXT'), findsOneWidget);
    });

    testWidgets('PermissionGuard.superAdmin renders only for super admin', (tester) async {
      final authService = AuthorizationService.instance;
      authService.setCurrentUser(UserModel(
        id: 3,
        email: 'admin@flexy.com',
        fullName: 'Admin',
        password: 'pass',
        roleName: 'admin',
      ));

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthorizationService>.value(
          value: authService,
          child: const MaterialApp(
            home: Scaffold(
              body: PermissionGuard.superAdmin(
                fallback: Text('NOT_SUPER_ADMIN'),
                child: Text('SUPER_ADMIN_SECRET'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('SUPER_ADMIN_SECRET'), findsNothing);
      expect(find.text('NOT_SUPER_ADMIN'), findsOneWidget);
    });
  });
}
