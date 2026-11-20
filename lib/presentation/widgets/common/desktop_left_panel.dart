import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_ui.dart';
import 'app_icon.dart';

/// Dark slate left panel for desktop split-screen layouts (VidPro style).
///
/// Used by splash, onboarding, welcome, auth, and student selection screens.
/// Shows school branding at top-left, optional center content, and
/// headline/subtitle at bottom-left on a dark gradient background.
class DesktopLeftPanel extends StatelessWidget {
  final String headline;
  final String subtitle;
  final Widget? centerContent;

  const DesktopLeftPanel({
    super.key,
    required this.headline,
    required this.subtitle,
    this.centerContent,
  });

  @override
  Widget build(BuildContext context) {
    // The desktop Peacock sign-in look: the school painting, deepened at the
    // foot with dark teal so the cream headline reads, and the FIT School
    // brand top-left. ([centerContent] is not drawn over the painting.)
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.3),
              errorBuilder: (_, __, ___) =>
                  const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.brandGradientVertical)),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.paper.withValues(alpha: 0.55),
                    AppColors.paper.withValues(alpha: 0.0),
                    AppColors.sideBg.withValues(alpha: 0.35),
                    AppColors.sideBg.withValues(alpha: 0.92),
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
            ),

            // Top-left branding
            Positioned(
              top: 36,
              left: 36,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
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
                          const AppIcon('book', size: 20, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'FIT ', style: AppFonts.heading(size: 24, color: AppColors.primaryDark)),
                    TextSpan(text: 'School', style: AppFonts.heading(size: 24, color: AppColors.goldDark)),
                  ])),
                ],
              ),
            ),

            // Bottom-left headline + subtitle
            Positioned(
              bottom: 44,
              left: 40,
              right: 40,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 36, height: 3, color: AppColors.gold),
                  const SizedBox(height: 14),
                  Text(
                    headline,
                    style: AppFonts.heading(size: 30, color: AppColors.onPrimary, height: 1.25),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: AppFonts.body(size: 15, color: AppColors.onPrimaryMuted, height: 1.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
