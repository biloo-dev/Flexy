import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../core/authorization/app_permissions.dart';
import '../core/authorization/authorization_service.dart';
import '../core/authorization/permission_guard.dart';
import '../database/database_helper.dart';
import '../models/user_model.dart';
import '../models/role_model.dart';
import '../providers/auth_provider.dart';
import 'access_denied_view.dart';

class UsersManagementView extends StatefulWidget {
  const UsersManagementView({super.key});

  @override
  State<UsersManagementView> createState() => _UsersManagementViewState();
}

class _UsersManagementViewState extends State<UsersManagementView> {
  List<UserModel> _users = [];
  List<RoleModel> _roles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _roleFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final users = await DatabaseHelper.instance.getAllUsers();
      final roles = await DatabaseHelper.instance.getAllRoles();
      if (mounted) {
        setState(() {
          _users = users;
          _roles = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  List<UserModel> get _filteredUsers {
    return _users.where((u) {
      final matchesSearch = u.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (u.roleDisplayName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

      final matchesRole = _roleFilter == 'all' || u.roleName == _roleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  void _openAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    int? selectedRoleId = _roles.isNotEmpty ? _roles.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.person_add_outlined, color: AppColors.primaryTeal),
              const SizedBox(width: 10),
              Text(context.tr('add_user'), style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('full_name'),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryTeal),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('email_address'),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryTeal),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.tr('password'),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryTeal),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: selectedRoleId,
                  decoration: InputDecoration(
                    labelText: context.tr('role'),
                    prefixIcon: const Icon(Icons.security, color: AppColors.primaryTeal),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  dropdownColor: AppColors.cardHover,
                  items: _roles.map((r) {
                    return DropdownMenuItem<int>(
                      value: r.id,
                      child: Text(r.displayName),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedRoleId = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.tr('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('fill_all_fields')), backgroundColor: Colors.orange),
                  );
                  return;
                }

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final messenger = ScaffoldMessenger.of(context);
                final successMsg = context.tr('user_added_success');
                final newUser = UserModel(
                  email: emailCtrl.text.trim(),
                  fullName: nameCtrl.text.trim(),
                  password: passCtrl.text,
                  roleId: selectedRoleId,
                );

                try {
                  await DatabaseHelper.instance.insertUser(
                    newUser,
                    actorId: authProvider.currentUser?.id,
                    actorName: authProvider.currentUser?.fullName,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (!mounted) return;
                  _loadData();
                  messenger.showSnackBar(
                    SnackBar(content: Text(successMsg), backgroundColor: AppColors.success),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
                  );
                }
              },
              child: Text(context.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _openEditUserDialog(UserModel user) {
    final nameCtrl = TextEditingController(text: user.fullName);
    final emailCtrl = TextEditingController(text: user.email);
    final passCtrl = TextEditingController();
    int? selectedRoleId = user.roleId ?? (_roles.isNotEmpty ? _roles.first.id : null);
    bool isActive = user.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.edit_outlined, color: AppColors.primaryTeal),
              const SizedBox(width: 10),
              Text(context.tr('edit_user'), style: const TextStyle(fontSize: 18)),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('full_name'),
                    prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryTeal),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr('email_address'),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primaryTeal),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.tr('new_password_optional'),
                    prefixIcon: const Icon(Icons.lock_reset, color: AppColors.primaryTeal),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 14),
                if (!user.isSuperAdmin) ...[
                  DropdownButtonFormField<int>(
                    initialValue: selectedRoleId,
                    decoration: InputDecoration(
                      labelText: context.tr('role'),
                      prefixIcon: const Icon(Icons.security, color: AppColors.primaryTeal),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    dropdownColor: AppColors.cardHover,
                    items: _roles.map((r) {
                      return DropdownMenuItem<int>(
                        value: r.id,
                        child: Text(r.displayName),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedRoleId = val),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile(
                    title: Text(context.tr('account_active')),
                    value: isActive,
                    activeThumbColor: AppColors.primaryTeal,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(context.tr('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('fill_all_fields')), backgroundColor: Colors.orange),
                  );
                  return;
                }

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final messenger = ScaffoldMessenger.of(context);
                final successMsg = context.tr('user_updated_success');
                final updatedUser = user.copyWith(
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text.trim(),
                  roleId: selectedRoleId,
                  isActive: isActive,
                );

                try {
                  await DatabaseHelper.instance.updateUser(
                    updatedUser,
                    actorId: authProvider.currentUser?.id,
                    actorName: authProvider.currentUser?.fullName,
                  );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (!mounted) return;
                  _loadData();
                  messenger.showSnackBar(
                    SnackBar(content: Text(successMsg), backgroundColor: AppColors.success),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
                  );
                }
              },
              child: Text(context.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(UserModel user) {
    if (user.isSuperAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cannot_delete_super_admin')), backgroundColor: AppColors.danger),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            const SizedBox(width: 10),
            Text(context.tr('confirm_delete')),
          ],
        ),
        content: Text('${context.tr('delete_user_confirm_msg')} (${user.fullName}) ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.tr('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              final successMsg = context.tr('user_deleted_success');
              try {
                await DatabaseHelper.instance.deleteUser(
                  user.id!,
                  actorId: authProvider.currentUser?.id,
                  actorName: authProvider.currentUser?.fullName,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (!mounted) return;
                _loadData();
                messenger.showSnackBar(
                  SnackBar(content: Text(successMsg), backgroundColor: AppColors.success),
                );
              } catch (e) {
                if (ctx.mounted) Navigator.of(ctx).pop();
                messenger.showSnackBar(
                  SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
                );
              }
            },
            child: Text(context.tr('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthorizationService>(context);

    if (!authService.can(AppPermissions.usersView)) {
      return const AccessDeniedView(requiredPermission: AppPermissions.usersView);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add User Action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.manage_accounts_outlined, color: AppColors.primaryTeal, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('users_management'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    context.tr('users_management_sub'),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              PermissionGuard(
                permission: AppPermissions.usersCreate,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    context.tr('add_user'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: _openAddUserDialog,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Filters Bar
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: context.tr('search_user_hint'),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _roleFilter,
                    dropdownColor: AppColors.cardHover,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(context.tr('all_roles'))),
                      ..._roles.map((r) => DropdownMenuItem(value: r.name, child: Text(r.displayName))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _roleFilter = val);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primaryTeal),
                onPressed: _loadData,
                tooltip: context.tr('refresh'),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Users Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 24,
                          headingRowColor: WidgetStateProperty.all(AppColors.cardHover),
                          columns: [
                            DataColumn(label: Text(context.tr('user_col_id'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('user_col_name'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('user_col_email'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('user_col_role'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('user_col_status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('user_col_last_login'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('user_col_actions'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _filteredUsers.map((u) {
                            return DataRow(
                              cells: [
                                DataCell(Text('#${u.id ?? "-"}')),
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                                        child: Text(
                                          u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : 'U',
                                          style: const TextStyle(fontSize: 12, color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(u.email)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: u.isSuperAdmin
                                          ? AppColors.primaryPurple.withValues(alpha: 0.2)
                                          : AppColors.primaryTeal.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: u.isSuperAdmin
                                            ? AppColors.primaryPurple.withValues(alpha: 0.4)
                                            : AppColors.primaryTeal.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Text(
                                      u.roleDisplayName ?? u.roleName ?? 'N/A',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: u.isSuperAdmin ? Colors.purpleAccent : AppColors.primaryTeal,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: u.isActive ? AppColors.success : AppColors.danger,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        u.isActive ? context.tr('status_active') : context.tr('status_inactive'),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: u.isActive ? AppColors.success : AppColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    u.lastLoginAt != null ? u.lastLoginAt!.substring(0, 16).replaceAll('T', ' ') : context.tr('never_logged'),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    children: [
                                      PermissionGuard(
                                        permission: AppPermissions.usersUpdate,
                                        child: IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueAccent),
                                          onPressed: () => _openEditUserDialog(u),
                                          tooltip: context.tr('edit'),
                                        ),
                                      ),
                                      if (!u.isSuperAdmin)
                                        PermissionGuard(
                                          permission: AppPermissions.usersDelete,
                                          child: IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                            onPressed: () => _confirmDeleteUser(u),
                                            tooltip: context.tr('delete'),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
