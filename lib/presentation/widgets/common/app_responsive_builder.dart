import 'package:flutter/material.dart';
import 'package:responsive_builder2/responsive_builder2.dart';

/// A reusable responsive layout widget that wraps [ScreenTypeLayout.builder]
/// from responsive_builder2.
///
/// Provides [mobile], [tablet], and [desktop] builder callbacks. At least one
/// of [mobile] or [desktop] must be provided. The package handles fallback
/// logic automatically (e.g. if [tablet] is not provided, it falls back to
/// [mobile]).
///
/// Example:
/// ```dart
/// AppResponsiveBuilder(
///   mobile: (context) => MobileHomeScreen(),
///   tablet: (context) => TabletHomeScreen(),
///   desktop: (context) => DesktopHomeScreen(),
/// )
/// ```
class AppResponsiveBuilder extends StatelessWidget {
  /// Builder for mobile/phone layout (width < 640).
  final Widget Function(BuildContext)? mobile;

  /// Builder for tablet layout (640 <= width < 1024).
  final Widget Function(BuildContext)? tablet;

  /// Builder for desktop layout (width >= 1024).
  final Widget Function(BuildContext)? desktop;

  const AppResponsiveBuilder({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
  }) : assert(
          mobile != null || desktop != null,
          'At least one of mobile or desktop must be provided.',
        );

  @override
  Widget build(BuildContext context) {
    return ScreenTypeLayout.builder(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}
