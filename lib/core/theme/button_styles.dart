import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

/// Centralised button styles with interaction-state handling.
///
/// Each style resolves bg / fg / overlay / elevation / cursor per
/// WidgetState (default, hover, focused, pressed, disabled) so the
/// same component reads correctly on web (cursor + keyboard) and
/// mobile (touch + a11y focus).
class AppButtonStyles {
  AppButtonStyles._();

  static const _radius = AppSizes.roundedLg;
  static const _textStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: AppSizes.buttonText,
    fontWeight: FontWeight.w600,
  );
  static const _padding = EdgeInsets.symmetric(
    horizontal: AppSizes.s6,
    vertical: AppSizes.s4,
  );

  // ── Filled (ElevatedButton) ──────────────────────────────────────
  static ButtonStyle elevated({double radius = _radius}) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return AppColors.buttonPrimaryDisabled;
        if (s.contains(WidgetState.pressed)) return AppColors.buttonPrimaryPressed;
        if (s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)) {
          return AppColors.buttonPrimaryHover;
        }
        return AppColors.buttonPrimary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return Colors.white.withValues(alpha: 0.7);
        return Colors.white;
      }),
      overlayColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.pressed)) return Colors.white.withValues(alpha: 0.16);
        if (s.contains(WidgetState.hovered)) return Colors.white.withValues(alpha: 0.08);
        if (s.contains(WidgetState.focused)) return Colors.white.withValues(alpha: 0.12);
        return null;
      }),
      elevation: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return 0;
        if (s.contains(WidgetState.pressed)) return 1;
        if (s.contains(WidgetState.hovered)) return 4;
        return 0;
      }),
      shadowColor: WidgetStateProperty.all(
        AppColors.buttonPrimary.withValues(alpha: 0.4),
      ),
      padding: WidgetStateProperty.all(_padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      textStyle: WidgetStateProperty.all(_textStyle),
      mouseCursor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return SystemMouseCursors.forbidden;
        return SystemMouseCursors.click;
      }),
    );
  }

  // ── Outlined (OutlinedButton) ────────────────────────────────────
  static ButtonStyle outlined({double radius = _radius}) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.pressed)) return AppColors.buttonPrimary.withValues(alpha: 0.16);
        if (s.contains(WidgetState.hovered)) return AppColors.buttonPrimary.withValues(alpha: 0.08);
        if (s.contains(WidgetState.focused)) return AppColors.buttonPrimary.withValues(alpha: 0.12);
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return AppColors.gray400;
        if (s.contains(WidgetState.pressed)) return AppColors.buttonPrimaryPressed;
        return AppColors.buttonPrimary;
      }),
      side: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return const BorderSide(color: AppColors.gray300);
        if (s.contains(WidgetState.pressed)) return const BorderSide(color: AppColors.buttonPrimaryPressed, width: 1.5);
        if (s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)) {
          return const BorderSide(color: AppColors.buttonPrimaryHover, width: 1.5);
        }
        return const BorderSide(color: AppColors.buttonPrimary);
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      padding: WidgetStateProperty.all(_padding),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      ),
      textStyle: WidgetStateProperty.all(_textStyle),
      mouseCursor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return SystemMouseCursors.forbidden;
        return SystemMouseCursors.click;
      }),
    );
  }

  // ── Text (TextButton) ────────────────────────────────────────────
  static ButtonStyle text() {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.pressed)) return AppColors.buttonPrimary.withValues(alpha: 0.14);
        if (s.contains(WidgetState.hovered)) return AppColors.buttonPrimary.withValues(alpha: 0.06);
        if (s.contains(WidgetState.focused)) return AppColors.buttonPrimary.withValues(alpha: 0.10);
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return AppColors.gray400;
        if (s.contains(WidgetState.pressed)) return AppColors.buttonPrimaryPressed;
        if (s.contains(WidgetState.hovered) || s.contains(WidgetState.focused)) {
          return AppColors.buttonPrimaryHover;
        }
        return AppColors.textLink;
      }),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      textStyle: WidgetStateProperty.all(_textStyle),
      mouseCursor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.disabled)) return SystemMouseCursors.forbidden;
        return SystemMouseCursors.click;
      }),
    );
  }
}
