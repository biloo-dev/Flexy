import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/app_localizations.dart';
import '../providers/flexy_provider.dart';
import 'components/dashboard_kpi_card.dart';
import 'components/dashboard_line_chart.dart';
import 'components/dashboard_donut_chart.dart';
import 'components/dashboard_bar_chart.dart';
import 'components/failed_transactions_card.dart';
import 'components/top_clients_card.dart';
import 'components/top_suppliers_card.dart';

class DashboardView extends StatefulWidget {
  final Function(int)? onNavigateToTab;

  const DashboardView({
    super.key,
    this.onNavigateToTab,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FlexyProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final flexyProvider = Provider.of<FlexyProvider>(context);

    // Compute dynamic values from DB if available
    final totalTransfersCount = flexyProvider.rawHistoriqueList.isNotEmpty
        ? flexyProvider.rawHistoriqueList.length
        : 2856;

    final successfulTransfersCount = flexyProvider.rawHistoriqueList.isNotEmpty
        ? flexyProvider.rawHistoriqueList.where((h) => h.status).length
        : 2642;

    final failedTransfersCount = flexyProvider.rawHistoriqueList.isNotEmpty
        ? flexyProvider.rawHistoriqueList.where((h) => !h.status).length
        : 214;

    final totalAmountSum = flexyProvider.rawHistoriqueList.isNotEmpty
        ? flexyProvider.todayTotalRevenue
        : 1285400.0;

    final totalClientsCount = flexyProvider.clientList.isNotEmpty
        ? flexyProvider.clientList.length
        : 1245;

    final debtClientsCount = flexyProvider.clientList.isNotEmpty
        ? flexyProvider.clientList.where((c) => c.credit > 0).length
        : 84;

    final totalDebtAmount = flexyProvider.clientList.isNotEmpty
        ? flexyProvider.totalClientCredit
        : 56780.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Header Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('dashboard'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('page_subtitle'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // Row 1: Core Transaction KPIs (5 Cards Grid)
            LayoutBuilder(
              builder: (context, constraints) {
                final kpisRow1 = [
                  DashboardKpiCard(
                    title: context.tr('total_transfers'),
                    value: totalTransfersCount.toString(),
                    subtitle: '+18.2% ${context.tr("vs_yesterday")}',
                    icon: Icons.swap_horiz_rounded,
                    iconColor: AppColors.primaryTeal,
                  ),
                  DashboardKpiCard(
                    title: context.tr('successful_transfers'),
                    value: successfulTransfersCount.toString(),
                    subtitle: '92.5% ${context.tr("of_total")}',
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.success,
                  ),
                  DashboardKpiCard(
                    title: context.tr('failed_transfers'),
                    value: failedTransfersCount.toString(),
                    subtitle: '7.5% ${context.tr("of_total")}',
                    icon: Icons.highlight_off_rounded,
                    iconColor: AppColors.danger,
                    onTap: () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(1); // Navigate to Flexy View
                      }
                    },
                  ),
                  DashboardKpiCard(
                    title: context.tr('pending_transfers'),
                    value: '35',
                    subtitle: '1.2% ${context.tr("of_total")}',
                    icon: Icons.schedule_rounded,
                    iconColor: AppColors.warning,
                  ),
                  DashboardKpiCard(
                    title: context.tr('montant_total'),
                    value: '${totalAmountSum.toStringAsFixed(2)} DA',
                    subtitle: '+24.7% ${context.tr("vs_yesterday")}',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.primaryPurple,
                  ),
                ];

                return _buildResponsiveGrid(constraints, kpisRow1);
              },
            ),

            const SizedBox(height: 14),

            // Row 2: Clients, Debts, Suppliers KPIs (5 Cards Grid)
            LayoutBuilder(
              builder: (context, constraints) {
                final kpisRow2 = [
                  DashboardKpiCard(
                    title: context.tr('total_clients'),
                    value: totalClientsCount.toString(),
                    subtitle: '+45 ${context.tr("this_month")}',
                    icon: Icons.people_outline_rounded,
                    iconColor: AppColors.primaryBlue,
                  ),
                  DashboardKpiCard(
                    title: context.tr('active_clients_today'),
                    value: '372',
                    subtitle: '29.9% ${context.tr("of_total")}',
                    icon: Icons.person_pin_circle_outlined,
                    iconColor: AppColors.secondaryCyan,
                  ),
                  DashboardKpiCard(
                    title: context.tr('debt_clients'),
                    value: debtClientsCount.toString(),
                    subtitle: '-5 ${context.tr("this_month")}',
                    icon: Icons.credit_card_off_outlined,
                    iconColor: AppColors.warning,
                    onTap: () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(2); // Navigate to Clients & Debts
                      }
                    },
                  ),
                  DashboardKpiCard(
                    title: context.tr('debt_amount'),
                    value: '${totalDebtAmount.toStringAsFixed(2)} DA',
                    subtitle: '-8.3% ${context.tr("this_month")}',
                    icon: Icons.attach_money_rounded,
                    iconColor: AppColors.danger,
                    onTap: () {
                      if (widget.onNavigateToTab != null) {
                        widget.onNavigateToTab!(2); // Navigate to Clients & Debts
                      }
                    },
                  ),
                  DashboardKpiCard(
                    title: context.tr('active_suppliers'),
                    value: '12',
                    subtitle: context.tr('active_label'),
                    icon: Icons.local_shipping_outlined,
                    iconColor: AppColors.primaryPurple,
                  ),
                ];

                return _buildResponsiveGrid(constraints, kpisRow2);
              },
            ),

            const SizedBox(height: 22),

            // Row 3: Charts & Failed Transactions (3 Cards Layout)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1250) {
                  return const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 4, child: DashboardLineChart()),
                      SizedBox(width: 16),
                      Expanded(flex: 3, child: DashboardDonutChart()),
                      SizedBox(width: 16),
                      Expanded(flex: 3, child: FailedTransactionsCard()),
                    ],
                  );
                }

                return const Column(
                  children: [
                    DashboardLineChart(),
                    SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: DashboardDonutChart()),
                        SizedBox(width: 16),
                        Expanded(child: FailedTransactionsCard()),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 22),

            // Row 4: Top Clients, Top Fournisseurs, Daily Inflow Bar Chart (3 Cards Layout)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 1250) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: TopClientsCard(
                          onViewAll: () {
                            if (widget.onNavigateToTab != null) widget.onNavigateToTab!(2);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(flex: 3, child: TopSuppliersCard()),
                      const SizedBox(width: 16),
                      const Expanded(flex: 3, child: DashboardBarChart()),
                    ],
                  );
                }

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TopClientsCard(
                            onViewAll: () {
                              if (widget.onNavigateToTab != null) widget.onNavigateToTab!(2);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(child: TopSuppliersCard()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const DashboardBarChart(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(BoxConstraints constraints, List<Widget> cards) {
    if (constraints.maxWidth > 1150) {
      return Row(
        children: cards
            .map(
              (card) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: card,
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: cards
          .map(
            (card) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: card,
            ),
          )
          .toList(),
    );
  }
}
