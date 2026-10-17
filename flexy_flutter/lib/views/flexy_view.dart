import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/widgets/operator_chip.dart';
import '../models/client_model.dart';
import '../models/historique_model.dart';
import '../providers/flexy_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/gsm_provider.dart';
import '../providers/license_provider.dart';
import '../services/gsm_service.dart';
import '../core/localization/app_localizations.dart';
import 'components/flexy_transfer_card.dart';
import 'components/flexy_table_card.dart';
import 'components/flexy_clients_card.dart';
import 'components/flexy_stats_cards.dart';

class FlexyView extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const FlexyView({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<FlexyView> createState() => _FlexyViewState();
}

class _FlexyViewState extends State<FlexyView> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController(text: '100');
  final _searchController = TextEditingController();
  late FocusNode _phoneFocusNode;

  String _selectedOperatorFilter = 'Tous';
  int _selectedSubTab = 0; // 0: Historique & Recharge, 1: Clients & Dettes
  bool _isCredit = false;
  String? _selectedClient;
  String? _currentGhostSuggestion;
  bool _isUpdatingPhone = false;

  // Fallback demo data matching the reference design image with both Envoyés (type: true) and Reçus (type: false)
  final List<HistoriqueModel> _mockTransactions = [
    HistoriqueModel(
      operateur: 2,
      numero: '0659812181',
      clientName: 'hhhh',
      somme: 100.0,
      type: true,
      credit: false,
      createdAt: DateTime(2026, 6, 18, 23, 37, 45),
    ),
    HistoriqueModel(
      operateur: 1,
      numero: '0772512141',
      clientName: 'hhhh',
      somme: 100.0,
      type: true,
      credit: false,
      createdAt: DateTime(2026, 6, 18, 23, 29, 1),
    ),
    HistoriqueModel(
      operateur: 2,
      numero: '0659812181',
      clientName: 'hhhh',
      somme: 200.0,
      type: true,
      credit: false,
      createdAt: DateTime(2026, 6, 18, 22, 47, 55),
    ),
    HistoriqueModel(
      operateur: 2,
      numero: '0655665151',
      clientName: 'Anonyme',
      somme: 200.0,
      type: true,
      credit: false,
      createdAt: DateTime(2026, 6, 18, 22, 38, 56),
    ),
    HistoriqueModel(
      operateur: 2,
      numero: '0659812181',
      clientName: 'bilal dev',
      somme: 1000.0,
      type: true,
      credit: true,
      createdAt: DateTime(2026, 6, 18, 22, 38, 12),
    ),
  ];

  @override
  void initState() {
    super.initState();

    _phoneFocusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.tab ||
              event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (_currentGhostSuggestion != null && _currentGhostSuggestion!.isNotEmpty) {
              _acceptGhostSuggestion();
              return KeyEventResult.handled;
            }
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            setState(() {
              _currentGhostSuggestion = null;
            });
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
    );

    _phoneController.addListener(_onPhoneChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flexyProvider = Provider.of<FlexyProvider>(context, listen: false);
      flexyProvider.loadData();
    });
  }

  void _onPhoneChanged() {
    if (_isUpdatingPhone) return;

    final query = _phoneController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _currentGhostSuggestion = null;
        _selectedClient = 'Sélectionner un client';
      });
      return;
    }

    final flexyProvider = Provider.of<FlexyProvider>(context, listen: false);
    final allHist = flexyProvider.historiqueList.isNotEmpty
        ? flexyProvider.historiqueList
        : _mockTransactions;

    final cleanQuery = query.replaceAll(RegExp(r'\s+'), '');

    // 1. Search candidate ghost suggestions from history
    String? match;
    for (final item in allHist) {
      final pClean = item.phone.replaceAll(RegExp(r'\s+'), '');
      if (pClean.startsWith(cleanQuery) && pClean.length > cleanQuery.length) {
        match = item.phone;
        break;
      }
    }

    // 2. Bidirectional Check: Check if entered phone number belongs to any registered client
    String? matchedClientName;
    for (final client in flexyProvider.clientList) {
      final hasPhone = client.numeroPhoneList.any((p) {
        final pClean = p.replaceAll(RegExp(r'\s+'), '');
        return pClean == cleanQuery;
      });
      if (hasPhone) {
        matchedClientName = client.nomPrenom;
        break;
      }
    }

    setState(() {
      _currentGhostSuggestion = match;
      if (matchedClientName != null) {
        _selectedClient = matchedClientName;
      } else {
        _selectedClient = 'Sélectionner un client';
      }
    });
  }

  void _acceptGhostSuggestion() {
    if (_currentGhostSuggestion != null) {
      final fullNumber = _currentGhostSuggestion!;
      _phoneController.text = fullNumber;
      _phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: fullNumber.length),
      );
      setState(() {
        _currentGhostSuggestion = null;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _phoneController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  /// Show mandatory add-client dialog for Credit (Dette) transfers
  Future<bool?> _showMustAddClientForCreditDialog(BuildContext context, String phone, double amount) {
    final nameController = TextEditingController();
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.border),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
              SizedBox(width: 10),
              Text(
                'الكريدي مخصص للزبائن فقط',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الرقم ($phone) غير مسجل في قائمة الزبائن. لا يمكن إرسال فليكسي بالدين بدون تسجيل الزبون.\nيرجى إدخال اسم ولقب الزبون لإضافته وتأكيد الدين ومتابعة الإرسال:',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'اسم ولقب الزبون (Nom & Prénom)',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.primaryTeal),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('إلغاء الإرسال (Annuler)', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                final flexyProvider = Provider.of<FlexyProvider>(context, listen: false);
                final newClient = ClientModel(
                  nomPrenom: name,
                  numeroPhoneList: [phone],
                  credit: 0.0,
                );
                await flexyProvider.saveClient(newClient);
                setState(() {
                  _selectedClient = name;
                });
                if (context.mounted) Navigator.pop(dialogCtx, true);
              },
              child: const Text('إضافة ومتابعة الإرسال ⚡', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleSendTransfer() async {
    final phone = _phoneController.text.trim();
    final amountText = _amountController.text.trim();

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro de téléphone doit contenir exactement 10 chiffres.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un montant valide.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final flexyProvider = Provider.of<FlexyProvider>(context, listen: false);

    // 1. If sending on Credit (Dette), enforce that the phone belongs to a registered client
    if (_isCredit) {
      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
      final existingClient = flexyProvider.clientList.firstWhere(
        (c) => c.numeroPhoneList.any((p) => p.replaceAll(RegExp(r'\s+'), '') == cleanPhone),
        orElse: () => ClientModel(nomPrenom: '', numeroPhoneList: []),
      );

      if (existingClient.id == null &&
          (_selectedClient == null ||
              _selectedClient == 'Sélectionner un client' ||
              _selectedClient == 'بدون اسم')) {
        final bool? added = await _showMustAddClientForCreditDialog(context, phone, amount);
        if (added != true || !mounted) {
          return; // User cancelled registration -> abort transfer!
        }
      }
    }

    if (!mounted) return;

    // 2. Show persistent loading SnackBar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(days: 1), // Stays active until process finishes
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${context.tr("sending_transfer")} ($amount DA ➔ $phone)',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primaryTeal,
      ),
    );

    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final licenseProvider = Provider.of<LicenseProvider>(context, listen: false);

    final operatorId = GsmService.instance.detectOperator(phone);

    // 3. Check SIM License Activation Status
    final isLicensed = licenseProvider.isSimActivated[operatorId] ?? false;
    if (!isLicensed) {
      final opName = licenseProvider.getOperatorName(operatorId);
      final statusLabel = licenseProvider.simStatusLabels[operatorId] ?? 'غير مفعلة';
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.danger,
          content: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '⛔ لا يمكن إرسال الفليكسي: شريحة متعامل $opName ($statusLabel). يرجى تفعيل الشريحة أولاً من شاشة تفعيل الشرائح.',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final settings = settingsProvider.getSettingsByOperator(operatorId);

    // 4. Perform async transfer
    final bool success = await flexyProvider.sendFlexy(
      phoneNumber: phone,
      price: amount,
      settings: settings,
      userId: authProvider.currentUser?.id,
      userFullname: authProvider.currentUser?.fullName,
      isCredit: _isCredit,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // 5. Show result SnackBar (Green on success, Red on failure)
    if (success) {
      _phoneController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.success,
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Transfert de $amount DA vers $phone effectué avec succès !',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      final errorMsg = flexyProvider.lastResponse ?? 'Erreur lors de l’exécution du transfert.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          backgroundColor: AppColors.danger,
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Échec du transfert : $errorMsg',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _handleRetryTransfer(HistoriqueModel tx) {
    _isUpdatingPhone = true;
    _phoneController.text = tx.phone;
    _amountController.text = tx.montant.toStringAsFixed(0);
    _isCredit = tx.isCredit;
    _selectedClient = tx.clientName ?? 'Sélectionner un client';
    _isUpdatingPhone = false;

    setState(() {
      _selectedSubTab = 0; // Return to recharge view
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم استرجاع بيانات العملية (${tx.phone} - ${tx.montant.toInt()} DA). راجع البيانات ثم اضغط إرسال.'),
        backgroundColor: AppColors.primaryTeal,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flexyProvider = Provider.of<FlexyProvider>(context);

    // Dynamic client list from DB
    final dynamicClientList = [
      'Sélectionner un client',
      ...flexyProvider.clientList.map((c) => c.nomPrenom).where((n) => n.isNotEmpty).toSet()
    ];

    // Combine provider transactions or fallback to mock data
    final transactionsList = flexyProvider.historiqueList.isNotEmpty
        ? flexyProvider.historiqueList
        : _mockTransactions;

    // Compute metrics
    final double totalAmountSent = transactionsList
        .where((item) => item.type && item.status)
        .fold(0.0, (sum, item) => sum + item.somme);
    final int creditCount = flexyProvider.clientList.isNotEmpty
        ? flexyProvider.clientList.where((c) => c.credit > 0).length
        : transactionsList.where((item) => item.credit).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Action Filters & Sub-Tabs Bar Row (Responsive LayoutBuilder)
            LayoutBuilder(
              builder: (context, constraints) {
                final chipsWidget = SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: ['Tous', 'Djezzy', 'Mobilis', 'Ooredoo'].map((operator) {
                      return OperatorChip(
                        label: operator,
                        isSelected: _selectedOperatorFilter == operator,
                        onTap: () {
                          setState(() {
                            _selectedOperatorFilter = operator;
                            _selectedSubTab = 0; // Automatically switch back to Flexy / Recharge!
                          });
                        },
                      );
                    }).toList(),
                  ),
                );

                final subTabsWidget = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SubTabItem(
                      title: context.tr('flexy_recharge'),
                      isActive: _selectedSubTab == 0,
                      onTap: () => setState(() => _selectedSubTab = 0),
                    ),
                    const SizedBox(width: 20),
                    _SubTabItem(
                      title: context.tr('clients_debts'),
                      isActive: _selectedSubTab == 1,
                      onTap: () => setState(() => _selectedSubTab = 1),
                    ),
                  ],
                );

                if (constraints.maxWidth < 780) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      chipsWidget,
                      const SizedBox(height: 14),
                      subTabsWidget,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: chipsWidget),
                    const SizedBox(width: 16),
                    subTabsWidget,
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            // Main Two Cards Responsive Layout: Transfer Card + Table Card / Clients Card
            LayoutBuilder(
              builder: (context, constraints) {
                final tableOrClientsCard = _selectedSubTab == 0
                    ? FlexyTableCard(
                        transactions: transactionsList,
                        selectedOperatorFilter: _selectedOperatorFilter,
                        searchController: _searchController,
                        phoneFilter: _phoneController.text.trim(),
                        onRetry: _handleRetryTransfer,
                      )
                    : FlexyClientsCard(
                        searchController: _searchController,
                      );

                final gsmProvider = Provider.of<GsmProvider>(context);
                final int connectedOpsCount = gsmProvider.connectedStatus.values.where((c) => c).length;

                final statsCardsWidget = FlexyStatsCards(
                  totalAmount: '${totalAmountSent.toStringAsFixed(2)} DA',
                  totalTransactions: transactionsList.length,
                  totalCredit: creditCount,
                  activeOperators: '$connectedOpsCount / 3',
                );

                // Right panel contains the Table/Clients Card at top and Stats Cards pinned directly below it!
                final rightPanelContent = Column(
                  children: [
                    tableOrClientsCard,
                    const SizedBox(height: 16),
                    statsCardsWidget,
                  ],
                );

                if (constraints.maxWidth > 1150) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 410,
                        child: FlexyTransferCard(
                          phoneController: _phoneController,
                          amountController: _amountController,
                          phoneFocusNode: _phoneFocusNode,
                          ghostSuggestion: _currentGhostSuggestion,
                          onAcceptGhost: _acceptGhostSuggestion,
                          isCredit: _isCredit,
                          onCreditChanged: (val) => setState(() => _isCredit = val),
                          onSendTransfer: _handleSendTransfer,
                          selectedClient: _selectedClient,
                          clientList: dynamicClientList,
                          onClientSelected: (val) {
                            setState(() {
                              _selectedClient = val;
                            });
                            if (val != null && val != 'Sélectionner un client' && val != 'بدون اسم') {
                              final client = flexyProvider.clientList.firstWhere(
                                (c) => c.nomPrenom == val,
                                orElse: () => ClientModel(nomPrenom: '', numeroPhoneList: []),
                              );
                              if (client.numeroPhoneList.isNotEmpty) {
                                _isUpdatingPhone = true;
                                _phoneController.text = client.numeroPhoneList.first;
                                _isUpdatingPhone = false;
                                setState(() {
                                  _currentGhostSuggestion = null;
                                });
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: rightPanelContent,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    FlexyTransferCard(
                      phoneController: _phoneController,
                      amountController: _amountController,
                      phoneFocusNode: _phoneFocusNode,
                      ghostSuggestion: _currentGhostSuggestion,
                      onAcceptGhost: _acceptGhostSuggestion,
                      isCredit: _isCredit,
                      onCreditChanged: (val) => setState(() => _isCredit = val),
                      onSendTransfer: _handleSendTransfer,
                      selectedClient: _selectedClient,
                      clientList: dynamicClientList,
                      onClientSelected: (val) {
                        setState(() {
                          _selectedClient = val;
                        });
                        if (val != null && val != 'Sélectionner un client' && val != 'بدون اسم') {
                          final client = flexyProvider.clientList.firstWhere(
                            (c) => c.nomPrenom == val,
                            orElse: () => ClientModel(nomPrenom: '', numeroPhoneList: []),
                          );
                          if (client.numeroPhoneList.isNotEmpty) {
                            _isUpdatingPhone = true;
                            _phoneController.text = client.numeroPhoneList.first;
                            _isUpdatingPhone = false;
                            setState(() {
                              _currentGhostSuggestion = null;
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    rightPanelContent,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SubTabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  final VoidCallback onTap;

  const _SubTabItem({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 3,
            width: isActive ? 140 : 0,
            decoration: BoxDecoration(
              color: AppColors.primaryTeal,
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.primaryTeal.withValues(alpha: 0.6),
                        blurRadius: 8,
                      )
                    ]
                  : [],
            ),
          ),
        ],
      ),
    );
  }
}
