import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/authorization/app_permissions.dart';
import '../../core/authorization/authorization_service.dart';
import '../../models/historique_model.dart';
import '../../providers/flexy_provider.dart';

class FlexyTableCard extends StatefulWidget {
  final List<HistoriqueModel> transactions;
  final String selectedOperatorFilter;
  final TextEditingController searchController;
  final String? phoneFilter;
  final Function(HistoriqueModel)? onRetry;

  const FlexyTableCard({
    super.key,
    required this.transactions,
    required this.selectedOperatorFilter,
    required this.searchController,
    this.phoneFilter,
    this.onRetry,
  });

  @override
  State<FlexyTableCard> createState() => _FlexyTableCardState();
}

class _FlexyTableCardState extends State<FlexyTableCard> {
  final ScrollController _tableScrollController = ScrollController();
  int _segmentedIndex = 0; // 0: Envoyés (type: true), 1: Reçus (type: false)
  int _currentPage = 1;
  int _rowsPerPage = 5;

  // Sorting State: 0: Opérateur, 1: Numéro, 2: Client, 3: Montant, 6: Date
  int? _sortColumnIndex = 6; // Default sort by Date
  bool _sortAscending = false; // Default newest first

  @override
  void dispose() {
    _tableScrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    // 1. Filter by type: Envoyés vs Reçus
    final filteredByType = widget.transactions.where((t) {
      if (_segmentedIndex == 0) return t.type == true;
      return t.type == false;
    }).toList();

    // 2. Filter by operator brand
    final filteredByOperator = filteredByType.where((t) {
      if (widget.selectedOperatorFilter == 'Tous') return true;
      return t.operatorName.toLowerCase() == widget.selectedOperatorFilter.toLowerCase();
    }).toList();

    // 3. Live Phone Filtering (Requirement: When user types phone in transfer card, filter table immediately!)
    final livePhone = (widget.phoneFilter ?? '').trim().replaceAll(RegExp(r'\s+'), '');
    final searchQuery = widget.searchController.text.trim().toLowerCase();

    final finalFiltered = filteredByOperator.where((t) {
      final tPhoneClean = t.phone.replaceAll(RegExp(r'\s+'), '');

      // If phone is typed in the main transfer card, live-filter by it
      if (livePhone.isNotEmpty) {
        return tPhoneClean.contains(livePhone);
      }

      if (searchQuery.isNotEmpty) {
        return t.phone.toLowerCase().contains(searchQuery) ||
            (t.clientName ?? '').toLowerCase().contains(searchQuery);
      }
      return true;
    }).toList();

    // 4. Column Sorting Logic
    if (_sortColumnIndex != null) {
      finalFiltered.sort((a, b) {
        int comparison = 0;
        switch (_sortColumnIndex) {
          case 0:
            comparison = a.operatorName.compareTo(b.operatorName);
            break;
          case 1:
            comparison = a.phone.compareTo(b.phone);
            break;
          case 2:
            comparison = (a.clientName ?? '').compareTo(b.clientName ?? '');
            break;
          case 3:
            comparison = a.montant.compareTo(b.montant);
            break;
          case 6:
            comparison = a.createdAt.compareTo(b.createdAt);
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    }

    // 5. Pagination Calculation
    final totalPages = (finalFiltered.length / _rowsPerPage).ceil().clamp(1, 999);
    if (_currentPage > totalPages) _currentPage = totalPages;

    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final endIndex = (startIndex + _rowsPerPage).clamp(0, finalFiltered.length);
    final currentPageItems = startIndex < finalFiltered.length
        ? finalFiltered.sublist(startIndex, endIndex)
        : <HistoriqueModel>[];

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SizedBox(
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Segmented Control (Envoyés / Reçus) & Search Bar
            Row(
              children: [
                // Segmented Pill Toggle: Envoyés / Reçus (Matching Reference Screenshot)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF070D18),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Row(
                    children: [
                      _SegmentedButton(
                        label: 'Envoyés',
                        icon: Icons.near_me_rounded,
                        isSelected: _segmentedIndex == 0,
                        onTap: () => setState(() {
                          _segmentedIndex = 0;
                          _currentPage = 1;
                        }),
                      ),
                      _SegmentedButton(
                        label: 'Reçus',
                        icon: Icons.move_to_inbox_rounded,
                        isSelected: _segmentedIndex == 1,
                        onTap: () => setState(() {
                          _segmentedIndex = 1;
                          _currentPage = 1;
                        }),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Live Active Filter Indicator (if user typed a phone number)
                if (livePhone.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E6A8).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00E6A8).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_rounded, size: 13, color: Color(0xFF00E6A8)),
                        const SizedBox(width: 4),
                        Text(
                          'Filtré: $livePhone (${finalFiltered.length})',
                          style: const TextStyle(
                            color: Color(0xFF00E6A8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // Search Input Field & Filter Action Button
                SizedBox(
                  width: 270,
                  height: 38,
                  child: TextField(
                    controller: widget.searchController,
                    onChanged: (_) => setState(() => _currentPage = 1),
                    style: const TextStyle(fontSize: 12.5, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par N° / Client...',
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                      prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF64748B)),
                      suffixIcon: const Icon(Icons.tune_rounded, size: 16, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: const Color(0xFF070D18),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1E293B)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1E293B)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF00E6A8), width: 1.2),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 2. Table Columns Header with Sorting Support
            _TableHeaderRow(
              sortColumnIndex: _sortColumnIndex,
              sortAscending: _sortAscending,
              onSort: _onSort,
            ),

            const Divider(color: Color(0xFF152238), height: 1),

            // 3. Table Rows Body (EXPANDED + SCROLLABLE)
            Expanded(
              child: finalFiltered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, color: Color(0xFF475569), size: 36),
                          const SizedBox(height: 8),
                          Text(
                            livePhone.isNotEmpty
                                ? 'لا توجد تحويلات سابقة للرقم $livePhone'
                                : 'Aucune transaction trouvée',
                            style: const TextStyle(color: Color(0xFF8F9CAE), fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  : Scrollbar(
                      controller: _tableScrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: _tableScrollController,
                        itemCount: currentPageItems.length,
                        separatorBuilder: (_, __) => const Divider(color: Color(0xFF152238), height: 1),
                        itemBuilder: (context, index) {
                          final tx = currentPageItems[index];
                          return _TransactionItemRow(
                            transaction: tx,
                            onRetry: widget.onRetry,
                          );
                        },
                      ),
                    ),
            ),

            // 4. Advanced DataTable Footer Bar: Rows Per Page + Item Counter + Pagination + Quick Exports
            Container(
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF152238), width: 1)),
              ),
              child: Row(
                children: [
                  // Rows Per Page Selector Dropdown
                  const Text(
                    'Lignes :',
                    style: TextStyle(color: Color(0xFF8F9CAE), fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _rowsPerPage,
                      dropdownColor: const Color(0xFF0F1A2C),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF8F9CAE), size: 16),
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
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

                  const SizedBox(width: 14),

                  // Item Range Counter (e.g. 1-5 sur 11)
                  Text(
                    finalFiltered.isNotEmpty
                        ? '${startIndex + 1}-$endIndex sur ${finalFiltered.length}'
                        : '0 transaction',
                    style: const TextStyle(
                      color: Color(0xFF8F9CAE),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const Spacer(),

                  // Interactive Pagination Controls (< Page 1 / 3 >)
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    color: _currentPage > 1 ? const Color(0xFF00E6A8) : const Color(0xFF475569),
                    onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070D18),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF1E293B)),
                    ),
                    child: Text(
                      '$_currentPage / $totalPages',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    color: _currentPage < totalPages ? const Color(0xFF00E6A8) : const Color(0xFF475569),
                    onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 14),

                  // Print & Export Action Chips
                  _FooterActionButton(
                    label: 'Imprimer',
                    icon: Icons.print_outlined,
                    onTap: () {},
                  ),
                  const SizedBox(width: 8),
                  _FooterActionButton(
                    label: 'Exporter CSV',
                    icon: Icons.hub_outlined,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FooterActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF070D18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: const Color(0xFFCBD5E1)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentedButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00E6A8) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? Colors.black : const Color(0xFF8F9CAE),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : const Color(0xFF8F9CAE),
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  final int? sortColumnIndex;
  final bool sortAscending;
  final Function(int) onSort;

  const _TableHeaderRow({
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
          Expanded(flex: 2, child: _buildSortHeader('Opérateur', 0)),
          Expanded(flex: 3, child: _buildSortHeader('Numéro', 1)),
          Expanded(flex: 2, child: _buildSortHeader('Client', 2)),
          Expanded(flex: 2, child: _buildSortHeader('Montant', 3)),
          const SizedBox(width: 50, child: Center(child: Text('Statut', style: _headerStyle))),
          const SizedBox(width: 50, child: Center(child: Text('Crédit', style: _headerStyle))),
          Expanded(flex: 3, child: _buildSortHeader('Date', 6)),
          const SizedBox(width: 24),
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
              color: isSelected ? const Color(0xFF00E6A8) : const Color(0xFF8F9CAE),
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
            color: isSelected ? const Color(0xFF00E6A8) : const Color(0xFF475569),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    color: Color(0xFF8F9CAE),
    fontSize: 11,
    fontWeight: FontWeight.bold,
  );
}

class _TransactionItemRow extends StatelessWidget {
  final HistoriqueModel transaction;
  final Function(HistoriqueModel)? onRetry;

  const _TransactionItemRow({
    required this.transaction,
    this.onRetry,
  });

  String _formatPhone(String raw) {
    final clean = raw.replaceAll(RegExp(r'\s+'), '');
    if (clean.length == 10) {
      return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, 6)} ${clean.substring(6, 8)} ${clean.substring(8, 10)}';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // 1. Operator Tag (Exact style with colored dot and dark border)
          Expanded(
            flex: 2,
            child: _OperatorTag(operatorName: transaction.operatorName),
          ),

          // 2. Phone Number (Large bold 2-digit formatted string: 06 55 12 51 21)
          Expanded(
            flex: 3,
            child: Text(
              _formatPhone(transaction.phone),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // 3. Client Name
          Expanded(
            flex: 2,
            child: Text(
              transaction.clientName ?? 'Anonyme',
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // 4. Amount Text (Bright Teal: 100.0 DA)
          Expanded(
            flex: 2,
            child: Text(
              '${transaction.montant.toStringAsFixed(1)} DA',
              style: const TextStyle(
                color: Color(0xFF00E6A8),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          // 5. Status Icon (Circular green check badge for SUCCESS, Red for FAILED)
          SizedBox(
            width: 50,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: transaction.status
                      ? const Color(0xFF10B981).withValues(alpha: 0.18)
                      : const Color(0xFFEF4444).withValues(alpha: 0.18),
                  border: Border.all(
                    color: transaction.status
                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                        : const Color(0xFFEF4444).withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  transaction.status ? Icons.check_rounded : Icons.close_rounded,
                  color: transaction.status ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 13,
                ),
              ),
            ),
          ),

          // 6. Credit Icon (Green check for PAID / FALSE credit, Amber triangle for TRUE credit / à crédit)
          SizedBox(
            width: 50,
            child: Center(
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCredit
                      ? const Color(0xFFF59E0B).withValues(alpha: 0.18)
                      : const Color(0xFF10B981).withValues(alpha: 0.18),
                  border: Border.all(
                    color: isCredit
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                        : const Color(0xFF10B981).withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  isCredit ? Icons.warning_rounded : Icons.check_rounded,
                  color: isCredit ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                  size: isCredit ? 12 : 13,
                ),
              ),
            ),
          ),

          // 7. Date & Time (10/05/2024 12:10:45)
          Expanded(
            flex: 3,
            child: Text(
              transaction.dateFormatted,
              style: const TextStyle(
                color: Color(0xFF8F9CAE),
                fontSize: 11,
              ),
            ),
          ),

          // 8. Action Menu (Popup menu with Retry, Copy Phone, Delete)
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              size: 16,
              color: Color(0xFF8F9CAE),
            ),
            color: const Color(0xFF0F1A2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF1E293B)),
            ),
            onSelected: (action) {
              if (action == 'retry') {
                onRetry?.call(transaction);
              } else if (action == 'copy') {
                Clipboard.setData(ClipboardData(text: transaction.phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Numéro ${transaction.phone} copié !'),
                    backgroundColor: const Color(0xFF00E6A8),
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (action == 'delete') {
                if (transaction.id != null) {
                  final flexyProvider = Provider.of<FlexyProvider>(context, listen: false);
                  flexyProvider.deleteHistorique(transaction.id!);
                }
              }
            },
            itemBuilder: (context) {
              final authService = Provider.of<AuthorizationService>(context, listen: false);
              return [
                if (authService.can(AppPermissions.transactionsCreate))
                  PopupMenuItem(
                    value: 'retry',
                    child: Row(
                      children: [
                        Icon(
                          Icons.replay_rounded,
                          size: 16,
                          color: !transaction.status ? const Color(0xFFEF4444) : const Color(0xFF00E6A8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          !transaction.status ? 'Réessayer le transfert 🔄' : 'Renvoyer à nouveau 🔄',
                          style: TextStyle(
                            color: !transaction.status ? const Color(0xFFEF4444) : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded, size: 16, color: Color(0xFFCBD5E1)),
                      SizedBox(width: 8),
                      Text('Copier le numéro 📋', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  ),
                ),
                if (authService.can(AppPermissions.transactionsDelete))
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 8),
                        Text('Supprimer 🗑️', style: TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
                      ],
                    ),
                  ),
              ];
            },
          ),
        ],
      ),
    );
  }
}

class _OperatorTag extends StatelessWidget {
  final String operatorName;

  const _OperatorTag({required this.operatorName});

  @override
  Widget build(BuildContext context) {
    Color dotColor = const Color(0xFF10B981); // Mobilis Green
    Widget dotWidget = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: dotColor,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    if (operatorName.toLowerCase().contains('djezzy')) {
      dotColor = const Color(0xFFE11D48); // Djezzy Red/Pink
      dotWidget = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      );
    } else if (operatorName.toLowerCase().contains('ooredoo')) {
      dotColor = const Color(0xFFEF4444); // Ooredoo Red
      dotWidget = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
        ),
      );
    }

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF070D18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dotWidget,
            const SizedBox(width: 6),
            Text(
              operatorName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
