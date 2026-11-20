import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_sizes.dart';

/// Semantic text styles for consistent typography
class AppTextStyles {
  AppTextStyles._();

  // App Title - 22px, w600
  static const TextStyle appTitle = TextStyle(
    fontSize: AppSizes.appTitle,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Section Title - 18px, w600
  static const TextStyle sectionTitle = TextStyle(
    fontSize: AppSizes.sectionTitle,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // Main Amount - 24px, w700
  static const TextStyle mainAmount = TextStyle(
    fontSize: AppSizes.mainAmount,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Body Text - 14px, w400
  static const TextStyle bodyText = TextStyle(
    fontSize: AppSizes.bodyText,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  // Secondary Text - 12px, w400
  static const TextStyle secondaryText = TextStyle(
    fontSize: AppSizes.secondaryText,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Button Text - 15px, w600
  static const TextStyle buttonText = TextStyle(
    fontSize: AppSizes.buttonText,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Tag Text - 12px, w600
  static const TextStyle tagText = TextStyle(
    fontSize: AppSizes.tagText,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
