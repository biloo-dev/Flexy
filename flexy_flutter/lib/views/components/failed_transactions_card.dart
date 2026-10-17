import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/localization/app_localizations.dart';

class FailedTransactionsCard extends StatelessWidget {
  final VoidCallback? onViewAll;

  const FailedTransactionsCard({
    super.key,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final failedItems = [
      {
        'operator': 'Djezzy',
        'phone': '0772512141',
        'reason': 'Solde insuffisant',
        'time': '23:37',
        'color': AppColors.djezzyRed,
      },
      {
        'operator': 'Mobilis',
        'phone': '0659812181',
        'reason': 'Numéro invalide',
        'time': '23:28',
        'color': AppColors.mobilisGreen,
      },
      {
        'operator': 'Ooredoo',
        'phone': '0555123456',
        'reason': 'Erreur réseau GSM',
        'time': '22:47',
        'color': AppColors.ooredooRed,
      },
      {
        'operator': 'Mobilis',
        'phone': '0661234567',
        'reason': 'Limite dépassée',
        'time': '22:10',
        'color': AppColors.mobilisGreen,
      },
      {
        'operator': 'Djezzy',
        'phone': '0799123456',
        'reason': 'Solde insuffisant',
        'time': '21:55',
        'color': AppColors.djezzyRed,
      },
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
                context.tr('recent_failed_ops'),
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

          // Failed Items List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: failedItems.length,
            separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 12),
            itemBuilder: (context, index) {
              final item = failedItems[index];
              return Row(
                children: [
                  // Red Cross Circle Icon
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Operator + Phone + Failure Reason
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              item['operator'] as String,
                              style: TextStyle(
                                color: item['color'] as Color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(' - ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                            Text(
                              item['phone'] as String,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['reason'] as String,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time String
                  Text(
                    item['time'] as String,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
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
}
