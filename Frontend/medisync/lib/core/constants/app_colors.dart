import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF2E5090);
  static const primaryDark = Color(0xFF1E3A6E);
  static const primaryLight = Color(0xFF4A6DB5);
  static const secondary = Color(0xFF4CAF50);
  static const secondaryDark = Color(0xFF388E3C);

  static const error = Color(0xFFD32F2F);
  static const warning = Color(0xFFF57C00);
  static const success = Color(0xFF388E3C);

  static const background = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF5F5F5);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onBackground = Color(0xFF212121);
  static const onSurface = Color(0xFF424242);
  static const textHint = Color(0xFF757575);
  static const divider = Color(0xFFE0E0E0);

  // Vital signs thresholds
  static const vitalsNormal = Color(0xFF4CAF50);
  static const vitalsWarning = Color(0xFFF57C00);
  static const vitalsCritical = Color(0xFFD32F2F);
}
