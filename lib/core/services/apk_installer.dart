/// Platform-selecting facade for the APK downloader/installer. On native
/// (Android) this resolves to the dart:io implementation; on web it resolves to
/// the stub so the app stays web-compilable.
export 'apk_installer_stub.dart' if (dart.library.io) 'apk_installer_io.dart';
