import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/splash/splash_screen.dart';
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/screens/welcome/welcome_screen.dart';
import '../presentation/screens/auth/sign_in_screen.dart';
import '../presentation/screens/auth/sign_up_screen.dart';
import '../presentation/screens/auth/otp_verification_screen.dart';
import '../presentation/screens/auth/set_password_screen.dart';
import '../presentation/screens/auth/forgot_password_screen.dart';
import '../presentation/screens/auth/forgot_password_otp_screen.dart';
import '../presentation/screens/student_selection/student_selection_screen.dart';
import '../presentation/screens/student_selection/switch_student_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/home/home_screen_copy.dart';
import '../presentation/screens/fees/fees_screen.dart';
import '../presentation/screens/fees/fee_details_screen.dart';
import '../presentation/screens/payments/payment_history_screen.dart';
import '../presentation/screens/payments/transaction_details_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/notifications/notification_detail_screen.dart';
import '../data/models/notification_model.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/support/support_screen.dart';
import '../presentation/screens/transport/bus_screen.dart';
import '../presentation/screens/cart/cart_screen.dart';
import '../presentation/screens/fees/all_pending_fees_screen.dart';
import '../presentation/screens/fees/pay_all_fees_screen.dart';
import '../presentation/screens/fees/paid_fees_screen.dart';
import '../presentation/widgets/common/main_scaffold.dart';
import '../presentation/providers/auth_provider.dart' show parentAuthStateProvider;
import '../presentation/providers/student_provider.dart';

/// Route names
class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const otpVerification = '/otp-verification';
  static const setPassword = '/set-password';
  static const forgotPassword = '/forgot-password';
  static const forgotPasswordOtp = '/forgot-password-otp';
  static const resetPassword = '/reset-password';
  static const studentSelection = '/student-selection';
  static const switchStudent = '/switch-student';
  static const home = '/home';
  static const fees = '/fees';
  static const feeDetails = '/fees/:feeId';
  static const paymentHistory = '/payment-history';
  static const paymentReceipt = '/payment-history/:paymentId';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const support = '/support';
  static const cart = '/cart';
  static const cartStandalone = '/cart-standalone';
  static const allPendingFees = '/all-pending-fees';
  static const payAllFees = '/pay-all-fees';
  static const paidFees = '/paid-fees';
  static const transactionDetails = '/transaction';
  static const homeTest = '/home-test';
  static const bus = '/bus';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Allow splash screen to show first
      final isOnSplash = state.matchedLocation == Routes.splash;
      if (isOnSplash) {
        return null; // Let splash screen handle navigation
      }

      // TESTING: Allow home test screen without auth
      if (state.matchedLocation == Routes.homeTest) {
        return null;
      }

      // Bypass authentication when using dummy data
      if (useDummyData) {
        return null;
      }

      // Read auth state directly for most up-to-date value
      final parentAuthState = ref.read(parentAuthStateProvider);
      final isLoggedIn = parentAuthState.valueOrNull?.isAuthenticated ?? false;
      final isOnAuthPage = state.matchedLocation == Routes.signIn ||
          state.matchedLocation == Routes.signUp ||
          state.matchedLocation == Routes.otpVerification ||
          state.matchedLocation == Routes.setPassword ||
          state.matchedLocation == Routes.forgotPassword ||
          state.matchedLocation == Routes.forgotPasswordOtp ||
          state.matchedLocation == Routes.resetPassword;
      final isOnOnboarding = state.matchedLocation == Routes.onboarding;
      final isOnWelcome = state.matchedLocation == Routes.welcome;
      final isOnStudentSelection = state.matchedLocation == Routes.studentSelection;

      // Allow onboarding and welcome without auth
      if (isOnOnboarding || isOnWelcome) {
        return null;
      }

      // Allow student selection when coming from login or if authenticated
      final extra = state.extra;
      final fromLogin = extra is Map && extra['fromLogin'] == true;
      if (isOnStudentSelection && (isLoggedIn || fromLogin)) {
        return null;
      }

      // Redirect to welcome if not logged in and not on auth pages
      if (!isLoggedIn && !isOnAuthPage) {
        return Routes.welcome;
      }

      // Redirect to student selection if logged in and on auth pages
      if (isLoggedIn && isOnAuthPage) {
        return Routes.studentSelection;
      }

      return null;
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding Screen
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Welcome Screen
      GoRoute(
        path: Routes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: Routes.signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: Routes.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: Routes.otpVerification,
        builder: (context, state) {
          final mobile = state.extra as String?;
          return OtpVerificationScreen(mobile: mobile ?? '');
        },
      ),
      GoRoute(
        path: Routes.setPassword,
        builder: (context, state) {
          final mobile = state.extra as String?;
          return SetPasswordScreen(mobile: mobile ?? '');
        },
      ),

      // Forgot Password Routes
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: Routes.forgotPasswordOtp,
        builder: (context, state) {
          final mobile = state.extra as String?;
          return ForgotPasswordOtpScreen(mobile: mobile ?? '');
        },
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) {
          final mobile = state.extra as String?;
          return SetPasswordScreen(mobile: mobile ?? '', isResetPassword: true);
        },
      ),

      // Student Selection
      GoRoute(
        path: Routes.studentSelection,
        builder: (context, state) => const StudentSelectionScreen(),
      ),

      // Standalone Cart Screen (without bottom nav, with back button)
      GoRoute(
        path: Routes.cartStandalone,
        builder: (context, state) => const CartScreen(isStandalone: true),
      ),

      // TESTING: Home Screen Copy (new design)
      GoRoute(
        path: Routes.homeTest,
        builder: (context, state) => const HomeScreenCopy(),
      ),

      // Main App with Bottom Navigation (Shell Route)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: Routes.home,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: Routes.fees,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FeesScreen(),
            ),
            routes: [
              GoRoute(
                path: ':feeId',
                builder: (context, state) {
                  final feeId = state.pathParameters['feeId']!;
                  return FeeDetailsScreen(feeId: feeId);
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.paymentHistory,
            pageBuilder: (context, state) {
              final initialTab = state.uri.queryParameters['tab'];
              return NoTransitionPage(
                child: PaymentHistoryScreen(initialTab: initialTab),
              );
            },
            routes: [
              GoRoute(
                path: ':paymentId',
                builder: (context, state) {
                  final paymentId = state.pathParameters['paymentId']!;
                  return TransactionDetailsScreen(paymentId: paymentId, isNested: true);
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.notifications,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NotificationsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':notificationId',
                builder: (context, state) {
                  final notificationId = state.pathParameters['notificationId']!;
                  final extra = state.extra;
                  final notification = extra is NotificationModel
                      ? extra
                      : extra is Map<String, dynamic>
                          ? NotificationModel.fromJson(extra)
                          : null;
                  return NotificationDetailScreen(
                    notificationId: notificationId,
                    notification: notification,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: Routes.profile,
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),

          // Drill-down routes (rendered inside MainScaffold)
          GoRoute(
            path: Routes.support,
            builder: (context, state) => const SupportScreen(),
          ),
          GoRoute(
            path: Routes.bus,
            builder: (context, state) => const BusScreen(),
          ),
          GoRoute(
            path: Routes.cart,
            builder: (context, state) => const CartScreen(),
          ),
          GoRoute(
            path: Routes.allPendingFees,
            builder: (context, state) {
              final feeGroup = state.uri.queryParameters['group'];
              final filterStatus = state.uri.queryParameters['status'];
              return AllPendingFeesScreen(filterGroup: feeGroup, filterStatus: filterStatus);
            },
          ),
          GoRoute(
            path: Routes.payAllFees,
            builder: (context, state) => const PayAllFeesScreen(),
          ),
          GoRoute(
            path: Routes.paidFees,
            builder: (context, state) => const PaidFeesScreen(),
          ),
          GoRoute(
            path: Routes.switchStudent,
            builder: (context, state) => const SwitchStudentScreen(),
          ),
          GoRoute(
            path: '${Routes.transactionDetails}/:paymentId',
            builder: (context, state) {
              final paymentId = state.pathParameters['paymentId']!;
              return TransactionDetailsScreen(paymentId: paymentId, isNested: true);
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
