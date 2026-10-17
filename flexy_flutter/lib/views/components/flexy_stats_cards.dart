import 'package:flutter/material.dart';
import '../../core/widgets/glass_card.dart';

class FlexyStatsCards extends StatelessWidget {
  final String totalAmount;
  final int totalTransactions;
  final int totalCredit;
  final String activeOperators;

  const FlexyStatsCards({
    super.key,
    this.totalAmount = '2,400.00 DA',
    this.totalTransactions = 11,
    this.totalCredit = 1,
    this.activeOperators = '1 / 3',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _StatCard(
            title: 'Total transferts',
            value: totalAmount,
            subtitle: 'Aujourd"hui',
            icon: Icons.near_me_rounded,
            iconColor: const Color(0xFF00E6A8),
            bgColor: const Color(0xFF00E6A8).withValues(alpha: 0.12),
          ),
          _StatCard(
            title: 'Transferts Réussis',
            value: totalTransactions.toString(),
            subtitle: 'Total',
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF818CF8),
            bgColor: const Color(0xFF818CF8).withValues(alpha: 0.12),
          ),
          _StatCard(
            title: 'À crédit',
            value: '$totalCredit ops',
            subtitle: 'En attente',
            icon: Icons.warning_amber_rounded,
            iconColor: const Color(0xFFF59E0B),
            bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.12),
          ),
          _StatCard(
            title: 'Fournisseurs',
            value: activeOperators,
            subtitle: 'Actifs',
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF38BDF8),
            bgColor: const Color(0xFF38BDF8).withValues(alpha: 0.12),
          ),
        ];

        if (constraints.maxWidth < 850) {
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
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          // Title, Value & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF8F9CAE),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Perfectly Circular Icon Container Matching Screenshot
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
