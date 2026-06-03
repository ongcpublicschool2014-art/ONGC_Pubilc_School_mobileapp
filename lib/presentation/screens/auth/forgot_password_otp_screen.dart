import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/app_colors.dart';
import '../../../config/routes.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_icon.dart';
import '../../widgets/common/auth_desktop_wrapper.dart';
import '../../widgets/common/screen_illustrations.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String mobile;

  const ForgotPasswordOtpScreen({
    super.key,
    required this.mobile,
  });

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends ConsumerState<ForgotPasswordOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  int _resendTimer = 30;
  Timer? _timer;
  bool _isOtpExpired = false; // Track if OTP has expired

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _isOtpExpired = false; // Reset expiry flag when new OTP is sent
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimer > 0) {
        setState(() => _resendTimer--);
      } else {
        timer.cancel();
        // OTP has expired - clear the input and mark as expired
        setState(() {
          _isOtpExpired = true;
          _otpController.clear();
        });
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    // Check if OTP has expired
    if (_isOtpExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP has expired. Please request a new OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use password reset OTP verification
      await ref.read(authProvider.notifier).verifyPasswordResetOtp(
        mobile: widget.mobile,
        otp: _otpController.text,
      );

      if (mounted) {
        // Navigate to reset password screen
        context.push(Routes.resetPassword, extra: widget.mobile);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (_resendTimer > 0) return;

    try {
      // Use password reset OTP request
      await ref.read(authProvider.notifier).requestPasswordResetOtp(
        mobile: widget.mobile,
      );
      _startResendTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg(context),
      body: AuthDesktopWrapper(
        headline: 'Verify Your Identity',
        subtitle: 'Enter the code sent to your phone',
        centerContent: ScreenIllustrations.otpVerification(size: 360, isDark: true),
        onBack: () => context.pop(),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Header with title and illustration
                        _buildHeader(),

                        const SizedBox(height: 32),

                        // OTP Input
                        _buildOtpInput(),

                        const SizedBox(height: 24),

                        // OTP Expired Warning
                        if (_isOtpExpired)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppIcon(
                                  'timer',
                                  size: 18,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'OTP has expired. Please request a new one.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Resend Timer
                        _buildResendTimer(),

                        const SizedBox(height: 32),

                        // Verify Button
                        _buildVerifyButton(),
                      ],
                    ),
                  ),
                ),
                ),
              ),
              // Back to Sign In Link at bottom
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _buildSignInLink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify OTP',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryC(context),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to\n+91 ${widget.mobile}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondaryC(context),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpInput() {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 56,
      textStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryC(context),
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderC(context)),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primary, width: 2),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.cardPurple,
        border: Border.all(color: AppColors.primary),
      ),
    );

    return Center(
      child: Pinput(
        controller: _otpController,
        length: 6,
        defaultPinTheme: defaultPinTheme,
        focusedPinTheme: focusedPinTheme,
        submittedPinTheme: submittedPinTheme,
        onCompleted: (_) => _handleVerifyOtp(),
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
      ),
    );
  }

  Widget _buildResendTimer() {
    return Center(
      child: _resendTimer > 0
          ? RichText(
              text: TextSpan(
                text: 'Resend OTP in ',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondaryC(context),
                ),
                children: [
                  TextSpan(
                    text: '${_resendTimer}s',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textLink,
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onTap: _handleResendOtp,
              child: Text(
                'Resend OTP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLink,
                ),
              ),
            ),
    );
  }

  Widget _buildVerifyButton() {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _isLoading
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFFD2913C).withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: _isLoading ? const Color(0xFFE8C896) : const Color(0xFFD2913C),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _isLoading ? null : _handleVerifyOtp,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.black.withValues(alpha: 0.06),
          focusColor: Colors.black.withValues(alpha: 0.10),
          splashColor: Colors.black.withValues(alpha: 0.22),
          highlightColor: Colors.black.withValues(alpha: 0.12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  const Text(
                    'Verify OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const AppIcon(
                    'tick-circle',
                    size: 22,
                    color: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password ?',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondaryC(context),
          ),
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => context.go(Routes.signIn),
          child: Text(
            'Sign In',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textLink,
            ),
          ),
        ),
      ],
    );
  }
}
