import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/utils/extensions.dart';
import '../../../config/routes.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/desktop_left_panel.dart';
import '../../widgets/common/screen_illustrations.dart';

class OnboardingData {
  final int id;
  final String title;
  final String subtitle;
  final String description;
  final IconData? icon;
  final String? imagePath;
  final Color iconColor;
  final Color backgroundColor;

  const OnboardingData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    this.icon,
    this.imagePath,
    required this.iconColor,
    required this.backgroundColor,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<OnboardingData> _pages = const [
    OnboardingData(
      id: 1,
      title: 'Welcome to SchoolPay',
      subtitle: 'Simplify Your School Payments',
      description:
          'Pay fees, track dues, and get instant receipts—all in one app.',
      imagePath: 'assets/Onboard and Welcome Screen Gif/Payment Information.gif',
      iconColor: AppColors.primary,
      backgroundColor: Color(0xFFE8F4FD),
    ),
    OnboardingData(
      id: 2,
      title: 'Easy, Secure & Instant',
      subtitle: 'Make Payments in Seconds',
      description:
          'Secure UPI & card payments, Instant receipt generation, Late fee alerts and reminders',
      imagePath: 'assets/Onboard and Welcome Screen Gif/Two factor authentication.gif',
      iconColor: AppColors.success,
      backgroundColor: Color(0xFFE8F8F0),
    ),
    OnboardingData(
      id: 3,
      title: 'Stay Notified. Stay Ahead.',
      subtitle: 'Never Miss a Due Date',
      description:
          'Get notified before deadlines, View fee breakdown anytime, Auto-reminders & history log',
      imagePath: 'assets/Onboard and Welcome Screen Gif/Push notifications.gif',
      iconColor: AppColors.warning,
      backgroundColor: Color(0xFFFFF8E8),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);

    if (mounted) {
      context.go(Routes.welcome);
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: context.isDesktop
          ? _buildDesktopLayout(isLastPage)
          : _buildMobileLayout(isLastPage),
    );
  }

  // â”€â”€â”€ Mobile layout — reference image style â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMobileLayout(bool isLastPage) {
    final currentData = _pages[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // Top illustration area — takes ~55% of screen
          Expanded(
            flex: 55,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: _pages[index].backgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildOnboardIllustration(index, isDark: false),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom content area — title, description, dots, button
          Expanded(
            flex: 45,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),
                      // Title
                      Text(
                        currentData.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
                      Text(
                        currentData.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6B6B6B),
                          height: 1.5,
                        ),
                      ),
                      const Spacer(flex: 2),
                      // Pagination dots
                      _buildPaginationDots(),
                      const Spacer(flex: 1),
                      // Full-width dark Next button
                      GestureDetector(
                        onTap: _nextPage,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2913C),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              isLastPage ? 'Get Started' : 'Next',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Skip link below button
                      if (!isLastPage) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _completeOnboarding,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B6B6B),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€ Desktop layout (split-screen) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDesktopLayout(bool isLastPage) {
    final currentData = _pages[_currentPage];

    return Row(
      children: [
        // Left panel — dark branding with PageView
        Expanded(
          flex: 5,
          child: DesktopLeftPanel(
            headline: currentData.title,
            subtitle: currentData.subtitle,
            centerContent: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: _buildOnboardIllustration(index, isDark: true),
                  );
                },
              ),
            ),
          ),
        ),

        // Right panel — text content + navigation
        Expanded(
          flex: 5,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 40,
                ),
                child: Column(
                  children: [
                    // Top row — Skip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildSkipButton(),
                      ],
                    ),

                    const Spacer(),

                    // Animated text content
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              currentData.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimaryC(context),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentData.subtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              currentData.description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondaryC(context),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Pagination dots
                    _buildPaginationDots(),

                    const SizedBox(height: 32),

                    // Full-width Next/Get Started button
                    _buildDesktopNextButton(isLastPage),

                    const SizedBox(height: 16),
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

  Widget _buildBackButton() {
    if (_currentPage == 0) {
      return const SizedBox(width: 44, height: 44);
    }

    return TextButton.icon(
      onPressed: _previousPage,
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
    );
  }

  Widget _buildPaginationDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => GestureDetector(
          onTap: () {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _currentPage == index
                  ? AppColors.primary
                  : AppColors.gray300,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _completeOnboarding,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        'Skip',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryC(context),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildNextButton(bool isLastPage) {
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.24),
              blurRadius: 1,
              offset: Offset.zero,
            ),
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.transparent
                  : const Color(0xFFE5E7EB),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isLastPage ? 'Get Started' : 'Next',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 10),
            const AppIcon(
              'arrow-right-1',
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopNextButton(bool isLastPage) {
    return GestureDetector(
      onTap: _nextPage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFD2913C),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastPage ? 'Get Started' : 'Next',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const AppIcon(
              'arrow-right-1',
              size: 20,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildOnboardIllustration(int index, {bool isDark = false}) {
  final size = isDark ? 360.0 : 280.0;
  switch (index) {
    case 0:
      return ScreenIllustrations.onboardPayment(size: size, isDark: isDark);
    case 1:
      return ScreenIllustrations.onboardSecurity(size: size, isDark: isDark);
    case 2:
      return ScreenIllustrations.onboardNotifications(size: size, isDark: isDark);
    default:
      return ScreenIllustrations.onboardPayment(size: size, isDark: isDark);
  }
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title
            Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryC(context),
                  height: 1.27,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Illustration
            _buildOnboardIllustration(data.id - 1, isDark: false),

            const SizedBox(height: 30),

            // Subtitle and Description
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    data.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    width: 261,
                    child: Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondaryC(context),
                        height: 1.43,
                      ),
                    ),
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
