import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads the APK at [url] and hands it to the Android package installer.
/// Reports progress (0..1) via [onProgress]. Returns null on success, or a
/// human-readable error string. Native (Android) implementation.
Future<String?> downloadAndInstallApk({
  required String url,
  required String version,
  required void Function(double) onProgress,
}) async {
  final dir = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
  final path = '${dir.path}/EduCore360-update-$version.apk';
  final client = http.Client();
  try {
    final resp = await client
        .send(http.Request('GET', Uri.parse(url)))
        // A stalled connection used to hang on this line for ever, with the
        // dialog frozen at whatever percentage it reached and no way out on a
        // mandatory update. Failing is kinder than hanging.
        .timeout(const Duration(seconds: 60),
            onTimeout: () => throw const SocketException(
                'The server did not respond. Check your connection and try again.'));
    if (resp.statusCode != 200) return 'HTTP ${resp.statusCode}';
    final total = resp.contentLength ?? 0;
    final file = File(path);
    final sink = file.openWrite();
    int received = 0;
    // THROTTLED ON PURPOSE. onProgress calls setState, and this used to run on
    // every chunk -- roughly 3,800 rebuilds for a 30 MB download, each one
    // scheduling a frame on the same isolate that is reading the socket. On a
    // low-end phone that starves the read loop, and the download a parent sees
    // crawls while the server is serving at full speed.
    //
    // A percent is the smallest change the bar can show, so anything finer is
    // work nobody can see.
    int lastShown = -1;
    await for (final chunk in resp.stream) {
      sink.add(chunk);
      received += chunk.length;
      if (total > 0) {
        final pct = (received * 100) ~/ total;
        if (pct != lastShown) {
          lastShown = pct;
          onProgress(received / total);
        }
      }
    }
    await sink.close();

    final result = await OpenFilex.open(
      path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      return 'Could not open the installer. Enable "Install unknown apps" for '
          'FIT School in Settings, then try again. (${result.message})';
    }
    return null; // installer launched
  } finally {
    client.close();
  }
}
