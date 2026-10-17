import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/theme/app_colors.dart';
import 'core/localization/language_provider.dart';
import 'core/authorization/authorization_service.dart';
import 'providers/auth_provider.dart';
import 'providers/flexy_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/gsm_provider.dart';
import 'providers/license_provider.dart';
import 'views/login_view.dart';
import 'views/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (Platform.isWindows) {
    try {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        final prefFile = File('$appData\\com.example\\flexy_flutter\\shared_preferences.json');
        if (prefFile.existsSync()) {
          final content = prefFile.readAsStringSync().trim();
          if (content.isEmpty || !content.startsWith('{')) {
            prefFile.writeAsStringSync('{}');
          }
        }
      }
    } catch (_) {}
  }

  runApp(const FlexyApp());
}

class FlexyApp extends StatelessWidget {
  const FlexyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: AuthorizationService.instance),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FlexyProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => GsmProvider()),
        ChangeNotifierProvider(create: (_) => LicenseProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<AuthProvider, LanguageProvider>(
        builder: (context, authProvider, langProvider, _) {
          return MaterialApp(
            title: 'FLEXY LE - Desktop',
            debugShowCheckedModeBanner: false,
            locale: langProvider.currentLocale,
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: AppColors.background,
              cardColor: AppColors.card,
              textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryTeal,
                surface: AppColors.card,
              ),
            ),
            builder: (context, child) {
              return Directionality(
                textDirection: langProvider.textDirection,
                child: child ?? const SizedBox(),
              );
            },
            home: authProvider.isAuthenticated ? const MainLayout() : const LoginView(),
          );
        },
      ),
    );
  }
}
