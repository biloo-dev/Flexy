import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/localization/app_localizations.dart';

class TopSuppliersCard extends StatelessWidget {
  final VoidCallback? onViewAll;

  const TopSuppliersCard({
    super.key,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final suppliers = [
      {'name': 'Fournisseur Alpha', 'count': 45, 'amount': '450 000,00 DA', 'lastOp': '18/06/2026'},
      {'name': 'Fournisseur Beta', 'count': 32, 'amount': '320 000,00 DA', 'lastOp': '18/06/2026'},
      {'name': 'Fournisseur Gamma', 'count': 28, 'amount': '280 000,00 DA', 'lastOp': '17/06/2026'},
      {'name': 'Fournisseur Delta', 'count': 15, 'amount': '150 000,00 DA', 'lastOp': '17/06/2026'},
      {'name': 'Fournisseur Epsilon', 'count': 10, 'amount': '100 000,00 DA', 'lastOp': '16/06/2026'},
    ];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + "Voir tout" link button
          Row(
            children: [
              Text(
                context.tr('top_suppliers'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onViewAll,
                child: Text(
                  context.tr('view_all'),
                  style: const TextStyle(
                    color: AppColors.primaryTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Table Header Row
          Row(
            children: [
              Expanded(flex: 4, child: Text(context.tr('active_suppliers'), style: _hdrStyle)),
              Expanded(flex: 2, child: Text(context.tr('total_transfers'), style: _hdrStyle)),
              Expanded(flex: 3, child: Text(context.tr('amount'), style: _hdrStyle)),
              Expanded(flex: 3, child: Text(context.tr('date'), style: _hdrStyle)),
            ],
          ),

          const Divider(color: AppColors.border, height: 16),

          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: suppliers.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 12),
            itemBuilder: (context, index) {
              final s = suppliers[index];
              return Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      s['name'] as String,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      s['count'].toString(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      s['amount'] as String,
                      style: const TextStyle(
                        color: AppColors.primaryPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      s['lastOp'] as String,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static const _hdrStyle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );
}
