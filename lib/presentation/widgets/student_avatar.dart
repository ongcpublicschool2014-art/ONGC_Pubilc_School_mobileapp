import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_ui.dart';

/// Reusable student avatar widget that displays the student photo
/// or falls back to first letter of student name with unique colors
class StudentAvatar extends StatelessWidget {
  final String studentName;
  final String? photoUrl;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final double fontSize;
  final FontWeight fontWeight;

  const StudentAvatar({
    super.key,
    required this.studentName,
    this.photoUrl,
    this.size = 50,
    this.backgroundColor,
    this.textColor,
    this.fontSize = 20,
    this.fontWeight = FontWeight.bold,
  });

  /// Peacock pale / ink pairs (desktop palette), picked by first letter.
  static const List<Map<String, Color>> _letterColors = [
    {'bg': AppColors.primarySoft, 'text': AppColors.primaryDark},
    {'bg': AppColors.goldSoft, 'text': AppColors.goldInk},
    {'bg': AppColors.purpleBg, 'text': AppColors.purple},
    {'bg': AppColors.blueBg, 'text': AppColors.blue},
    {'bg': AppColors.coralBg, 'text': AppColors.coralInk},
  ];

  /// Get colors based on first letter of name
  Map<String, Color> _getColorsForLetter() {
    if (studentName.isEmpty) {
      return {'bg': AppColors.segmentBg, 'text': AppColors.ink2};
    }

    final firstChar = studentName[0].toUpperCase();
    if (firstChar.codeUnitAt(0) >= 65 && firstChar.codeUnitAt(0) <= 90) {
      // A-Z (ASCII 65-90)
      final index = firstChar.codeUnitAt(0) - 65;
      return _letterColors[index % _letterColors.length];
    }

    // Default for non-letter characters
    return {'bg': AppColors.segmentBg, 'text': AppColors.ink2};
  }

  /// Creates a small avatar (40x40)
  factory StudentAvatar.small({
    Key? key,
    required String studentName,
    String? photoUrl,
  }) {
    return StudentAvatar(
      key: key,
      studentName: studentName,
      photoUrl: photoUrl,
      size: 40,
      fontSize: 16,
    );
  }

  /// Creates a medium avatar (50x50) - default size
  factory StudentAvatar.medium({
    Key? key,
    required String studentName,
    String? photoUrl,
  }) {
    return StudentAvatar(
      key: key,
      studentName: studentName,
      photoUrl: photoUrl,
      size: 50,
      fontSize: 20,
    );
  }

  /// Creates a large avatar (80x80) - for profile pages
  factory StudentAvatar.large({
    Key? key,
    required String studentName,
    String? photoUrl,
  }) {
    return StudentAvatar(
      key: key,
      studentName: studentName,
      photoUrl: photoUrl,
      size: 80,
      fontSize: 32,
    );
  }

  bool get _hasPhoto => photoUrl != null && photoUrl!.isNotEmpty;

  String get _firstLetter {
    if (studentName.isEmpty) return 'S';
    return studentName[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColorsForLetter();
    final bgColor = backgroundColor ?? colors['bg']!;
    final txtColor = textColor ?? colors['text']!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _hasPhoto ? null : bgColor,
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: size >= 80
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: _hasPhoto
          ? CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              placeholder: (context, url) => Container(
                color: bgColor,
                child: Center(
                  child: SizedBox(
                    width: size * 0.4,
                    height: size * 0.4,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildLetterFallback(bgColor, txtColor),
            )
          : _buildLetterFallback(bgColor, txtColor),
    );
  }

  Widget _buildLetterFallback(Color bgColor, Color txtColor) {
    return Container(
      color: bgColor,
      child: Center(
        child: Text(
          _firstLetter,
          // Avatar letters are Fraunces, as on the desktop.
          style: AppFonts.heading(
            size: fontSize,
            weight: FontWeight.w600,
            color: txtColor,
          ),
        ),
      ),
    );
  }
}
