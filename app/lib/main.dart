import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'data/database.dart';
import 'map/map_library_controller.dart';
import 'map/map_store.dart';
import 'recording/geolocator_location_source.dart';
import 'recording/recording_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Az importált térképek az app saját dokumentummappájában élnek.
  final docs = await getApplicationDocumentsDirectory();
  final mapsDir = Directory('${docs.path}${Platform.pathSeparator}maps');

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(AppDatabase.open()),
      locationSourceProvider.overrideWithValue(
        const GeolocatorLocationSource(),
      ),
      mapStoreProvider.overrideWithValue(MapStore(mapsDir)),
    ],
  );

  // Folyamatonként egyszer: félbemaradt rögzítés keresése az adatbázisban.
  unawaited(container.read(recordingControllerProvider.notifier).restore());

  runApp(
    UncontrolledProviderScope(container: container, child: const OsvenyApp()),
  );
}
