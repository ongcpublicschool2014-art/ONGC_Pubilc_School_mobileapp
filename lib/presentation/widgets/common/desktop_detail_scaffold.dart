import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../core/utils/extensions.dart';

/// A responsive scaffold for detail/sub-screens that renders the
/// "floating card dashboard" look on desktop and passes through on mobile.
///
/// On desktop (≥1024px):
///   - scaffoldBg background with 16px outer padding
///   - Header in a rounded card container
///   - Body in a rounded card container
///   - Optional bottom bar in a rounded card container
///
/// On mobile: standard Scaffold with header + body + optional bottom bar.
///
/// [isNested] = true when inside MainScaffold (ShellRoute) —
/// skips outer Scaffold/padding since MainScaffold provides them.
class DesktopDetailScaffold extends StatelessWidget {
  /// Header content (e.g. Row with back button, title, actions).
  final Widget header;

  /// Main scrollable/content body.
  final Widget body;

  /// Optional bottom action bar (e.g. pay button, add-to-cart bar).
  final Widget? bottomBar;

  /// Optional toolbar rendered **outside** the body card (e.g. breadcrumb).
  /// On desktop: appears between header and body card.
  /// On mobile: appears between header and body.
  final Widget? toolbar;

  /// AppBar for mobile only (screens that use standard AppBar on mobile).
  /// On desktop, [header] is used instead.
  final PreferredSizeWidget? mobileAppBar;

  /// True when screen is inside ShellRoute/MainScaffold.
  /// On desktop, skips outer Scaffold + padding (MainScaffold provides them).
  final bool isNested;

  const DesktopDetailScaffold({
    super.key,
    required this.header,
    required this.body,
    this.bottomBar,
    this.toolbar,
    this.mobileAppBar,
    this.isNested = false,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return _buildDesktop(context);
    }
    return _buildMobile(context);
  }

  /// Responsive horizontal padding for body content on desktop.
  /// Keeps content readable on wide screens.
  double _bodyHorizontalPadding(double screenWidth) {
    if (screenWidth >= 1600) return 64;  // Large desktop
    if (screenWidth >= 1280) return 32;  // Medium desktop
    return 0;                            // Small desktop (1024–1280)
  }

  Widget _buildDesktop(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bodyPadding = _bodyHorizontalPadding(screenWidth);

    final content = Column(
      children: [
        // Header card — skip when nested (MainScaffold top bar shows the title)
        if (!isNested) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow(context),
            ),
            child: header,
          ),
          const SizedBox(height: 16),
        ],
        // Toolbar (outside card, e.g. breadcrumb)
        if (toolbar != null) toolbar!,
        // Body card
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow(context),
            ),
            clipBehavior: Clip.antiAlias,
            padding: bodyPadding > 0
                ? EdgeInsets.symmetric(horizontal: bodyPadding)
                : null,
            child: body,
          ),
        ),
        // Bottom bar card (optional)
        if (bottomBar != null) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow(context),
            ),
            child: bottomBar!,
          ),
        ],
      ],
    );

    // Nested: MainScaffold already provides Scaffold + padding
    if (isNested) return content;

    // Standalone: wrap in Scaffold + outer padding
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: content,
      ),
    );
  }

  Widget _buildMobile(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBg(context) : AppUi.pageBg,
      appBar: mobileAppBar,
      body: Column(
        children: [
          // Header (only for screens without AppBar). A hairline under it
          // instead of a drop shadow -- the bar reads as part of the page,
          // which is what lets the content below carry the weight.
          if (mobileAppBar == null)
            Container(
              color: AppColors.headerBg(context),
              child: SafeArea(
                bottom: false,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.headerBg(context),
                    border: Border(
                      bottom: BorderSide(
                          color: isDark
                              ? AppColors.borderC(context)
                              : AppUi.line),
                    ),
                  ),
                  child: header,
                ),
              ),
            ),
          // Body
          Expanded(child: body),
          // Bottom bar
          if (bottomBar != null) bottomBar!,
        ],
      ),
    );
  }
}
