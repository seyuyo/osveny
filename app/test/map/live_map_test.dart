import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_core/geo_core.dart';
import 'package:osveny/data/database.dart';
import 'package:osveny/map/live_map.dart';
import 'package:osveny/map/map_store.dart';
import 'package:osveny/map/pmtiles_header.dart';
import 'package:osveny/map/tile_source.dart';
import 'package:osveny/recording/location_source.dart';
import 'package:osveny/recording/recording_controller.dart';
import 'package:osveny/recording/track_profile.dart';

import 'map_test_helpers.dart';

/// Kézzel vezérelhető helyforrás (broadcast, mint a valódi GPS).
class FakeSource implements LocationSource {
  final controller = StreamController<Fix>.broadcast();

  @override
  Stream<Fix> fixes(TrackProfile profile) => controller.stream;
}

final pilis = InstalledMap(
  name: 'pilis.pmtiles',
  path: '/nincs/pilis.pmtiles',
  sizeBytes: 11 * 1024 * 1024,
  modified: DateTime(2026, 10, 2),
  info: const PmtilesInfo(
    minZoom: 0,
    maxZoom: 15,
    minLonDeg: 18.8,
    minLatDeg: 47.6,
    maxLonDeg: 19.1,
    maxLatDeg: 47.8,
    centerZoom: 8,
    centerLonDeg: 18.95,
    centerLatDeg: 47.7,
  ),
);

/// Észak felé haladó séta a Pilis közepén (kb. 11 m/s lépés, a szűrő elfogadja).
Fix walk(int i, {double hAccM = 5}) => Fix(
  tMs: 1000 * i,
  latDeg: 47.70 + i * 1e-4,
  lonDeg: 18.95,
  hAccM: hAccM,
  speedMps: 1.4,
);

void main() {
  late FakeSource source;

  setUp(() => source = FakeSource());

  /// A vezérlő valódi időben dolgozik (adatbázis), a widgetfa a hamis órában:
  /// váltogatjuk a kettőt, amíg az [until] nem teljesül.
  Future<void> settle(WidgetTester tester, bool Function() until) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (until()) return;
    }
    fail('a várt állapot nem állt be');
  }

  /// A `vector_map_tiles` 3 mp-es időzítője (lásd offline_map_test.dart).
  Future<void> drain(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  }

  /// A `vector_map_tiles` a kamera mozgásakor (pl. követés) megszakítja a
  /// folyamatban lévő csempe-rendereléseket, és ezt `CancellationException`
  /// („Cancelled”) hibaként jelenti a Flutter hibakezelőjének. Ez a könyvtár
  /// zaja (valódi eszközön is látszik a naplóban), nem hiba: csak ezt az egy,
  /// név szerint azonosított kivételt engedjük át, minden más hiba elbuktatja
  /// a tesztet. A végén a 3 mp-es időzítőt is lecsengetjük.
  void testLive(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      final original = FlutterError.onError;
      FlutterError.onError = (details) {
        final e = details.exception;
        if (e.runtimeType.toString() == 'CancellationException') return;
        original?.call(details);
      };
      try {
        await body(tester);
        await drain(tester);
      } finally {
        FlutterError.onError = original;
      }
    });
  }

  Future<ProviderContainer> pumpLive(WidgetTester tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          locationSourceProvider.overrideWithValue(source),
          tileSourceOpenerProvider.overrideWithValue(fakeTileSourceOpener),
        ],
        child: MaterialApp(
          home: Scaffold(body: LiveMap(map: pilis)),
        ),
      ),
    );
    await settle(tester, () => find.byType(FlutterMap).evaluate().isNotEmpty);
    await tester.pump(); // onMapReady
    return ProviderScope.containerOf(tester.element(find.byType(LiveMap)));
  }

  Future<void> startRecording(WidgetTester tester, ProviderContainer c) async {
    await tester.runAsync(
      () => c
          .read(recordingControllerProvider.notifier)
          .start(profile: TrackProfile.precise),
    );
    await tester.pump();
  }

  Future<void> feed(
    WidgetTester tester,
    ProviderContainer c,
    List<Fix> fixes,
  ) async {
    for (final f in fixes) {
      source.controller.add(f);
    }
    final last = fixes.last.tMs;
    await settle(tester, () {
      final recent = c.read(recordingControllerProvider).recent;
      return recent.isNotEmpty && recent.last.fix.tMs == last;
    });
    // A ritkító és a kamera frissítése.
    await settle(tester, () => true);
  }

  Iterable<Polyline<Object>> polylines(WidgetTester tester) => tester
      .widgetList<PolylineLayer<Object>>(
        find.byWidgetPredicate((w) => w is PolylineLayer),
      )
      .expand((l) => l.polylines);

  List<CircleMarker<Object>> circles(WidgetTester tester) => tester
      .widgetList<CircleLayer<Object>>(
        find.byWidgetPredicate((w) => w is CircleLayer),
      )
      .expand((l) => l.circles)
      .toList();

  LatLngLike center(WidgetTester tester) {
    final c = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera
        .center;
    return (c.latitude, c.longitude);
  }

  testLive('rögzítés nélkül nincs nyomvonal és pozíció', (tester) async {
    await pumpLive(tester);

    expect(polylines(tester), isEmpty);
    expect(circles(tester), isEmpty);
    expect(find.byTooltip('Követés'), findsNothing);
  });

  testLive(
    'rögzítés közben: nyomvonal az elfogadott pontokból, pozíció pontossági körrel',
    (tester) async {
      final c = await pumpLive(tester);
      await startRecording(tester, c);
      await feed(tester, c, [
        walk(0),
        walk(1),
        walk(2, hAccM: 100), // a szűrő eldobja: nem kerül a vonalba
        walk(3),
        walk(4, hAccM: 12),
      ]);

      final line = polylines(tester).single;
      expect(line.points.length, 4);
      expect(line.points.last.latitude, closeTo(walk(4).latDeg, 1e-9));

      final cs = circles(tester);
      final accuracy = cs.firstWhere((m) => m.useRadiusInMeter);
      expect(accuracy.radius, 12, reason: 'a legutóbbi fix pontossága');
      expect(accuracy.point.latitude, closeTo(walk(4).latDeg, 1e-9));
      expect(
        cs.where((m) => !m.useRadiusInMeter),
        hasLength(1),
        reason: 'a pozíciót jelölő pötty',
      );
    },
  );

  testLive('követés: a térkép a legutóbbi pozícióra áll', (tester) async {
    final c = await pumpLive(tester);
    await startRecording(tester, c);
    await feed(tester, c, [walk(0), walk(1), walk(5)]);

    final (lat, lon) = center(tester);
    expect(lat, closeTo(walk(5).latDeg, 1e-6));
    expect(lon, closeTo(walk(5).lonDeg, 1e-6));
    expect(find.byTooltip('Követés'), findsNothing);
  });

  testLive('kézi húzás kikapcsolja a követést, a gomb visszakapcsolja', (
    tester,
  ) async {
    final c = await pumpLive(tester);
    await startRecording(tester, c);
    await feed(tester, c, [walk(0), walk(1)]);

    await tester.drag(find.byType(FlutterMap), const Offset(120, 0));
    await tester.pump();
    expect(find.byTooltip('Követés'), findsOneWidget);
    final moved = center(tester);

    // Követés nélkül az új fix nem mozgatja a térképet.
    await feed(tester, c, [walk(2)]);
    expect(center(tester), moved);

    await tester.tap(find.byTooltip('Követés'));
    await tester.pump();
    final (lat, lon) = center(tester);
    expect(lat, closeTo(walk(2).latDeg, 1e-6));
    expect(lon, closeTo(walk(2).lonDeg, 1e-6));
    expect(find.byTooltip('Követés'), findsNothing);

    // Újra követ: a következő fixre is ráugrik.
    await feed(tester, c, [walk(3)]);
    expect(center(tester).$1, closeTo(walk(3).latDeg, 1e-6));
  });

  testLive('szünetben a pozíció eltűnik, a nyomvonal megmarad', (tester) async {
    final c = await pumpLive(tester);
    await startRecording(tester, c);
    await feed(tester, c, [walk(0), walk(1), walk(2)]);

    // Nem `runAsync`-ban várjuk meg: a pause a hamis órájú zónában indult
    // mentési láncra vár, amit a valós zóna közben nem léptet (holtpont).
    unawaited(c.read(recordingControllerProvider.notifier).pause());
    await settle(tester, () => circles(tester).isEmpty);

    expect(polylines(tester).single.points.length, 3);
  });
}

typedef LatLngLike = (double, double);
