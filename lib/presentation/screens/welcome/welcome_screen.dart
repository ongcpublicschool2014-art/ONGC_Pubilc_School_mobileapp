import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../config/routes.dart';
import '../../widgets/common/app_action_button.dart';
import '../../widgets/common/auth_desktop_wrapper.dart';
import '../../widgets/common/desktop_left_panel.dart';
import '../../../core/constants/app_ui.dart';
import '../../widgets/common/screen_illustrations.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: context.isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
    );
  }

  // ─── Mobile layout — the desktop sign-in look ─────────────────────────
  // The school painting (as on the desktop) fading into the paper page, the
  // "Welcome to FIT School" headline in Fraunces, then the features and the
  // two buttons.
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const PeacockAuthHeader(height: 250, showBrand: false),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME TO',
                    style: AppFonts.body(
                        size: 11.5, weight: FontWeight.w800, color: AppColors.goldInk, letterSpacing: 1.6),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(children: [
                      TextSpan(text: 'FIT ', style: AppFonts.heading(size: 34, color: AppColors.primaryDark, height: 1.1)),
                      TextSpan(text: 'School', style: AppFonts.heading(size: 34, color: AppColors.goldDark, height: 1.1)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Container(width: 36, height: 3, color: AppColors.gold),
                  const SizedBox(height: 14),
                  Text(
                    'Pay school fees, see receipts and get reminders -- all in one place.',
                    style: AppFonts.body(size: 15, color: AppColors.ink2, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  _buildFeatureItem(
                    context: context,
                    iconAsset: 'assets/icons/linear/flash.svg',
                    text: 'Quick & Easy Payments',
                    color: AppColors.primarySoft,
                    iconColor: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    context: context,
                    iconAsset: 'assets/icons/linear/shield-tick.svg',
                    text: '100% Secure Transactions',
                    color: AppColors.goldSoft,
                    iconColor: AppColors.goldDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    context: context,
                    iconAsset: 'assets/icons/linear/receipt-text.svg',
                    text: 'Instant Digital Receipts',
                    color: AppColors.blueBg,
                    iconColor: AppColors.blue,
                  ),
                  const SizedBox(height: 28),
                  _buildSignInButton(context),
                  const SizedBox(height: 12),
                  _buildCreateAccountButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Desktop layout (split-screen) ─────────────────────────────────
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left panel — dark branding
        Expanded(
          flex: 5,
          child: DesktopLeftPanel(
            headline: 'Welcome to FIT School',
            subtitle: 'Pay school fees with ease',
            centerContent: ScreenIllustrations.welcomeDark(size: 360),
          ),
        ),

        // Right panel — features + actions
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimaryC(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Get started with secure and hassle-free school fee payments.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondaryC(context),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 36),
                    _buildFeatureItem(
                      context: context,
                      iconAsset: 'assets/icons/linear/flash.svg',
                      text: 'Quick & Easy Payments',
                      color: AppColors.cardPurple,
                      iconColor: AppColors.cardPurpleDark,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context: context,
                      iconAsset: 'assets/icons/linear/shield-tick.svg',
                      text: '100% Secure Transactions',
                      color: AppColors.cardGreen,
                      iconColor: AppColors.cardGreenDark,
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureItem(
                      context: context,
                      iconAsset: 'assets/icons/linear/receipt-text.svg',
                      text: 'Instant Digital Receipts',
                      color: AppColors.cardBlue,
                      iconColor: AppColors.cardBlueDark,
                    ),
                    const SizedBox(height: 40),
                    _buildSignInButton(context),
                    const SizedBox(height: 12),
                    _buildCreateAccountButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared widgets ────────────────────────────────────────────────

  Widget _buildSignInButton(BuildContext context) {
    return AppActionButton(
      onPressed: () => context.push(Routes.signIn),
      label: 'Sign In',
      borderRadius: 12,
      verticalPadding: 16,
      trailing: SvgPicture.asset(
        'assets/icons/linear/login.svg',
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(AppColors.onPrimary, BlendMode.srcIn),
      ),
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return AppActionButton(
      onPressed: () => context.push(Routes.signUp),
      label: 'Create Account',
      variant: AppActionButtonVariant.outlined,
      borderRadius: 12,
      verticalPadding: 16,
      trailing: SvgPicture.asset(
        'assets/icons/linear/user-add.svg',
        width: 20,
        height: 20,
        colorFilter: const ColorFilter.mode(
          AppColors.primaryDark,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required String iconAsset,
    required String text,
    required Color color,
    required Color iconColor,
  }) {
    final isMobile = !context.isDesktop;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        // Spec: card border navy on desktop / #E8E7E4 on mobile
        border: Border.all(
          color: isMobile ? const Color(0xFFE6DFCF) : AppColors.primary,
          width: isMobile ? 1 : 1.5,
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? []
            : [BoxShadow(color: AppColors.shadowLight, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              iconAsset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimaryC(context),
              ),
            ),
          ),
          SvgPicture.asset(
            'assets/icons/linear/tick-circle.svg',
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.success,
              BlendMode.srcIn,
            ),
          ),
        ],
      ),
    );
  }
}
