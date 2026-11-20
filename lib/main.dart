import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_builder2/responsive_builder2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'core/services/notification_service.dart';
import 'core/services/app_token_http_client.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (mobile only — web supports any orientation)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Set system UI overlay style (will be overridden by AnnotatedRegion in main_scaffold)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Configure responsive_builder2 breakpoints to match existing app breakpoints
  // mobile < 640, tablet 640–1024, desktop >= 1024
  ResponsiveSizingConfig.instance.setCustomBreakpoints(
    const ScreenBreakpoints(
      small: 300,  // below 300 = watch (not used in this app)
      normal: 640, // 300–640 = phone/mobile (matches AppSizes.screenSm)
      large: 1024, // >= 1024 = desktop (matches AppSizes.screenLg)
    ),
  );

  // Initialize Supabase. A custom http client attaches the parent session token
  // as an `x-app-token` header on every request so RLS can scope data to this
  // parent's students (see AppTokenHttpClient / app_pre_request).
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    httpClient: AppTokenHttpClient(),
  );

  // Initialize local notifications and schedule daily 2:05 PM reminder
  // awesome_notifications is Android/iOS only — skip on web
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
      await NotificationService.requestPermission();
      await NotificationService.scheduleDailyReminder();
    } catch (_) {}
  }

  runApp(
    const ProviderScope(
      child: SchoolFeesApp(),
    ),
  );
}
