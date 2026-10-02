import 'package:flutter/material.dart';

import 'features/debug/debug_screen.dart';
import 'map/map_screen.dart';

/// Az alkalmazás főképernyője: alsó navigációs sáv a Térkép és a Debug fül
/// között. Az `IndexedStack` megőrzi a fülök állapotát (térképnézet, a debug
/// képernyő profilválasztása) váltáskor.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [MapScreen(), DebugScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Térkép',
          ),
          NavigationDestination(
            icon: Icon(Icons.bug_report_outlined),
            selectedIcon: Icon(Icons.bug_report),
            label: 'Debug',
          ),
        ],
      ),
    );
  }
}
