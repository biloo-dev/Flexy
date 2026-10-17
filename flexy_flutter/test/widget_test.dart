import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flexy_flutter/views/access_denied_view.dart';
import 'package:flexy_flutter/core/localization/language_provider.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('AccessDeniedView renders title and action buttons', (WidgetTester tester) async {
    bool didGoBack = false;
    bool didGoDashboard = false;

    await tester.pumpWidget(
      ChangeNotifierProvider<LanguageProvider>(
        create: (_) => LanguageProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: AccessDeniedView(
              requiredPermission: 'admin.secret',
              onGoBack: () => didGoBack = true,
              onGoDashboard: () => didGoDashboard = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Accès Refusé'), findsOneWidget);
    expect(find.text('Permission requise: admin.secret'), findsOneWidget);

    await tester.tap(find.text('Retour'));
    expect(didGoBack, isTrue);

    await tester.tap(find.text('Tableau de bord'));
    expect(didGoDashboard, isTrue);
  });
}
