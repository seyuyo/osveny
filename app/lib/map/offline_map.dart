import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import 'map_store.dart';
import 'protomaps_schema.dart';
import 'tile_source.dart';

/// Az aktív térkép megjelenítése: `flutter_map` + vektoros PMTiles-réteg
/// Protomaps-témával (a séma és a rendszer világos/sötét módja szerint).
/// Hálózati kérés nincs: a csempék a helyi fájlból jönnek.
class OfflineMap extends ConsumerStatefulWidget {
  const OfflineMap({
    super.key,
    required this.map,
    this.mapController,
    this.onMapEvent,
    this.onMapReady,
    this.layers = const [],
  });

  final InstalledMap map;

  /// A kamera vezérléséhez (követő mód); ha nincs, a térkép sajátot használ.
  final MapController? mapController;

  /// A térkép eseményei (pl. kézi mozgatás felismeréséhez).
  final MapEventCallback? onMapEvent;

  /// Akkor hívódik, amikor a [mapController] már használható.
  final VoidCallback? onMapReady;

  /// Rétegek a csempék fölé (nyomvonal, pozíció).
  final List<Widget> layers;

  @override
  ConsumerState<OfflineMap> createState() => _OfflineMapState();
}

class _OfflineMapState extends ConsumerState<OfflineMap> {
  late Future<OpenedTileSource> _opening;

  @override
  void initState() {
    super.initState();
    _opening = _open();
  }

  @override
  void didUpdateWidget(OfflineMap old) {
    super.didUpdateWidget(old);
    // Másik térkép: a régit lezárjuk, az újat megnyitjuk. Ugyanazon fájl
    // újraépítésénél nem nyitunk újra.
    if (old.map.path != widget.map.path) {
      _close(_opening);
      _opening = _open();
    }
  }

  @override
  void dispose() {
    _close(_opening);
    super.dispose();
  }

  Future<OpenedTileSource> _open() =>
      ref.read(tileSourceOpenerProvider)(widget.map.path);

  /// A megnyitás eredményétől függetlenül lezárja a forrást; ha a megnyitás
  /// hibázott, nincs mit lezárni.
  void _close(Future<OpenedTileSource> opening) {
    opening.then((source) => source.close()).catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OpenedTileSource>(
      future: _opening,
      builder: (context, snapshot) {
        // Új `Future`-nél a FutureBuilder egy képkockára megtartja a régi
        // adatot (vagy hibát): addig töltésjelzőt mutatunk, különben az új
        // térkép nézete a régi csempeforrással épülne fel, és az újonnan
        // megnyílt forrás érkezésekor már nem épülne újra.
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) return const _OpenError();
        final source = snapshot.requireData;
        // A kulcs a fájl útvonala: másik térképre váltva a FlutterMap és a
        // csemperéteg belső állapota (csempe-szolgáltató, kezdő
        // kameraillesztés) újraépül. Enélkül valódi eszközön a régi térkép
        // állapota ragadt a rétegben, és az új térkép üresen maradt.
        return _MapView(
          key: ValueKey(widget.map.path),
          map: widget.map,
          source: source,
          mapController: widget.mapController,
          onMapEvent: widget.onMapEvent,
          onMapReady: widget.onMapReady,
          layers: widget.layers,
        );
      },
    );
  }
}

class _MapView extends StatelessWidget {
  const _MapView({
    super.key,
    required this.map,
    required this.source,
    required this.mapController,
    required this.onMapEvent,
    required this.onMapReady,
    required this.layers,
  });

  final InstalledMap map;
  final OpenedTileSource source;
  final MapController? mapController;
  final MapEventCallback? onMapEvent;
  final VoidCallback? onMapReady;
  final List<Widget> layers;

  /// A letöltött területen túl a nagyítás a csempék legnagyobb zoomjánál
  /// ennyivel mehet tovább: a vektoros csempék élesen felskálázhatók.
  static const _overzoom = 2;

  @override
  Widget build(BuildContext context) {
    final info = map.info;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bounds = LatLngBounds(
      LatLng(info.minLatDeg, info.minLonDeg),
      LatLng(info.maxLatDeg, info.maxLonDeg),
    );

    // A témát a séma és a mód választja; a típus neve nem szerepel (lásd
    // protomaps_schema.dart).
    final theme = switch ((source.schema, dark)) {
      (ProtomapsSchema.v3, false) => protomapsLightV3,
      (ProtomapsSchema.v3, true) => protomapsDarkV3,
      (ProtomapsSchema.v4, false) => protomapsLightV4,
      (ProtomapsSchema.v4, true) => protomapsDarkV4,
    };

    return Stack(
      key: const Key('offline-map'),
      children: [
        FlutterMap(
          mapController: mapController,
          options: MapOptions(
            onMapEvent: onMapEvent,
            onMapReady: onMapReady,
            // Az illesztés előtti kezdő kamera is a terület közepére kerül:
            // külső MapControllernél a flutter_map ezt is ellenőrzi a
            // `containCenter` korláttal, és az alapértelmezett (é. sz. 50°,
            // k. h. 0°) közép assert-hibát adna.
            initialCenter: bounds.center,
            initialCameraFit: CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.all(16),
            ),
            minZoom: info.minZoom.toDouble(),
            maxZoom: (info.maxZoom + _overzoom).toDouble(),
            // A közép a letöltött területen belül marad: nem lehet a
            // végtelen üres háttérbe pásztázni.
            cameraConstraint: CameraConstraint.containCenter(bounds: bounds),
            backgroundColor: Theme.of(context).colorScheme.surface,
          ),
          children: [
            VectorTileLayer(
              theme: theme,
              tileProviders: TileProviders({'protomaps': source.provider}),
              // Helyi fájlból olvasunk, a gyorsítótár térképcsere után
              // elavult csempét adhatna (DECISIONS.md).
              fileCacheTtl: Duration.zero,
            ),
            ...layers,
          ],
        ),
        const Align(
          alignment: Alignment.bottomRight,
          child: _Attribution(key: Key('map-attribution')),
        ),
      ],
    );
  }
}

/// A Protomaps és az OpenStreetMap forrásmegjelölése (az ODbL megköveteli).
class _Attribution extends StatelessWidget {
  const _Attribution({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.8),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          '© OpenStreetMap · Protomaps',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _OpenError extends StatelessWidget {
  const _OpenError();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('map-open-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'A térkép nem nyitható meg.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'A fájl sérült lehet. Töröld a Térképek kezelése oldalon, és '
              'importáld újra.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
