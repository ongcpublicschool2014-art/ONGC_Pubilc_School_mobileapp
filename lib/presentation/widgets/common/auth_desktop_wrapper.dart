import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import '../../../core/utils/extensions.dart';
import 'app_icon.dart';
import 'desktop_left_panel.dart';

/// Wraps auth screen content with a desktop split-screen layout.
///
/// On desktop (>=1024px): Dark left panel with branding/headline +
///   right panel with the form content (scrollable, 560px max-width).
/// On mobile / narrow screens: Renders child directly.
class AuthDesktopWrapper extends StatelessWidget {
  final Widget child;
  final String headline;
  final String subtitle;
  final Widget? centerContent;
  final VoidCallback? onBack;

  const AuthDesktopWrapper({
    super.key,
    required this.child,
    this.headline = 'Welcome Back',
    this.subtitle = 'Secure & easy school fee payments',
    this.centerContent,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final showSplitScreen = context.isDesktop;

    if (!showSplitScreen) {
      // Phone: the desktop sign-in look -- the school painting under a paper
      // wash with the FIT School brand, then the form on the paper page.
      return Column(
        children: [
          PeacockAuthHeader(onBack: onBack),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: child,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Left panel — dark branding
        Expanded(
          flex: 5,
          child: DesktopLeftPanel(
            headline: headline,
            subtitle: subtitle,
            centerContent: centerContent,
          ),
        ),

        // Right panel — form content
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: child,
                ),
              ),
              // Back button at top-left
              if (onBack != null)
                Positioned(
                  top: 24,
                  left: 32,
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: AppIcon(
                      'arrow-left-1',
                      size: 18,
                      color: AppColors.textSecondaryC(context),
                    ),
                    label: Text(
                      'Back',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondaryC(context),
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The school painting (assets/images/login_bg.jpg, the same picture as the
/// desktop sign-in) under a paper wash, with the logo and "FIT School" in
/// Fraunces -- "FIT" deep teal, "School" marigold-dark, as on the desktop.
class PeacockAuthHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final double height;
  final bool showBrand;

  const PeacockAuthHeader({super.key, this.onBack, this.height = 196, this.showBrand = true});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: height + top,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_bg.jpg',
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.3),
            errorBuilder: (_, __, ___) => const ColoredBox(color: AppColors.primaryTint),
          ),
          // Soften the picture, then fade it into the paper page below.
          ColoredBox(color: AppColors.paper.withValues(alpha: 0.22)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.paper.withValues(alpha: 0.0),
                  AppColors.paper.withValues(alpha: 0.35),
                  AppColors.paper,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          if (showBrand)
          Positioned(
            left: 20,
            right: 20,
            bottom: 14,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Image.asset(
                    'assets/images/app_logo_mark.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.school_outlined, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(
                        text: 'FIT ',
                        style: AppFonts.heading(size: 26, color: AppColors.primaryDark)),
                    TextSpan(
                        text: 'School',
                        style: AppFonts.heading(size: 26, color: AppColors.goldDark)),
                  ]),
                ),
              ],
            ),
          ),
          if (onBack != null)
            Positioned(
              top: top + 8,
              left: 12,
              child: Material(
                color: AppColors.card.withValues(alpha: 0.92),
                shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
                child: IconButton(
                  onPressed: onBack,
                  tooltip: 'Back',
                  icon: AppIcon('arrow-left-1', size: 20, color: AppColors.ink),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
