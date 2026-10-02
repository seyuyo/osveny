import 'dart:typed_data';

import 'package:osveny/map/map_file_picker.dart';
import 'package:osveny/map/map_store.dart';
import 'package:osveny/map/protomaps_schema.dart';
import 'package:osveny/map/tile_source.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

/// Kézzel vezérelhető fájlkiválasztó a tesztekhez.
class FakePicker implements MapFilePicker {
  ImportSource? next;
  Object? error;
  int calls = 0;

  @override
  Future<ImportSource?> pick() async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return next;
  }
}

/// A bájtokból kis darabokban olvasható forrás (a folyamatjelző teszteléséhez).
ImportSource sourceOf(String name, Uint8List bytes, {int chunk = 40}) =>
    ImportSource(
      name: name,
      length: bytes.length,
      open: () => Stream.fromIterable([
        for (var i = 0; i < bytes.length; i += chunk)
          bytes.sublist(i, i + chunk > bytes.length ? bytes.length : i + chunk),
      ]),
    );

/// Üres csempéket adó forrás: nincs benne valódi térkép, a widgetek
/// bekötését teszteljük, nem a rajzolást (azt a valódi eszközön nézzük).
class FakeTileProvider extends VectorTileProvider {
  @override
  int get maximumZoom => 15;

  @override
  int get minimumZoom => 0;

  @override
  Future<Uint8List> provide(TileIdentity tile) async => Uint8List(0);
}

/// A csempeforrás-megnyitó hamis változata: nem nyúl a fájlhoz.
Future<OpenedTileSource> fakeTileSourceOpener(String path) async =>
    OpenedTileSource(
      provider: FakeTileProvider(),
      schema: ProtomapsSchema.v4,
      close: () async {},
    );
