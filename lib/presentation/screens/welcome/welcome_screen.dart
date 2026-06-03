import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../config/routes.dart';
import '../../widgets/common/amber_button.dart';
import '../../widgets/common/desktop_left_panel.dart';

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

  // â”€â”€â”€ Mobile layout — reference image style â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 60),
                  // Title
                  const Text(
                    'Welcome to\nSchoolPay',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A1A),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Subtitle
                  const Text(
                    'Your go-to destination for smart, fast, and hassle-free fee payments',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B6B6B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),
                  // Feature items
                  _buildFeatureItem(
                    context: context,
                    iconAsset: 'assets/icons/linear/flash.svg',
                    text: 'Quick & Easy Payments',
                    color: AppColors.cardGreen,
                    iconColor: AppColors.cardGreenDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    context: context,
                    iconAsset: 'assets/icons/linear/shield-tick.svg',
                    text: '100% Secure Transactions',
                    color: AppColors.cardGreen,
                    iconColor: AppColors.cardGreenDark,
                  ),
                  const SizedBox(height: 10),
                  _buildFeatureItem(
                    context: context,
                    iconAsset: 'assets/icons/linear/receipt-text.svg',
                    text: 'Instant Digital Receipts',
                    color: AppColors.cardGreen,
                    iconColor: AppColors.cardGreenDark,
                  ),
                  const SizedBox(height: 32),
                  // Sign In — dark button
                  _buildSignInButton(context),
                  const SizedBox(height: 12),
                  // Create Account — outlined
                  _buildCreateAccountButton(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
    );
  }

  // â”€â”€â”€ Desktop layout (split-screen) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        // Left panel — dark branding
        Expanded(
          flex: 5,
          child: DesktopLeftPanel(
            headline: 'Welcome to SchoolPay',
            subtitle: 'Pay school fees with ease',
            centerContent: Image.asset(
              'assets/images/educore360_logo.png',
              width: 360,
              height: 360,
              fit: BoxFit.contain,
            ),
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

  // â”€â”€â”€ Shared widgets â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Widget _buildLogo(BuildContext context, double size) {
    return Image.asset(
      'assets/images/educore360_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return AmberButton(
      label: 'Sign In',
      icon: 'login',
      height: 56,
      onPressed: () => context.push(Routes.signIn),
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    final isMobile = !context.isDesktop;
    final fg = isMobile ? const Color(0xFF1A1A1A) : AppColors.primary;
    return Material(
      color: isMobile ? Colors.white : AppColors.cardBg(context),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(Routes.signUp),
        borderRadius: BorderRadius.circular(16),
        hoverColor: const Color(0xFFD2913C).withValues(alpha: 0.06),
        focusColor: const Color(0xFFD2913C).withValues(alpha: 0.10),
        splashColor: const Color(0xFFD2913C).withValues(alpha: 0.14),
        highlightColor: const Color(0xFFD2913C).withValues(alpha: 0.06),
        mouseCursor: SystemMouseCursors.click,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMobile ? const Color(0xFFE8E7E4) : AppColors.primary,
              width: isMobile ? 1 : 2,
            ),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/icons/linear/user-add.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(fg, BlendMode.srcIn),
                ),
              ],
            ),
          ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
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
