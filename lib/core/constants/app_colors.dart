import 'package:flutter/material.dart';

/// App color palette - Modern, Colorful School Fees App Theme
class AppColors {
  AppColors._();

  // Primary Color - Deep Navy (brand)
  static const Color primary = Color(0xFF002147);
  static const Color primary50 = Color(0xFFE6EAF0);
  static const Color primary100 = Color(0xFFC6D3E4);
  static const Color primary200 = Color(0xFF94A8C3);
  static const Color primary300 = Color(0xFF6280A3);
  static const Color primary400 = Color(0xFF315583);
  static const Color primary500 = Color(0xFF002147);
  static const Color primary600 = Color(0xFF001A38);
  static const Color primary700 = Color(0xFF00142B);
  static const Color primary800 = Color(0xFF000D1D);
  static const Color primary900 = Color(0xFF000610);

  // Secondary Color - Burnished Amber (action / accent)
  static const Color secondary = Color(0xFFD2913C);
  static const Color secondaryLight = Color(0xFFF3DCB5);

  // Accent Colors
  static const Color accent = Color(0xFFD2913C);
  static const Color accent2 = Color(0xFFE4EAF2);

  // Gradient Colors - Navy brand gradient (light -> navy -> deep navy)
  static const Color gradientStart = Color(0xFF3A5A8C);
  static const Color gradientMiddle = Color(0xFF002147);
  static const Color gradientEnd = Color(0xFF00132E);

  /// Navy brand gradient — primary background gradient (panels, splash, hero).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3A5A8C), Color(0xFF002147), Color(0xFF00132E)],
  );

  /// Vertical navy gradient — splash / full-screen backgrounds.
  static const LinearGradient brandGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3A5A8C), Color(0xFF002147), Color(0xFF00132E)],
  );

  /// Amber accent gradient — highlights / active states.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE5A85C), Color(0xFFD2913C), Color(0xFFA66A24)],
  );

  // Neutral/Gray Colors - Refined tones
  static const Color gray50 = Color(0xFFFAFAFC);
  static const Color gray100 = Color(0xFFF4F4F7);
  static const Color gray200 = Color(0xFFE8E8ED);
  static const Color gray300 = Color(0xFFD1D1DB);
  static const Color gray400 = Color(0xFF9E9EAF);
  static const Color gray500 = Color(0xFF6B6B80);
  static const Color gray600 = Color(0xFF4A4A5E);
  static const Color gray700 = Color(0xFF363649);
  static const Color gray800 = Color(0xFF252536);
  static const Color gray900 = Color(0xFF151523);

  // Status Colors - Vibrant tones
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFD97706);

  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF2563EB);

  // Background Colors - Soft gradients
  static const Color background = Color(0xFFF0FBF6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bgPrimary = Color(0xFFFFFFFF);
  static const Color bgSecondary = Color(0xFFF8F9FC);
  static const Color bgTertiary = Color(0xFFF0EFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textDisabled = Color(0xFFD1D5DB);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textLink = Color(0xFFB5752A); // Amber for text buttons/links

  // Border/Divider Colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderLight = Color(0xFFF3F4F6);
  static const Color divider = Color(0xFFE5E7EB);
  static const Color borderFocus = Color(0xFFD2913C); // Amber focus ring

  // Semantic Fee Status Colors
  static const Color feePaid = Color(0xFF10B981);
  static const Color feePaidBg = Color(0xFFD1FAE5);
  static const Color feePending = Color(0xFFEF4444);
  static const Color feePendingBg = Color(0xFFFEE2E2);
  static const Color feeOverdue = Color(0xFFDC2626);
  static const Color feeOverdueBg = Color(0xFFFEE2E2);
  static const Color feePartial = Color(0xFFF59E0B);
  static const Color feePartialBg = Color(0xFFFEF3C7);

  // Card Colors - Modern Pastel Palette
  static const Color cardBlue = Color(0xFFE8F4FD);
  static const Color cardBlueDark = Color(0xFF4A9FD4);

  static const Color cardPurple = Color(0xFFF0EEFF);
  static const Color cardPurpleDark = Color(0xFF8B5CF6);

  static const Color cardPink = Color(0xFFFFE8EF);
  static const Color cardPinkDark = Color(0xFFEC4899);

  static const Color cardGreen = Color(0xFFE6F9F0);
  static const Color cardGreenDark = Color(0xFF10B981);

  static const Color cardOrange = Color(0xFFFFF4E6);
  static const Color cardOrangeDark = Color(0xFFF97316);

  static const Color cardYellow = Color(0xFFFFFBE6);
  static const Color cardYellowDark = Color(0xFFEAB308);

  static const Color cardCyan = Color(0xFFE6FFFE);
  static const Color cardCyanDark = Color(0xFF06B6D4);

  static const Color cardRose = Color(0xFFFFF1F2);
  static const Color cardRoseDark = Color(0xFFFB7185);

  // Card Icon Background Colors - Vibrant pastel tones
  static const Color schoolFeesBg = Color(0xFFEDE9FE);
  static const Color schoolFeesIcon = Color(0xFF8B5CF6);

  static const Color transportBg = Color(0xFFD1FAE5);
  static const Color transportIcon = Color(0xFF10B981);

  static const Color hostelBg = Color(0xFFFFE4E6);
  static const Color hostelIcon = Color(0xFFF43F5E);

  static const Color examBg = Color(0xFFCFFAFE);
  static const Color examIcon = Color(0xFF06B6D4);

  static const Color historyBg = Color(0xFFFEF3C7);
  static const Color historyIcon = Color(0xFFF59E0B);

  static const Color supportBg = Color(0xFFE0E7FF);
  static const Color supportIcon = Color(0xFF6366F1);

  // Avatar Colors
  static const Color avatarBg = Color(0xFFD2913C); // Amber avatar background
  static const Color avatarText = Color(0xFFFFFFFF);

  // Button Colors - Amber primary action with interaction states
  static const Color buttonPrimary = Color(0xFFD2913C);
  static const Color buttonPrimaryHover = Color(0xFFB5752A);   // hover + focused
  static const Color buttonPrimaryPressed = Color(0xFFA66A24); // pressed / active
  static const Color buttonPrimaryDisabled = Color(0xFFE8C896);
  static const Color buttonSecondary = Color(0xFFFFFFFF);
  static const Color buttonSecondaryBorder = Color(0xFFE5E7EB);
  static const Color buttonDanger = Color(0xFFEF4444);
  static const Color buttonDangerBg = Color(0xFFFEF2F2);

  // Shadow Colors
  static const Color shadowLight = Color(0x0D000000);
  static const Color shadowMedium = Color(0x1A000000);
  static const Color shadowDark = Color(0x26000000);

  // Card shadow with color tint
  static const Color shadowBlue = Color(0x1A3B82F6);
  static const Color shadowPurple = Color(0x1A8B5CF6);
  static const Color shadowPink = Color(0x1AEC4899);
  static const Color shadowGreen = Color(0x1A10B981);

  // Glassmorphism effect colors
  static const Color glassWhite = Color(0xCCFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ──────────────────────────────────────────────
  // Brightness-aware colors (for dark mode support)
  // ──────────────────────────────────────────────

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// Scaffold / page background
  static Color scaffoldBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF121218) : const Color(0xFFF1F5F9);

  /// Card / container surface background
  static Color cardBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1E1E2A) : Colors.white;

  /// Primary text color
  static Color textPrimaryC(BuildContext context) =>
      _isDark(context) ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937);

  /// Secondary text color
  static Color textSecondaryC(BuildContext context) =>
      _isDark(context) ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  /// Hint / tertiary text color
  static Color textHintC(BuildContext context) =>
      _isDark(context) ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF);

  /// Border / divider color
  static Color borderC(BuildContext context) =>
      _isDark(context) ? const Color(0xFF2D2D3D) : const Color(0xFFE5E7EB);

  /// Filter tab / section inactive background
  static Color filterBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF252536) : const Color(0xFFF1F5F9);

  /// Icon button background (cart, notification buttons) — amber rounded square
  static Color iconButtonBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF374151) : const Color(0xFFD2913C);

  /// Icon button border (same as bg)
  static Color iconButtonBorder(BuildContext context) =>
      _isDark(context) ? const Color(0xFF374151) : const Color(0xFFD2913C);

  /// Icon button icon color — white on dark bg
  static const Color iconButtonColor = Color(0xFFFFFFFF);

  /// Header / app bar container background
  static Color headerBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1A26) : Colors.white;

  /// Card shadow (invisible in dark mode)
  static List<BoxShadow> cardShadow(BuildContext context) =>
      _isDark(context)
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ];
}
