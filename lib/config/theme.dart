import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_ui.dart';

/// The FIT School desktop "Peacock" theme, sized for a phone.
///
/// Same colours, fonts, radii and component styles as the desktop app
/// (new-ongc lib/utils/app_theme.dart): teal buttons with cream text and a
/// marigold focus ring, cream cards (radius 14) with a hairline border, 10px
/// controls, Plus Jakarta Sans body text. Light only -- Peacock has no dark
/// mode, so [darkTheme] is the same theme.
class AppTheme {
  AppTheme._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle _m(double size, FontWeight w, Color c, {double? ls}) =>
      GoogleFonts.plusJakartaSans(fontSize: size, fontWeight: w, color: c, letterSpacing: ls, fontFeatures: _tabular);

  static WidgetStateProperty<BorderSide?> _focusSide(BorderSide rest) =>
      WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.gold, width: 2);
        }
        return rest;
      });

  static final ButtonStyle _solid = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.onPrimary,
    disabledBackgroundColor: AppColors.line,
    disabledForegroundColor: AppColors.ink3,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    minimumSize: const Size(0, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.controlRadius)),
    textStyle: _m(15, FontWeight.w700, AppColors.onPrimary),
  ).copyWith(side: _focusSide(BorderSide.none));

  static final ButtonStyle _outline = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primaryDark,
    backgroundColor: AppColors.card,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    minimumSize: const Size(0, 48),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.controlRadius)),
    textStyle: _m(15, FontWeight.w700, AppColors.primaryDark),
  ).copyWith(side: _focusSide(const BorderSide(color: AppColors.fieldBorder, width: 1)));

  static final ButtonStyle _text = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.controlRadius)),
    textStyle: _m(14, FontWeight.w700, AppColors.primary),
  ).copyWith(side: _focusSide(BorderSide.none));

  static OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppUi.controlRadius),
        borderSide: BorderSide(color: c, width: w),
      );

  static ThemeData get lightTheme {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    TextStyle t(TextStyle? b, double size, FontWeight w, Color c, {double? ls}) =>
        (b ?? const TextStyle()).merge(_m(size, w, c, ls: ls));
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.card,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.gold,
        onSecondary: AppColors.goldInk,
        surface: AppColors.card,
        onSurface: AppColors.ink,
        error: AppColors.error,
      ),
      fontFamily: AppFonts.bodyFamily,
      textTheme: base.copyWith(
        displayLarge: t(base.displayLarge, 22, FontWeight.w700, AppColors.ink),
        displayMedium: t(base.displayMedium, 24, FontWeight.w700, AppColors.ink),
        displaySmall: t(base.displaySmall, 18, FontWeight.w700, AppColors.ink),
        headlineLarge: t(base.headlineLarge, 22, FontWeight.w700, AppColors.ink),
        headlineMedium: t(base.headlineMedium, 18, FontWeight.w700, AppColors.ink),
        headlineSmall: t(base.headlineSmall, 16, FontWeight.w700, AppColors.ink),
        titleLarge: t(base.titleLarge, 16, FontWeight.w700, AppColors.ink),
        titleMedium: t(base.titleMedium, 14, FontWeight.w600, AppColors.ink),
        titleSmall: t(base.titleSmall, 13, FontWeight.w700, AppColors.ink),
        bodyLarge: t(base.bodyLarge, 14, FontWeight.w500, AppColors.ink),
        bodyMedium: t(base.bodyMedium, 14, FontWeight.w500, AppColors.ink2),
        bodySmall: t(base.bodySmall, 12, FontWeight.w500, AppColors.textTertiary),
        labelLarge: t(base.labelLarge, 12, FontWeight.w700, AppColors.ink),
        labelMedium: t(base.labelMedium, 12, FontWeight.w700, AppColors.ink2),
        labelSmall: t(base.labelSmall, 10.5, FontWeight.w800, AppColors.ink3, ls: 1.2),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.paper,
        surfaceTintColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        titleTextStyle: AppFonts.heading(size: 19, color: AppColors.ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _solid),
      filledButtonTheme: FilledButtonThemeData(style: _solid),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _outline),
      textButtonTheme: TextButtonThemeData(style: _text),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.controlRadius)),
        ).copyWith(side: _focusSide(BorderSide.none)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFEFB), // desktop fieldBg
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _border(AppColors.fieldBorder),
        enabledBorder: _border(AppColors.fieldBorder),
        disabledBorder: _border(AppColors.line),
        focusedBorder: _border(AppColors.primary, 2),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 2),
        hintStyle: _m(14, FontWeight.w500, AppColors.ink3),
        labelStyle: _m(13, FontWeight.w700, AppColors.ink2),
        floatingLabelStyle: _m(13, FontWeight.w700, AppColors.primary),
        helperStyle: _m(12, FontWeight.w500, AppColors.ink3),
        errorStyle: _m(12, FontWeight.w600, AppColors.error),
        prefixIconColor: AppColors.ink3,
        suffixIconColor: AppColors.ink3,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: const BorderSide(color: Color(0xFFC9BFA9), width: 1.5),
        checkColor: const WidgetStatePropertyAll(AppColors.onPrimary),
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : const Color(0xFFFFFEFB)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.onPrimary : AppColors.card),
        trackColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : const Color(0xFFD8CFBC)),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
            (s) => s.contains(WidgetState.selected) ? AppColors.primary : const Color(0xFFC9BFA9)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: AppColors.card,
        surfaceTintColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppUi.radius),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.segmentBg,
        selectedColor: AppColors.primarySoft,
        checkmarkColor: AppColors.primary,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: _m(12, FontWeight.w700, AppColors.ink2),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.ink3,
        indicatorColor: AppColors.primary,
        labelStyle: _m(14, FontWeight.w700, AppColors.primary),
        unselectedLabelStyle: _m(14, FontWeight.w600, AppColors.ink3),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.controlRadius)),
        titleTextStyle: _m(14, FontWeight.w600, AppColors.ink),
        subtitleTextStyle: _m(12.5, FontWeight.w500, AppColors.ink3),
        iconColor: AppColors.ink2,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.card,
        surfaceTintColor: AppColors.card,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.line),
        ),
        textStyle: _m(14, FontWeight.w600, AppColors.ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        elevation: 10,
        shadowColor: AppColors.ink.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.radius)),
        titleTextStyle: _m(18, FontWeight.w700, AppColors.ink),
        contentTextStyle: _m(14, FontWeight.w500, AppColors.ink2),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        modalBackgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppUi.radius + 6))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: _m(14, FontWeight.w600, AppColors.onPrimary),
        actionTextColor: AppColors.onPrimaryAccent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: Color(0xFFEFE8D9),
        circularTrackColor: Color(0xFFEFE8D9),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line2, thickness: 1, space: 1),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        headerBackgroundColor: AppColors.primary,
        headerForegroundColor: AppColors.onPrimary,
        todayBorder: const BorderSide(color: AppColors.gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppUi.radius)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.ink3,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: _m(11, FontWeight.w700, AppColors.primary),
        unselectedLabelStyle: _m(11, FontWeight.w600, AppColors.ink3),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: AppColors.card,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStateProperty.resolveWith((s) => _m(11,
            s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            s.contains(WidgetState.selected) ? AppColors.primary : AppColors.ink3)),
      ),
    );
  }

  /// Peacock is light only (as on the desktop).
  static ThemeData get darkTheme => lightTheme;
}
