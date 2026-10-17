import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/language_provider.dart';
import '../../core/authorization/app_permissions.dart';
import '../../core/authorization/authorization_service.dart';
import '../../providers/auth_provider.dart';
import 'account_switcher_dialog.dart';

class NavigationTabItem {
  final int index;
  final IconData icon;
  final String titleKey;
  final String? requiredPermission;

  const NavigationTabItem({
    required this.index,
    required this.icon,
    required this.titleKey,
    this.requiredPermission,
  });
}

class FlexySidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final bool isDarkMode;
  final Function(bool) onDarkModeChanged;
  final VoidCallback? onLogout;

  const FlexySidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.isDarkMode,
    required this.onDarkModeChanged,
    this.onLogout,
  });

  static const List<NavigationTabItem> allTabs = [
    NavigationTabItem(
      index: 0,
      icon: Icons.dashboard_outlined,
      titleKey: 'dashboard',
      requiredPermission: AppPermissions.dashboardView,
    ),
    NavigationTabItem(
      index: 1,
      icon: Icons.swap_horiz_rounded,
      titleKey: 'flexy_recharge',
      requiredPermission: AppPermissions.transactionsView,
    ),
    NavigationTabItem(
      index: 2,
      icon: Icons.people_outline_rounded,
      titleKey: 'clients_debts',
      requiredPermission: AppPermissions.customersView,
    ),
    NavigationTabItem(
      index: 3,
      icon: Icons.sim_card_outlined,
      titleKey: 'sim_activation',
      requiredPermission: AppPermissions.simActivationView,
    ),
    NavigationTabItem(
      index: 4,
      icon: Icons.terminal_outlined,
      titleKey: 'modem_terminal',
      requiredPermission: AppPermissions.terminalView,
    ),
    NavigationTabItem(
      index: 5,
      icon: Icons.settings_outlined,
      titleKey: 'settings',
      requiredPermission: AppPermissions.settingsView,
    ),
    NavigationTabItem(
      index: 6,
      icon: Icons.manage_accounts_outlined,
      titleKey: 'users_management',
      requiredPermission: AppPermissions.usersView,
    ),
    NavigationTabItem(
      index: 7,
      icon: Icons.admin_panel_settings_outlined,
      titleKey: 'roles_permissions',
      requiredPermission: AppPermissions.rolesView,
    ),
    NavigationTabItem(
      index: 8,
      icon: Icons.history_edu_outlined,
      titleKey: 'audit_logs',
      requiredPermission: AppPermissions.auditLogsView,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final authService = Provider.of<AuthorizationService>(context);

    final visibleTabs = allTabs.where((tab) {
      if (tab.requiredPermission == null) return true;
      return authService.can(tab.requiredPermission!);
    }).toList();

    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(
          right: BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 28),

          // Logo Branding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: AppGradients.brandLogo,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  'FLEXY',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Navigation Menu List
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ...visibleTabs.map((tab) {
                    return _SidebarItem(
                      icon: tab.icon,
                      title: context.tr(tab.titleKey),
                      isActive: selectedIndex == tab.index,
                      onTap: () => onItemSelected(tab.index),
                    );
                  }),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // Sidebar Utility Row: Language Selector + Notifications
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Language Selector Dropdown (🇫🇷 / 🇩🇿 / 🇬🇧)
                Consumer<LanguageProvider>(
                  builder: (context, langProvider, _) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: langProvider.currentLanguage,
                          dropdownColor: AppColors.cardHover,
                          icon: const Icon(Icons.language_rounded, color: AppColors.primaryTeal, size: 16),
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                          onChanged: (val) {
                            if (val != null) langProvider.setLanguage(val);
                          },
                          items: const [
                            DropdownMenuItem(value: 'fr', child: Text(' 🇫🇷 FR ')),
                            DropdownMenuItem(value: 'ar', child: Text(' 🇩🇿 AR ')),
                            DropdownMenuItem(value: 'en', child: Text(' 🇬🇧 EN ')),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Notification Bell
                Stack(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.textSecondary,
                        size: 17,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // Dark/Light Mode Switch Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.dark_mode_outlined,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  context.tr('dark_mode'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isDarkMode,
                  onChanged: onDarkModeChanged,
                  activeThumbColor: AppColors.primaryPurple,
                  activeTrackColor: AppColors.primaryPurple.withValues(alpha: 0.3),
                  inactiveThumbColor: AppColors.textSecondary,
                  inactiveTrackColor: AppColors.card,
                ),
              ],
            ),
          ),

          const Divider(color: AppColors.border, height: 1),

          // Authenticated User Profile Footer
          Container(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => AccountSwitcherDialog.show(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: authProvider.currentUser?.isSuperAdmin == true
                            ? AppGradients.brandLogo
                            : null,
                        color: authProvider.currentUser?.isSuperAdmin == true
                            ? null
                            : AppColors.primaryTeal.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Icon(
                          authProvider.currentUser?.isSuperAdmin == true
                              ? Icons.admin_panel_settings
                              : Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            authProvider.currentUser?.fullName ?? context.tr('administrator'),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            authProvider.roleDisplayName,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                      color: AppColors.cardHover,
                      onSelected: (value) {
                        if (value == 'switch_account') {
                          AccountSwitcherDialog.show(context);
                        } else if (value == 'logout' && onLogout != null) {
                          onLogout!();
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'switch_account',
                          child: Row(
                            children: [
                              const Icon(Icons.switch_account_outlined, size: 18, color: AppColors.primaryTeal),
                              const SizedBox(width: 8),
                              Text(context.tr('switch_account')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'profile',
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18),
                              const SizedBox(width: 8),
                              Text(context.tr('my_profile')),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout, color: AppColors.danger, size: 18),
                              const SizedBox(width: 8),
                              Text(context.tr('logout'), style: const TextStyle(color: AppColors.danger)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isActive ? AppGradients.activeSidebar : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryTealDark.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(
            icon,
            color: isActive ? Colors.white : AppColors.textSecondary,
            size: 20,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}
