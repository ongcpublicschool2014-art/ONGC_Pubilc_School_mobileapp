import 'package:flutter/material.dart';
import 'app_icon.dart';

/// Amber primary action button with full state feedback.
///
/// Default → Hover → Focused → Pressed → Disabled. Press paints a dark
/// ripple AND shrinks the button to 0.96 for tactile feedback. Drop shadow
/// is a neutral black low-alpha (not an amber halo) so the button reads as
/// elevated rather than outlined.
class AmberButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final String? icon;
  final bool isLoading;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? padding;
  final bool fullWidth;
  final double fontSize;
  final double iconSize;

  const AmberButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 52,
    this.radius = 16,
    this.padding,
    this.fullWidth = true,
    this.fontSize = 16,
    this.iconSize = 20,
  });

  @override
  State<AmberButton> createState() => _AmberButtonState();
}

class _AmberButtonState extends State<AmberButton> {
  static const _amber = Color(0xFFD2913C);
  static const _amberDisabled = Color(0xFFE8C896);
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.isLoading || widget.onPressed == null;
    final radius = widget.radius;

    return AnimatedScale(
      scale: _pressed && !disabled ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Material(
          color: disabled ? _amberDisabled : _amber,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            onTap: disabled ? null : widget.onPressed,
            onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
            onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
            onTapCancel: disabled ? null : () => setState(() => _pressed = false),
            borderRadius: BorderRadius.circular(radius),
            hoverColor: Colors.black.withValues(alpha: 0.06),
            focusColor: Colors.black.withValues(alpha: 0.10),
            splashColor: Colors.black.withValues(alpha: 0.22),
            highlightColor: Colors.black.withValues(alpha: 0.12),
            mouseCursor: disabled
                ? SystemMouseCursors.forbidden
                : SystemMouseCursors.click,
            child: SizedBox(
              width: widget.fullWidth ? double.infinity : null,
              height: widget.height,
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize:
                      widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                  children: [
                    if (widget.isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else ...[
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (widget.icon != null) ...[
                        const SizedBox(width: 10),
                        AppIcon(widget.icon!,
                            size: widget.iconSize, color: Colors.white),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
