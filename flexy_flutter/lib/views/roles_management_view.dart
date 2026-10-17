import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../core/authorization/app_permissions.dart';
import '../core/authorization/authorization_service.dart';
import '../core/authorization/permission_guard.dart';
import '../database/database_helper.dart';
import '../models/role_model.dart';
import '../providers/auth_provider.dart';
import 'access_denied_view.dart';

class RolesManagementView extends StatefulWidget {
  const RolesManagementView({super.key});

  @override
  State<RolesManagementView> createState() => _RolesManagementViewState();
}

class _RolesManagementViewState extends State<RolesManagementView> {
  List<RoleModel> _roles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() => _isLoading = true);
    try {
      final roles = await DatabaseHelper.instance.getAllRoles();
      if (mounted) {
        setState(() {
          _roles = roles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _openRoleDialog({RoleModel? roleToEdit}) {
    final bool isEdit = roleToEdit != null;
    final nameCtrl = TextEditingController(text: roleToEdit?.displayName ?? '');
    final descCtrl = TextEditingController(text: roleToEdit?.description ?? '');
    final Set<String> selectedPermissions = Set<String>.from(roleToEdit?.permissions ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final grouped = AppPermissions.groupedPermissions;

          return Dialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 720,
              height: 680,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEdit ? Icons.edit_note_rounded : Icons.add_moderator_rounded,
                        color: AppColors.primaryTeal,
                        size: 26,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEdit ? context.tr('edit_role') : context.tr('create_role'),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Role Name & Description
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameCtrl,
                          decoration: InputDecoration(
                            labelText: context.tr('role_display_name'),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            labelText: context.tr('role_description'),
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Permission Matrix Header & Select/Clear Global
                  Row(
                    children: [
                      Text(
                        context.tr('permissions_matrix'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(Icons.select_all_rounded, size: 18),
                        label: Text(context.tr('select_all')),
                        onPressed: () {
                          setDialogState(() {
                            selectedPermissions.clear();
                            for (final p in AppPermissions.allPermissions) {
                              selectedPermissions.add(p.code);
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: Text(context.tr('clear_all')),
                        onPressed: () {
                          setDialogState(() {
                            selectedPermissions.clear();
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Grouped Permissions List
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListView(
                        padding: const EdgeInsets.all(12),
                        children: grouped.entries.map((entry) {
                          final moduleName = entry.key;
                          final permissions = entry.value;
                          final bool allModuleSelected = permissions.every((p) => selectedPermissions.contains(p.code));

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Material(
                              color: AppColors.card,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: ExpansionTile(
                                shape: const Border(),
                                collapsedShape: const Border(),
                                initiallyExpanded: true,
                                title: Row(
                                  children: [
                                    Text(
                                      _formatModuleName(moduleName, context),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryTeal.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${permissions.where((p) => selectedPermissions.contains(p.code)).length}/${permissions.length}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Checkbox(
                                      value: allModuleSelected,
                                      activeColor: AppColors.primaryTeal,
                                      onChanged: (val) {
                                        setDialogState(() {
                                          if (val == true) {
                                            for (final p in permissions) {
                                              selectedPermissions.add(p.code);
                                            }
                                          } else {
                                            for (final p in permissions) {
                                              selectedPermissions.remove(p.code);
                                            }
                                          }
                                        });
                                      },
                                    ),
                                    const Icon(Icons.expand_more),
                                  ],
                                ),
                                children: permissions.map((p) {
                                  final isChecked = selectedPermissions.contains(p.code);
                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(p.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    subtitle: Text(p.code, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace')),
                                    value: isChecked,
                                    activeColor: AppColors.primaryTeal,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == true) {
                                          selectedPermissions.add(p.code);
                                        } else {
                                          selectedPermissions.remove(p.code);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(context.tr('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
                      ),
                      const SizedBox(width: 14),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.tr('fill_all_fields')), backgroundColor: Colors.orange),
                            );
                            return;
                          }

                          final authProvider = Provider.of<AuthProvider>(context, listen: false);

                          final messenger = ScaffoldMessenger.of(context);
                          final successMessage = isEdit ? context.tr('role_updated_success') : context.tr('role_created_success');

                          try {
                            if (isEdit) {
                              final updated = roleToEdit.copyWith(
                                displayName: nameCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                              );
                              await DatabaseHelper.instance.updateRole(
                                updated,
                                selectedPermissions.toList(),
                                actorId: authProvider.currentUser?.id,
                                actorName: authProvider.currentUser?.fullName,
                              );
                            } else {
                              final newRole = RoleModel(
                                name: nameCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
                                displayName: nameCtrl.text.trim(),
                                description: descCtrl.text.trim(),
                              );
                              await DatabaseHelper.instance.insertRole(
                                newRole,
                                selectedPermissions.toList(),
                                actorId: authProvider.currentUser?.id,
                                actorName: authProvider.currentUser?.fullName,
                              );
                            }

                            if (ctx.mounted) Navigator.of(ctx).pop();
                            if (!mounted) return;
                            _loadRoles();
                            await authProvider.refreshCurrentUser();

                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(successMessage),
                                backgroundColor: AppColors.success,
                              ),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteRole(RoleModel role) {
    if (role.isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cannot_delete_system_role')), backgroundColor: AppColors.danger),
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
        content: Text('${context.tr('delete_role_confirm_msg')} (${role.displayName}) ?'),
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
              final successMsg = context.tr('role_deleted_success');
              try {
                await DatabaseHelper.instance.deleteRole(
                  role.id!,
                  actorId: authProvider.currentUser?.id,
                  actorName: authProvider.currentUser?.fullName,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (!mounted) return;
                _loadRoles();
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

  String _formatModuleName(String module, BuildContext context) {
    switch (module) {
      case 'dashboard':
        return context.tr('dashboard');
      case 'transactions':
        return context.tr('flexy_recharge');
      case 'customers':
        return context.tr('clients_debts');
      case 'debts':
        return context.tr('debt_amount');
      case 'sim_activation':
        return context.tr('sim_activation');
      case 'terminal':
        return context.tr('modem_terminal');
      case 'settings':
        return context.tr('settings');
      case 'users':
        return context.tr('users_management');
      case 'roles':
        return context.tr('roles_permissions');
      case 'audit_logs':
        return context.tr('audit_logs');
      default:
        return module.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthorizationService>(context);

    if (!authService.can(AppPermissions.rolesView)) {
      return const AccessDeniedView(requiredPermission: AppPermissions.rolesView);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Role Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.primaryPurple, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('roles_permissions'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    context.tr('roles_management_sub'),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              PermissionGuard(
                permission: AppPermissions.rolesCreate,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text(
                    context.tr('create_role'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openRoleDialog(),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Roles List Cards
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryTeal))
                : ListView.builder(
                    itemCount: _roles.length,
                    itemBuilder: (context, index) {
                      final role = _roles[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: role.isSystem
                                    ? AppColors.primaryPurple.withValues(alpha: 0.15)
                                    : AppColors.primaryTeal.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                role.isSystem ? Icons.shield_outlined : Icons.badge_outlined,
                                color: role.isSystem ? AppColors.primaryPurple : AppColors.primaryTeal,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        role.displayName,
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(width: 10),
                                      if (role.isSystem)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: Colors.purple.withValues(alpha: 0.4)),
                                          ),
                                          child: Text(
                                            context.tr('system_role'),
                                            style: const TextStyle(fontSize: 10, color: Colors.purpleAccent, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    role.description ?? context.tr('no_description'),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: role.permissions.take(6).map((p) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Text(
                                          p,
                                          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                        ),
                                      );
                                    }).toList()
                                      ..addAll([
                                        if (role.permissions.length > 6)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryTeal.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '+${role.permissions.length - 6} permissions',
                                              style: const TextStyle(fontSize: 10, color: AppColors.primaryTeal, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                      ]),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                PermissionGuard(
                                  permission: AppPermissions.rolesUpdate,
                                  child: IconButton(
                                    icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                                    onPressed: () => _openRoleDialog(roleToEdit: role),
                                    tooltip: context.tr('edit_role'),
                                  ),
                                ),
                                if (!role.isSystem)
                                  PermissionGuard(
                                    permission: AppPermissions.rolesDelete,
                                    child: IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                                      onPressed: () => _confirmDeleteRole(role),
                                      tooltip: context.tr('delete_role'),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
