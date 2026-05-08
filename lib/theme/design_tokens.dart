import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF1A73E8); // Google Blue
  static const Color secondary = Color(0xFF5F6368); // Grey
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onSecondary = Colors.white;
  static const Color onBackground = Color(0xFF202124);
  static const Color onSurface = Color(0xFF202124);
}

class AppTypography {
  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.onBackground,
  );

  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.secondary,
  );
}
