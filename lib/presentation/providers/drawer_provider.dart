import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single stable GlobalKey for the main scaffold
final GlobalKey<ScaffoldState> _mainScaffoldKey = GlobalKey<ScaffoldState>();

/// Provider to hold the main scaffold key for opening the drawer from any screen
final mainScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return _mainScaffoldKey;
});

/// Helper function to open the main drawer from any screen
void openMainDrawer(WidgetRef ref) {
  _mainScaffoldKey.currentState?.openDrawer();
}
