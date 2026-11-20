import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.borderRadius,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppSizes.s4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(borderRadius ?? AppSizes.roundedXl),
        border: border ?? Border.all(color: AppColors.borderC(context)),
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius:
              BorderRadius.circular(borderRadius ?? AppSizes.roundedXl),
          child: card,
        ),
      );
    }

    return card;
  }
}
