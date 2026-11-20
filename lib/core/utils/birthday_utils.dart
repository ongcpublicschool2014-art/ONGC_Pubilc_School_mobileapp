import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/student_model.dart';

class BirthdayUtils {
  static String _getKey(int studentId) {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return 'birthday_shown_${studentId}_$dateStr';
  }

  /// Check if today is the student's birthday (month and day match)
  static bool isBirthdayToday(StudentModel student) {
    final now = DateTime.now();
    final dob = student.dateOfBirth;
    return now.month == dob.month && now.day == dob.day;
  }

  /// Check if the birthday dialog has already been shown today for this student
  static Future<bool> hasShownToday(int studentId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_getKey(studentId)) ?? false;
  }

  /// Mark the birthday dialog as shown for today for this student
  static Future<void> markAsShown(int studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_getKey(studentId), true);
  }

  /// Full check: is it the birthday AND has the dialog NOT been shown yet?
  static Future<bool> shouldShowBirthdayDialog(StudentModel? student) async {
    if (student == null) return false;
    if (!isBirthdayToday(student)) return false;
    final alreadyShown = await hasShownToday(student.stuId);
    return !alreadyShown;
  }
}
