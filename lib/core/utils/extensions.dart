import 'package:flutter/material.dart';
import 'package:responsive_builder2/responsive_builder2.dart'
    as responsive_builder;
import '../constants/app_sizes.dart';
import '../constants/app_colors.dart';

/// Tailwind-style extensions for cleaner code
extension ContextExtensions on BuildContext {
  // Media Query shortcuts
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  // Responsive breakpoints
  bool get isMobile => screenWidth < AppSizes.screenSm;
  bool get isTablet =>
      screenWidth >= AppSizes.screenSm && screenWidth < AppSizes.screenLg;
  bool get isDesktop => screenWidth >= AppSizes.screenLg;

  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => Theme.of(this).textTheme;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Returns a value based on the current screen type using responsive_builder2.
  ///
  /// Uses the globally configured breakpoints (mobile < 640, tablet 640–1024,
  /// desktop >= 1024). Falls back from desktop -> tablet -> mobile when a
  /// value is not provided.
  ///
  /// Example:
  /// ```dart
  /// final padding = context.responsiveValue<double>(
  ///   mobile: 16,
  ///   tablet: 24,
  ///   desktop: 32,
  /// );
  /// ```
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return responsive_builder.getValueForScreenType<T>(
      context: this,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

extension WidgetExtensions on Widget {
  // Padding extensions (Tailwind: p-4, px-2, py-3, etc.)
  Widget p(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);
  Widget px(double value) =>
      Padding(padding: EdgeInsets.symmetric(horizontal: value), child: this);
  Widget py(double value) =>
      Padding(padding: EdgeInsets.symmetric(vertical: value), child: this);
  Widget pt(double value) =>
      Padding(padding: EdgeInsets.only(top: value), child: this);
  Widget pb(double value) =>
      Padding(padding: EdgeInsets.only(bottom: value), child: this);
  Widget pl(double value) =>
      Padding(padding: EdgeInsets.only(left: value), child: this);
  Widget pr(double value) =>
      Padding(padding: EdgeInsets.only(right: value), child: this);

  // Margin using Container
  Widget m(double value) =>
      Container(margin: EdgeInsets.all(value), child: this);
  Widget mx(double value) =>
      Container(margin: EdgeInsets.symmetric(horizontal: value), child: this);
  Widget my(double value) =>
      Container(margin: EdgeInsets.symmetric(vertical: value), child: this);
  Widget mt(double value) =>
      Container(margin: EdgeInsets.only(top: value), child: this);
  Widget mb(double value) =>
      Container(margin: EdgeInsets.only(bottom: value), child: this);

  // Center widget
  Widget get centered => Center(child: this);

  // Expanded and Flexible
  Widget get expanded => Expanded(child: this);
  Widget flex(int value) => Expanded(flex: value, child: this);

  // Make widget scrollable
  Widget get scrollable => SingleChildScrollView(child: this);

  // Opacity
  Widget opacity(double value) => Opacity(opacity: value, child: this);

  // Visibility
  Widget visible(bool isVisible) => Visibility(visible: isVisible, child: this);

  // Safe Area
  Widget get safeArea => SafeArea(child: this);

  // Hero animation
  Widget hero(String tag) => Hero(tag: tag, child: this);

  // Gestures
  Widget onTap(VoidCallback onTap) => GestureDetector(onTap: onTap, child: this);
}

extension TextStyleExtensions on TextStyle {
  // Font weight shortcuts
  TextStyle get thin => copyWith(fontWeight: FontWeight.w100);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
  TextStyle get extrabold => copyWith(fontWeight: FontWeight.w800);

  // Color shortcuts
  TextStyle get primary => copyWith(color: AppColors.primary);
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);
  TextStyle get muted => copyWith(color: AppColors.textTertiary);
  TextStyle get white => copyWith(color: Colors.white);
  TextStyle get error => copyWith(color: AppColors.error);
  TextStyle get success => copyWith(color: AppColors.success);

  // Size shortcuts
  TextStyle get xs => copyWith(fontSize: AppSizes.textXs);
  TextStyle get sm => copyWith(fontSize: AppSizes.textSm);
  TextStyle get base => copyWith(fontSize: AppSizes.textBase);
  TextStyle get lg => copyWith(fontSize: AppSizes.textLg);
  TextStyle get xl => copyWith(fontSize: AppSizes.textXl);
  TextStyle get xxl => copyWith(fontSize: AppSizes.text2xl);
  TextStyle get xxxl => copyWith(fontSize: AppSizes.text3xl);
}

extension SizedBoxExtensions on num {
  // Vertical spacing (Tailwind: space-y-4)
  SizedBox get h => SizedBox(height: toDouble());

  // Horizontal spacing (Tailwind: space-x-4)
  SizedBox get w => SizedBox(width: toDouble());

  // Square box
  SizedBox get box => SizedBox(height: toDouble(), width: toDouble());
}

extension EdgeInsetsExtensions on num {
  EdgeInsets get all => EdgeInsets.all(toDouble());
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: toDouble());
  EdgeInsets get vertical => EdgeInsets.symmetric(vertical: toDouble());
  EdgeInsets get top => EdgeInsets.only(top: toDouble());
  EdgeInsets get bottom => EdgeInsets.only(bottom: toDouble());
  EdgeInsets get left => EdgeInsets.only(left: toDouble());
  EdgeInsets get right => EdgeInsets.only(right: toDouble());
}

extension BorderRadiusExtensions on num {
  BorderRadius get rounded => BorderRadius.circular(toDouble());
}

extension StringExtensions on String {
  // Currency formatting for Indian Rupees
  String get inr => '₹$this';

  // Capitalize first letter
  String get capitalize =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  // Title case
  String get titleCase => split(' ').map((word) => word.capitalize).join(' ');
}

extension DateTimeExtensions on DateTime {
  String get formatted =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  String get monthYear => '${_monthName(month)} $year';
  String get dayMonthYear =>
      '${day.toString().padLeft(2, '0')} ${_monthName(month)} $year';

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return isBefore(today);
  }
}

extension NumberExtensions on num {
  // Currency formatting
  String get currency => '₹${toStringAsFixed(2)}';
  String get currencyCompact {
    if (this >= 10000000) return '₹${(this / 10000000).toStringAsFixed(2)} Cr';
    if (this >= 100000) return '₹${(this / 100000).toStringAsFixed(2)} L';
    if (this >= 1000) return '₹${(this / 1000).toStringAsFixed(2)} K';
    return '₹${toStringAsFixed(2)}';
  }
}
