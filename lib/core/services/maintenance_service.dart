import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/supabase_config.dart';

/// Result of a maintenance-flag check. All fields except [active] are optional
/// and drive the maintenance screen — an empty field is simply not rendered.
class MaintenanceStatus {
  final bool active;
  final String title; // heading (defaults to "Server Maintenance" if empty)
  final String message; // body paragraph
  final String time; // "Maintenance Time" value (use \n for a second line)
  final String duration; // "Expected Duration" value
  final String notice; // bottom info-banner text
  const MaintenanceStatus({
    required this.active,
    this.title = '',
    this.message = '',
    this.time = '',
    this.duration = '',
    this.notice = '',
  });

  static const MaintenanceStatus off = MaintenanceStatus(active: false);

  bool sameAs(MaintenanceStatus o) =>
      active == o.active &&
      title == o.title &&
      message == o.message &&
      time == o.time &&
      duration == o.duration &&
      notice == o.notice;
}

/// Reads the SAME hosted "maintenance" flag as the desktop and web apps so all
/// clients can be gated from one place while the live database is being worked
/// on. The flag lives in a **public Supabase Storage object** (not the DB), so
/// migrating DB tables never affects it — the apps can still read it mid-work.
///
/// Fail-open: any error (network, missing file / 404, bad JSON) returns
/// [MaintenanceStatus.off] so a transient problem never locks users out. To
/// START maintenance upload `maintenance.json` with `{"maintenance": true,
/// "message": "..."}`; to END it set `false` (or delete the file).
class MaintenanceService {
  /// Public Supabase Storage object. Bucket `app-updates`, file
  /// `maintenance.json` — shared by desktop / mobile / web.
  static const String manifestUrl =
      '${SupabaseConfig.url}/storage/v1/object/public/app-updates/maintenance.json';

  static Future<MaintenanceStatus> check() async {
    try {
      final uri = Uri.parse(
          '$manifestUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return MaintenanceStatus.off;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      return MaintenanceStatus(
        active: j['maintenance'] == true,
        title: (j['title'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        time: (j['time'] ?? '').toString(),
        duration: (j['duration'] ?? '').toString(),
        notice: (j['notice'] ?? '').toString(),
      );
    } catch (_) {
      return MaintenanceStatus.off;
    }
  }
}
