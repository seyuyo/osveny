import 'package:flutter/material.dart';

import 'home_shell.dart';
import 'permissions/permission_gate.dart';

/// Az alkalmazás gyökere: a főképernyő (Térkép és Debug fül) az
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
      home: const PermissionGate(child: HomeShell()),
    );
  }
}
