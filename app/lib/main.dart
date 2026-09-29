import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database.dart';
import 'recording/geolocator_location_source.dart';
import 'recording/recording_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(AppDatabase.open()),
      locationSourceProvider.overrideWithValue(
        const GeolocatorLocationSource(),
      ),
    ],
  );

  // Folyamatonként egyszer: félbemaradt rögzítés keresése az adatbázisban.
  unawaited(container.read(recordingControllerProvider.notifier).restore());

  runApp(
    UncontrolledProviderScope(container: container, child: const OsvenyApp()),
  );
}
