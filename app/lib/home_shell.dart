import 'package:flutter/material.dart';

import 'features/debug/debug_screen.dart';
import 'map/map_screen.dart';
import 'permissions/permission_gate.dart';

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
        // Az engedélykapu csak a rögzítést védi: a térkép megnyitásához és az
        // importhoz nem kell helyzet, és helyszolgáltatás nélkül is működnie
        // kell (offline használat).
        children: const [
          MapScreen(),
          PermissionGate(child: DebugScreen()),
        ],
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
