import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../config/routes.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/desktop_left_panel.dart';
import '../../providers/auth_provider.dart' show parentAuthStateProvider;
import '../../providers/student_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _pulseController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _startAnimationSequence() async {
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _textController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    _pulseController.repeat(reverse: true);
    await Future.delayed(const Duration(milliseconds: 1500));
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

    if (useDummyData) {
      if (!mounted) return;
      context.go(Routes.onboarding);
      return;
    }

    final parentAuthState = ref.read(parentAuthStateProvider);
    final isLoggedIn = parentAuthState.valueOrNull?.isAuthenticated ?? false;

    if (!mounted) return;

    if (isLoggedIn) {
      final savedStudentId = prefs.getInt('selected_student_id');
      if (savedStudentId != null) {
        context.go(Routes.home);
      } else {
        context.go(Routes.studentSelection);
      }
    } else if (hasSeenOnboarding) {
      context.go(Routes.welcome);
    } else {
      context.go(Routes.onboarding);
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: context.isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
    );
  }

  // ─── Mobile layout (existing design) ───────────────────────────────
  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // Background decorative elements
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.3,
          left: -40,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardGreen.withValues(alpha: 0.3),
            ),
          ),
        ),

        // Main content
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAnimatedLogo(context, 120),
              const SizedBox(height: 32),
              _buildAnimatedText(context),
            ],
          ),
        ),

        // Bottom loading indicator
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _textOpacity,
            child: Column(
              children: [
                _buildLoadingDots(),
                const SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondaryC(context),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Version at bottom
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: FadeTransition(
            opacity: _textOpacity,
            child: Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textHintC(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
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
            headline: 'SchoolPay',
            subtitle: 'Loading your experience...',
            centerContent: _buildAnimatedLogo(context, 160),
          ),
        ),

        // Right panel — loading state
        Expanded(
          flex: 5,
          child: Center(
            child: FadeTransition(
              opacity: _textOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLoadingDots(),
                  const SizedBox(height: 24),
                  Text(
                    'Loading your dashboard...',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppColors.textSecondaryC(context),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we set things up',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHintC(context),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHintC(context),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Shared animated widgets ───────────────────────────────────────

  Widget _buildAnimatedLogo(BuildContext context, double size) {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacity.value,
          child: Transform.scale(
            scale: _logoScale.value,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: context.isDesktop
                          ? Colors.white.withValues(alpha: 0.15)
                          : AppColors.cardBg(context),
                      borderRadius: BorderRadius.circular(size * 0.27),
                      boxShadow: context.isDesktop
                          ? []
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: size * 0.53,
                          height: size * 0.53,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: context.isDesktop
                                  ? [Colors.white, Colors.white.withValues(alpha: 0.9)]
                                  : [AppColors.primary, AppColors.primary600],
                            ),
                            borderRadius: BorderRadius.circular(size * 0.15),
                          ),
                          child: AppIcon(
                            'book',
                            size: size * 0.3,
                            color: context.isDesktop ? AppColors.primary : Colors.white,
                          ),
                        ),
                        Positioned(
                          right: size * 0.13,
                          bottom: size * 0.13,
                          child: Container(
                            width: size * 0.27,
                            height: size * 0.27,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF2E4F7A),
                                  Color(0xFF002147),
                                ],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: context.isDesktop
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : AppColors.cardBg(context),
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF002147).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AppIcon(
                              'empty-wallet',
                              size: size * 0.13,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText(BuildContext context) {
    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textOpacity,
        child: Column(
          children: [
            Text(
              'SchoolPay',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimaryC(context),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardGreen,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.cardGreenDark,
                      shape: BoxShape.circle,
                    ),
                    child: const AppIcon(
                      'verify',
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Secure & Easy Fee Payments',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.cardGreenDark,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
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

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_pulseController.value + delay) % 1.0;
            final opacity = 0.3 + (0.7 * (value < 0.5 ? value * 2 : (1 - value) * 2));
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
