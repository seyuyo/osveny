import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_core/geo_core.dart';
import 'package:geo_core/testing.dart';
import 'package:osveny/data/database.dart';
import 'package:osveny/features/debug/csv_export.dart';
import 'package:osveny/features/debug/debug_screen.dart';
import 'package:osveny/recording/location_source.dart';
import 'package:osveny/recording/recording_controller.dart';
import 'package:osveny/recording/track_profile.dart';

Fix fix(int tMs, {double hAccM = 5}) =>
    Fix(tMs: tMs, latDeg: 47.5 + tMs * 1e-7, lonDeg: 19.0, hAccM: hAccM);

class _FailingSource implements LocationSource {
  @override
  Stream<Fix> fixes(TrackProfile profile) =>
      Stream.error(StateError('helyszolgáltatás kikapcsolva'));
}

void main() {
  late AppDatabase db;
  late List<({String fileName, String csv})> exported;

  /// A képernyő kapu nélkül, fake forrással és exportálóval. A `ProviderScope`
  /// a fa lebontásakor felszabadítja a controllert (és a puffer időzítőjét).
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    List<Fix> playback = const [],
    LocationSource? source,
    Future<void> Function()? seedDb,
    bool restore = false,
  }) async {
    exported = [];
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    if (seedDb != null) await tester.runAsync(seedDb);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          locationSourceProvider.overrideWithValue(
            source ?? ReplayLocationSource(playback),
          ),
          csvExporterProvider.overrideWithValue(
            ({required fileName, required csv}) async =>
                exported.add((fileName: fileName, csv: csv)),
          ),
        ],
        child: const MaterialApp(home: DebugScreen()),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(DebugScreen)),
    );
    if (restore) {
      await tester.runAsync(
        container.read(recordingControllerProvider.notifier).restore,
      );
      await tester.pump();
    }
    return container;
  }

  /// Az adatbázis és az isolate valódi időben fut: kis lépésekben várunk, amíg
  /// az [until] igaz nem lesz (legfeljebb ~5 s).
  Future<void> settle(WidgetTester tester, {bool Function()? until}) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      if (i >= 1 && (until == null || until())) return;
    }
    fail('a várt állapot nem állt be');
  }

  Future<void> tapAndSettle(
    WidgetTester tester,
    String label, {
    bool Function()? until,
  }) async {
    await tester.tap(find.text(label));
    await settle(tester, until: until);
  }

  bool shows(String text) => find.text(text).evaluate().isNotEmpty;

  testWidgets('üresjárat: indítás gomb, profilválasztó, nincs export', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Nem rögzít'), findsOneWidget);
    expect(find.text('Rögzítés indítása'), findsOneWidget);
    expect(find.text('Pontos'), findsOneWidget);
    expect(find.text('Akkukímélő'), findsOneWidget);
    expect(find.text('CSV exportálás'), findsNothing);
  });

  testWidgets('indítás a kiválasztott profillal', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Akkukímélő'));
    await tester.pump();
    await tapAndSettle(
      tester,
      'Rögzítés indítása',
      until: () => shows('Rögzítés folyamatban'),
    );

    final t = (await tester.runAsync(db.latestTrack))!;
    expect(t.profile, TrackProfile.batterySaver);
    expect(find.text('Szünet'), findsOneWidget);
    expect(find.text('Befejezés'), findsOneWidget);
  });

  testWidgets('élő lista, elfogadott/eldobott arány és az ok', (tester) async {
    await pumpScreen(
      tester,
      playback: [fix(1000), fix(2000, hAccM: 100), fix(3000)],
    );
    await tapAndSettle(
      tester,
      'Rögzítés indítása',
      until: () => find.byKey(const Key('fix-3000')).evaluate().isNotEmpty,
    );

    expect(find.byKey(const Key('fix-1000')), findsOneWidget);
    expect(find.byKey(const Key('fix-2000')), findsOneWidget);
    expect(find.textContaining('Elfogadva: 2'), findsOneWidget);
    expect(find.textContaining('Eldobva: 1'), findsOneWidget);
    expect(find.textContaining('33%'), findsOneWidget);
    expect(find.textContaining('Pontatlan: 1'), findsOneWidget);
    expect(find.textContaining('Memóriában: 3'), findsOneWidget);
  });

  testWidgets('a legújabb fix van legfelül', (tester) async {
    await pumpScreen(tester, playback: [fix(1000), fix(2000)]);
    await tapAndSettle(
      tester,
      'Rögzítés indítása',
      until: () => find.byKey(const Key('fix-2000')).evaluate().isNotEmpty,
    );

    final newer = tester.getTopLeft(find.byKey(const Key('fix-2000')));
    final older = tester.getTopLeft(find.byKey(const Key('fix-1000')));
    expect(newer.dy, lessThan(older.dy));
  });

  testWidgets('szünet, folytatás, befejezés a gombokkal', (tester) async {
    await pumpScreen(tester);
    await tapAndSettle(
      tester,
      'Rögzítés indítása',
      until: () => shows('Rögzítés folyamatban'),
    );

    await tapAndSettle(tester, 'Szünet', until: () => shows('Szüneteltetve'));
    expect(find.text('Folytatás'), findsOneWidget);

    await tapAndSettle(
      tester,
      'Folytatás',
      until: () => shows('Rögzítés folyamatban'),
    );

    await tapAndSettle(tester, 'Befejezés', until: () => shows('Lezárva'));
    expect(find.text('Rögzítés indítása'), findsOneWidget);
  });

  testWidgets('félbemaradt rögzítés: folytatás vagy lezárás felajánlva', (
    tester,
  ) async {
    late int id;
    await pumpScreen(
      tester,
      restore: true,
      seedDb: () async {
        id = await db.createTrack(
          name: 'Kilőtt',
          profile: TrackProfile.precise,
          startedAtMs: 0,
        );
        await db.openSegment(id, 0);
        await db.insertFixBatch(id, [fix(1000), fix(2000)]);
      },
    );

    expect(find.text('Félbemaradt rögzítés'), findsWidgets);
    expect(find.text('Folytatás'), findsOneWidget);
    expect(find.text('Lezárás'), findsOneWidget);
    expect(find.text('Rögzítés indítása'), findsNothing);

    await tapAndSettle(tester, 'Lezárás', until: () => shows('Lezárva'));
    final t = (await tester.runAsync(() => db.trackById(id)))!;
    expect(t.status, TrackStatus.finished);
  });

  testWidgets('félbemaradt rögzítés folytatása', (tester) async {
    late int id;
    await pumpScreen(
      tester,
      restore: true,
      seedDb: () async {
        id = await db.createTrack(
          name: 'Kilőtt',
          profile: TrackProfile.precise,
          startedAtMs: 0,
        );
        await db.openSegment(id, 0);
        await db.insertFixBatch(id, [fix(1000)]);
      },
    );
    await tapAndSettle(
      tester,
      'Folytatás',
      until: () => shows('Rögzítés folyamatban'),
    );

    final t = (await tester.runAsync(() => db.trackById(id)))!;
    expect(t.status, TrackStatus.recording);
  });

  testWidgets('nyers CSV-export: a DB fixei, a geo_core formátumában', (
    tester,
  ) async {
    final playback = [fix(1000), fix(2000, hAccM: 100), fix(3000)];
    final container = await pumpScreen(tester, playback: playback);
    await tapAndSettle(
      tester,
      'Rögzítés indítása',
      until: () => find.byKey(const Key('fix-3000')).evaluate().isNotEmpty,
    );
    await tapAndSettle(tester, 'Befejezés', until: () => shows('Lezárva'));
    await tapAndSettle(
      tester,
      'CSV exportálás',
      until: () => exported.isNotEmpty,
    );

    final id = container.read(recordingControllerProvider).trackId;
    expect(exported, hasLength(1));
    expect(exported.single.fileName, 'osveny_track_$id.csv');
    expect(exported.single.csv, fixesToCsv(playback));
    expect(
      parseFixCsv(exported.single.csv),
      playback,
      reason: 'a szűrő által eldobott fix is a nyers exportban van',
    );
  });

  testWidgets('a helyforrás hibája látszik, nem nyelődik el', (tester) async {
    await pumpScreen(tester, source: _FailingSource());
    await tapAndSettle(
      tester,
      'Rögzítés indítása',
      until: () => find
          .textContaining('helyszolgáltatás kikapcsolva')
          .evaluate()
          .isNotEmpty,
    );

    expect(find.text('Rögzítés folyamatban'), findsOneWidget);
  });
}
