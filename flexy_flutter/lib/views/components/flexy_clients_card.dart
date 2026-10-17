import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/cyber_button.dart';
import '../../models/client_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/flexy_provider.dart';

class FlexyClientsCard extends StatefulWidget {
  final TextEditingController searchController;

  const FlexyClientsCard({
    super.key,
    required this.searchController,
  });

  @override
  State<FlexyClientsCard> createState() => _FlexyClientsCardState();
}

class _FlexyClientsCardState extends State<FlexyClientsCard> {
  final ScrollController _clientsScrollController = ScrollController();
  int _currentPage = 1;
  int _rowsPerPage = 5;

  // Sorting State: 0: Nom & Prénom, 2: Dette (Credit)
  int? _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void dispose() {
    _clientsScrollController.dispose();
    super.dispose();
  }

  void _onSort(int columnIndex) {
    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }
    });
  }

  // Demo mock clients when database is empty
  final List<ClientModel> _mockClients = [
    ClientModel(
      id: 1,
      nomPrenom: 'bilal dev',
      fidel: true,
      type: false,
      numeroPhoneList: ['0659812181'],
      credit: 1000.0,
    ),
    ClientModel(
      id: 2,
      nomPrenom: 'hhhh',
      fidel: false,
      type: false,
      numeroPhoneList: ['0772512141', '0659812181'],
      credit: 0.0,
    ),
    ClientModel(
      id: 3,
      nomPrenom: 'Anonyme',
      fidel: false,
      type: false,
      numeroPhoneList: ['0655665151'],
      credit: 200.0,
    ),
    ClientModel(
      id: 4,
      nomPrenom: 'Fournisseur Mobilis',
      fidel: true,
      type: true,
      numeroPhoneList: ['0600000000'],
      credit: 0.0,
    ),
  ];

  void _showAddClientDialog(BuildContext context, [ClientModel? existingClient]) {
    final nameController = TextEditingController(text: existingClient?.nomPrenom ?? '');
    final phoneController = TextEditingController(
      text: existingClient != null ? existingClient.numeroPhoneList.join(', ') : '',
    );
    final creditController = TextEditingController(
      text: existingClient != null ? existingClient.credit.toString() : '0',
    );
    bool isFidel = existingClient?.fidel ?? false;
    bool isFournisseur = existingClient?.type ?? false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              title: Row(
                children: [
                  const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryTeal),
                  const SizedBox(width: 10),
                  Text(
                    existingClient == null ? 'Ajouter un nouveau client' : 'Modifier le client',
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Nom & Prénom',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.person_outline, color: AppColors.primaryTeal),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: phoneController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Numéro(s) de téléphone (séparés par virgule)',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primaryTeal),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: creditController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Crédit initial / Dette (DA)',
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primaryTeal),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Checkbox(
                            value: isFidel,
                            activeColor: AppColors.primaryTeal,
                            onChanged: (val) => setDialogState(() => isFidel = val ?? false),
                          ),
                          const Text('Client Fidèle ⭐', style: TextStyle(color: AppColors.textPrimary)),
                          const Spacer(),
                          Checkbox(
                            value: isFournisseur,
                            activeColor: AppColors.primaryPurple,
                            onChanged: (val) => setDialogState(() => isFournisseur = val ?? false),
                          ),
                          const Text('Fournisseur', style: TextStyle(color: AppColors.textPrimary)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final phones = phoneController.text
                        .split(',')
                        .map((p) => p.trim())
                        .where((p) => p.isNotEmpty)
                        .toList();

                    final credit = double.tryParse(creditController.text.trim()) ?? 0.0;

                    final client = ClientModel(
                      id: existingClient?.id,
                      nomPrenom: name,
                      fidel: isFidel,
                      type: isFournisseur,
                      numeroPhoneList: phones,
                      credit: credit,
                    );

                    final provider = Provider.of<FlexyProvider>(context, listen: false);
                    await provider.saveClient(client);
                    if (context.mounted) Navigator.pop(dialogCtx);
                  },
                  child: const Text('Enregistrer', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPayDebtDialog(BuildContext context, ClientModel client) {
    final amountController = TextEditingController(text: client.credit.toStringAsFixed(0));
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          title: Row(
            children: [
              const Icon(Icons.monetization_on_rounded, color: AppColors.warning),
              const SizedBox(width: 10),
              Text(
                'Règlement de dette: ${client.nomPrenom}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded, color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Dette actuelle: ${client.credit.toStringAsFixed(2)} DA',
                      style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Montant à régler (DA)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.primaryTeal),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Note / Remarque (Optionnel)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.primaryTeal),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                if (amount <= 0) return;

                final flexyProvider = Provider.of<FlexyProvider>(context, listen: false);
                final authProvider = Provider.of<AuthProvider>(context, listen: false);

                final currentUser = authProvider.currentUser ??
                    UserModel(email: 'admin@flexy.com', fullName: 'Admin', password: '');

                await flexyProvider.payClientCredit(
                  client: client,
                  amountPaid: amount,
                  user: currentUser,
                  note: noteController.text.trim(),
                );

                if (context.mounted) Navigator.pop(dialogCtx);
              },
              child: const Text('Valider le paiement', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final flexyProvider = Provider.of<FlexyProvider>(context);
    final query = widget.searchController.text.toLowerCase().trim();

    final clientsList = flexyProvider.clientList.isNotEmpty
        ? flexyProvider.clientList
        : _mockClients;

    final filteredClients = clientsList.where((c) {
      if (query.isEmpty) return true;
      final matchesName = c.nomPrenom.toLowerCase().contains(query);
      final matchesPhone = c.numeroPhoneList.any((p) => p.contains(query));
      return matchesName || matchesPhone;
    }).toList();

    // Column Sorting Logic
    if (_sortColumnIndex != null) {
      filteredClients.sort((a, b) {
        int comparison = 0;
        switch (_sortColumnIndex) {
          case 0: // Nom & Prénom
            comparison = a.nomPrenom.compareTo(b.nomPrenom);
            break;
          case 2: // Dette / Crédit
            comparison = a.credit.compareTo(b.credit);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }

    // Pagination Calculation
    final totalPages = (filteredClients.length / _rowsPerPage).ceil().clamp(1, 999);
    if (_currentPage > totalPages) _currentPage = totalPages;

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, filteredClients.length);
    final currentPageItems = startIndex < filteredClients.length
        ? filteredClients.sublist(startIndex, endIndex)
        : <ClientModel>[];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        height: 455,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar: Title + Search Bar + Add Client Button
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, color: AppColors.primaryTeal, size: 22),
                    const SizedBox(width: 10),
                    const Text(
                      'Clients & Dettes',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    // Search Input
                    SizedBox(
                      width: 250,
                      height: 42,
                      child: TextField(
                        controller: widget.searchController,
                        onChanged: (_) => setState(() => _currentPage = 1),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un client...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.background,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.primaryTeal, width: 1.2),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Add Client Button
                    SizedBox(
                      width: 200,
                      child: CyberButton(
                        label: 'Nouveau client',
                        icon: Icons.person_add_rounded,
                        height: 42,
                        onPressed: () => _showAddClientDialog(context),
                      ),
                    ),
                  ],
                ),

            const SizedBox(height: 10),

            // Clients Table Header with Sorting
            _ClientsTableHeader(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              onSort: _onSort,
            ),

            const Divider(color: AppColors.border, height: 1),

            // Clients List Rows Body (EXPANDED + SCROLLABLE: Never Overflows!)
            Expanded(
              child: filteredClients.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, color: AppColors.textMuted, size: 36),
                          SizedBox(height: 8),
                          Text(
                            'Aucun client trouvé',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      controller: _clientsScrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _clientsScrollController,
                        itemCount: currentPageItems.length,
                        separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (context, index) {
                          final client = currentPageItems[index];
                          return _ClientRowItem(
                            client: client,
                            onPayDebt: () => _showPayDebtDialog(context, client),
                            onEdit: () => _showAddClientDialog(context, client),
                            onDelete: () async {
                              if (client.id != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Client ${client.nomPrenom} supprimé')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
            ),

            // Footer Bar: Rows Per Page Selector + Counter + Interactive Pagination
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              child: Row(
                children: [
                  // Rows Per Page Selector Dropdown
                  const Text(
                    'Lignes :',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                  ),
                  const SizedBox(width: 4),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _rowsPerPage,
                      dropdownColor: AppColors.cardHover,
                      icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.primaryTeal, size: 16),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _rowsPerPage = val;
                            _currentPage = 1;
                          });
                        }
                      },
                      items: [5, 10, 20, 50].map((int val) {
                        return DropdownMenuItem<int>(
                          value: val,
                          child: Text('$val'),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Item Range Counter
                  Text(
                    filteredClients.isNotEmpty
                        ? '${startIndex + 1}-$endIndex sur ${filteredClients.length} clients'
                        : '0 clients',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  // Interactive Pagination Controls (< Page 1 / 2 >)
                  if (totalPages > 1) ...[
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      color: _currentPage > 1 ? AppColors.primaryTeal : AppColors.textMuted,
                      onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        '$_currentPage / $totalPages',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      color: _currentPage < totalPages ? AppColors.primaryTeal : AppColors.textMuted,
                      onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientsTableHeader extends StatelessWidget {
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int) onSort;

  const _ClientsTableHeader({
    required this.sortColumnIndex,
    required this.sortAscending,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildSortHeader('Nom & Prénom', 0)),
          const Expanded(flex: 3, child: Text('Numéros de Téléphone', style: _headerStyle)),
          const Expanded(flex: 2, child: Text('Type', style: _headerStyle)),
          Expanded(flex: 3, child: _buildSortHeader('Crédit / Dette', 2)),
          const SizedBox(width: 120, child: Text('Actions', style: _headerStyle)),
        ],
      ),
    );
  }

  Widget _buildSortHeader(String label, int index) {
    final isSelected = sortColumnIndex == index;
    return InkWell(
      onTap: () => onSort(index),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primaryTeal : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            isSelected
                ? (sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded)
                : Icons.unfold_more_rounded,
            size: 13,
            color: isSelected ? AppColors.primaryTeal : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );
}

class _ClientRowItem extends StatelessWidget {
  final ClientModel client;
  final VoidCallback onPayDebt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientRowItem({
    required this.client,
    required this.onPayDebt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasCredit = client.credit > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          // Client Name & Avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: client.type ? AppColors.primaryPurple : AppColors.primaryTeal,
                  child: Text(
                    client.nomPrenom.isNotEmpty ? client.nomPrenom[0].toUpperCase() : 'C',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          client.nomPrenom,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (client.fidel) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Phone Numbers List
          Expanded(
            flex: 3,
            child: Text(
              client.numeroPhoneList.isNotEmpty ? client.numeroPhoneList.join(', ') : 'Aucun',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Client Type Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: client.type
                      ? AppColors.primaryPurple.withValues(alpha: 0.15)
                      : AppColors.primaryTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  client.type ? 'Fournisseur' : 'Client',
                  style: TextStyle(
                    color: client.type ? AppColors.primaryPurple : AppColors.primaryTeal,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          // Credit / Debt Amount Pill
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasCredit
                      ? AppColors.danger.withValues(alpha: 0.15)
                      : AppColors.success.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: hasCredit ? AppColors.danger : AppColors.success,
                    width: 1,
                  ),
                ),
                child: Text(
                  '${client.credit.toStringAsFixed(2)} DA',
                  style: TextStyle(
                    color: hasCredit ? AppColors.danger : AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons: Pay Debt, Edit, Delete
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasCredit)
                  IconButton(
                    icon: const Icon(Icons.payments_rounded, color: AppColors.warning, size: 19),
                    onPressed: onPayDebt,
                    tooltip: 'تسديد الدين (Payer la dette)',
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary, size: 18),
                  onPressed: onEdit,
                  tooltip: 'تعديل البيانات',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                  onPressed: onDelete,
                  tooltip: 'حذف الزبون',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
