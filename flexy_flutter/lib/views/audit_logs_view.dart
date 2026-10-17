import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../core/authorization/app_permissions.dart';
import '../core/authorization/authorization_service.dart';
import '../database/database_helper.dart';
import '../models/audit_log_model.dart';
import 'access_denied_view.dart';

class AuditLogsView extends StatefulWidget {
  const AuditLogsView({super.key});

  @override
  State<AuditLogsView> createState() => _AuditLogsViewState();
}

class _AuditLogsViewState extends State<AuditLogsView> {
  List<AuditLogModel> _logs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await DatabaseHelper.instance.getAllAuditLogs(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _statusFilter != 'all' ? _statusFilter : null,
      );
      if (mounted) {
        setState(() {
          _logs = logs;
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

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthorizationService>(context);

    if (!authService.can(AppPermissions.auditLogsView)) {
      return const AccessDeniedView(requiredPermission: AppPermissions.auditLogsView);
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_edu_outlined, color: Colors.amberAccent, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('audit_logs'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  Text(
                    context.tr('audit_logs_sub'),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.primaryTeal),
                onPressed: _loadLogs,
                tooltip: context.tr('refresh'),
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
                    hintText: context.tr('search_audit_hint'),
                    prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                  ),
                  onSubmitted: (val) {
                    _searchQuery = val;
                    _loadLogs();
                  },
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
                    value: _statusFilter,
                    dropdownColor: AppColors.cardHover,
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(context.tr('all_statuses'))),
                      DropdownMenuItem(value: 'SUCCESS', child: Text(context.tr('status_success'))),
                      DropdownMenuItem(value: 'DENIED', child: Text(context.tr('status_denied'))),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _statusFilter = val);
                        _loadLogs();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Table
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
                          columnSpacing: 20,
                          headingRowColor: WidgetStateProperty.all(AppColors.cardHover),
                          columns: [
                            DataColumn(label: Text(context.tr('audit_col_id'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('audit_col_timestamp'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('audit_col_user'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('audit_col_action'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('audit_col_resource'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('audit_col_status'), style: const TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text(context.tr('audit_col_reason'), style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _logs.map((log) {
                            return DataRow(
                              cells: [
                                DataCell(Text('#${log.id}')),
                                DataCell(Text(
                                  log.createdAt.substring(0, 19).replaceAll('T', ' '),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'monospace'),
                                )),
                                DataCell(
                                  Text(
                                    log.userFullName ?? (log.userId != null ? 'User #${log.userId}' : 'Système / Anonyme'),
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Text(
                                      log.action,
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.primaryTeal),
                                    ),
                                  ),
                                ),
                                DataCell(Text(log.resource)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: log.isSuccess
                                          ? AppColors.success.withValues(alpha: 0.15)
                                          : AppColors.danger.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: log.isSuccess
                                            ? AppColors.success.withValues(alpha: 0.4)
                                            : AppColors.danger.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      log.status,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: log.isSuccess ? AppColors.success : AppColors.danger,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    log.reason ?? '-',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
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
