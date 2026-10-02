import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

import 'protomaps_schema.dart';

/// Egy megnyitott térképfájl: a csempék forrása, a csempék sémája és a
/// lezárás (a fájlolvasó erőforrásainak felszabadítása).
class OpenedTileSource {
  const OpenedTileSource({
    required this.provider,
    required this.schema,
    required this.close,
  });

  final VectorTileProvider provider;
  final ProtomapsSchema schema;
  final Future<void> Function() close;
}

/// A térképfájl megnyitása. Cserélhető a teszthez.
typedef TileSourceOpener = Future<OpenedTileSource> Function(String path);

final tileSourceOpenerProvider = Provider<TileSourceOpener>(
  (ref) => openPmtilesSource,
);

/// Helyi `.pmtiles` fájl megnyitása. Csak fájlrendszerbeli útvonalat fogad el:
/// az URL-ek olvasása hálózati kérés lenne, azt nem engedjük.
Future<OpenedTileSource> openPmtilesSource(String path) async {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    throw ArgumentError.value(path, 'path', 'csak helyi fájl nyitható meg');
  }
  final provider = await PmTilesVectorTileProvider.fromSource(path);
  Object? metadata;
  try {
    metadata = await provider.archive.metadata;
  } catch (_) {
    // Hibás metaadat: a séma ismeretlen, az alapértelmezés lép érvénybe.
  }
  return OpenedTileSource(
    provider: provider,
    schema: schemaFromMetadata(metadata),
    close: provider.archive.close,
  );
}
