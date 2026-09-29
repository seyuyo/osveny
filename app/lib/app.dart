import 'package:flutter/material.dart';

import 'features/debug/debug_screen.dart';
import 'permissions/permission_gate.dart';

/// Az alkalmazás gyökere. M2-ben a debug képernyő a kezdőképernyő, az
/// engedélykérés kapuja mögött.
class OsvenyApp extends StatelessWidget {
  const OsvenyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Colors.green;
    return MaterialApp(
      title: 'Ösvény',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: seed)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const PermissionGate(child: DebugScreen()),
    );
  }
}
