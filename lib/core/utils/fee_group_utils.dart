import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Shared utility for fee group icon, color, and classification.
/// Adding a new fee group to the database only requires updating
/// the keyword map here (or it falls back to a default style).
class FeeGroupUtils {
  FeeGroupUtils._();

  /// Returns icon, colors, and display metadata for a fee group.
  /// [groupName] can be the database fgdesc or the demfeetype string.
  static Map<String, dynamic> getStyle(String groupName) {
    final lower = groupName.toLowerCase();

    if (lower.contains('school') || lower.contains('tuition')) {
      return {
        'icon': 'book',
        'color': const Color(0xFFD2913C),
        'iconBgColor': const Color(0xFFFAF1E4),
        'badgeColor': AppColors.success,
      };
    } else if (lower.contains('van') || lower.contains('bus') || lower.contains('transport')) {
      return {
        'icon': 'bus',
        'color': const Color(0xFFF59E0B),
        'iconBgColor': const Color(0xFFFEF3C7),
        'badgeColor': const Color(0xFFF59E0B),
      };
    } else if (lower.contains('hostel')) {
      return {
        'icon': 'home-2',
        'color': const Color(0xFF3B82F6),
        'iconBgColor': const Color(0xFFDBEAFE),
        'badgeColor': const Color(0xFF3B82F6),
      };
    } else if (lower.contains('exam') || lower.contains('test')) {
      return {
        'icon': 'task-square',
        'color': const Color(0xFFEF4444),
        'iconBgColor': const Color(0xFFFEE2E2),
        'badgeColor': const Color(0xFFEF4444),
      };
    } else {
      return {
        'icon': 'receipt',
        'color': AppColors.cardPurpleDark,
        'iconBgColor': const Color(0xFFF3E8FF),
        'badgeColor': AppColors.cardPurpleDark,
      };
    }
  }

  /// Returns true if this group uses term-based (accordion) display.
  /// School/tuition fees have I TERM, II TERM structure.
  /// All other groups use the flat "grouped card" layout.
  static bool isTermBasedGroup(String groupName) {
    final lower = groupName.toLowerCase();
    return lower.contains('school') || lower.contains('tuition');
  }

  /// Determine the fee group name for a fee, with fallback logic.
  /// Priority: feeGroupName (joined data) > keyword matching on demfeetype.
  static String resolveGroupName(String feeGroupName, String demfeetype) {
    if (feeGroupName.isNotEmpty) return feeGroupName;
    return _inferGroupFromType(demfeetype);
  }

  /// Infer a group label from the demfeetype string when joined data is unavailable.
  static String _inferGroupFromType(String demfeetype) {
    final lower = demfeetype.toLowerCase();
    if (lower.contains('bus') || lower.contains('transport') || lower.contains('van')) {
      return 'VAN FEES';
    }
    if (lower.contains('hostel')) return 'Hostel FEES';
    if (lower.contains('exam') || lower.contains('test')) return 'EXAM FEES';
    if (lower.contains('tuition')) return 'SCHOOL FEES';
    return 'SCHOOL FEES'; // default
  }
}
