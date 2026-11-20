import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/student_model.dart';
import '../../data/models/institution_model.dart';
import '../../core/services/supabase_service.dart';
import 'auth_provider.dart' show supabaseClientProvider, parentAuthStateProvider;
import 'cart_provider.dart';

/// Set to false to use Supabase data, true for dummy data
const bool useDummyData = false;

/// Key for persisting selected student ID
const String _selectedStudentIdKey = 'selected_student_id';

/// Currently selected student - managed by StateNotifier for persistence
final selectedStudentProvider = StateNotifierProvider<SelectedStudentNotifier, StudentModel?>((ref) {
  return SelectedStudentNotifier(ref);
});

/// Notifier that handles student selection with persistence
class SelectedStudentNotifier extends StateNotifier<StudentModel?> {
  final Ref _ref;
  bool _manuallySelected = false;

  SelectedStudentNotifier(this._ref) : super(null) {
    _loadSavedStudent();
  }

  /// Load saved student from SharedPreferences
  Future<void> _loadSavedStudent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStudentId = prefs.getInt(_selectedStudentIdKey);

      if (savedStudentId != null) {
        debugPrint('Loading saved student ID: $savedStudentId');

        // If user already selected a student manually, don't overwrite
        if (_manuallySelected) {
          debugPrint('Student already selected manually, skipping saved load');
          return;
        }

        final response = await SupabaseService.fromSchema('students')
            .select('*')
            .eq('stu_id', savedStudentId)
            .eq('activestatus', 1)
            .maybeSingle();

        // Check again after async gap — user may have selected during DB fetch
        if (_manuallySelected) {
          debugPrint('Student was selected during load, skipping');
          return;
        }

        if (response != null) {
          state = StudentModel.fromJson(response);
          debugPrint('Loaded student: ${state?.name}');
        }
      }
    } catch (e) {
      debugPrint('Error loading saved student: $e');
    }
  }

  /// Save student selection to SharedPreferences
  Future<void> _saveStudent(int? studentId) async {
    final prefs = await SharedPreferences.getInstance();
    if (studentId != null) {
      await prefs.setInt(_selectedStudentIdKey, studentId);
    } else {
      await prefs.remove(_selectedStudentIdKey);
    }
  }

  /// Select a student and switch to the correct institution schema
  Future<void> selectStudent(StudentModel student) async {
    _manuallySelected = true;

    // Clear cart when switching students
    final currentStudentId = state?.stuId;
    if (currentStudentId != null && currentStudentId != student.stuId) {
      _ref.read(cartProvider.notifier).clearCartLocal();
      debugPrint('Cart cleared for student switch');
    }

    // Switch schema to match this student's institution
    final schemas = SupabaseService.parentSchemas;
    final match = schemas.where((s) => s.insId == student.insId).firstOrNull;
    if (match != null) {
      SupabaseService.setSchema(match.schema);
      debugPrint('Schema switched to ${match.schema} for ins_id=${student.insId}');
    } else {
      // Fallback: determine schema from institution
      await SupabaseService.determineAndSetSchema(student.insId);
    }

    state = student;
    await _saveStudent(student.stuId);
    debugPrint('Selected student: ${student.name}');
  }

  /// Clear selection (on logout)
  Future<void> clearSelection() async {
    state = null;
    await _saveStudent(null);
  }
}

/// Fetch students by parent ID across ALL institution schemas.
/// A parent with the same mobile in 3 institutions will see
/// students from all 3 institutions in the student selection screen.
final studentsByParentProvider = FutureProvider<List<StudentModel>>((ref) async {
  final parentAuthState = ref.watch(parentAuthStateProvider);

  final parent = parentAuthState.valueOrNull?.parent;
  if (parent == null) {
    return [];
  }

  // On page refresh the in-memory schema cache is empty even though the
  // parent session is restored. Re-scan now (auth_provider does this too,
  // but unawaited — we'd otherwise lose the multi-institution students until
  // a manual invalidate). Skip the rescan when the cache is already warm.
  var schemas = SupabaseService.parentSchemas;
  if (schemas.isEmpty && parent.payinchargemob.isNotEmpty) {
    final matches = await SupabaseService.findParentInstitutions(parent.payinchargemob);
    if (matches.isNotEmpty) {
      SupabaseService.setParentSchemas(matches);
      schemas = matches;
    }
  }

  final allStudents = <StudentModel>[];

  // Query each schema where this parent exists — in PARALLEL. The schemas are
  // independent, so scanning them concurrently collapses N sequential round
  // trips into a single batch (major speedup for multi-institution parents).
  final perSchema = await Future.wait(schemas.map((entry) async {
    try {
      // A parent may have MORE THAN ONE par_id for the same mobile (e.g. one
      // record per child). Fetch ALL of them — taking only the first (.limit(1))
      // dropped children linked to the other par_id(s).
      final parentRows = await SupabaseService.client.schema(entry.schema)
          .from('parents')
          .select('par_id')
          .eq('payinchargemob', parent.payinchargemob)
          .eq('activestatus', 1);
      final parIds = (parentRows as List<dynamic>)
          .map((e) => (e['par_id'] as num).toInt())
          .toList();

      if (parIds.isEmpty) return const <StudentModel>[];

      // Get student IDs from parentdetail for ALL of this mobile's par_ids.
      final parentDetailResponse = await SupabaseService.client.schema(entry.schema)
          .from('parentdetail')
          .select('stu_id')
          .inFilter('par_id', parIds)
          .eq('activestatus', 1);

      final studentIds = (parentDetailResponse as List<dynamic>)
          .map((e) => (e['stu_id'] as num).toInt())
          .toSet()
          .toList();

      if (studentIds.isEmpty) return const <StudentModel>[];

      // Fetch student records from this schema
      final response = await SupabaseService.client.schema(entry.schema)
          .from('students')
          .select('*')
          .inFilter('stu_id', studentIds)
          .eq('activestatus', 1)
          .order('stuname', ascending: true);

      return (response as List<dynamic>)
          .map((e) => StudentModel.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Error fetching students from schema ${entry.schema}: $e');
      return const <StudentModel>[];
    }
  }));
  for (final list in perSchema) {
    allStudents.addAll(list);
  }

  // Fallback: if no schemas cached, use current schema — fetch ALL par_ids for
  // this mobile (a parent may have several).
  if (schemas.isEmpty) {
    try {
      final parentRows = await SupabaseService.fromSchema('parents')
          .select('par_id')
          .eq('payinchargemob', parent.payinchargemob)
          .eq('activestatus', 1);
      final parIds = (parentRows as List<dynamic>)
          .map((e) => (e['par_id'] as num).toInt())
          .toList();

      final parentDetailResponse = parIds.isEmpty
          ? const <dynamic>[]
          : await SupabaseService.fromSchema('parentdetail')
              .select('stu_id')
              .inFilter('par_id', parIds)
              .eq('activestatus', 1);

      final studentIds = (parentDetailResponse as List<dynamic>)
          .map((e) => (e['stu_id'] as num).toInt())
          .toSet()
          .toList();

      if (studentIds.isNotEmpty) {
        final response = await SupabaseService.fromSchema('students')
            .select('*')
            .inFilter('stu_id', studentIds)
            .eq('activestatus', 1)
            .order('stuname', ascending: true);

        allStudents.addAll(
          (response as List<dynamic>).map((e) => StudentModel.fromJson(e)),
        );
      }
    } catch (e) {
      debugPrint('Error fetching students (fallback): $e');
    }
  }

  allStudents.sort((a, b) => a.stuname.compareTo(b.stuname));
  return allStudents;
});

/// Fetch all students from Supabase (schema-specific)
final studentsProvider = FutureProvider<List<StudentModel>>((ref) async {
  try {
    final response = await SupabaseService.fromSchema('students')
        .select('*')
        .eq('activestatus', 1)
        .order('stuname', ascending: true);

    return (response as List<dynamic>)
        .map((e) => StudentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching students: $e');
    return [];
  }
});

/// Fetch students by institution ID (schema-specific)
final studentsByInstitutionProvider = FutureProvider.family<List<StudentModel>, int>((ref, insId) async {
  try {
    final response = await SupabaseService.fromSchema('students')
        .select('*')
        .eq('ins_id', insId)
        .eq('activestatus', 1)
        .order('stuname', ascending: true);

    return (response as List<dynamic>)
        .map((e) => StudentModel.fromJson(e))
        .toList();
  } catch (e) {
    debugPrint('Error fetching students by institution: $e');
    return [];
  }
});

/// Fetch a single student by ID (schema-specific)
final studentByIdProvider = FutureProvider.family<StudentModel?, int>((ref, stuId) async {
  try {
    final response = await SupabaseService.fromSchema('students')
        .select('*')
        .eq('stu_id', stuId)
        .maybeSingle();

    if (response != null) {
      return StudentModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching student by ID: $e');
    return null;
  }
});

/// Fetch student by mobile number (schema-specific)
final studentByMobileProvider = FutureProvider.family<StudentModel?, String>((ref, mobile) async {
  try {
    final response = await SupabaseService.fromSchema('students')
        .select('*')
        .eq('stumobile', mobile)
        .eq('activestatus', 1)
        .maybeSingle();

    if (response != null) {
      return StudentModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching student by mobile: $e');
    return null;
  }
});

/// Fetch student by admission number (schema-specific)
final studentByAdmissionProvider = FutureProvider.family<StudentModel?, String>((ref, admNo) async {
  try {
    final response = await SupabaseService.fromSchema('students')
        .select('*')
        .eq('stuadmno', admNo)
        .eq('activestatus', 1)
        .maybeSingle();

    if (response != null) {
      return StudentModel.fromJson(response);
    }
    return null;
  } catch (e) {
    debugPrint('Error fetching student by admission number: $e');
    return null;
  }
});

/// Provider to check if parent has multiple students
final hasMultipleStudentsProvider = Provider<bool>((ref) {
  final studentsAsync = ref.watch(studentsByParentProvider);
  return studentsAsync.maybeWhen(
    data: (students) => students.length > 1,
    orElse: () => false,
  );
});

/// Provider to get student count
final studentCountProvider = Provider<int>((ref) {
  final studentsAsync = ref.watch(studentsByParentProvider);
  return studentsAsync.maybeWhen(
    data: (students) => students.length,
    orElse: () => 0,
  );
});

/// Fetch institution for selected student based on ins_id
final selectedStudentWithInstitutionProvider = FutureProvider<InstitutionModel?>((ref) async {
  final selectedStudent = ref.watch(selectedStudentProvider);

  if (selectedStudent == null) {
    debugPrint('Institution Provider: No student selected');
    return null;
  }

  debugPrint('Institution Provider: Fetching institution for student "${selectedStudent.name}" with ins_id=${selectedStudent.insId}');
  final client = ref.watch(supabaseClientProvider);

  try {
    // Query institution table matching ins_id from student record
    final response = await client
        .from('institution')
        .select('*')
        .eq('ins_id', selectedStudent.insId)
        .maybeSingle();

    debugPrint('Institution Provider: Response for ins_id=${selectedStudent.insId}: $response');

    if (response != null) {
      final institution = InstitutionModel.fromJson(response);
      debugPrint('Institution Provider: Found institution "${institution.insname}"');
      return institution;
    }

    debugPrint('Institution Provider: No institution found for ins_id=${selectedStudent.insId}');
    return null;
  } catch (e) {
    debugPrint('Institution Provider: Error fetching institution: $e');
    return null;
  }
});
