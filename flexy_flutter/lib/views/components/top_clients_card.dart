import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/localization/app_localizations.dart';

class TopClientsCard extends StatelessWidget {
  final VoidCallback? onViewAll;

  const TopClientsCard({
    super.key,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final clients = [
      {'name': 'hhhh', 'count': 28, 'amount': '45 600,00 DA', 'lastOp': '18/06/2026 23:37'},
      {'name': 'bilal dev', 'count': 16, 'amount': '23 400,00 DA', 'lastOp': '18/06/2026 22:38'},
      {'name': 'Anonyme', 'count': 14, 'amount': '18 650,00 DA', 'lastOp': '18/06/2026 22:10'},
      {'name': 'mohamed', 'count': 9, 'amount': '12 200,00 DA', 'lastOp': '17/06/2026 19:22'},
      {'name': 'yassin', 'count': 7, 'amount': '9 800,00 DA', 'lastOp': '17/06/2026 18:45'},
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
                context.tr('top_active_clients'),
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
              Expanded(flex: 3, child: Text(context.tr('client'), style: _hdrStyle)),
              Expanded(flex: 2, child: Text(context.tr('total_transfers'), style: _hdrStyle)),
              Expanded(flex: 3, child: Text(context.tr('montant_total'), style: _hdrStyle)),
              Expanded(flex: 3, child: Text(context.tr('date'), style: _hdrStyle)),
            ],
          ),

          const Divider(color: AppColors.border, height: 16),

          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: clients.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 12),
            itemBuilder: (context, index) {
              final c = clients[index];
              return Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      c['name'] as String,
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
                      c['count'].toString(),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      c['amount'] as String,
                      style: const TextStyle(
                        color: AppColors.primaryTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      c['lastOp'] as String,
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
