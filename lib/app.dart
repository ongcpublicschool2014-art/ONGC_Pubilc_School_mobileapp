import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'presentation/widgets/maintenance_gate.dart';

class SchoolFeesApp extends ConsumerWidget {
  const SchoolFeesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'FIT School',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Peacock is light only, like the desktop
      routerConfig: router,
      builder: (context, child) {
        // TEXT SCALING IS CLAMPED.
        //
        // Android and iOS let a person set the system font as large as 2x. At
        // that size a row of label + amount stops fitting its line and Flutter
        // paints the yellow-and-black overflow bars over the screen -- on a
        // fee amount, which is the one thing that must always be readable.
        //
        // 1.3 is the largest that every screen here survives; below 0.85 the
        // receipt tables become unreadably small. Accessibility still works,
        // it just stops short of breaking the layout.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.3,
            ),
          ),
          // Gate every screen behind the shared maintenance flag so all
          // clients can be blocked from one hosted file during live DB work.
          child: MaintenanceGate(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}
