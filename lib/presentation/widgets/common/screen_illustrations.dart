import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'app_icon.dart';

/// Animated Flutter widget-based illustrations for screens.
/// Replaces GIF/PNG assets that fail to load on Flutter web.
class ScreenIllustrations {
  ScreenIllustrations._();

  // ── Sign In ──────────────────────────────────────────────────────
  static Widget signIn({double size = 120, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        if (!isDark) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(size: size * 0.90, color: AppColors.primary.withValues(alpha: 0.06), animation: anim),
              Container(
                width: size * 0.78, height: size * 0.78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
                    AppColors.primary.withValues(alpha: 0.10), AppColors.primary.withValues(alpha: 0.03),
                  ]),
                ),
              ),
              _FloatOffset(animation: anim, dy: 3.0, child: Container(
                width: size * 0.52, height: size * 0.62,
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(size * 0.07),
                  boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 6))],
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: size * 0.20, height: size * 0.20,
                    decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary600])),
                    child: AppIcon('profile-circle', size: size * 0.12, color: Colors.white)),
                  SizedBox(height: size * 0.04),
                  Container(width: size * 0.32, height: size * 0.03, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(size * 0.01))),
                  SizedBox(height: size * 0.025),
                  Container(width: size * 0.26, height: size * 0.03, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(size * 0.01))),
                  SizedBox(height: size * 0.04),
                  Container(width: size * 0.28, height: size * 0.05, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600]), borderRadius: BorderRadius.circular(size * 0.025))),
                ]),
              )),
              Positioned(left: size * 0.06, top: size * 0.12, child: _FloatOffset(animation: anim, dy: 4.0, phase: 0.3, child: Container(
                width: size * 0.14, height: size * 0.14,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                child: AppIcon('key', size: size * 0.07, color: AppColors.primary),
              ))),
              Positioned(right: size * 0.08, bottom: size * 0.10, child: _PulseBadge(animation: anim, size: size * 0.22, colors: const [Color(0xFF002147), Color(0xFF001834)], icon: 'login', iconSize: size * 0.11)),
            ],
          );
        }

        // ── Desktop dark panel: browser-style sign in ──
        const blue = Color(0xFF3B82F6);
        final bgRing = Colors.white.withValues(alpha: 0.08);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: bgRing, animation: anim),
            Container(width: size * 0.70, height: size * 0.70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04))),

            // Key card behind browser
            Positioned(left: size * 0.02, top: size * 0.10, child: _FloatOffset(animation: anim, dy: 3.0, phase: 0.3, child: Transform.rotate(angle: -0.10, child: Container(
              width: size * 0.28, height: size * 0.22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [blue, Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(size * 0.025),
                boxShadow: [BoxShadow(color: blue.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(-2, 6))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppIcon('key', size: size * 0.08, color: Colors.white),
                SizedBox(height: size * 0.006),
                Container(width: size * 0.12, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              ]),
            )))),

            // Browser window
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(children: [
                // Green header
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary600])),
                  child: Center(child: AppIcon('profile-circle', size: size * 0.025, color: Colors.white))),
                SizedBox(height: size * 0.02),
                // Avatar
                Container(width: size * 0.06, height: size * 0.06, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600])),
                  child: AppIcon('profile-circle', size: size * 0.035, color: Colors.white)),
                SizedBox(height: size * 0.015),
                // Username field
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.024, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(size * 0.006))),
                SizedBox(height: size * 0.01),
                // Password field
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.024, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(size * 0.006))),
                const Spacer(),
                // Sign in button
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.015),
              ]),
            ))),

            // Lock badge top-left
            Positioned(left: size * 0.04, top: size * 0.06, child: _FloatOffset(animation: anim, dy: 3.5, phase: 0.5, child: _PulseBadge(
              animation: anim, size: size * 0.12, colors: const [blue, Color(0xFF2563EB)], icon: 'lock', iconSize: size * 0.06, borderColor: Colors.white,
            ))),

            // Login badge bottom-right
            Positioned(right: size * 0.04, bottom: size * 0.10, child: _PulseBadge(
              animation: anim, size: size * 0.11, colors: const [Color(0xFF002147), Color(0xFF001834)], icon: 'login', iconSize: size * 0.055, borderColor: Colors.white,
            )),

            // Sparkle
            Positioned(right: size * 0.18, top: size * 0.04, child: _FloatOffset(animation: anim, dy: 2.0, phase: 0.8, child: AppIcon('star', size: size * 0.03, color: Colors.white.withValues(alpha: 0.3)))),
          ],
        );
      },
    );
  }

  // ── Sign Up ──────────────────────────────────────────────────────
  static Widget signUp({double size = 120, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        if (!isDark) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(size: size * 0.90, color: const Color(0xFF002147).withValues(alpha: 0.06), animation: anim),
              Container(width: size * 0.78, height: size * 0.78, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFF002147).withValues(alpha: 0.10), const Color(0xFF002147).withValues(alpha: 0.03)]))),
              _FloatOffset(animation: anim, dy: 3.0, child: Container(
                width: size * 0.52, height: size * 0.62,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.07), boxShadow: [BoxShadow(color: const Color(0xFF002147).withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 6))]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: size * 0.20, height: size * 0.20, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF002147).withValues(alpha: 0.12)), child: AppIcon('user-add', size: size * 0.12, color: const Color(0xFF001834))),
                  SizedBox(height: size * 0.035),
                  for (int i = 0; i < 3; i++) ...[
                    Container(width: i < 2 ? size * 0.32 : size * 0.26, height: size * 0.028, decoration: BoxDecoration(color: AppColors.gray200, borderRadius: BorderRadius.circular(size * 0.01))),
                    if (i < 2) SizedBox(height: size * 0.022),
                  ],
                  SizedBox(height: size * 0.035),
                  Container(width: size * 0.28, height: size * 0.05, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF002147), Color(0xFF001834)]), borderRadius: BorderRadius.circular(size * 0.025))),
                ]),
              )),
              Positioned(right: size * 0.06, top: size * 0.12, child: _FloatOffset(animation: anim, dy: 3.5, phase: 0.5, child: Container(
                width: size * 0.14, height: size * 0.14,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                child: AppIcon('shield', size: size * 0.07, color: const Color(0xFF002147)),
              ))),
              Positioned(right: size * 0.10, bottom: size * 0.10, child: _PulseBadge(animation: anim, size: size * 0.22, colors: const [Color(0xFF002147), Color(0xFF001834)], icon: 'add', iconSize: size * 0.13)),
            ],
          );
        }

        // ── Desktop dark panel: browser-style sign up ──
        const teal = Color(0xFF14B8A6);
        const deepTeal = Color(0xFF0D9488);
        final bgRing = Colors.white.withValues(alpha: 0.08);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: bgRing, animation: anim),
            Container(width: size * 0.70, height: size * 0.70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04))),

            // Shield card behind browser
            Positioned(right: size * 0.02, top: size * 0.10, child: _FloatOffset(animation: anim, dy: 3.0, phase: 0.3, child: Container(
              width: size * 0.24, height: size * 0.26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF002147), Color(0xFF001834)]),
                borderRadius: BorderRadius.circular(size * 0.025),
                boxShadow: [BoxShadow(color: const Color(0xFF002147).withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(2, 6))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppIcon('shield', size: size * 0.08, color: Colors.white),
                SizedBox(height: size * 0.006),
                AppIcon('tick-circle', size: size * 0.04, color: Colors.white.withValues(alpha: 0.7)),
              ]),
            ))),

            // Browser window
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [teal, deepTeal])),
                  child: Center(child: AppIcon('user-add', size: size * 0.025, color: Colors.white))),
                SizedBox(height: size * 0.015),
                for (int i = 0; i < 3; i++) ...[
                  Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.022, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(size * 0.006))),
                  SizedBox(height: size * 0.008),
                ],
                const Spacer(),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [teal, deepTeal]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.015),
              ]),
            ))),

            // Person-add badge top-left
            Positioned(left: size * 0.04, top: size * 0.06, child: _FloatOffset(animation: anim, dy: 3.5, phase: 0.5, child: _PulseBadge(
              animation: anim, size: size * 0.12, colors: const [teal, deepTeal], icon: 'user-add', iconSize: size * 0.06, borderColor: Colors.white,
            ))),

            // Check badge bottom-right
            Positioned(right: size * 0.04, bottom: size * 0.10, child: _PulseBadge(
              animation: anim, size: size * 0.11, colors: const [Color(0xFF002147), Color(0xFF001834)], icon: 'tick-circle', iconSize: size * 0.055, borderColor: Colors.white,
            )),

            // Sparkle
            Positioned(left: size * 0.18, bottom: size * 0.06, child: _FloatOffset(animation: anim, dy: 1.5, phase: 0.1, child: AppIcon('star', size: size * 0.03, color: Colors.white.withValues(alpha: 0.3)))),
          ],
        );
      },
    );
  }

  // ── OTP Verification ─────────────────────────────────────────────
  static Widget otpVerification({double size = 120, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        if (!isDark) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(size: size * 0.90, color: AppColors.primary.withValues(alpha: 0.06), animation: anim),
              Container(width: size * 0.78, height: size * 0.78, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary.withValues(alpha: 0.10), AppColors.primary.withValues(alpha: 0.03)]))),
              _FloatOffset(animation: anim, dy: 3.5, child: Container(
                width: size * 0.38, height: size * 0.62,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(size * 0.055), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.14), blurRadius: 18, offset: const Offset(0, 6))]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AppIcon('sms', size: size * 0.08, color: AppColors.primary.withValues(alpha: 0.4)),
                  SizedBox(height: size * 0.03),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(
                    margin: EdgeInsets.symmetric(horizontal: size * 0.008), width: size * 0.055, height: size * 0.065,
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.06), border: Border.all(color: i < 3 ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2), width: 1.5), borderRadius: BorderRadius.circular(4)),
                    child: Center(child: i < 3 ? Text('${i + 3}', style: TextStyle(fontSize: size * 0.032, fontWeight: FontWeight.w700, color: AppColors.primary)) : Container(width: size * 0.015, height: size * 0.002, color: AppColors.primary.withValues(alpha: 0.3))),
                  ))),
                  SizedBox(height: size * 0.035),
                  Container(width: size * 0.22, height: size * 0.04, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600]), borderRadius: BorderRadius.circular(size * 0.02))),
                ]),
              )),
              Positioned(left: size * 0.06, top: size * 0.14, child: _FloatOffset(animation: anim, dy: 4.0, phase: 0.4, child: Container(
                width: size * 0.15, height: size * 0.15,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                child: AppIcon('sms-tracking', size: size * 0.075, color: AppColors.primary),
              ))),
              Positioned(right: size * 0.08, bottom: size * 0.10, child: _PulseBadge(animation: anim, size: size * 0.24, colors: const [AppColors.primary, AppColors.primary600], icon: 'verify', iconSize: size * 0.12)),
            ],
          );
        }

        // ── Desktop dark panel: browser-style OTP ──
        const indigo = Color(0xFF6366F1);
        const deepIndigo = Color(0xFF4F46E5);
        final bgRing = Colors.white.withValues(alpha: 0.08);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: bgRing, animation: anim),
            Container(width: size * 0.70, height: size * 0.70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04))),

            // Envelope card behind browser
            Positioned(left: size * 0.02, top: size * 0.10, child: _FloatOffset(animation: anim, dy: 3.0, phase: 0.3, child: Transform.rotate(angle: -0.10, child: Container(
              width: size * 0.28, height: size * 0.22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [indigo, deepIndigo]),
                borderRadius: BorderRadius.circular(size * 0.025),
                boxShadow: [BoxShadow(color: indigo.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(-2, 6))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppIcon('sms-tracking', size: size * 0.08, color: Colors.white),
                SizedBox(height: size * 0.006),
                Container(width: size * 0.12, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              ]),
            )))),

            // Browser window
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [indigo, deepIndigo])),
                  child: Center(child: AppIcon('sms', size: size * 0.025, color: Colors.white))),
                SizedBox(height: size * 0.02),
                // Lock circle
                Container(width: size * 0.05, height: size * 0.05, decoration: BoxDecoration(shape: BoxShape.circle, color: indigo.withValues(alpha: 0.10)),
                  child: AppIcon('lock', size: size * 0.025, color: indigo)),
                SizedBox(height: size * 0.015),
                // 4 OTP code boxes
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(
                  margin: EdgeInsets.symmetric(horizontal: size * 0.006),
                  width: size * 0.05, height: size * 0.045,
                  decoration: BoxDecoration(
                    color: i < 3 ? indigo.withValues(alpha: 0.08) : Colors.transparent,
                    border: Border.all(color: i < 3 ? indigo : const Color(0xFFCBD5E1), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(child: i < 3 ? Text('${i + 3}', style: TextStyle(fontSize: size * 0.02, fontWeight: FontWeight.w700, color: indigo)) : null),
                ))),
                const Spacer(),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [indigo, deepIndigo]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.015),
              ]),
            ))),

            // Verified badge top-left
            Positioned(left: size * 0.04, top: size * 0.06, child: _FloatOffset(animation: anim, dy: 3.5, phase: 0.5, child: _PulseBadge(
              animation: anim, size: size * 0.12, colors: const [indigo, deepIndigo], icon: 'verify', iconSize: size * 0.06, borderColor: Colors.white,
            ))),

            // Shield badge bottom-right
            Positioned(right: size * 0.04, bottom: size * 0.10, child: _PulseBadge(
              animation: anim, size: size * 0.11, colors: const [Color(0xFF002147), Color(0xFF001834)], icon: 'shield', iconSize: size * 0.055, borderColor: Colors.white,
            )),

            // Sparkle
            Positioned(right: size * 0.18, top: size * 0.04, child: _FloatOffset(animation: anim, dy: 2.0, phase: 0.8, child: AppIcon('star', size: size * 0.03, color: Colors.white.withValues(alpha: 0.3)))),
          ],
        );
      },
    );
  }

  // ── Set Password ─────────────────────────────────────────────────
  static Widget setPassword({double size = 100, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        if (!isDark) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(size: size * 0.88, color: AppColors.primary.withValues(alpha: 0.06), animation: anim),
              Container(width: size * 0.78, height: size * 0.78, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary.withValues(alpha: 0.10), AppColors.primary.withValues(alpha: 0.03)]))),
              Positioned(top: size * 0.10, child: Container(width: size * 0.28, height: size * 0.22, decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 0.14), border: Border.all(color: AppColors.primary, width: size * 0.032), color: Colors.transparent))),
              _FloatOffset(animation: anim, dy: 2.5, child: Container(
                width: size * 0.42, height: size * 0.36, margin: EdgeInsets.only(top: size * 0.10),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600]), borderRadius: BorderRadius.circular(size * 0.06), boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 16, offset: const Offset(0, 5))]),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AppIcon('lock', size: size * 0.16, color: Colors.white),
                  SizedBox(height: size * 0.02),
                  Container(width: size * 0.04, height: size * 0.06, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(size * 0.02))),
                ]),
              )),
              Positioned(right: size * 0.06, bottom: size * 0.08, child: _PulseBadge(animation: anim, size: size * 0.22, colors: const [Color(0xFFF59E0B), Color(0xFFD97706)], icon: 'key', iconSize: size * 0.11)),
              Positioned(right: size * 0.10, top: size * 0.06, child: _FloatOffset(animation: anim, dy: 3.0, phase: 0.6, child: AppIcon('star', size: size * 0.08, color: const Color(0xFFF59E0B).withValues(alpha: 0.5)))),
            ],
          );
        }

        // ── Desktop dark panel: browser-style set password ──
        const amber = Color(0xFFF59E0B);
        const deepAmber = Color(0xFFD97706);
        final bgRing = Colors.white.withValues(alpha: 0.08);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: bgRing, animation: anim),
            Container(width: size * 0.70, height: size * 0.70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04))),

            // Key card behind browser
            Positioned(right: size * 0.02, top: size * 0.10, child: _FloatOffset(animation: anim, dy: 3.0, phase: 0.3, child: Container(
              width: size * 0.24, height: size * 0.26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [amber, deepAmber]),
                borderRadius: BorderRadius.circular(size * 0.025),
                boxShadow: [BoxShadow(color: amber.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(2, 6))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppIcon('key', size: size * 0.08, color: Colors.white),
                SizedBox(height: size * 0.006),
                Container(width: size * 0.12, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              ]),
            ))),

            // Browser window
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary600])),
                  child: Center(child: AppIcon('lock', size: size * 0.025, color: Colors.white))),
                SizedBox(height: size * 0.015),
                AppIcon('lock', size: size * 0.04, color: AppColors.primary),
                SizedBox(height: size * 0.012),
                // Password field
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.024, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(size * 0.006))),
                SizedBox(height: size * 0.008),
                // Confirm field
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.024, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(size * 0.006))),
                SizedBox(height: size * 0.008),
                // Strength bar
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.007,
                  child: Row(children: [
                    Expanded(flex: 3, child: Container(decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)))),
                    SizedBox(width: size * 0.004),
                    Expanded(flex: 1, child: Container(decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                  ]),
                ),
                const Spacer(),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.015),
              ]),
            ))),

            // Shield badge top-left
            Positioned(left: size * 0.04, top: size * 0.06, child: _FloatOffset(animation: anim, dy: 3.5, phase: 0.5, child: _PulseBadge(
              animation: anim, size: size * 0.12, colors: const [AppColors.primary, AppColors.primary600], icon: 'shield', iconSize: size * 0.06, borderColor: Colors.white,
            ))),

            // Star badge bottom-right
            Positioned(right: size * 0.04, bottom: size * 0.10, child: _PulseBadge(
              animation: anim, size: size * 0.11, colors: const [amber, deepAmber], icon: 'star', iconSize: size * 0.055, borderColor: Colors.white,
            )),

            // Sparkle
            Positioned(left: size * 0.18, bottom: size * 0.06, child: _FloatOffset(animation: anim, dy: 1.5, phase: 0.1, child: AppIcon('star', size: size * 0.03, color: Colors.white.withValues(alpha: 0.3)))),
          ],
        );
      },
    );
  }

  // ── Forgot Password ──────────────────────────────────────────────
  static Widget forgotPassword({double size = 120, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        if (!isDark) {
          return Stack(
            alignment: Alignment.center,
            children: [
              _PulseRing(size: size * 0.90, color: const Color(0xFFF59E0B).withValues(alpha: 0.06), animation: anim),
              Container(width: size * 0.78, height: size * 0.78, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [const Color(0xFFF59E0B).withValues(alpha: 0.10), const Color(0xFFF59E0B).withValues(alpha: 0.03)]))),
              _FloatOffset(animation: anim, dy: 3.0, child: Container(
                width: size * 0.48, height: size * 0.48,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]), boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.28), blurRadius: 20, offset: const Offset(0, 8))]),
                child: AppIcon('message-question', size: size * 0.26, color: Colors.white),
              )),
              Positioned(left: size * 0.08, top: size * 0.14, child: _FloatOffset(animation: anim, dy: 3.5, phase: 0.3, child: Container(
                width: size * 0.14, height: size * 0.14,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))]),
                child: AppIcon('unlock', size: size * 0.07, color: const Color(0xFFF59E0B)),
              ))),
              Positioned(right: size * 0.06, bottom: size * 0.10, child: _SpinBadge(animation: anim, size: size * 0.24, colors: const [AppColors.primary, AppColors.primary600], icon: 'refresh', iconSize: size * 0.12)),
            ],
          );
        }

        // ── Desktop dark panel: browser-style forgot password ──
        const orange = Color(0xFFF97316);
        const deepOrange = Color(0xFFEA580C);
        final bgRing = Colors.white.withValues(alpha: 0.08);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: bgRing, animation: anim),
            Container(width: size * 0.70, height: size * 0.70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04))),

            // Lock-open card behind browser
            Positioned(left: size * 0.02, top: size * 0.10, child: _FloatOffset(animation: anim, dy: 3.0, phase: 0.3, child: Transform.rotate(angle: -0.10, child: Container(
              width: size * 0.28, height: size * 0.22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [orange, deepOrange]),
                borderRadius: BorderRadius.circular(size * 0.025),
                boxShadow: [BoxShadow(color: orange.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(-2, 6))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppIcon('unlock', size: size * 0.08, color: Colors.white),
                SizedBox(height: size * 0.006),
                Container(width: size * 0.12, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              ]),
            )))),

            // Browser window
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [orange, deepOrange])),
                  child: Center(child: AppIcon('message-question', size: size * 0.025, color: Colors.white))),
                SizedBox(height: size * 0.02),
                // Question mark icon
                Container(width: size * 0.06, height: size * 0.06, decoration: BoxDecoration(shape: BoxShape.circle, color: orange.withValues(alpha: 0.10)),
                  child: AppIcon('message-question', size: size * 0.035, color: orange)),
                SizedBox(height: size * 0.015),
                // Email field
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.024, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(size * 0.006))),
                const Spacer(),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [orange, deepOrange]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.015),
              ]),
            ))),

            // Email badge top-left
            Positioned(left: size * 0.04, top: size * 0.06, child: _FloatOffset(animation: anim, dy: 3.5, phase: 0.5, child: _PulseBadge(
              animation: anim, size: size * 0.12, colors: const [orange, deepOrange], icon: 'sms', iconSize: size * 0.06, borderColor: Colors.white,
            ))),

            // Refresh spin badge bottom-right
            Positioned(right: size * 0.04, bottom: size * 0.10, child: _SpinBadge(
              animation: anim, size: size * 0.11, colors: const [AppColors.primary, AppColors.primary600], icon: 'refresh', iconSize: size * 0.055,
            )),

            // Sparkle
            Positioned(right: size * 0.18, top: size * 0.04, child: _FloatOffset(animation: anim, dy: 2.0, phase: 0.8, child: AppIcon('star', size: size * 0.03, color: Colors.white.withValues(alpha: 0.3)))),
          ],
        );
      },
    );
  }

  // ── Student Selection ────────────────────────────────────────────
  static Widget studentSelection({double size = 120, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      heightFactor: isDark ? 1.0 : 0.85,
      builder: (size, anim) {
        if (!isDark) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(width: size * 0.88, height: size * 0.72, decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 0.10), gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primary.withValues(alpha: 0.07), AppColors.primary.withValues(alpha: 0.02)]))),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _FloatOffset(animation: anim, dy: 3.0, phase: 0.0, child: _avatar(size * 0.26, const Color(0xFF8B5CF6))),
                SizedBox(width: size * 0.02),
                _FloatOffset(animation: anim, dy: 4.0, phase: 0.33, child: _avatar(size * 0.33, AppColors.primary)),
                SizedBox(width: size * 0.02),
                _FloatOffset(animation: anim, dy: 3.0, phase: 0.66, child: _avatar(size * 0.26, const Color(0xFF002147))),
              ]),
              Positioned(right: size * 0.06, bottom: size * 0.04, child: _PulseBadge(animation: anim, size: size * 0.19, colors: const [Color(0xFF002147), Color(0xFF001834)], icon: 'tick-circle', iconSize: size * 0.10)),
            ],
          );
        }

        // ── Desktop dark panel: browser-style student selection ──
        const purple = Color(0xFF8B5CF6);
        const deepPurple = Color(0xFF7C3AED);
        final bgRing = Colors.white.withValues(alpha: 0.08);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: bgRing, animation: anim),
            Container(width: size * 0.70, height: size * 0.70, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.04))),

            // School card behind browser
            Positioned(right: size * 0.02, top: size * 0.10, child: _FloatOffset(animation: anim, dy: 3.0, phase: 0.3, child: Container(
              width: size * 0.24, height: size * 0.26,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [purple, deepPurple]),
                borderRadius: BorderRadius.circular(size * 0.025),
                boxShadow: [BoxShadow(color: purple.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(2, 6))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppIcon('book', size: size * 0.08, color: Colors.white),
                SizedBox(height: size * 0.006),
                Container(width: size * 0.12, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              ]),
            ))),

            // Browser window
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [purple, deepPurple])),
                  child: Center(child: AppIcon('people', size: size * 0.025, color: Colors.white))),
                SizedBox(height: size * 0.01),
                // 3 student rows
                for (int i = 0; i < 3; i++) ...[
                  Padding(padding: EdgeInsets.symmetric(horizontal: size * 0.02), child: Container(
                    padding: EdgeInsets.all(size * 0.007),
                    decoration: BoxDecoration(
                      color: i == 0 ? purple.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(size * 0.008),
                      border: i == 0 ? Border.all(color: purple.withValues(alpha: 0.2), width: 1) : null,
                    ),
                    child: Row(children: [
                      Container(width: size * 0.03, height: size * 0.03, decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: [
                          [purple, const Color(0xFF002147), const Color(0xFF3B82F6)][i],
                          [deepPurple, const Color(0xFF001834), const Color(0xFF2563EB)][i],
                        ]),
                      ), child: AppIcon('profile-circle', size: size * 0.015, color: Colors.white)),
                      SizedBox(width: size * 0.008),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: size * 0.10 - (i * size * 0.01), height: size * 0.005, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(1))),
                        SizedBox(height: size * 0.003),
                        Container(width: size * 0.07, height: size * 0.004, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(1))),
                      ])),
                      if (i == 0) AppIcon('tick-circle', size: size * 0.018, color: purple),
                    ]),
                  )),
                  SizedBox(height: size * 0.006),
                ],
                const Spacer(),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.04), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [purple, deepPurple]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.015),
              ]),
            ))),

            // People badge top-left
            Positioned(left: size * 0.04, top: size * 0.06, child: _FloatOffset(animation: anim, dy: 3.5, phase: 0.5, child: _PulseBadge(
              animation: anim, size: size * 0.12, colors: const [purple, deepPurple], icon: 'people', iconSize: size * 0.06, borderColor: Colors.white,
            ))),

            // Check badge bottom-right
            Positioned(right: size * 0.04, bottom: size * 0.10, child: _PulseBadge(
              animation: anim, size: size * 0.11, colors: const [Color(0xFF002147), Color(0xFF001834)], icon: 'tick-circle', iconSize: size * 0.055, borderColor: Colors.white,
            )),

            // Sparkle
            Positioned(left: size * 0.18, bottom: size * 0.06, child: _FloatOffset(animation: anim, dy: 1.5, phase: 0.1, child: AppIcon('star', size: size * 0.03, color: Colors.white.withValues(alpha: 0.3)))),
          ],
        );
      },
    );
  }

  // ── Welcome (light – mobile) ─────────────────────────────────────
  static Widget welcome({double size = 180}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing ring
          _PulseRing(size: size * 0.92, color: AppColors.primary.withValues(alpha: 0.06), animation: anim),
          Container(
            width: size * 0.78,
            height: size * 0.78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.08), width: 2),
            ),
          ),
          Container(
            width: size * 0.64,
            height: size * 0.64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.05),
            ),
          ),
          // Center icon — floating
          _FloatOffset(
            animation: anim,
            dy: 4.0,
            child: Container(
              width: size * 0.44,
              height: size * 0.44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600]),
                boxShadow: [
                  BoxShadow(color: AppColors.primary.withValues(alpha: 0.32), blurRadius: 24, offset: const Offset(0, 10)),
                ],
              ),
              child: AppIcon('book', size: size * 0.22, color: Colors.white),
            ),
          ),
          // Rupee badge bottom-right
          Positioned(
            right: size * 0.07,
            bottom: size * 0.14,
            child: _PulseBadge(
              animation: anim,
              size: size * 0.20,
              colors: const [Color(0xFF002147), Color(0xFF001834)],
              icon: 'empty-wallet',
              iconSize: size * 0.10,
            ),
          ),
          // Verified icon top-left
          Positioned(
            left: size * 0.08,
            top: size * 0.12,
            child: _FloatOffset(
              animation: anim,
              dy: 3.5,
              phase: 0.5,
              child: Container(
                width: size * 0.16,
                height: size * 0.16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: AppIcon('verify', size: size * 0.09, color: AppColors.primary),
              ),
            ),
          ),
          // Receipt icon top-right
          Positioned(
            right: size * 0.10,
            top: size * 0.10,
            child: _FloatOffset(
              animation: anim,
              dy: 2.5,
              phase: 0.25,
              child: Container(
                width: size * 0.12,
                height: size * 0.12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: AppIcon('receipt-text', size: size * 0.06, color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Welcome (dark panel – desktop) ───────────────────────────────
  static Widget welcomeDark({double size = 240}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        const goldAccent = Color(0xFFFBBF24);
        const blue = Color(0xFF3B82F6);
        const purple = Color(0xFF8B5CF6);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: Colors.white.withValues(alpha: 0.08), animation: anim),
            Container(
              width: size * 0.70,
              height: size * 0.70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),

            // ── School building card behind browser ──
            Positioned(left: size * 0.02, top: size * 0.08, child: _FloatOffset(animation: anim, dy: 3.0, phase: 0.3, child: Transform.rotate(angle: -0.10, child: Container(
              width: size * 0.28, height: size * 0.22,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [blue, Color(0xFF2563EB)]),
                borderRadius: BorderRadius.circular(size * 0.025),
                boxShadow: [BoxShadow(color: blue.withValues(alpha: 0.30), blurRadius: 16, offset: const Offset(-2, 6))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                AppIcon('book', size: size * 0.08, color: Colors.white),
                SizedBox(height: size * 0.006),
                Container(width: size * 0.12, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              ]),
            )))),

            // ── Browser window (main center) ──
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary600])),
                  child: Center(child: AppIcon('book', size: size * 0.025, color: Colors.white))),
                SizedBox(height: size * 0.015),
                // Welcome text
                Container(width: size * 0.16, height: size * 0.008, decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(2))),
                SizedBox(height: size * 0.008),
                Container(width: size * 0.10, height: size * 0.005, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(1))),
                SizedBox(height: size * 0.018),
                // Feature icons row
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final color in [AppColors.primary, blue, goldAccent]) ...[
                    Container(width: size * 0.04, height: size * 0.04, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.12)),
                      child: AppIcon(color == AppColors.primary ? 'wallet-3' : color == blue ? 'receipt-text' : 'notification', size: size * 0.018, color: color)),
                    SizedBox(width: size * 0.008),
                  ],
                ]),
                const Spacer(),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.04), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.008),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.04), height: size * 0.03, decoration: BoxDecoration(borderRadius: BorderRadius.circular(size * 0.012), border: Border.all(color: const Color(0xFFE2E8F0), width: 1))),
                SizedBox(height: size * 0.012),
              ]),
            ))),

            // ── Gold rupee badge top-left ──
            Positioned(
              left: size * 0.06,
              top: size * 0.06,
              child: _FloatOffset(
                animation: anim,
                dy: 3.5,
                phase: 0.5,
                child: _PulseBadge(
                  animation: anim,
                  size: size * 0.12,
                  colors: const [goldAccent, Color(0xFFF59E0B)],
                  icon: 'empty-wallet',
                  iconSize: size * 0.06,
                  borderColor: Colors.white,
                ),
              ),
            ),

            // ── Purple receipt badge top-right ──
            Positioned(
              right: size * 0.08,
              top: size * 0.08,
              child: _FloatOffset(
                animation: anim,
                dy: 2.5,
                phase: 0.2,
                child: Container(
                  width: size * 0.09,
                  height: size * 0.09,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [purple, Color(0xFF7C3AED)]),
                    boxShadow: [
                      BoxShadow(color: purple.withValues(alpha: 0.30), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: AppIcon('receipt-text', size: size * 0.045, color: Colors.white),
                ),
              ),
            ),

            // ── Verified badge bottom-right ──
            Positioned(
              right: size * 0.06,
              bottom: size * 0.12,
              child: _PulseBadge(
                animation: anim,
                size: size * 0.11,
                colors: const [Color(0xFF002147), Color(0xFF001834)],
                icon: 'verify',
                iconSize: size * 0.055,
                borderColor: Colors.white,
              ),
            ),

            // Sparkle
            Positioned(
              left: size * 0.20,
              bottom: size * 0.06,
              child: _FloatOffset(
                animation: anim,
                dy: 1.5,
                phase: 0.1,
                child: AppIcon('star', size: size * 0.03,
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Onboarding 1: Payment ────────────────────────────────────────
  static Widget onboardPayment({double size = 300, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        // Colors based on panel
        final phoneScreen = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC);
        final cardGrad1 = isDark ? const Color(0xFF1E3A5F) : const Color(0xFF1E293B);
        final cardGrad2 = isDark ? const Color(0xFF3B82F6) : const Color(0xFF334155);
        const goldAccent = Color(0xFFFBBF24);
        const successGreen = Color(0xFF002147);
        final bgRingColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.06);

        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer pulsing ring
            _PulseRing(size: size * 0.82, color: bgRingColor, animation: anim),

            // Soft bg circle
            Container(
              width: size * 0.70,
              height: size * 0.70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.primary.withValues(alpha: 0.04),
              ),
            ),

            // ── Credit card (behind browser, tilted) ──
            Positioned(
              left: size * 0.02,
              top: size * 0.08,
              child: _FloatOffset(
                animation: anim, dy: 3.0, phase: 0.3,
                child: Transform.rotate(angle: -0.12, child: Container(
                  width: size * 0.32, height: size * 0.20,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [cardGrad1, cardGrad2]),
                    borderRadius: BorderRadius.circular(size * 0.025),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(-2, 6))],
                  ),
                  child: Padding(padding: EdgeInsets.all(size * 0.02), child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(width: size * 0.03, height: size * 0.022, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFE5C07B), Color(0xFFD4A259)]), borderRadius: BorderRadius.circular(2))),
                        const Spacer(),
                        AppIcon('wifi', size: size * 0.025, color: Colors.white.withValues(alpha: 0.5)),
                      ]),
                      const Spacer(),
                      Row(children: List.generate(4, (g) => Padding(
                        padding: EdgeInsets.only(right: size * 0.01),
                        child: Row(children: List.generate(4, (_) => Container(
                          margin: EdgeInsets.only(right: size * 0.003), width: size * 0.007, height: size * 0.007,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: g == 3 ? 0.8 : 0.35)),
                        ))),
                      ))),
                      SizedBox(height: size * 0.01),
                      Row(children: [
                        Container(width: size * 0.06, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(1))),
                        const Spacer(),
                        Container(width: size * 0.03, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(1))),
                      ]),
                    ],
                  )),
                )),
              ),
            ),

            // ── Browser window (main center element) ──
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: phoneScreen,
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary600])),
                  child: Center(child: Container(width: size * 0.10, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))))),
                SizedBox(height: size * 0.018),
                // Amount
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AppIcon('empty-wallet', size: size * 0.03, color: const Color(0xFF1F2937)),
                  Container(width: size * 0.06, height: size * 0.012, decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(2))),
                ]),
                SizedBox(height: size * 0.012),
                Container(width: size * 0.25, height: 1, color: const Color(0xFFE2E8F0)),
                SizedBox(height: size * 0.012),
                // Fee rows
                for (int i = 0; i < 3; i++) ...[
                  Padding(padding: EdgeInsets.symmetric(horizontal: size * 0.03), child: Row(children: [
                    Container(width: size * 0.012, height: size * 0.012, decoration: BoxDecoration(shape: BoxShape.circle, color: [AppColors.primary, const Color(0xFF3B82F6), const Color(0xFFF59E0B)][i].withValues(alpha: 0.15))),
                    SizedBox(width: size * 0.008),
                    Container(width: size * 0.08 + (i * size * 0.01), height: size * 0.005, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(1))),
                    const Spacer(),
                    Container(width: size * 0.04, height: size * 0.005, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(1))),
                  ])),
                  SizedBox(height: size * 0.008),
                ],
                const Spacer(),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.04), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primary600]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.015),
              ]),
            ))),

            // ── Gold coin top-left ──
            Positioned(
              left: size * 0.06,
              top: size * 0.06,
              child: _FloatOffset(
                animation: anim,
                dy: 3.5,
                phase: 0.5,
                child: Container(
                  width: size * 0.11,
                  height: size * 0.11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [goldAccent, goldAccent.withValues(alpha: 0.8)],
                    ),
                    border: Border.all(color: const Color(0xFFE5A600), width: 2),
                    boxShadow: [
                      BoxShadow(color: goldAccent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: AppIcon('empty-wallet', size: size * 0.055, color: Colors.white),
                ),
              ),
            ),

            // ── Small gold coin top-right ──
            Positioned(
              right: size * 0.08,
              top: size * 0.10,
              child: _FloatOffset(
                animation: anim,
                dy: 2.5,
                phase: 0.2,
                child: Container(
                  width: size * 0.07,
                  height: size * 0.07,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [goldAccent, goldAccent.withValues(alpha: 0.7)],
                    ),
                    border: Border.all(color: const Color(0xFFE5A600), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: goldAccent.withValues(alpha: 0.25), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: AppIcon('empty-wallet', size: size * 0.032, color: Colors.white),
                ),
              ),
            ),

            // ── Success checkmark badge bottom-right ──
            Positioned(
              right: size * 0.06,
              bottom: size * 0.12,
              child: _PulseBadge(
                animation: anim,
                size: size * 0.14,
                colors: const [successGreen, Color(0xFF001834)],
                icon: 'tick-circle',
                iconSize: size * 0.07,
                borderColor: Colors.white,
              ),
            ),

            // ── Receipt floating bottom-left ──
            Positioned(
              left: size * 0.08,
              bottom: size * 0.14,
              child: _FloatOffset(
                animation: anim,
                dy: 3.0,
                phase: 0.7,
                child: Container(
                  width: size * 0.10,
                  height: size * 0.12,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.90) : Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.012),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: size * 0.06,
                        height: size * 0.004,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      SizedBox(height: size * 0.006),
                      Container(
                        width: size * 0.045,
                        height: size * 0.004,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      SizedBox(height: size * 0.006),
                      AppIcon('tick-circle', size: size * 0.03, color: successGreen),
                    ],
                  ),
                ),
              ),
            ),

            // ── Sparkles ──
            Positioned(
              right: size * 0.18,
              top: size * 0.04,
              child: _FloatOffset(
                animation: anim,
                dy: 2.0,
                phase: 0.8,
                child: AppIcon('star', size: size * 0.04,
                    color: isDark ? goldAccent.withValues(alpha: 0.6) : AppColors.primary.withValues(alpha: 0.3)),
              ),
            ),
            Positioned(
              left: size * 0.22,
              bottom: size * 0.06,
              child: _FloatOffset(
                animation: anim,
                dy: 1.5,
                phase: 0.1,
                child: AppIcon('star', size: size * 0.03,
                    color: isDark ? Colors.white.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Onboarding 2: Security ───────────────────────────────────────
  static Widget onboardSecurity({double size = 300, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        const purple = Color(0xFF8B5CF6);
        const deepPurple = Color(0xFF6D28D9);
        const teal = Color(0xFF14B8A6);
        final bgRingColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFF002147).withValues(alpha: 0.06);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: bgRingColor, animation: anim),
            Container(
              width: size * 0.70,
              height: size * 0.70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFF002147).withValues(alpha: 0.04),
              ),
            ),

            // ── Shield behind browser ──
            Positioned(
              left: size * 0.02,
              top: size * 0.08,
              child: _FloatOffset(
                animation: anim,
                dy: 3.0,
                phase: 0.3,
                child: Container(
                  width: size * 0.26,
                  height: size * 0.30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [purple, deepPurple],
                    ),
                    borderRadius: BorderRadius.circular(size * 0.04),
                    boxShadow: [
                      BoxShadow(
                        color: purple.withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(-2, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon('shield', size: size * 0.12, color: Colors.white),
                      SizedBox(height: size * 0.012),
                      AppIcon('tick-circle', size: size * 0.06, color: Colors.white.withValues(alpha: 0.7)),
                    ],
                  ),
                ),
              ),
            ),

            // ── Browser window (main center) ──
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [purple, deepPurple])),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AppIcon('shield-tick', size: size * 0.022, color: Colors.white.withValues(alpha: 0.8)),
                    SizedBox(width: size * 0.008),
                    Container(width: size * 0.07, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                  ])),
                SizedBox(height: size * 0.018),
                Container(width: size * 0.07, height: size * 0.07, decoration: BoxDecoration(shape: BoxShape.circle, color: purple.withValues(alpha: 0.10)),
                  child: AppIcon('lock', size: size * 0.035, color: purple)),
                SizedBox(height: size * 0.012),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(
                  margin: EdgeInsets.symmetric(horizontal: size * 0.006),
                  width: size * 0.05, height: size * 0.045,
                  decoration: BoxDecoration(
                    color: i < 2 ? purple.withValues(alpha: 0.08) : Colors.transparent,
                    border: Border.all(color: i < 2 ? purple : const Color(0xFFD1D5DB), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(child: i < 2 ? Container(width: size * 0.01, height: size * 0.01, decoration: const BoxDecoration(shape: BoxShape.circle, color: purple)) : null),
                ))),
                const Spacer(),
                Container(margin: EdgeInsets.symmetric(horizontal: size * 0.06), height: size * 0.03, decoration: BoxDecoration(gradient: const LinearGradient(colors: [purple, deepPurple]), borderRadius: BorderRadius.circular(size * 0.012))),
                SizedBox(height: size * 0.015),
              ]),
            ))),

            // ── Lock badge top-right ──
            Positioned(
              right: size * 0.06,
              top: size * 0.08,
              child: _FloatOffset(
                animation: anim,
                dy: 3.5,
                phase: 0.5,
                child: _PulseBadge(
                  animation: anim,
                  size: size * 0.12,
                  colors: const [purple, deepPurple],
                  icon: 'lock',
                  iconSize: size * 0.06,
                  borderColor: Colors.white,
                ),
              ),
            ),

            // ── Fingerprint badge bottom-left ──
            Positioned(
              left: size * 0.06,
              bottom: size * 0.10,
              child: _FloatOffset(
                animation: anim,
                dy: 3.0,
                phase: 0.7,
                child: Container(
                  width: size * 0.11,
                  height: size * 0.11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [teal, teal.withValues(alpha: 0.8)]),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: teal.withValues(alpha: 0.30), blurRadius: 8, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: AppIcon('finger-scan', size: size * 0.055, color: Colors.white),
                ),
              ),
            ),

            // ── Key badge bottom-right ──
            Positioned(
              right: size * 0.08,
              bottom: size * 0.14,
              child: _FloatOffset(
                animation: anim,
                dy: 2.5,
                phase: 0.2,
                child: Container(
                  width: size * 0.08,
                  height: size * 0.08,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white.withValues(alpha: 0.90) : Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: AppIcon('key', size: size * 0.04, color: purple),
                ),
              ),
            ),

            // Sparkle
            Positioned(
              right: size * 0.20,
              top: size * 0.04,
              child: _FloatOffset(
                animation: anim,
                dy: 2.0,
                phase: 0.8,
                child: AppIcon('star', size: size * 0.035,
                    color: isDark ? purple.withValues(alpha: 0.5) : teal.withValues(alpha: 0.3)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Onboarding 3: Notifications ──────────────────────────────────
  static Widget onboardNotifications({double size = 300, bool isDark = false}) {
    return _AnimatedIllustration(
      size: size,
      builder: (size, anim) {
        const amber = Color(0xFFF59E0B);
        const deepAmber = Color(0xFFD97706);
        const red = Color(0xFFEF4444);
        final bgRingColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : amber.withValues(alpha: 0.06);

        return Stack(
          alignment: Alignment.center,
          children: [
            _PulseRing(size: size * 0.82, color: bgRingColor, animation: anim),
            Container(
              width: size * 0.70,
              height: size * 0.70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : amber.withValues(alpha: 0.04),
              ),
            ),

            // ── Bell card behind browser ──
            Positioned(
              right: size * 0.02,
              top: size * 0.08,
              child: _FloatOffset(
                animation: anim,
                dy: 3.0,
                phase: 0.3,
                child: Container(
                  width: size * 0.24,
                  height: size * 0.28,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [amber, deepAmber],
                    ),
                    borderRadius: BorderRadius.circular(size * 0.035),
                    boxShadow: [
                      BoxShadow(
                        color: amber.withValues(alpha: 0.30),
                        blurRadius: 16,
                        offset: const Offset(2, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _WobbleBell(animation: anim, size: size * 0.10, color: Colors.white),
                      SizedBox(height: size * 0.01),
                      // Red dot
                      Container(
                        width: size * 0.03,
                        height: size * 0.03,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: red,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Browser window (main center) ──
            _FloatOffset(animation: anim, dy: 4.0, child: _browserWindow(size, content: Container(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
              child: Column(children: [
                Container(height: size * 0.05, decoration: const BoxDecoration(gradient: LinearGradient(colors: [amber, deepAmber])),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AppIcon('notification', size: size * 0.022, color: Colors.white.withValues(alpha: 0.8)),
                    SizedBox(width: size * 0.008),
                    Container(width: size * 0.07, height: size * 0.006, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(2))),
                  ])),
                SizedBox(height: size * 0.01),
                // Notification items
                for (int i = 0; i < 3; i++) ...[
                  Padding(padding: EdgeInsets.symmetric(horizontal: size * 0.02), child: Container(
                    padding: EdgeInsets.all(size * 0.007),
                    decoration: BoxDecoration(
                      color: i == 0 ? amber.withValues(alpha: 0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(size * 0.008),
                      border: i == 0 ? Border.all(color: amber.withValues(alpha: 0.2), width: 1) : null,
                    ),
                    child: Row(children: [
                      Container(width: size * 0.025, height: size * 0.025, decoration: BoxDecoration(shape: BoxShape.circle, color: [amber, red, const Color(0xFF3B82F6)][i].withValues(alpha: 0.15)),
                        child: AppIcon(['wallet-3', 'warning-2', 'info-circle'][i], size: size * 0.013, color: [amber, red, const Color(0xFF3B82F6)][i])),
                      SizedBox(width: size * 0.008),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: size * 0.12 - (i * size * 0.01), height: size * 0.004, decoration: BoxDecoration(color: const Color(0xFF94A3B8), borderRadius: BorderRadius.circular(1))),
                        SizedBox(height: size * 0.003),
                        Container(width: size * 0.08, height: size * 0.003, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(1))),
                      ])),
                      if (i == 0) Container(width: size * 0.012, height: size * 0.012, decoration: const BoxDecoration(shape: BoxShape.circle, color: red)),
                    ]),
                  )),
                  SizedBox(height: size * 0.006),
                ],
                const Spacer(),
                // Due date bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: size * 0.02),
                  padding: EdgeInsets.symmetric(vertical: size * 0.006, horizontal: size * 0.01),
                  decoration: BoxDecoration(color: red.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(size * 0.008), border: Border.all(color: red.withValues(alpha: 0.2), width: 1)),
                  child: Row(children: [
                    AppIcon('clock', size: size * 0.016, color: red),
                    SizedBox(width: size * 0.005),
                    Container(width: size * 0.07, height: size * 0.004, decoration: BoxDecoration(color: red.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(1))),
                  ]),
                ),
                SizedBox(height: size * 0.012),
              ]),
            ))),

            // ── Calendar badge top-left ──
            Positioned(
              left: size * 0.06,
              top: size * 0.06,
              child: _FloatOffset(
                animation: anim,
                dy: 3.5,
                phase: 0.5,
                child: _PulseBadge(
                  animation: anim,
                  size: size * 0.12,
                  colors: const [amber, deepAmber],
                  icon: 'calendar',
                  iconSize: size * 0.055,
                  borderColor: Colors.white,
                ),
              ),
            ),

            // ── Red alert dot top-right ──
            Positioned(
              left: size * 0.16,
              top: size * 0.10,
              child: _PulseRing(
                size: size * 0.10,
                color: red.withValues(alpha: 0.20),
                animation: anim,
                child: Container(
                  width: size * 0.05,
                  height: size * 0.05,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: red,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),

            // ── Clock badge bottom-left ──
            Positioned(
              left: size * 0.10,
              bottom: size * 0.12,
              child: _FloatOffset(
                animation: anim,
                dy: 2.5,
                phase: 0.6,
                child: Container(
                  width: size * 0.09,
                  height: size * 0.09,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.white.withValues(alpha: 0.90) : Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: AppIcon('clock', size: size * 0.045, color: amber),
                ),
              ),
            ),

            // ── Success badge bottom-right ──
            Positioned(
              right: size * 0.06,
              bottom: size * 0.10,
              child: _PulseBadge(
                animation: anim,
                size: size * 0.11,
                colors: const [Color(0xFF002147), Color(0xFF001834)],
                icon: 'tick-circle',
                iconSize: size * 0.055,
                borderColor: Colors.white,
              ),
            ),

            // Sparkle
            Positioned(
              right: size * 0.16,
              top: size * 0.04,
              child: _FloatOffset(
                animation: anim,
                dy: 2.0,
                phase: 0.8,
                child: AppIcon('star', size: size * 0.035,
                    color: isDark ? amber.withValues(alpha: 0.5) : amber.withValues(alpha: 0.3)),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  /// Browser/desktop window frame for dark panel illustrations.
  static Widget _browserWindow(double size, {required Widget content}) {
    return Container(
      width: size * 0.56,
      height: size * 0.44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.018),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 24, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.018),
        child: Column(
          children: [
            // Browser title bar
            Container(
              height: size * 0.034,
              padding: EdgeInsets.symmetric(horizontal: size * 0.012),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
              ),
              child: Row(
                children: [
                  for (final c in [const Color(0xFFEF4444), const Color(0xFFF59E0B), const Color(0xFF002147)])
                    Container(
                      margin: EdgeInsets.only(right: size * 0.005),
                      width: size * 0.009,
                      height: size * 0.009,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                    ),
                  SizedBox(width: size * 0.012),
                  Expanded(child: Container(
                    height: size * 0.016,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(size * 0.006),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
                    ),
                  )),
                  SizedBox(width: size * 0.012),
                ],
              ),
            ),
            // Content
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  static Widget _avatar(double size, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.8)]),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: AppIcon('profile-circle', size: size * 0.50, color: Colors.white),
        ),
        SizedBox(height: size * 0.10),
        Container(
          width: size * 0.65,
          height: size * 0.10,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(2)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Animation widgets
// ═══════════════════════════════════════════════════════════════════

/// Root animated illustration — drives a single looping animation controller.
class _AnimatedIllustration extends StatefulWidget {
  final double size;
  final double heightFactor;
  final Widget Function(double size, Animation<double> animation) builder;

  const _AnimatedIllustration({
    required this.size,
    this.heightFactor = 1.0,
    required this.builder,
  });

  @override
  State<_AnimatedIllustration> createState() => _AnimatedIllustrationState();
}

class _AnimatedIllustrationState extends State<_AnimatedIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size * widget.heightFactor,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => widget.builder(widget.size, _controller),
      ),
    );
  }
}

/// Floats a child up and down in a sine wave pattern.
class _FloatOffset extends StatelessWidget {
  final Animation<double> animation;
  final double dy;
  final double phase;
  final Widget child;

  const _FloatOffset({
    required this.animation,
    required this.child,
    this.dy = 4.0,
    this.phase = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final t = (animation.value + phase) % 1.0;
    final offset = math.sin(t * 2 * math.pi) * dy;
    return Transform.translate(
      offset: Offset(0, offset),
      child: child,
    );
  }
}

/// A pulsing outer ring effect.
class _PulseRing extends StatelessWidget {
  final double size;
  final Color color;
  final Animation<double> animation;
  final Widget? child;

  const _PulseRing({
    required this.size,
    required this.color,
    required this.animation,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + 0.06 * math.sin(animation.value * 2 * math.pi);
    final alpha = (0.4 + 0.6 * (0.5 + 0.5 * math.cos(animation.value * 2 * math.pi)));
    return Transform.scale(
      scale: scale,
      child: child ?? Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: color.a * alpha), width: 2),
        ),
      ),
    );
  }
}

/// A badge that gently pulses (scales).
class _PulseBadge extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final List<Color> colors;
  final String icon;
  final double iconSize;
  final Color borderColor;

  const _PulseBadge({
    required this.animation,
    required this.size,
    required this.colors,
    required this.icon,
    required this.iconSize,
    this.borderColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final scale = 1.0 + 0.08 * math.sin(animation.value * 2 * math.pi);
    return Transform.scale(
      scale: scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: colors),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: [
            BoxShadow(color: colors[0].withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: AppIcon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}

/// A badge that slowly rotates (for refresh icon).
class _SpinBadge extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final List<Color> colors;
  final String icon;
  final double iconSize;

  const _SpinBadge({
    required this.animation,
    required this.size,
    required this.colors,
    required this.icon,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: colors),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(color: colors[0].withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Transform.rotate(
        angle: animation.value * 2 * math.pi,
        child: AppIcon(icon, size: iconSize, color: Colors.white),
      ),
    );
  }
}

/// Bell icon that wobbles side-to-side.
class _WobbleBell extends StatelessWidget {
  final Animation<double> animation;
  final double size;
  final Color color;

  const _WobbleBell({
    required this.animation,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final angle = math.sin(animation.value * 2 * math.pi) * 0.15;
    return Transform.rotate(
      angle: angle,
      child: AppIcon('notification', size: size, color: color),
    );
  }
}
