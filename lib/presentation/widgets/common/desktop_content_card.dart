import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// A reusable card container for desktop dashboard content sections.
///
/// Wraps content in a rounded card with consistent padding, border radius,
/// and subtle shadow. Used on desktop to create the "padded dashboard" look.
///
/// Usage:
///   DesktopContentCard(child: myWidget)
///   DesktopContentCard(title: 'Fee Status', trailing: viewAllBtn, child: table)
///   DesktopContentCard(hasPadding: false, child: fullWidthTable)
class DesktopContentCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final bool hasPadding;

  const DesktopContentCard({
    super.key,
    required this.child,
    this.title,
    this.trailing,
    this.padding,
    this.hasPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow(context),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryC(context),
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (hasPadding)
            Padding(
              padding: padding ?? const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: child,
            )
          else
            child,
        ],
      ),
    );
  }
}
