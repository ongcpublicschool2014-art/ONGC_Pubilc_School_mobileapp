import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/theme/button_styles.dart';

enum AppButtonVariant { filled, outlined, text }

enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: _getHeight(),
      child: _buildButton(isDisabled),
    );
  }

  double _getHeight() {
    switch (size) {
      case AppButtonSize.small:
        return 36;
      case AppButtonSize.medium:
        return 52;
      case AppButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.small:
        return AppSizes.secondaryText;
      case AppButtonSize.medium:
        return AppSizes.buttonText;
      case AppButtonSize.large:
        return AppSizes.sectionTitle;
    }
  }

  Widget _buildButton(bool isDisabled) {
    // Per-instance overrides applied on top of the centralised state-aware
    // styles. backgroundColor / textColor only override the default state;
    // hover / pressed / focused / disabled keep their state-resolved values.
    ButtonStyle merge(ButtonStyle base) {
      final bg = backgroundColor;
      final fg = textColor;
      if (bg == null && fg == null) return base;
      return base.copyWith(
        backgroundColor: bg == null
            ? null
            : WidgetStateProperty.resolveWith((s) {
                if (s.contains(WidgetState.disabled) ||
                    s.contains(WidgetState.pressed) ||
                    s.contains(WidgetState.hovered) ||
                    s.contains(WidgetState.focused)) {
                  return base.backgroundColor?.resolve(s);
                }
                return bg;
              }),
        foregroundColor: fg == null ? null : WidgetStateProperty.all(fg),
      );
    }

    switch (variant) {
      case AppButtonVariant.filled:
        return ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          style: merge(AppButtonStyles.elevated(radius: 8)),
          child: _buildContent(textColor ?? Colors.white),
        );
      case AppButtonVariant.outlined:
        return OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          style: merge(AppButtonStyles.outlined(radius: 8)),
          child: _buildContent(textColor ?? AppColors.buttonPrimary),
        );
      case AppButtonVariant.text:
        return TextButton(
          onPressed: isDisabled ? null : onPressed,
          style: merge(AppButtonStyles.text()),
          child: _buildContent(textColor ?? AppColors.buttonPrimary),
        );
    }
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSizes.s2),
          Text(
            text,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }
}
