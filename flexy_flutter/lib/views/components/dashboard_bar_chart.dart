import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/localization/app_localizations.dart';

class DashboardBarChart extends StatelessWidget {
  final String totalInflow;

  const DashboardBarChart({
    super.key,
    this.totalInflow = '1 300 000,00 DA',
  });

  @override
  Widget build(BuildContext context) {
    final dailyData = [
      {'day': '12/06', 'val': 180000.0},
      {'day': '13/06', 'val': 240000.0},
      {'day': '14/06', 'val': 310000.0},
      {'day': '15/06', 'val': 290000.0},
      {'day': '16/06', 'val': 350000.0},
      {'day': '17/06', 'val': 380000.0},
      {'day': '18/06', 'val': 260000.0},
    ];

    const double maxVal = 400000.0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Title + Filter Dropdown
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('daily_flexy_inflow'),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$totalInflow ${context.tr("total_entered")}',
                    style: const TextStyle(
                      color: AppColors.primaryTeal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  context.tr('7_days'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Bar Chart Canvas Height
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: dailyData.map((item) {
                final double val = item['val'] as double;
                final String day = item['day'] as String;
                final double heightFactor = val / maxVal;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Glowing Teal Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 22,
                      height: 100 * heightFactor,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primaryTealDark,
                            AppColors.primaryTeal,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryTeal.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      day,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
