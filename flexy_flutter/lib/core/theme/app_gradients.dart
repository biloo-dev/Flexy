import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppGradients {
  static const LinearGradient primaryButton = LinearGradient(
    colors: [
      AppColors.primaryPurple,
      AppColors.primaryTeal,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient activeSidebar = LinearGradient(
    colors: [
      AppColors.primaryTealDark,
      Color(0xFF087D74),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient brandLogo = LinearGradient(
    colors: [
      AppColors.primaryTeal,
      AppColors.primaryPurple,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardBorder = LinearGradient(
    colors: [
      Color(0xFF2E3E61),
      Color(0xFF14203D),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient promoCardBg = LinearGradient(
    colors: [
      Color(0xFF181B38),
      Color(0xFF0E1428),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
