import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/routes.dart';
import '../../../core/constants/app_colors.dart';
import 'app_icon.dart';

/// A premium "pill container" breadcrumb.
///
/// The entire trail (back button + crumbs) lives inside one soft rounded
/// pill with a subtle border, banking-app style. Keeps a compact footprint
/// while making the nav target area obvious and tactile.
///
/// Renders: `[ ← │ 🏠 Dashboard  ›  Current Page ]`
class BreadcrumbBar extends StatefulWidget {
  /// Label of the parent crumb (e.g. "Dashboard", "Payment History").
  final String parentLabel;

  /// Route to navigate to when tapping the parent crumb.
  /// Defaults to [Routes.home].
  final String? parentRoute;

  /// Current page title — shown as the last, non-tappable segment.
  final String currentLabel;

  /// Optional icon asset name rendered before [currentLabel].
  final String? currentIcon;

  const BreadcrumbBar({
    super.key,
    this.parentLabel = 'Dashboard',
    this.parentRoute,
    required this.currentLabel,
    this.currentIcon,
  });

  @override
  State<BreadcrumbBar> createState() => _BreadcrumbBarState();
}

class _BreadcrumbBarState extends State<BreadcrumbBar> {
  bool _parentHovered = false;
  bool _backHovered = false;

  bool get _isRoot =>
      widget.parentRoute == null || widget.parentRoute == Routes.home;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(widget.parentRoute ?? Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pillBg = isDark
        ? const Color(0xFF1E1E2A)
        : Colors.white;
    final pillBorder = isDark
        ? const Color(0xFF2D2D3D)
        : const Color(0xFFE6DFCF);
    final dividerColor = isDark
        ? const Color(0xFF2D2D3D)
        : const Color(0xFFE6DFCF);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 24, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: pillBorder, width: 1),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBackSegment(context),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: dividerColor,
                  indent: 8,
                  endIndent: 8,
                ),
                Flexible(child: _buildTrailSegment(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackSegment(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _backHovered = true),
      onExit: (_) => setState(() => _backHovered = false),
      child: GestureDetector(
        onTap: _goBack,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _backHovered
                ? AppColors.textLink.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(999),
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                'arrow-left-1',
                size: 13,
                color: AppColors.textLink,
              ),
              SizedBox(width: 6),
              Text(
                'Back',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailSegment(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 9, 18, 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildParentCrumb(context),
          _buildSeparator(context),
          Flexible(child: _buildCurrentCrumb(context)),
        ],
      ),
    );
  }

  Widget _buildParentCrumb(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _parentHovered = true),
      onExit: (_) => setState(() => _parentHovered = false),
      child: GestureDetector(
        onTap: () => context.go(widget.parentRoute ?? Routes.home),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRoot) ...[
              AppIcon(
                'home-2',
                size: 13,
                color: _parentHovered
                    ? AppColors.textLink
                    : AppColors.textSecondaryC(context),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              widget.parentLabel,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _parentHovered
                    ? AppColors.textLink
                    : AppColors.textSecondaryC(context),
                decoration: _parentHovered
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: AppColors.textLink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: AppIcon(
        'arrow-right-1',
        size: 9,
        color: AppColors.textHintC(context),
      ),
    );
  }

  Widget _buildCurrentCrumb(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.currentIcon != null) ...[
          AppIcon(
            widget.currentIcon!,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            widget.currentLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimaryC(context),
              letterSpacing: -0.1,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
