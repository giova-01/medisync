import 'package:flutter/material.dart';
import 'app_colors.dart';

// All sizes >= 18sp to meet elderly-user usability requirements.
abstract final class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
    height: 1.3,
  );

  static const heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.onBackground,
    height: 1.3,
  );

  static const heading3 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
    height: 1.3,
  );

  static const body = TextStyle(
    fontSize: 18,
    color: AppColors.onBackground,
    height: 1.5,
  );

  static const bodySecondary = TextStyle(
    fontSize: 18,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static const label = TextStyle(
    fontSize: 16,
    color: AppColors.onSurface,
    fontWeight: FontWeight.w500,
  );

  static const hint = TextStyle(
    fontSize: 16,
    color: AppColors.textHint,
  );

  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.5,
  );

  static const caption = TextStyle(
    fontSize: 14,
    color: AppColors.textHint,
  );

  static const error = TextStyle(
    fontSize: 14,
    color: AppColors.error,
  );
}
