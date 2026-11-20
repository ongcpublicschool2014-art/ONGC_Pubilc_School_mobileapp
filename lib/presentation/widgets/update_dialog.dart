import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../core/services/update_service.dart';
import '../../core/services/apk_installer.dart';
import '../../core/constants/app_colors.dart';

/// True once the prompt has been offered in this app RUN.
///
/// The caller sits in HomeScreen.initState, which runs again every time that
/// screen is rebuilt -- coming back from the Android installer without
/// finishing it, switching student, logging out and back in. Each rebuild asked
/// again, so a parent who stepped out of the installer was prompted twice over.
/// It was called a one-shot check but was one-shot per SCREEN, not per run.
///
/// Deliberately NOT persisted across runs: someone who postpones an update
/// should be asked again next time they open the app.
bool _promptedThisRun = false;

/// Checks for an update and, if one exists, shows the prompt. Safe to call from
/// anywhere: it acts at most once per app run. No-op on web, on failure, or
/// when already current.
Future<void> maybePromptUpdate(BuildContext context) async {
  if (kIsWeb) return; // APK self-update is Android-only
  if (_promptedThisRun) return;
  final info = await UpdateService.checkForUpdate();
  if (info == null || !context.mounted) return;
  // Set only once an update is genuinely being offered, so a failed or
  // not-yet-published check does not consume the one chance to ask.
  _promptedThisRun = true;
  await showDialog<void>(
    context: context,
    barrierDismissible: !info.mandatory,
    builder: (_) => _UpdateDialog(info: info),
  );
}

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.info});
  final UpdateInfo info;
  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  bool _downloading = false;
  double _progress = 0;
  String? _error;

  Future<void> _downloadAndInstall() async {
    setState(() {
      _downloading = true;
      _error = null;
      _progress = 0;
    });
    final err = await downloadAndInstallApk(
      url: widget.info.url,
      version: widget.info.version,
      onProgress: (p) {
        if (mounted) setState(() => _progress = p);
      },
    );
    // On success the Android installer takes over; only surface failures.
    if (err != null && mounted) {
      setState(() {
        _downloading = false;
        _error = err;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = widget.info;
    // A mandatory update must survive the BACK BUTTON too. barrierDismissible
    // only stops a tap outside the dialog; on Android, back still pops the
    // route, which let a parent dismiss an update the manifest marked
    // compulsory. canPop: false closes that, and also blocks the gesture while
    // a download is in flight so the install is not abandoned half-way.
    return PopScope(
      canPop: !i.mandatory && !_downloading,
      child: AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: const [
        Icon(Icons.system_update_rounded, color: AppColors.primary),
        SizedBox(width: 10),
        Expanded(child: Text('Update available', style: TextStyle(fontWeight: FontWeight.w800))),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Version ${i.version} is ready to install.',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (i.notes.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(i.notes.trim(), style: const TextStyle(fontSize: 13, color: Colors.black54)),
          ],
          if (_downloading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(value: _progress > 0 ? _progress : null, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(
              _progress > 0 ? 'Downloading… ${(_progress * 100).toStringAsFixed(0)}%' : 'Starting download…',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ],
        ],
      ),
      actions: _downloading
          ? const []
          : [
              if (!i.mandatory)
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
              ElevatedButton.icon(
                onPressed: _downloadAndInstall,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Update now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
    ),
    );
  }
}
