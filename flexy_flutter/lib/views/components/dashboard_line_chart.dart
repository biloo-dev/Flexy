import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/localization/app_localizations.dart';

class DashboardLineChart extends StatefulWidget {
  const DashboardLineChart({super.key});

  @override
  State<DashboardLineChart> createState() => _DashboardLineChartState();
}

class _DashboardLineChartState extends State<DashboardLineChart> {
  String _selectedPeriodCode = '7d';

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Period Selector Dropdown
          Row(
            children: [
              Text(
                context.tr('evolution_transfers'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriodCode,
                    dropdownColor: AppColors.cardHover,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary, size: 18),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPeriodCode = val);
                    },
                    items: [
                      DropdownMenuItem(value: '7d', child: Text(context.tr('7_days'))),
                      DropdownMenuItem(value: '30d', child: Text(context.tr('30_days'))),
                      DropdownMenuItem(value: '1y', child: Text(context.tr('this_year'))),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Main Trend Chart Canvas
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _MultiLineChartPainter(),
            ),
          ),

          const SizedBox(height: 16),

          // Bottom Legend: Réussis, Échoués, En Attente
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(color: AppColors.success, label: context.tr('reussis')),
              const SizedBox(width: 20),
              _LegendItem(color: AppColors.danger, label: context.tr('echoues')),
              const SizedBox(width: 20),
              _LegendItem(color: AppColors.warning, label: context.tr('en_attente')),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _MultiLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    const int gridRows = 4;
    for (int i = 0; i <= gridRows; i++) {
      final y = size.height * (i / gridRows);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line Paints
    final successPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final failedPaint = Paint()
      ..color = AppColors.danger
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final pendingPaint = Paint()
      ..color = AppColors.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Sample data points across 7 days
    final dates = ['12/06', '13/06', '14/06', '15/06', '16/06', '17/06', '18/06'];
    final successRatios = [0.45, 0.40, 0.55, 0.65, 0.85, 0.75, 0.90];
    final failedRatios = [0.10, 0.08, 0.12, 0.15, 0.10, 0.08, 0.05];
    final pendingRatios = [0.03, 0.05, 0.04, 0.06, 0.05, 0.04, 0.02];

    final successPath = Path();
    final failedPath = Path();
    final pendingPath = Path();

    for (int i = 0; i < dates.length; i++) {
      final x = size.width * (i / (dates.length - 1));
      final ySuccess = size.height * (1.0 - successRatios[i]);
      final yFailed = size.height * (1.0 - failedRatios[i]);
      final yPending = size.height * (1.0 - pendingRatios[i]);

      if (i == 0) {
        successPath.moveTo(x, ySuccess);
        failedPath.moveTo(x, yFailed);
        pendingPath.moveTo(x, yPending);
      } else {
        successPath.lineTo(x, ySuccess);
        failedPath.lineTo(x, yFailed);
        pendingPath.lineTo(x, yPending);
      }

      // Draw data point dots on success line
      canvas.drawCircle(Offset(x, ySuccess), 3.5, Paint()..color = AppColors.success);
    }

    canvas.drawPath(successPath, successPaint);
    canvas.drawPath(failedPath, failedPaint);
    canvas.drawPath(pendingPath, pendingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
