import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../core/authorization/app_permissions.dart';
import '../core/authorization/authorization_service.dart';
import '../providers/auth_provider.dart';
import '../providers/gsm_provider.dart';
import '../providers/license_provider.dart';
import 'components/flexy_sidebar.dart';
import 'components/flexy_top_header.dart';
import 'dashboard_view.dart';
import 'flexy_view.dart';
import 'activation_sim_view.dart';
import 'clients_dette_view.dart';
import 'modem_terminal_view.dart';
import 'settings_view.dart';
import 'users_management_view.dart';
import 'roles_management_view.dart';
import 'audit_logs_view.dart';
import 'access_denied_view.dart';
import 'login_view.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 1; // Default to Flexy / Recharge View
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gsmProvider = Provider.of<GsmProvider>(context, listen: false);
      final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);
      final authService = Provider.of<AuthorizationService>(context, listen: false);

      gsmProvider.startAutoDetection();
      licenseProvider.checkSimsOnStartup(gsmProvider);

      // If user doesn't have permission for default Flexy tab (index 1), navigate to first allowed tab
      if (!authService.can(AppPermissions.transactionsView)) {
        if (authService.can(AppPermissions.dashboardView)) {
          setState(() => _selectedIndex = 0);
        } else if (authService.can(AppPermissions.customersView)) {
          setState(() => _selectedIndex = 2);
        }
      }
    });
  }

  Widget _buildGuardedView({
    required String requiredPermission,
    required Widget view,
  }) {
    final authService = Provider.of<AuthorizationService>(context);
    if (!authService.can(requiredPermission)) {
      return AccessDeniedView(
        requiredPermission: requiredPermission,
        onGoDashboard: () {
          setState(() => _selectedIndex = 0);
        },
      );
    }
    return view;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    final List<String> pageTitles = [
      context.tr('dashboard'),
      context.tr('flexy_recharge'),
      context.tr('clients_debts'),
      context.tr('sim_activation'),
      context.tr('modem_terminal'),
      context.tr('settings'),
      context.tr('users_management'),
      context.tr('roles_permissions'),
      context.tr('audit_logs'),
    ];

    final List<Widget> views = [
      _buildGuardedView(
        requiredPermission: AppPermissions.dashboardView,
        view: DashboardView(
          onNavigateToTab: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      _buildGuardedView(
        requiredPermission: AppPermissions.transactionsView,
        view: FlexyView(
          onNavigateToTab: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
      _buildGuardedView(
        requiredPermission: AppPermissions.customersView,
        view: const ClientsDetteView(),
      ),
      _buildGuardedView(
        requiredPermission: AppPermissions.simActivationView,
        view: const ActivationSimView(),
      ),
      _buildGuardedView(
        requiredPermission: AppPermissions.terminalView,
        view: const ModemTerminalView(),
      ),
      _buildGuardedView(
        requiredPermission: AppPermissions.settingsView,
        view: const SettingsView(),
      ),
      _buildGuardedView(
        requiredPermission: AppPermissions.usersView,
        view: const UsersManagementView(),
      ),
      _buildGuardedView(
        requiredPermission: AppPermissions.rolesView,
        view: const RolesManagementView(),
      ),
      _buildGuardedView(
        requiredPermission: AppPermissions.auditLogsView,
        view: const AuditLogsView(),
      ),
    ];

    final safeIndex = (_selectedIndex >= 0 && _selectedIndex < views.length) ? _selectedIndex : 0;

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        cardColor: AppColors.card,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primaryTeal,
          surface: AppColors.card,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Row(
            children: [
              // Left Cyber Sidebar Navigation Drawer
              FlexySidebar(
                selectedIndex: safeIndex,
                onItemSelected: (index) {
                  setState(() {
                    _selectedIndex = index;
                  });
                },
                isDarkMode: _isDarkMode,
                onDarkModeChanged: (val) {
                  setState(() {
                    _isDarkMode = val;
                  });
                },
                onLogout: () {
                  authProvider.logout();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginView()),
                  );
                },
              ),

              // Main Desktop View Area
              Expanded(
                child: Column(
                  children: [
                    // Top Navigation Header
                    FlexyTopHeader(
                      pageTitle: safeIndex < pageTitles.length ? pageTitles[safeIndex] : '',
                      pageSubtitle: context.tr('page_subtitle'),
                    ),

                    // View Content Body
                    Expanded(
                      child: IndexedStack(
                        index: safeIndex,
                        children: views,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
