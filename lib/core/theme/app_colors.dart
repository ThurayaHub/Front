import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF000666);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFD4AF37);
  static const Color onSecondary = Color(0xFF1C1B1B);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFFCF9F8);
  static const Color panel = Color(0xFFF6F3F2);
  static const Color panelBorder = Color(0xFFE5E2E1);
  static const Color textPrimary = Color(0xFF1C1B1B);
  static const Color textSecondary = Color(0xFF454652);
  static const Color textMuted = Color(0xFF767683);
  static const Color inputHint = Color(0xFFC6C5D4);
  static const Color outline = Color(0xFFD4AF37);
  static const Color hot = Color(0xFF93000A);
  static const Color shadow = Color(0xFF1A237E);
  static const Color award = Color(0xFF1A237E);
  static const Color awardStar = Color(0xFFFED65B);
  static const Color error = hot;
  static const Color onError = Color(0xFFFFFFFF);

  static const ColorScheme lightScheme = ColorScheme.light(
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    surface: surface,
    onSurface: textPrimary,
    error: error,
    onError: onError,
    outline: outline,
  );
}
