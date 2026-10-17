import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../database/database_helper.dart';

class AccountSwitcherDialog extends StatefulWidget {
  const AccountSwitcherDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AccountSwitcherDialog(),
    );
  }

  @override
  State<AccountSwitcherDialog> createState() => _AccountSwitcherDialogState();
}

class _AccountSwitcherDialogState extends State<AccountSwitcherDialog> {
  bool _showAddForm = false;
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isAdding = false;
  String? _addError;
  List<UserModel> _allDatabaseUsers = [];

  @override
  void initState() {
    super.initState();
    _loadAllUsersForSuperAdmin();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAllUsersForSuperAdmin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser?.isSuperAdmin == true || auth.currentUser?.isAdmin == true) {
      try {
        final users = await DatabaseHelper.instance.getAllUsers();
        if (mounted) {
          setState(() {
            _allDatabaseUsers = users;
          });
        }
      } catch (_) {}
    }
  }

  /// Opens a dedicated Password Confirmation modal to verify the user's identity before switching
  void _openPasswordPrompt(UserModel targetUser) {
    final passCtrl = TextEditingController();
    bool isVerifying = false;
    String? errorText;
    bool obscure = true;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_person_outlined, color: AppColors.primaryTeal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('password_verification_title'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Target Account Card Preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryTeal.withValues(alpha: 0.2),
                        child: Text(
                          targetUser.fullName.isNotEmpty ? targetUser.fullName[0].toUpperCase() : 'U',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryTeal, fontSize: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              targetUser.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                            ),
                            Text(
                              targetUser.email,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.cardHover,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          targetUser.roleDisplayName ?? targetUser.roleName ?? '',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr('enter_account_password_prompt'),
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  obscureText: obscure,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: context.tr('password'),
                    prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.primaryTeal),
                    suffixIcon: IconButton(
                      icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                      onPressed: () => setDialogState(() => obscure = !obscure),
                    ),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onSubmitted: (_) async {
                    // Trigger switch on Enter key
                    final pass = passCtrl.text;
                    if (pass.isEmpty) return;

                    setDialogState(() {
                      isVerifying = true;
                      errorText = null;
                    });

                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final messenger = ScaffoldMessenger.of(context);
                    final msg = context.tr('account_switched_success');

                    final success = await authProvider.switchAccountWithPassword(targetUser.email, pass);

                    if (dlgCtx.mounted) {
                      setDialogState(() => isVerifying = false);
                      if (success) {
                        Navigator.of(dlgCtx).pop(); // Close password dialog
                        if (mounted) Navigator.of(context).pop(); // Close switcher modal
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('$msg (${targetUser.fullName})'),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      } else {
                        setDialogState(() {
                          errorText = authProvider.errorMessage ?? context.tr('incorrect_password');
                        });
                      }
                    }
                  },
                ),
                if (errorText != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          errorText!,
                          style: const TextStyle(color: AppColors.danger, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dlgCtx).pop(),
              child: Text(context.tr('cancel'), style: const TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isVerifying
                  ? null
                  : () async {
                      final pass = passCtrl.text;
                      if (pass.isEmpty) {
                        setDialogState(() => errorText = context.tr('fill_all_fields'));
                        return;
                      }

                      setDialogState(() {
                        isVerifying = true;
                        errorText = null;
                      });

                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final messenger = ScaffoldMessenger.of(context);
                      final msg = context.tr('account_switched_success');

                      final success = await authProvider.switchAccountWithPassword(targetUser.email, pass);

                      if (dlgCtx.mounted) {
                        setDialogState(() => isVerifying = false);
                        if (success) {
                          Navigator.of(dlgCtx).pop(); // Close password dialog
                          if (mounted) Navigator.of(context).pop(); // Close switcher modal
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('$msg (${targetUser.fullName})'),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        } else {
                          setDialogState(() {
                            errorText = authProvider.errorMessage ?? context.tr('incorrect_password');
                          });
                        }
                      }
                    },
              child: isVerifying
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : Text(context.tr('confirm_and_switch'), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewAccountAndSwitch() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _addError = context.tr('fill_all_fields'));
      return;
    }

    setState(() {
      _isAdding = true;
      _addError = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    final msg = context.tr('account_switched_success');

    final success = await authProvider.addAndSwitchAccount(email, password);

    if (mounted) {
      setState(() => _isAdding = false);
      if (success) {
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text('$msg (${authProvider.currentUser?.fullName})'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _addError = authProvider.errorMessage ?? context.tr('incorrect_password'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.currentUser;
    final savedAccounts = authProvider.savedAccounts;

    // Combine saved accounts with any extra database accounts if user is Admin/SuperAdmin
    final List<UserModel> otherAccounts = [];
    final Set<int> addedIds = {};

    if (currentUser?.id != null) {
      addedIds.add(currentUser!.id!);
    }

    for (final sa in savedAccounts) {
      if (sa.id != null && !addedIds.contains(sa.id)) {
        otherAccounts.add(sa);
        addedIds.add(sa.id!);
      }
    }

    // If Admin/SuperAdmin, also list other system users for quick administrative switching
    if (currentUser?.isAdmin == true) {
      for (final u in _allDatabaseUsers) {
        if (u.id != null && !addedIds.contains(u.id)) {
          otherAccounts.add(u);
          addedIds.add(u.id!);
        }
      }
    }

    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: 520,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.switch_account_rounded, color: AppColors.primaryTeal, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('switch_account'),
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      Text(
                        context.tr('switch_account_sub'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Active Account Card
            if (currentUser != null) ...[
              Text(
                context.tr('active_account'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryTeal.withValues(alpha: 0.5), width: 1.5),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primaryTeal,
                      child: Text(
                        currentUser.fullName.isNotEmpty ? currentUser.fullName[0].toUpperCase() : 'U',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                currentUser.fullName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  context.tr('active_label'),
                                  style: const TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentUser.email,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardHover,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        authProvider.roleDisplayName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Other Saved Accounts List
            if (otherAccounts.isNotEmpty) ...[
              Text(
                context.tr('saved_accounts'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: otherAccounts.length,
                  itemBuilder: (context, index) {
                    final acc = otherAccounts[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.cardHover,
                            child: Text(
                              acc.fullName.isNotEmpty ? acc.fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  acc.fullName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                Text(
                                  '${acc.email} • ${acc.roleDisplayName ?? acc.roleName ?? ""}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.cardHover,
                              foregroundColor: AppColors.primaryTeal,
                              side: const BorderSide(color: AppColors.primaryTeal),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.lock_outline, size: 15),
                            label: Text(
                              context.tr('switch_button'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _openPasswordPrompt(acc),
                          ),
                          if (savedAccounts.any((sa) => sa.id == acc.id))
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
                              tooltip: context.tr('remove_saved_account'),
                              onPressed: () => authProvider.removeSavedAccount(acc.id!),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Toggle / Add Another Account Section
            if (!_showAddForm) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.borderLight),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18, color: AppColors.primaryTeal),
                  label: Text(context.tr('add_account')),
                  onPressed: () => setState(() => _showAddForm = true),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.tr('add_account'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryTeal),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => setState(() {
                            _showAddForm = false;
                            _addError = null;
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(
                        labelText: context.tr('email_address'),
                        prefixIcon: const Icon(Icons.email_outlined, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: context.tr('password'),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (_addError != null) ...[
                      const SizedBox(height: 8),
                      Text(_addError!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryTeal,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isAdding ? null : _addNewAccountAndSwitch,
                        child: _isAdding
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                            : Text(context.tr('login_button'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
