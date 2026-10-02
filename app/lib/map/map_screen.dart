import 'package:flutter/material.dart';

/// A Térkép fül. Az M3.1–M3.3 lépésekben kap tartalmat (import, térkép,
/// élő réteg); addig üres állapotot mutat.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key('map-tab'),
      body: Center(child: Text('Még nincs térkép.')),
    );
  }
}
