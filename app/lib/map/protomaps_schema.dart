import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

/// A Protomaps-alaptérkép csempéinek sémája. A témának a séma verziójához kell
/// tartoznia: a v3 és a v4 más mezőneveket használ (pl. `pmap:kind` / `kind`),
/// ezért egy v4-es fájlt v3-as témával elrontva rajzolnánk ki.
enum ProtomapsSchema { v3, v4 }

/// A PMTiles-metaadat `version` mezőjéből a séma. A hiányzó vagy
/// értelmezhetetlen érték v4: a jelenlegi napi buildek ilyenek.
ProtomapsSchema schemaFromMetadata(Object? metadata) {
  if (metadata is! Map) return ProtomapsSchema.v4;
  final version = metadata['version'];
  final major = switch (version) {
    final num n => n.floor(),
    final String s => int.tryParse(s.split('.').first),
    _ => null,
  };
  return major == 3 ? ProtomapsSchema.v3 : ProtomapsSchema.v4;
}

// A témák felépítése (a JSON-stílus feldolgozása) költséges, ezért a felső
// szintű változók lustán, az első használatkor, egyszer épülnek fel.
//
// A típust szándékosan nem nevezzük meg: a renderelő `Theme` osztálya a
// `vector_tile_renderer`-ből jön, ami csak tranzitív függőség (a
// `vector_map_tiles` nem exportálja), új függőséget pedig nem vettünk fel.
//
// A témák `glyphs`/`sprites` URL-jeit a renderelő nem használja (a sprite-ot
// a `VectorTileLayer`-nek kellene átadni, ezt nem tesszük), így nincs
// hálózati kérés; lásd DECISIONS.md.
final protomapsLightV3 = ProtomapsThemes.lightV3();
final protomapsDarkV3 = ProtomapsThemes.darkV3();
final protomapsLightV4 = ProtomapsThemes.lightV4();
final protomapsDarkV4 = ProtomapsThemes.darkV4();
