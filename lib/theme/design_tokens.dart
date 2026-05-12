import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

enum AppThemeMode { dark, light }

/// Two complete palettes — Deep Slate (dark) and Cloud White (light).
/// Switched by `AppColors.setMode()`. Widgets that read AppColors values
/// must rebuild when mode changes (handled at the MaterialApp level via a
/// `Consumer<ThemeController>`).
class _Palette {
  final Color primary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerHighest;
  final Color onPrimary;
  final Color onSecondary;
  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outlineVariant;
  final Color error;

  const _Palette({
    required this.primary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerHighest,
    required this.onPrimary,
    required this.onSecondary,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outlineVariant,
    required this.error,
  });
}

const _dark = _Palette(
  primary: Color(0xFFC0C1FF),
  secondary: Color(0xFF7BD0FF),
  background: Color(0xFF0B1326),
  surface: Color(0xFF0B1326),
  surfaceContainer: Color(0xFF171F33),
  surfaceContainerHighest: Color(0xFF2D3449),
  onPrimary: Color(0xFF1000A9),
  onSecondary: Color(0xFF00354A),
  onBackground: Color(0xFFDAE2FD),
  onSurface: Color(0xFFDAE2FD),
  onSurfaceVariant: Color(0xFFC7C4D7),
  outlineVariant: Color(0xFF464554),
  error: Color(0xFFFFB4AB),
);

const _light = _Palette(
  primary: Color(0xFF4A4DCC),
  secondary: Color(0xFF0288D1),
  background: Color(0xFFF7F8FB),
  surface: Color(0xFFFFFFFF),
  surfaceContainer: Color(0xFFEEF1F7),
  surfaceContainerHighest: Color(0xFFE2E6F0),
  onPrimary: Color(0xFFFFFFFF),
  onSecondary: Color(0xFFFFFFFF),
  onBackground: Color(0xFF12172A),
  onSurface: Color(0xFF12172A),
  onSurfaceVariant: Color(0xFF555A6E),
  outlineVariant: Color(0xFFCBD0DD),
  error: Color(0xFFB3261E),
);

class AppColors {
  static AppThemeMode _mode = AppThemeMode.dark;
  static AppThemeMode get mode => _mode;
  static void setMode(AppThemeMode m) => _mode = m;
  static _Palette get _p => _mode == AppThemeMode.dark ? _dark : _light;

  static Color get primary => _p.primary;
  static Color get secondary => _p.secondary;
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceContainer => _p.surfaceContainer;
  static Color get surfaceContainerHighest => _p.surfaceContainerHighest;
  static Color get onPrimary => _p.onPrimary;
  static Color get onSecondary => _p.onSecondary;
  static Color get onBackground => _p.onBackground;
  static Color get onSurface => _p.onSurface;
  static Color get onSurfaceVariant => _p.onSurfaceVariant;
  static Color get outlineVariant => _p.outlineVariant;
  static Color get error => _p.error;
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

/// Persistent theme controller — broadcasts mode changes and saves to disk.
class ThemeController extends ChangeNotifier {
  static const _kFile = 'theme_mode.txt';
  AppThemeMode _mode = AppThemeMode.dark;

  AppThemeMode get mode => _mode;
  bool get isDark => _mode == AppThemeMode.dark;

  Future<void> load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/$_kFile');
      if (!await f.exists()) return;
      final raw = (await f.readAsString()).trim();
      _mode = raw == 'light' ? AppThemeMode.light : AppThemeMode.dark;
      AppColors.setMode(_mode);
      notifyListeners();
    } catch (e) {
      debugPrint('[ThemeController] load failed: $e');
    }
  }

  Future<void> setMode(AppThemeMode m) async {
    if (_mode == m) return;
    _mode = m;
    AppColors.setMode(m);
    notifyListeners();
    try {
      final dir = await getApplicationSupportDirectory();
      final f = File('${dir.path}/$_kFile');
      await f.writeAsString(jsonEncode(m.name));
    } catch (e) {
      debugPrint('[ThemeController] save failed: $e');
    }
  }

  Future<void> toggle() => setMode(isDark ? AppThemeMode.light : AppThemeMode.dark);
}
