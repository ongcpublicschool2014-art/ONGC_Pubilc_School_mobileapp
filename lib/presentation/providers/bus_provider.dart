import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/supabase_service.dart';
import '../../data/models/bus_info_model.dart';
import 'student_provider.dart';

/// The selected child's school bus: route, stops and where the bus is
/// (server function `tr_parent_bus`, parent session only). Null when no
/// child is selected or the app has no session yet.
final busInfoProvider = FutureProvider.autoDispose<BusInfo?>((ref) async {
  final student = ref.watch(selectedStudentProvider);
  final token = SupabaseService.sessionToken;
  if (student == null || token == null || token.isEmpty) return null;
  final res = await SupabaseService.client.rpc('tr_parent_bus', params: {
    'p_token': token,
    'p_stu_id': student.stuId,
  });
  if (res is! Map) return null;
  return BusInfo.fromJson(res.cast<String, dynamic>());
});

/// Turns a server error into a sentence for the parent.
String busErrorText(Object e) {
  final s = e.toString();
  if (s.contains('not on your account')) return 'This student is not on your account.';
  if (s.contains('expired session') || s.contains('sign in again')) return 'Please sign in again to see the bus.';
  if (s.contains('SocketException') || s.contains('Failed host lookup') || s.contains('ClientException')) {
    return 'No internet connection. Check your connection and try again.';
  }
  return 'Could not load the bus right now. Please try again.';
}
