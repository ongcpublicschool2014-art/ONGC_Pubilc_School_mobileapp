import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';

/// Round 44×44 amber header icon button (notification bell, cart, etc.).
///
/// Press paints a dark ripple AND shrinks to 0.92 for tactile feedback.
/// Subtle black drop shadow keeps it elevated. Optional [badgeCount]
/// paints a red badge in the upper-right corner.
class HeaderIconButton extends StatefulWidget {
  final IconData? icon;
  final String? svgPath;
  final int badgeCount;
  final VoidCallback onTap;

  const HeaderIconButton({
    super.key,
    this.icon,
    this.svgPath,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  State<HeaderIconButton> createState() => _HeaderIconButtonState();
}

class _HeaderIconButtonState extends State<HeaderIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.92 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: SizedBox(
        width: 44,
        height: 44,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: const Color(0xFFD2913C),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              customBorder: const CircleBorder(),
              hoverColor: Colors.black.withValues(alpha: 0.06),
              focusColor: Colors.black.withValues(alpha: 0.10),
              splashColor: Colors.black.withValues(alpha: 0.22),
              highlightColor: Colors.black.withValues(alpha: 0.12),
              mouseCursor: SystemMouseCursors.click,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (widget.svgPath != null)
                    SvgPicture.asset(
                      widget.svgPath!,
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                          Colors.white, BlendMode.srcIn),
                    )
                  else
                    Icon(widget.icon, size: 20, color: Colors.white),
                  if (widget.badgeCount > 0)
                    Positioned(
                      top: -3,
                      right: -3,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
