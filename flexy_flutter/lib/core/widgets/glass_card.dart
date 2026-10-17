import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool hasGlow;
  final Color? glowColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.borderRadius = 18.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.hasGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.card;
    final effectiveBorder = borderColor ?? AppColors.border;
    final effectiveGlow = glowColor ?? AppColors.primaryTeal.withValues(alpha: 0.15);

    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: effectiveBorder,
          width: borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          if (hasGlow)
            BoxShadow(
              color: effectiveGlow,
              blurRadius: 20,
              spreadRadius: -2,
            ),
        ],
      ),
      child: child,
    );
  }
}
