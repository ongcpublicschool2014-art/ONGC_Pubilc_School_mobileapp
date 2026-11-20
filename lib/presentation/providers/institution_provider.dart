import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/supabase_service.dart';
import '../../data/models/institution_model.dart';
import 'auth_provider.dart' show supabaseClientProvider;
import 'student_provider.dart' show selectedStudentProvider;

/// Fetch institution by ID
final institutionByIdProvider = FutureProvider.family<InstitutionModel?, int>((ref, insId) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    try {
      final response = await client
          .from('institution')
          .select('*')
          .eq('ins_id', insId)
          .eq('activestatus', 1)
          .maybeSingle();

      if (response != null) {
        return InstitutionModel.fromJson(response);
      }
    } catch (_) {
      // Fallback without city join
      final response = await client
          .from('institution')
          .select('*')
          .eq('ins_id', insId)
          .eq('activestatus', 1)
          .maybeSingle();

      if (response != null) {
        return InstitutionModel.fromJson(response);
      }
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching institution by ID: $e');
    return null;
  }
});

/// Fetch institution for selected student with city join
final selectedStudentInstitutionProvider = FutureProvider<InstitutionModel?>((ref) async {
  final selectedStudent = ref.watch(selectedStudentProvider);

  if (selectedStudent == null) {
    debugPrint('Institution Provider: No student selected');
    return null;
  }

  debugPrint('Institution Provider: Fetching institution for ins_id=${selectedStudent.insId}');
  final client = ref.watch(supabaseClientProvider);

  try {
    // Simple query - removed activestatus filter for testing
    final response = await client
        .from('institution')
        .select('*')
        .eq('ins_id', selectedStudent.insId)
        .maybeSingle();

    debugPrint('Institution Provider: Response = $response');

    if (response != null) {
      final institution = InstitutionModel.fromJson(response);
      debugPrint('Institution Provider: Parsed name = ${institution.name}');
      return institution;
    }
    debugPrint('Institution Provider: No institution found');
    return null;
  } catch (e) {
    debugPrint('Error fetching institution for student: $e');
    return null;
  }
});

/// Fetch the active academic year label for the selected student's institution.
/// Falls back to current calendar-year guess if not available.
final activeYearLabelProvider = FutureProvider<String>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  if (student == null) {
    final now = DateTime.now();
    return now.month >= 6 ? '${now.year}-${now.year + 1}' : '${now.year - 1}-${now.year}';
  }

  final label = await SupabaseService.fetchActiveYearLabel(student.insId);
  if (label != null && label.isNotEmpty) return label;

  final now = DateTime.now();
  return now.month >= 6 ? '${now.year}-${now.year + 1}' : '${now.year - 1}-${now.year}';
});

/// Fetch all active institutions
final institutionsProvider = FutureProvider<List<InstitutionModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);

  try {
    // Try with city join first
    try {
      final response = await client
          .from('institution')
          .select('*')
          .eq('activestatus', 1)
          .order('insname', ascending: true);

      return (response as List<dynamic>)
          .map((e) => InstitutionModel.fromJson(e))
          .toList();
    } catch (_) {
      // Fallback without city join
      final response = await client
          .from('institution')
          .select('*')
          .eq('activestatus', 1)
          .order('insname', ascending: true);

      return (response as List<dynamic>)
          .map((e) => InstitutionModel.fromJson(e))
          .toList();
    }
  } catch (e) {
    debugPrint('Error fetching institutions: $e');
    return [];
  }
});
