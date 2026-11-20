/// Web / non-IO fallback: APK install isn't possible here. Keeps the app
/// compilable for web (no dart:io / native plugins pulled in).
Future<String?> downloadAndInstallApk({
  required String url,
  required String version,
  required void Function(double) onProgress,
}) async {
  return 'App updates are available only on the Android app.';
}
