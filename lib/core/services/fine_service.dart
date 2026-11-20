import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

/// Computes fines for overdue fees using the institution's `finerule` table.
///
/// Rule structure (matches admin app):
/// - `from_days`, `to_days`: overdue-day range the rule applies to
/// - `fine_type`: 'FIXED' (flat amount) or 'PERCENT' (% of fee amount)
/// - `fine_value`: the amount or percentage
/// - `feetype`: specific fee type or 'ALL'
/// - `feefineapplicable`: feetype must have this flag = 1
class FineService {
  static List<Map<String, dynamic>>? _cachedRules;
  static int? _cachedForInsId;

  /// Load finerule entries for the given institution (from institution schema).
  /// Results are cached until clearCache() is called.
  static Future<List<Map<String, dynamic>>> loadRules(int insId) async {
    if (_cachedForInsId == insId && _cachedRules != null) {
      return _cachedRules!;
    }

    try {
      final result = await SupabaseService.fromSchema('finerule')
          .select('*')
          .eq('ins_id', insId)
          .eq('activestatus', 1)
          .order('from_days', ascending: true);

      _cachedRules = List<Map<String, dynamic>>.from(result as List);
      _cachedForInsId = insId;
      return _cachedRules!;
    } catch (e) {
      debugPrint('FineService: finerule fetch failed: $e');
      _cachedRules = [];
      _cachedForInsId = insId;
      return _cachedRules!;
    }
  }

  static void clearCache() {
    _cachedRules = null;
    _cachedForInsId = null;
  }

  /// Calculate fine for a single fee.
  /// Returns 0 if no rule matches or fee is not overdue.
  ///
  /// [demfeetype] — fee type name (e.g. "School Fees")
  /// [dueDate] — fee due date
  /// [feeAmount] — base amount of the fee (used for PERCENT rules)
  static double calculateFine({
    required String demfeetype,
    required DateTime dueDate,
    required double feeAmount,
    required List<Map<String, dynamic>> rules,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);

    // Not overdue
    if (!due.isBefore(today)) return 0;

    final overdueDays = today.difference(due).inDays;

    // Find matching rule: fee type specific first, then 'ALL'
    Map<String, dynamic>? matchedRule;
    for (final rule in rules) {
      final ruleFeeType = (rule['feetype'] as String?)?.toUpperCase() ?? '';
      final fromDays = (rule['from_days'] as num?)?.toInt() ?? 0;
      final toDaysRaw = rule['to_days'];
      final toDays = toDaysRaw == null ? null : (toDaysRaw as num).toInt();

      // Check day range
      final inRange = overdueDays >= fromDays &&
          (toDays == null || overdueDays <= toDays);
      if (!inRange) continue;

      // Check fee type match
      final matchesFeeType = ruleFeeType == 'ALL' ||
          ruleFeeType == demfeetype.toUpperCase();
      if (!matchesFeeType) continue;

      // Prefer specific feetype match over 'ALL'
      if (ruleFeeType != 'ALL') {
        matchedRule = rule;
        break;
      }
      matchedRule ??= rule;
    }

    if (matchedRule == null) return 0;

    final fineType = (matchedRule['fine_type'] as String?)?.toUpperCase() ?? 'FIXED';
    final fineValue = (matchedRule['fine_value'] as num?)?.toDouble() ?? 0;

    if (fineType == 'PERCENT') {
      return (feeAmount * fineValue) / 100;
    }
    return fineValue;
  }
}
