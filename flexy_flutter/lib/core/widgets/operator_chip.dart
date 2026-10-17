import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OperatorChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const OperatorChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color activeBg = AppColors.primaryTeal;
    Color activeTextColor = Colors.black;
    Color iconColor = AppColors.textSecondary;

    if (label == 'Djezzy') {
      iconColor = AppColors.djezzyRed;
      if (isSelected) {
        activeBg = AppColors.djezzyRed;
        activeTextColor = Colors.white;
      }
    } else if (label == 'Mobilis') {
      iconColor = AppColors.mobilisGreen;
      if (isSelected) {
        activeBg = AppColors.mobilisGreen;
        activeTextColor = Colors.white;
      }
    } else if (label == 'Ooredoo') {
      iconColor = AppColors.ooredooRed;
      if (isSelected) {
        activeBg = AppColors.ooredooRed;
        activeTextColor = Colors.white;
      }
    } else {
      // Tous
      iconColor = AppColors.primaryTeal;
      if (isSelected) {
        activeBg = AppColors.primaryTeal;
        activeTextColor = Colors.black;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? activeBg : AppColors.border,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeBg.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  label == 'Tous' ? Icons.apps_rounded : Icons.sim_card_rounded,
                  size: 16,
                  color: isSelected ? activeTextColor : iconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? activeTextColor : AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
