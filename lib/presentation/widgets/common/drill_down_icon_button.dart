import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/constants/app_colors.dart';

/// Drill-down screen header icon button (44×44 amber circle with shadow).
/// Used for back arrows + notification bells on detail / list screens.
///
/// Press paints a dark ripple AND shrinks the button to 0.92 for tactile
/// feedback. Subtle black drop shadow keeps it elevated.
class DrillDownIconButton extends StatefulWidget {
  final String svgPath;
  final VoidCallback onTap;
  final int badgeCount;

  const DrillDownIconButton({
    super.key,
    required this.svgPath,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<DrillDownIconButton> createState() => _DrillDownIconButtonState();
}

class _DrillDownIconButtonState extends State<DrillDownIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.iconButtonBg(context);
    final border = AppColors.iconButtonBorder(context);

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
            color: bg,
            shape: CircleBorder(side: BorderSide(color: border)),
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
                  SvgPicture.asset(
                    widget.svgPath,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                        Colors.white, BlendMode.srcIn),
                  ),
                  if (widget.badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                          border: Border.all(color: bg, width: 2),
                        ),
                        child: Text(
                          widget.badgeCount > 9 ? '9+' : '${widget.badgeCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
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
