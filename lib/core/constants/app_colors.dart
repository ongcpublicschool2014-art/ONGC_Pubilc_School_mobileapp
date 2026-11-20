import 'package:flutter/material.dart';

/// FIT School "Peacock" palette -- the same colours as the desktop app
/// (new-ongc lib/utils/app_theme.dart): deep teal primary, marigold accent,
/// warm paper surfaces, coral errors, purple info.
///
/// The token NAMES are the parent app's old ones, so every screen follows the
/// theme without being edited. Peacock has no dark mode (light only, like the
/// desktop); the context helpers at the end return the light values.
class AppColors {
  AppColors._();

  // ── Peacock core (same values as the desktop) ──────────────────────
  static const Color ink = Color(0xFF17232B); // main text, headings
  static const Color ink2 = Color(0xFF4A5A63); // labels, secondary text
  static const Color ink3 = Color(0xFF8A979D); // hints, placeholders
  static const Color paper = Color(0xFFF5F1E8); // page background
  static const Color card = Color(0xFFFFFDF8); // cards, sheets, dialogs
  static const Color sunken = Color(0xFFFBF8F0); // inset areas
  static const Color segmentBg = Color(0xFFF3EDE0); // tab / segment track
  static const Color line = Color(0xFFE6DFCF); // card borders
  static const Color line2 = Color(0xFFEFE9DC); // row dividers
  static const Color fieldBorder = Color(0xFFDDD4C1);
  static const Color primaryDark = Color(0xFF0A4D47);
  static const Color primarySoft = Color(0xFFE1F0EC);
  static const Color primaryTint = Color(0xFFF1F8F6);
  static const Color primaryLine = Color(0xFFBFDDD7);
  static const Color onPrimary = Color(0xFFFFF7E6);
  static const Color onPrimaryMuted = Color(0xFFA9D2CC);
  static const Color onPrimaryAccent = Color(0xFFFFE3B5);
  static const Color gold = Color(0xFFF0A43A); // marigold accent (never small text)
  static const Color goldDark = Color(0xFFB7701A);
  static const Color goldSoft = Color(0xFFFDF0DA);
  static const Color goldTint = Color(0xFFFFF8EA);
  static const Color goldLine = Color(0xFFEFCF96);
  static const Color goldInk = Color(0xFF7A4A0E);
  static const Color coral = Color(0xFFC8453A);
  static const Color coralBg = Color(0xFFFBE6E2);
  static const Color coralInk = Color(0xFF8E2B22);
  static const Color purple = Color(0xFF6B4FA0);
  static const Color purpleBg = Color(0xFFEEE8F7);
  static const Color blue = Color(0xFF2F7FB5);
  static const Color blueBg = Color(0xFFE3EFF8);
  static const Color sideBg = Color(0xFF0C2D2A); // dark teal (splash, hero foot)

  // ──────────────────────────────────────────────
  // 1. Primary — Peacock teal
  // ──────────────────────────────────────────────
  static const Color primary = Color(0xFF0F6B63);
  static const Color primary50 = primaryTint;
  static const Color primary100 = primarySoft;
  static const Color primary200 = primaryLine;
  static const Color primary300 = Color(0xFFA7CFC8);
  static const Color primary400 = Color(0xFF1F8C80);
  static const Color primary500 = primary;
  static const Color primary600 = primaryDark;
  static const Color primary700 = Color(0xFF083F3A);
  static const Color primary800 = sideBg;
  static const Color primary900 = Color(0xFF061C1A);

  // ──────────────────────────────────────────────
  // 2. Secondary / Accent
  // ──────────────────────────────────────────────
  // As on the desktop, `accent` is teal (used for text and edges); the bright
  // marigold accent is [gold].
  static const Color secondary = primary;
  static const Color secondaryLight = primarySoft;

  static const Color accent = primary;
  static const Color accent2 = primaryTint;

  // ──────────────────────────────────────────────
  // 3. Gradient stops + LinearGradient constants
  // ──────────────────────────────────────────────
  static const Color gradientStart = primary;
  static const Color gradientMiddle = primaryDark;
  static const Color gradientEnd = sideBg;

  // = desktop AppColors.primaryGradient
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientMiddle],
  );

  // = desktop AppColors.splashGradient
  static const LinearGradient brandGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [gradientStart, gradientMiddle, gradientEnd],
  );

  // = desktop AppColors.accentGradient (marigold)
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gold, goldDark],
  );

  // ──────────────────────────────────────────────
  // 4. Neutrals — warm Peacock greys
  // ──────────────────────────────────────────────
  static const Color gray50 = sunken;
  static const Color gray100 = segmentBg;
  static const Color gray200 = line;
  static const Color gray300 = fieldBorder;
  static const Color gray400 = ink3;
  static const Color gray500 = Color(0xFF6B7A82);
  static const Color gray600 = ink2;
  static const Color gray700 = Color(0xFF34444C);
  static const Color gray800 = Color(0xFF243239);
  static const Color gray900 = ink;

  // ──────────────────────────────────────────────
  // 5. Status
  // ──────────────────────────────────────────────
  static const Color success = primary; // paid / settled
  static const Color successLight = primarySoft;
  static const Color successDark = primaryDark;

  static const Color warning = gold; // pending
  static const Color warningLight = goldSoft;
  static const Color warningDark = goldDark;

  static const Color error = coral;
  static const Color errorLight = coralBg;
  static const Color errorDark = coralInk;

  static const Color info = blue;
  static const Color infoLight = blueBg;
  static const Color infoDark = Color(0xFF1F5F8C);

  // ──────────────────────────────────────────────
  // 6. Backgrounds & surfaces
  // ──────────────────────────────────────────────
  static const Color background = paper;
  static const Color surface = card;
  static const Color bgPrimary = card;
  static const Color bgSecondary = sunken;
  static const Color bgTertiary = primaryTint;

  // ──────────────────────────────────────────────
  // 7. Text
  // ──────────────────────────────────────────────
  static const Color textPrimary = ink;
  static const Color textSecondary = ink2;
  static const Color textTertiary = Color(0xFF6B7A82);
  static const Color textHint = ink3;
  static const Color textDisabled = fieldBorder;
  static const Color textInverse = onPrimary;
  static const Color textLink = primary;

  // ──────────────────────────────────────────────
  // 8. Borders / dividers
  // ──────────────────────────────────────────────
  static const Color border = line;
  static const Color borderLight = line2;
  static const Color divider = line2;
  static const Color borderFocus = primary;

  // ──────────────────────────────────────────────
  // Semantic Fee Status colors
  // ──────────────────────────────────────────────
  static const Color feePaid = primary;
  static const Color feePaidBg = primarySoft;
  static const Color feePending = goldDark;
  static const Color feePendingBg = goldSoft;
  static const Color feeOverdue = coral;
  static const Color feeOverdueBg = coralBg;
  static const Color feePartial = gold;
  static const Color feePartialBg = goldTint;

  // ──────────────────────────────────────────────
  // 9. Card tints (pale + strong pair), on the Peacock family
  // ──────────────────────────────────────────────
  static const Color cardBlue = blueBg;
  static const Color cardBlueDark = blue;

  static const Color cardPurple = purpleBg;
  static const Color cardPurpleDark = purple;

  static const Color cardPink = coralBg;
  static const Color cardPinkDark = coral;

  static const Color cardGreen = primarySoft;
  static const Color cardGreenDark = primary;

  static const Color cardOrange = goldSoft;
  static const Color cardOrangeDark = goldDark;

  static const Color cardYellow = goldTint;
  static const Color cardYellowDark = gold;

  static const Color cardCyan = primaryTint;
  static const Color cardCyanDark = Color(0xFF1F8C80);

  static const Color cardRose = Color(0xFFFFF8F6);
  static const Color cardRoseDark = coral;

  // Category icon tints
  static const Color schoolFeesBg = primarySoft;
  static const Color schoolFeesIcon = primary;

  static const Color transportBg = blueBg;
  static const Color transportIcon = blue;

  static const Color hostelBg = purpleBg;
  static const Color hostelIcon = purple;

  static const Color examBg = goldSoft;
  static const Color examIcon = goldDark;

  static const Color historyBg = goldSoft;
  static const Color historyIcon = goldDark;

  static const Color supportBg = purpleBg;
  static const Color supportIcon = purple;

  // ──────────────────────────────────────────────
  // 10. Avatars & buttons
  // ──────────────────────────────────────────────
  static const Color avatarBg = primarySoft;
  static const Color avatarText = primaryDark;

  static const Color buttonPrimary = primary;
  static const Color buttonPrimaryHover = primaryDark;
  static const Color buttonSecondary = card;
  static const Color buttonSecondaryBorder = fieldBorder;
  static const Color buttonDanger = coral;
  static const Color buttonDangerBg = coralBg;

  // ──────────────────────────────────────────────
  // 11. Shadows (desktop card shadow: ink at low alpha)
  // ──────────────────────────────────────────────
  static const Color shadowLight = Color(0x0817232B);
  static const Color shadowMedium = Color(0x1417232B);
  static const Color shadowDark = Color(0x2617232B);

  static const Color shadowBlue = Color(0x1A0F6B63);
  static const Color shadowPurple = Color(0x1A6B4FA0);
  static const Color shadowPink = Color(0x1AC8453A);
  static const Color shadowGreen = Color(0x1A0F6B63);

  // ──────────────────────────────────────────────
  // 12. Glassmorphism
  // ──────────────────────────────────────────────
  static const Color glassWhite = Color(0xCCFFFDF8);
  static const Color glassBorder = Color(0x33FFFDF8);

  // ──────────────────────────────────────────────
  // 13. Context helpers (kept for the screens that call them). Peacock is
  // light only, so these return the light values.
  // ──────────────────────────────────────────────
  static Color scaffoldBg(BuildContext context) => paper;
  static Color cardBg(BuildContext context) => card;
  static Color textPrimaryC(BuildContext context) => ink;
  static Color textSecondaryC(BuildContext context) => ink2;
  static Color textHintC(BuildContext context) => ink3;
  static Color borderC(BuildContext context) => line;
  static Color filterBg(BuildContext context) => segmentBg;

  /// Icon button (cart, notifications): teal tile with a cream icon.
  static Color iconButtonBg(BuildContext context) => primary;
  static Color iconButtonBorder(BuildContext context) => primary;
  static const Color iconButtonColor = onPrimary;

  static Color headerBg(BuildContext context) => card;

  /// The desktop card shadow: a 1px hairline plus a soft long drop.
  static List<BoxShadow> cardShadow(BuildContext context) => const [
        BoxShadow(color: Color.fromRGBO(23, 35, 43, 0.03), offset: Offset(0, 1)),
        BoxShadow(
            color: Color.fromRGBO(23, 35, 43, 0.35),
            offset: Offset(0, 12),
            blurRadius: 28,
            spreadRadius: -22),
      ];
}
