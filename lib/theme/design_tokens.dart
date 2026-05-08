import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFFC0C1FF); // CloudFlow Indigo
  static const Color secondary = Color(0xFF7BD0FF); // Sky
  static const Color background = Color(0xFF0B1326);
  static const Color surface = Color(0xFF0B1326);
  static const Color surfaceContainer = Color(0xFF171F33);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);
  static const Color onPrimary = Color(0xFF1000A9);
  static const Color onSecondary = Color(0xFF00354A);
  static const Color onBackground = Color(0xFFDAE2FD);
  static const Color onSurface = Color(0xFFDAE2FD);
  static const Color onSurfaceVariant = Color(0xFFC7C4D7);
  static const Color error = Color(0xFFFFB4AB);
}

class AppTypography {
  static TextStyle get display => GoogleFonts.geist(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.02,
        color: AppColors.onSurface,
      );

  static TextStyle get h1 => GoogleFonts.geist(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: AppColors.onSurface,
      );

  static TextStyle get h2 => GoogleFonts.geist(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyLg => GoogleFonts.geist(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: AppColors.onSurface,
      );

  static TextStyle get bodyMd => GoogleFonts.geist(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurface,
      );

  static TextStyle get code => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: AppColors.onSurfaceVariant,
      );

  static TextStyle get labelCaps => GoogleFonts.geist(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 0.05,
        color: AppColors.onSurfaceVariant,
      );
}
