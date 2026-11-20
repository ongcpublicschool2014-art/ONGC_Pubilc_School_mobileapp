// Basic widget test for School Fees App

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:school_fees_app/app.dart';

void main() {
  testWidgets('App smoke test - app should build', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolFeesApp(),
      ),
    );

    // Wait for any async operations
    await tester.pumpAndSettle();

    // Verify the app builds without crashing
    expect(find.byType(SchoolFeesApp), findsOneWidget);
  });
}
