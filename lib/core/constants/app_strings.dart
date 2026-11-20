/// App-wide string constants
class AppStrings {
  AppStrings._();

  // App
  static const String appName = 'FIT School';
  /// Shown on the splash; keep in step with `version:` in pubspec.yaml.
  static const String appVersion = '0.0.0';
  static const String appTagline = 'Easy School Fee Payments';

  // Auth
  static const String signIn = 'Sign In';
  static const String signUp = 'Sign Up';
  static const String signOut = 'Sign Out';
  static const String welcomeBack = 'Welcome Back';
  static const String createAccount = 'Create Account';
  static const String forgotPassword = 'Forgot Password?';
  static const String enterMobile = 'Enter your 10-digit mobile number';
  static const String enterPassword = 'Enter your password';
  static const String confirmPassword = 'Confirm Password';
  static const String verifyOtp = 'Verify OTP';
  static const String resendOtp = 'Resend OTP';
  static const String setPassword = 'Set Password';

  // Validation
  static const String invalidMobile = 'Please enter a valid 10-digit mobile number';
  static const String invalidPassword = 'Password must be at least 8 characters';
  static const String passwordMismatch = 'Passwords do not match';
  static const String invalidOtp = 'Please enter a valid 6-digit OTP';
  static const String requiredField = 'This field is required';

  // Home
  static const String home = 'Home';
  static const String quickActions = 'Quick Actions';
  static const String recentPayments = 'Recent Payments';
  static const String viewAll = 'View All';

  // Fees
  static const String fees = 'Fees';
  static const String pendingFees = 'Pending Fees';
  static const String paidFees = 'Paid Fees';
  static const String totalDue = 'Total Due';
  static const String totalPaid = 'Total Paid';
  static const String payNow = 'Pay Now';
  static const String feeDetails = 'Fee Details';

  // Payments
  static const String paymentHistory = 'Payment History';
  static const String paymentSuccess = 'Payment Successful';
  static const String paymentFailed = 'Payment Failed';
  static const String downloadReceipt = 'Download Receipt';
  static const String shareReceipt = 'Share Receipt';

  // Students
  static const String selectStudent = 'Select Student';
  static const String switchStudent = 'Switch Student';
  static const String yourChildren = 'Your Children';
  static const String noStudentsFound = 'No Students Found';

  // Notifications
  static const String notifications = 'Notifications';
  static const String noNotifications = 'No notifications yet';

  // Profile
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String myAccount = 'My Account';
  static const String helpSupport = 'Help & Support';
  static const String aboutApp = 'About App';

  // Common
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String loading = 'Loading...';
  static const String retry = 'Retry';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String next = 'Next';
  static const String skip = 'Skip';
  static const String getStarted = 'Get Started';

  // Onboarding
  static const String onboardingTitle1 = 'Easy School Fee Payments';
  static const String onboardingDesc1 =
      'Pay your child\'s school fees anytime, anywhere with just a few taps. No more standing in queues!';
  static const String onboardingTitle2 = 'Multiple Students';
  static const String onboardingDesc2 =
      'Manage fees for all your children from a single account. Switch between students effortlessly.';
  static const String onboardingTitle3 = 'Secure & Instant Receipts';
  static const String onboardingDesc3 =
      'Get instant payment confirmations and download receipts. Your transactions are 100% secure.';
}
