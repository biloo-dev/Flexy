import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/localization/app_localizations.dart';

class DashboardDonutChart extends StatelessWidget {
  final int totalCount;
  final int mobilisCount;
  final int djezzyCount;
  final int ooredooCount;

  const DashboardDonutChart({
    super.key,
    this.totalCount = 2856,
    this.mobilisCount = 1564,
    this.djezzyCount = 856,
    this.ooredooCount = 436,
  });

  @override
  Widget build(BuildContext context) {
    final double mobPct = (mobilisCount / totalCount) * 100;
    final double djzPct = (djezzyCount / totalCount) * 100;
    final double oorPct = (ooredooCount / totalCount) * 100;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Filter Dropdown
          Row(
            children: [
              Text(
                context.tr('operator_distribution'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
                  context.tr('today'),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Donut Chart + Side Legend Layout
          Row(
            children: [
              // Custom Donut Canvas with Center Text
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(140, 140),
                      painter: _DonutChartPainter(
                        mobilisPct: mobPct / 100,
                        djezzyPct: djzPct / 100,
                        ooredooPct: oorPct / 100,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                        Text(
                          totalCount.toString(),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Operator Details Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _OperatorLegendRow(
                      name: 'Mobilis',
                      count: mobilisCount,
                      pct: mobPct,
                      color: AppColors.mobilisGreen,
                    ),
                    const SizedBox(height: 14),
                    _OperatorLegendRow(
                      name: 'Djezzy',
                      count: djezzyCount,
                      pct: djzPct,
                      color: AppColors.djezzyRed,
                    ),
                    const SizedBox(height: 14),
                    _OperatorLegendRow(
                      name: 'Ooredoo',
                      count: ooredooCount,
                      pct: oorPct,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OperatorLegendRow extends StatelessWidget {
  final String name;
  final int count;
  final double pct;
  final Color color;

  const _OperatorLegendRow({
    required this.name,
    required this.count,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        Text(
          '$count (${pct.toStringAsFixed(1)}%)',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final double mobilisPct;
  final double djezzyPct;
  final double ooredooPct;

  _DonutChartPainter({
    required this.mobilisPct,
    required this.djezzyPct,
    required this.ooredooPct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 8;
    const strokeWidth = 16.0;

    final rect = Rect.fromCircle(center: center, radius: radius);
    double startAngle = -pi / 2;

    // Mobilis Arc (Green)
    final mobPaint = Paint()
      ..color = AppColors.mobilisGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    final mobSweep = 2 * pi * mobilisPct;
    canvas.drawArc(rect, startAngle, mobSweep, false, mobPaint);
    startAngle += mobSweep;

    // Djezzy Arc (Red)
    final djzPaint = Paint()
      ..color = AppColors.djezzyRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    final djzSweep = 2 * pi * djezzyPct;
    canvas.drawArc(rect, startAngle, djzSweep, false, djzPaint);
    startAngle += djzSweep;

    // Ooredoo Arc (Yellow/Orange)
    final oorPaint = Paint()
      ..color = AppColors.warning
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    final oorSweep = 2 * pi * ooredooPct;
    canvas.drawArc(rect, startAngle, oorSweep, false, oorPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
