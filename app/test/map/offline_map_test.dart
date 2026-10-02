import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/map/map_store.dart';
import 'package:osveny/map/offline_map.dart';
import 'package:osveny/map/pmtiles_header.dart';
import 'package:osveny/map/protomaps_schema.dart';
import 'package:osveny/map/tile_source.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';

import 'map_test_helpers.dart';

InstalledMap installedMap({
  String name = 'pilis.pmtiles',
  int minZoom = 0,
  int maxZoom = 15,
}) => InstalledMap(
  name: name,
  path: '/nincs/$name',
  sizeBytes: 11 * 1024 * 1024,
  modified: DateTime(2026, 10, 2),
  info: PmtilesInfo(
    minZoom: minZoom,
    maxZoom: maxZoom,
    minLonDeg: 18.8,
    minLatDeg: 47.6,
    maxLonDeg: 19.1,
    maxLatDeg: 47.8,
    centerZoom: 8,
    centerLonDeg: 18.95,
    centerLatDeg: 47.7,
  ),
);

void main() {
  /// A `vector_map_tiles` réteg `initState`-je 3 másodperces
  /// `Future.delayed`-et indít, amit a `dispose` nem állít le. A teszt végén
  /// a fa lebontása után léptetjük az órát, különben a teszt függő időzítő
  /// miatt elbukna.
  void testMap(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    });
  }

  late List<String> opened;
  late int closed;
  ProtomapsSchema schema = ProtomapsSchema.v4;
  Object? openError;
  Completer<void>? gate;

  setUp(() {
    opened = [];
    closed = 0;
    schema = ProtomapsSchema.v4;
    openError = null;
    gate = null;
  });

  Future<OpenedTileSource> fakeOpener(String path) async {
    opened.add(path);
    await gate?.future;
    final e = openError;
    if (e != null) throw e;
    return OpenedTileSource(
      provider: FakeTileProvider(),
      schema: schema,
      close: () async => closed++,
    );
  }

  Widget host(InstalledMap map, {Brightness brightness = Brightness.light}) =>
      ProviderScope(
        overrides: [tileSourceOpenerProvider.overrideWithValue(fakeOpener)],
        child: MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: Scaffold(body: OfflineMap(map: map)),
        ),
      );

  VectorTileLayer layer(WidgetTester tester) =>
      tester.widget<VectorTileLayer>(find.byType(VectorTileLayer));

  testMap('megnyitás közben töltésjelző, utána a térkép és az attribúció', (
    tester,
  ) async {
    gate = Completer<void>();
    await tester.pumpWidget(host(installedMap()));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);

    gate!.complete();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(VectorTileLayer), findsOneWidget);
    expect(opened, ['/nincs/pilis.pmtiles']);
  });

  testMap('az attribúció látható: OpenStreetMap és Protomaps', (tester) async {
    await tester.pumpWidget(host(installedMap()));
    await tester.pump();
    await tester.pump();

    final text = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('map-attribution')),
        matching: find.byType(Text),
      ),
    );
    expect(text.data, contains('OpenStreetMap'));
    expect(text.data, contains('Protomaps'));
  });

  testMap('csak a téma `protomaps` forrását kötjük be, hálózati réteg nélkül', (
    tester,
  ) async {
    await tester.pumpWidget(host(installedMap()));
    await tester.pump();
    await tester.pump();

    final providers = layer(tester).tileProviders.tileProviderBySource;
    expect(providers.keys, ['protomaps']);
    expect(providers['protomaps'], isA<FakeTileProvider>());
    expect(
      layer(tester).sprites,
      isNull,
      reason: 'sprite nélkül a renderelő nem kér semmit a hálózatról',
    );
    expect(layer(tester).fileCacheTtl, Duration.zero);
  });

  group('téma', () {
    Future<void> pumpTheme(
      WidgetTester tester,
      ProtomapsSchema s,
      Brightness b,
    ) async {
      schema = s;
      await tester.pumpWidget(host(installedMap(), brightness: b));
      await tester.pump();
      await tester.pump();
    }

    testMap('v4 + világos', (tester) async {
      await pumpTheme(tester, ProtomapsSchema.v4, Brightness.light);
      expect(identical(layer(tester).theme, protomapsLightV4), isTrue);
    });

    testMap('v4 + sötét', (tester) async {
      await pumpTheme(tester, ProtomapsSchema.v4, Brightness.dark);
      expect(identical(layer(tester).theme, protomapsDarkV4), isTrue);
    });

    testMap('v3 + világos', (tester) async {
      await pumpTheme(tester, ProtomapsSchema.v3, Brightness.light);
      expect(identical(layer(tester).theme, protomapsLightV3), isTrue);
    });

    testMap('v3 + sötét', (tester) async {
      await pumpTheme(tester, ProtomapsSchema.v3, Brightness.dark);
      expect(identical(layer(tester).theme, protomapsDarkV3), isTrue);
    });
  });

  group('kamera a fájl adataihoz igazodik', () {
    testMap('legkisebb zoom a fájlé, a legnagyobb 2 szinttel több', (
      tester,
    ) async {
      await tester.pumpWidget(host(installedMap(minZoom: 2, maxZoom: 14)));
      await tester.pump();
      await tester.pump();

      final options = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .options;
      expect(options.minZoom, 2);
      expect(options.maxZoom, 16);
    });

    testMap('induláskor a fájl határaira illeszkedik', (tester) async {
      await tester.pumpWidget(host(installedMap()));
      await tester.pump();
      await tester.pump();

      final options = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .options;
      final fit = options.initialCameraFit;
      expect(fit, isA<FitBounds>());
      final bounds = (fit! as FitBounds).bounds;
      expect(bounds.south, closeTo(47.6, 1e-9));
      expect(bounds.north, closeTo(47.8, 1e-9));
      expect(bounds.west, closeTo(18.8, 1e-9));
      expect(bounds.east, closeTo(19.1, 1e-9));
    });
  });

  group('bővítési pontok az élő térképhez', () {
    testMap('a rétegek a csempék fölé, a térképen belülre kerülnek', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tileSourceOpenerProvider.overrideWithValue(fakeOpener)],
          child: MaterialApp(
            home: Scaffold(
              body: OfflineMap(
                map: installedMap(),
                layers: const [SizedBox(key: Key('saját-réteg'))],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(FlutterMap),
          matching: find.byKey(const Key('saját-réteg')),
        ),
        findsOneWidget,
      );
      // A csemperéteg alatta van (előbb szerepel a gyerekek között).
      final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(map.children.first, isA<VectorTileLayer>());
      expect((map.children.last as SizedBox).key, const Key('saját-réteg'));
    });

    testMap('a kívülről adott MapController a térképhez kapcsolódik, '
        'és a kész jelzés megérkezik', (tester) async {
      final controller = MapController();
      var ready = false;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tileSourceOpenerProvider.overrideWithValue(fakeOpener)],
          child: MaterialApp(
            home: Scaffold(
              body: OfflineMap(
                map: installedMap(),
                mapController: controller,
                onMapReady: () => ready = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      // Az `onMapReady` a FlutterMap első képkockája utáni callbackben jön.
      await tester.pump();

      expect(ready, isTrue);
      final center = controller.camera.center;
      expect(center.latitude, closeTo(47.7, 0.05));
      expect(center.longitude, closeTo(18.95, 0.05));
    });

    testMap('a térkép eseményei kifelé is eljutnak (húzás)', (tester) async {
      final sources = <MapEventSource>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [tileSourceOpenerProvider.overrideWithValue(fakeOpener)],
          child: MaterialApp(
            home: Scaffold(
              body: OfflineMap(
                map: installedMap(),
                onMapEvent: (e) => sources.add(e.source),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      await tester.drag(find.byType(FlutterMap), const Offset(80, 40));
      await tester.pump();

      expect(sources, contains(MapEventSource.onDrag));
    });
  });

  testMap('megnyitási hiba: érthető üzenet, nem összeomlás', (tester) async {
    openError = StateError('sérült');
    await tester.pumpWidget(host(installedMap()));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('map-open-error')), findsOneWidget);
    expect(find.textContaining('nem nyitható meg'), findsOneWidget);
    expect(find.byType(FlutterMap), findsNothing);
  });

  testMap('eltávolításkor lezárja a megnyitott archívumot', (tester) async {
    await tester.pumpWidget(host(installedMap()));
    await tester.pump();
    await tester.pump();
    expect(closed, 0);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(closed, 1);
  });

  testMap('másik térképre váltva a régit lezárja, az újat megnyitja', (
    tester,
  ) async {
    await tester.pumpWidget(host(installedMap(name: 'a.pmtiles')));
    await tester.pump();
    await tester.pump();

    await tester.pumpWidget(host(installedMap(name: 'b.pmtiles')));
    await tester.pump();
    await tester.pump();

    expect(opened, ['/nincs/a.pmtiles', '/nincs/b.pmtiles']);
    expect(closed, 1);
    expect(find.byType(VectorTileLayer), findsOneWidget);
  });

  testMap(
    'másik térképre váltva a FlutterMap és a csemperéteg állapota újraépül',
    (tester) async {
      // Valódi eszközön a régi térkép állapota ragadt a rétegben, és az új
      // térkép üresen maradt: a belső állapot (csempe-szolgáltató, kezdő
      // kameraillesztés) csak újraépítéssel frissül. Az elemek azonosságát
      // vizsgáljuk: újraépítéskor új elem jön létre.
      await tester.pumpWidget(host(installedMap(name: 'a.pmtiles')));
      await tester.pump();
      await tester.pump();
      final mapBefore = tester.element(find.byType(FlutterMap));
      final layerBefore = tester.element(find.byType(VectorTileLayer));

      await tester.pumpWidget(host(installedMap(name: 'b.pmtiles')));
      await tester.pump();
      await tester.pump();

      expect(
        identical(tester.element(find.byType(FlutterMap)), mapBefore),
        isFalse,
        reason: 'új FlutterMap kell, hogy az új fájl határaira illeszkedjen',
      );
      expect(
        identical(tester.element(find.byType(VectorTileLayer)), layerBefore),
        isFalse,
        reason: 'új csemperéteg kell az új csempe-szolgáltatóval',
      );
    },
  );

  testMap('ugyanazon térkép újraépítésénél az állapot megmarad', (
    tester,
  ) async {
    final map = installedMap();
    await tester.pumpWidget(host(map));
    await tester.pump();
    await tester.pump();
    final mapBefore = tester.element(find.byType(FlutterMap));

    await tester.pumpWidget(host(map));
    await tester.pump();

    expect(
      identical(tester.element(find.byType(FlutterMap)), mapBefore),
      isTrue,
    );
  });

  testMap('ugyanannak a térképnek az újraépítése nem nyit újra', (
    tester,
  ) async {
    final map = installedMap();
    await tester.pumpWidget(host(map));
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(host(map));
    await tester.pump();

    expect(opened.length, 1);
    expect(closed, 0);
  });

  testMap('megnyitás közben eltávolítva a megnyílt archívum is lezárul', (
    tester,
  ) async {
    gate = Completer<void>();
    await tester.pumpWidget(host(installedMap()));
    await tester.pumpWidget(const SizedBox());

    gate!.complete();
    await tester.pump();
    await tester.pump();

    expect(closed, 1);
  });
}
