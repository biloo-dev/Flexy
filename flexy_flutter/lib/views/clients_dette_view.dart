import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../core/authorization/app_permissions.dart';
import '../core/authorization/permission_guard.dart';
import '../models/client_model.dart';
import '../providers/auth_provider.dart';
import '../providers/flexy_provider.dart';

class ClientsDetteView extends StatefulWidget {
  const ClientsDetteView({super.key});

  @override
  State<ClientsDetteView> createState() => _ClientsDetteViewState();
}

class _ClientsDetteViewState extends State<ClientsDetteView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flexyProvider = Provider.of<FlexyProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    final clientsWithDebt = flexyProvider.clientList.where((c) {
      final matchesSearch = c.nomPrenom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.numeroPhoneList.any((p) => p.contains(_searchQuery));
      return c.credit > 0 && matchesSearch;
    }).toList();

    final allClients = flexyProvider.clientList.where((c) {
      return c.nomPrenom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.numeroPhoneList.any((p) => p.contains(_searchQuery));
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header title & Summary Cards
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined, size: 28, color: Colors.amberAccent),
              const SizedBox(width: 12),
              const Text(
                'إدارة الديون وتسديد المبالغ',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),

              // Quick summary metrics
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.money_off, color: Colors.redAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'إجمالي الديون: ${flexyProvider.totalClientCredit.toStringAsFixed(2)} DA',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Search & Tabs Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'البحث عن زبون برقم الهاتف أو الاسم...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 380,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.amberAccent,
                  labelColor: Colors.amberAccent,
                  tabs: const [
                    Tab(icon: Icon(Icons.people_outline), text: 'الزبائن والديون'),
                    Tab(icon: Icon(Icons.receipt_long_outlined), text: 'سجل التسديدات والمستلمين'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Clients & Debts List
                _buildClientsDebtList(context, clientsWithDebt, allClients, flexyProvider, authProvider),

                // Tab 2: Payment Audit Log History
                _buildPaymentAuditLog(context, flexyProvider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientsDebtList(
    BuildContext context,
    List<ClientModel> debtClients,
    List<ClientModel> allClients,
    FlexyProvider flexyProvider,
    AuthProvider authProvider,
  ) {
    if (debtClients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'لا توجد ديون مستحقة على الزبائن حالياً',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: debtClients.length,
      itemBuilder: (context, index) {
        final client = debtClients[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.amber.withValues(alpha: 0.2),
                  child: Text(
                    client.nomPrenom.isNotEmpty ? client.nomPrenom[0].toUpperCase() : 'Z',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client.nomPrenom,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'الهاتف: ${client.numeroPhoneList.join(" | ")}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('الدين المستحق', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      '${client.credit.toStringAsFixed(2)} DA',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                PermissionGuard(
                  permission: AppPermissions.debtsPay,
                  child: ElevatedButton.icon(
                    onPressed: () => _showPaymentDialog(context, client, flexyProvider, authProvider),
                    icon: const Icon(Icons.payments_outlined, size: 18),
                    label: const Text('تسديد الدين'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaymentAuditLog(BuildContext context, FlexyProvider flexyProvider) {
    final logs = flexyProvider.paiementDetteList;

    if (logs.isEmpty) {
      return const Center(
        child: Text('لا توجد عمليات تسديد مسجلة بعد', style: TextStyle(color: Colors.grey)),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = logs[index];
          final dateStr = DateFormat('yyyy-MM-dd  HH:mm').format(item.createdAt);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Icon(Icons.history_outlined, color: Colors.blue[300], size: 22),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الزبون: ${item.nomClient}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      dateStr,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'المبلغ المدفوع: ${item.montant.toStringAsFixed(2)} DA',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                    ),
                    Text(
                      'الدين: ${item.ancienCredit.toStringAsFixed(0)} ➔ ${item.nouveauCredit.toStringAsFixed(0)} DA',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                if (item.note != null && item.note!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.note!.contains('دين')
                          ? Colors.orangeAccent.withValues(alpha: 0.15)
                          : Colors.greenAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: item.note!.contains('دين')
                            ? Colors.orangeAccent.withValues(alpha: 0.3)
                            : Colors.greenAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      item.note!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.note!.contains('دين') ? Colors.orangeAccent : Colors.greenAccent,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin, size: 14, color: Colors.blueAccent),
                      const SizedBox(width: 4),
                      Text(
                        'المستلم: ${item.userFullname}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPaymentDialog(
    BuildContext context,
    ClientModel client,
    FlexyProvider flexyProvider,
    AuthProvider authProvider,
  ) {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    double amountPaid = 0.0;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final double remainingDebt = (client.credit - amountPaid).clamp(0.0, double.infinity);
            final currentUser = authProvider.currentUser;

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.payments, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Text('تسديد دين الزبون: ${client.nomPrenom}'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Total Debt & Cashier info header
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('إجمالي الدين الحلي:'),
                              Text(
                                '${client.credit.toStringAsFixed(2)} DA',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('المستلم الحصالي (المستقبل):'),
                              Text(
                                currentUser?.fullName ?? 'Administrator',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick Preset Chips
                    const Text('اختر مبلغا سريعا:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (var val in [500.0, 1000.0, 2000.0, 5000.0])
                          if (val < client.credit)
                            ChoiceChip(
                              label: Text('${val.toInt()} DA'),
                              selected: (amountPaid - val).abs() < 0.01,
                              onSelected: (_) {
                                setDialogState(() {
                                  amountPaid = val;
                                  amountController.text = val.toStringAsFixed(0);
                                });
                              },
                            ),
                        ChoiceChip(
                          label: Text('تسديد الكل (${client.credit.toStringAsFixed(0)} DA)'),
                          selected: (amountPaid - client.credit).abs() < 0.01,
                          onSelected: (_) {
                            setDialogState(() {
                              amountPaid = client.credit;
                              amountController.text = client.credit.toStringAsFixed(0);
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Custom Amount Input
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        setDialogState(() {
                          amountPaid = double.tryParse(val) ?? 0.0;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'المبلغ المدفوع (DA)',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Remaining Debt Preview
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('الدين المتبقي بعد التسديد:'),
                        Text(
                          '${remainingDebt.toStringAsFixed(2)} DA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: remainingDebt == 0 ? Colors.greenAccent : Colors.amberAccent,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Optional Note
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظة (اختياري)',
                        prefixIcon: Icon(Icons.edit_note),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('إلغاء'),
                ),
                ElevatedButton(
                  onPressed: amountPaid <= 0
                      ? null
                      : () async {
                          Navigator.pop(dialogCtx);
                          if (currentUser != null) {
                            await flexyProvider.payClientCredit(
                              client: client,
                              amountPaid: amountPaid,
                              user: currentUser,
                              note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'تم تسجيل تسديد ${amountPaid.toStringAsFixed(2)} DA للزبون ${client.nomPrenom} بنجاح!',
                                  ),
                                  backgroundColor: Colors.green[700],
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('تأكيد التسديد'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
