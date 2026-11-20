import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders an SVG icon from `assets/icons/linear/<name>.svg` (or `bold`).
/// Use this instead of Material `Icon` to get the project's icon set.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.name, {
    super.key,
    this.size = 20,
    this.color,
    this.bold = false,
  });

  final String name;
  final double size;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final folder = bold ? 'bold' : 'linear';
    // Wrap in a SizedBox so the icon keeps its intended size even when
    // placed as the direct child of a larger fixed-size Container.
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SvgPicture.asset(
          'assets/icons/$folder/$name.svg',
          width: size,
          height: size,
          fit: BoxFit.contain,
          colorFilter:
              color == null ? null : ColorFilter.mode(color!, BlendMode.srcIn),
        ),
      ),
    );
  }
}
