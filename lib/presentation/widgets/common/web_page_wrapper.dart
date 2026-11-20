import 'package:flutter/material.dart';
import '../../../core/utils/extensions.dart';

/// Centers content horizontally with a max-width constraint on desktop (≥1024px).
/// On mobile/tablet it renders the child directly without modification.
///
/// Handles two layout contexts automatically:
///  • Bounded height (Scaffold body): uses Stack+Positioned so Expanded/Flex
///    children continue to receive tight height constraints.
///  • Unbounded height (scroll context): uses Center+ConstrainedBox.
///
/// Usage:
///   WebPageWrapper(child: myWidget)               // default 900px
///   WebPageWrapper(maxWidth: 480, child: myWidget) // auth screens: 480px
class WebPageWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final bool fullWidth;

  const WebPageWrapper({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isDesktop || fullWidth) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedHeight) {
          // Scroll context — just constrain width and center
          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: child,
            ),
          );
        }
        // Fixed-height context (e.g. Scaffold body) — use Positioned so that
        // Expanded/Flex children keep tight height constraints.
        final sideMargin =
            ((constraints.maxWidth - maxWidth) / 2).clamp(0.0, double.infinity);
        return Stack(
          children: [
            Positioned(
              left: sideMargin,
              right: sideMargin,
              top: 0,
              bottom: 0,
              child: child,
            ),
          ],
        );
      },
    );
  }
}
