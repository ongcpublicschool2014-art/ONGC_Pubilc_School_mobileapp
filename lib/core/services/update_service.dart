import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../../config/supabase_config.dart';

/// One available update, parsed from the hosted `latest-android.json` manifest.
class UpdateInfo {
  final String version; // e.g. "1.1.0"
  final String url;      // direct download URL of the new .apk
  final String notes;
  final bool mandatory;
  const UpdateInfo({
    required this.version,
    required this.url,
    this.notes = '',
    this.mandatory = false,
  });
}

/// Checks a hosted manifest for a newer app version (Android direct-APK).
/// Never throws — a failed check returns null so the app is never blocked.
class UpdateService {
  /// Public Supabase Storage object. Bucket `app-updates`, file
  /// `latest-android.json` (separate from the desktop `latest.json`).
  static const String manifestUrl =
      '${SupabaseConfig.url}/storage/v1/object/public/app-updates/latest-android.json';

  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final uri = Uri.parse('$manifestUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final latest = (j['version'] ?? '').toString().trim();
      final url = (j['url'] ?? '').toString().trim();
      if (latest.isEmpty || url.isEmpty) return null;

      final current = (await PackageInfo.fromPlatform()).version;
      if (!_isNewer(latest, current)) return null;

      return UpdateInfo(
        version: latest,
        url: url,
        notes: (j['notes'] ?? '').toString(),
        mandatory: j['mandatory'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> currentVersion() async {
    try {
      return (await PackageInfo.fromPlatform()).version;
    } catch (_) {
      return '';
    }
  }

  /// Numeric semantic-version compare: true when [a] > [b].
  static bool _isNewer(String a, String b) {
    List<int> parts(String v) =>
        v.split(RegExp(r'[.+-]')).map((x) => int.tryParse(x) ?? 0).toList();
    final pa = parts(a), pb = parts(b);
    for (var i = 0; i < 3; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x > y;
    }
    return false;
  }
}
