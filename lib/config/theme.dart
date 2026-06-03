import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_sizes.dart';
import '../core/theme/button_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        // App Title - 22px, w600
        displayLarge: TextStyle(
          fontSize: AppSizes.appTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Main Amount - 24px, w700
        displayMedium: TextStyle(
          fontSize: AppSizes.mainAmount,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        // Section Title - 18px, w600
        displaySmall: TextStyle(
          fontSize: AppSizes.sectionTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppSizes.sectionTitle,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        // Body Text - 14px, w400
        bodyLarge: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        // Secondary Text - 12px, w400
        bodySmall: TextStyle(
          fontSize: AppSizes.secondaryText,
          fontWeight: FontWeight.w400,
          color: AppColors.textTertiary,
        ),
        // Tag - 12px, w600
        labelLarge: TextStyle(
          fontSize: AppSizes.tagText,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: AppSizes.textLg,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.elevated()),
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtonStyles.outlined()),
      textButtonTheme: TextButtonThemeData(style: AppButtonStyles.text()),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s4,
          vertical: AppSizes.s4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: AppSizes.textSm,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedXl),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  // Dark mode colors
  static const Color _darkScaffold = Color(0xFF121218);
  static const Color _darkSurface = Color(0xFF1E1E2A);
  static const Color _darkCard = Color(0xFF1E1E2A);
  static const Color _darkBorder = Color(0xFF2D2D3D);
  static const Color _darkTextPrimary = Color(0xFFF3F4F6);
  static const Color _darkTextSecondary = Color(0xFFD1D5DB);
  static const Color _darkTextTertiary = Color(0xFF9CA3AF);
  static const Color _darkTextHint = Color(0xFF6B7280);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: _darkScaffold,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: _darkSurface,
        onSurface: _darkTextPrimary,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppSizes.appTitle,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: AppSizes.mainAmount,
          fontWeight: FontWeight.w700,
          color: _darkTextPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: AppSizes.sectionTitle,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: AppSizes.sectionTitle,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: AppSizes.buttonText,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w500,
          color: _darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w400,
          color: _darkTextPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: AppSizes.bodyText,
          fontWeight: FontWeight.w400,
          color: _darkTextSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: AppSizes.secondaryText,
          fontWeight: FontWeight.w400,
          color: _darkTextTertiary,
        ),
        labelLarge: TextStyle(
          fontSize: AppSizes.tagText,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _darkSurface,
        foregroundColor: _darkTextPrimary,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: AppSizes.textLg,
          fontWeight: FontWeight.w600,
          color: _darkTextPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtonStyles.elevated()),
      outlinedButtonTheme: OutlinedButtonThemeData(style: AppButtonStyles.outlined()),
      textButtonTheme: TextButtonThemeData(style: AppButtonStyles.text()),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.s4,
          vertical: AppSizes.s4,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: _darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedLg),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: const TextStyle(
          color: _darkTextHint,
          fontSize: AppSizes.textSm,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: _darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.roundedXl),
          side: const BorderSide(color: _darkBorder),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: _darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: AppSizes.textXs,
          fontWeight: FontWeight.normal,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: _darkBorder,
      ),
    );
  }
}
