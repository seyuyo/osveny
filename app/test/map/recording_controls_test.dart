import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_core/geo_core.dart';
import 'package:osveny/data/database.dart';
import 'package:osveny/map/recording_controls.dart';
import 'package:osveny/permissions/permission_gateway.dart';
import 'package:osveny/recording/location_source.dart';
import 'package:osveny/recording/recording_controller.dart';
import 'package:osveny/recording/track_profile.dart';

import '../permissions/fake_permission_gateway.dart';

class FakeSource implements LocationSource {
  final controller = StreamController<Fix>.broadcast();

  @override
  Stream<Fix> fixes(TrackProfile profile) => controller.stream;
}

void main() {
  late FakeGateway gw;
  late AppDatabase db;

  setUp(() {
    gw = FakeGateway()
      ..access = LocationAccess.granted
      ..notification = true;
  });

  /// Az adatbázis valódi időben dolgozik: a `runAsync` és a `pump`
  /// váltogatásával várunk, amíg az [until] nem teljesül.
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

  Future<ProviderContainer> pumpControls(
    WidgetTester tester, {
    Future<void> Function()? seedDb,
    bool restore = false,
  }) async {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));
    if (seedDb != null) await tester.runAsync(seedDb);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          locationSourceProvider.overrideWithValue(FakeSource()),
          permissionGatewayProvider.overrideWithValue(gw),
        ],
        child: const MaterialApp(
          home: Scaffold(body: Center(child: RecordingControls())),
        ),
      ),
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(RecordingControls)),
    );
    if (restore) {
      unawaited(c.read(recordingControllerProvider.notifier).restore());
      await settle(
        tester,
        () =>
            c.read(recordingControllerProvider).recState ==
            RecState.interrupted,
      );
    }
    return c;
  }

  RecState stateOf(ProviderContainer c) =>
      c.read(recordingControllerProvider).recState;

  bool shows(String label) => find.text(label).evaluate().isNotEmpty;

  testWidgets('nincs rögzítés: csak a Rögzítés gomb', (tester) async {
    await pumpControls(tester);
    expect(find.text('Rögzítés'), findsOneWidget);
    expect(find.text('Szünet'), findsNothing);
    expect(find.text('Befejezés'), findsNothing);
  });

  testWidgets('engedéllyel a Rögzítés elindítja a rögzítést', (tester) async {
    final c = await pumpControls(tester);
    await tester.tap(find.text('Rögzítés'));
    await settle(tester, () => stateOf(c) == RecState.recording);

    expect(find.text('Szünet'), findsOneWidget);
    expect(find.text('Befejezés'), findsOneWidget);
    expect(find.text('Rögzítés'), findsNothing);
    expect(c.read(recordingControllerProvider).profile, TrackProfile.precise);
  });

  testWidgets('engedély nélkül előbb a magyarázó oldal, utána indul', (
    tester,
  ) async {
    gw.access = LocationAccess.denied;
    final c = await pumpControls(tester);

    await tester.tap(find.text('Rögzítés'));
    await tester.pumpAndSettle();
    expect(find.text('Helyzet a túra rögzítéséhez'), findsOneWidget);
    expect(stateOf(c), RecState.idle);

    await tester.tap(find.text('Tovább'));
    await settle(tester, () => stateOf(c) == RecState.recording);
    // Az engedélyoldal visszalépési animációjának vége.
    await tester.pumpAndSettle();

    expect(find.text('Helyzet a túra rögzítéséhez'), findsNothing);
    expect(find.text('Szünet'), findsOneWidget);
  });

  testWidgets('az engedélyoldalról visszalépve nem indul rögzítés', (
    tester,
  ) async {
    gw.access = LocationAccess.denied;
    final c = await pumpControls(tester);

    await tester.tap(find.text('Rögzítés'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(stateOf(c), RecState.idle);
    expect(find.text('Rögzítés'), findsOneWidget);
    expect(gw.calls, isNot(contains('requestLocation')));
  });

  testWidgets('szünet és folytatás', (tester) async {
    final c = await pumpControls(tester);
    await tester.tap(find.text('Rögzítés'));
    await settle(tester, () => stateOf(c) == RecState.recording);

    await tester.tap(find.text('Szünet'));
    await settle(tester, () => shows('Folytatás'));
    expect(stateOf(c), RecState.paused);
    expect(find.text('Befejezés'), findsOneWidget);

    await tester.tap(find.text('Folytatás'));
    await settle(tester, () => stateOf(c) == RecState.recording);
    expect(find.text('Szünet'), findsOneWidget);
  });

  testWidgets('befejezés megerősítéssel; a Mégse nem zár le', (tester) async {
    final c = await pumpControls(tester);
    await tester.tap(find.text('Rögzítés'));
    await settle(tester, () => stateOf(c) == RecState.recording);

    await tester.tap(find.text('Befejezés'));
    await tester.pumpAndSettle();
    expect(find.text('Befejezed a túrát?'), findsOneWidget);
    await tester.tap(find.text('Mégse'));
    await tester.pumpAndSettle();
    expect(stateOf(c), RecState.recording);

    await tester.tap(find.text('Befejezés'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Befejezés').last);
    await settle(tester, () => stateOf(c) == RecState.finished);
    await settle(tester, () => shows('Rögzítés'));
  });

  testWidgets('félbemaradt túra: Folytatás vagy Lezárás', (tester) async {
    late int id;
    final c = await pumpControls(
      tester,
      restore: true,
      seedDb: () async {
        id = await db.createTrack(
          name: 'Kilőtt',
          profile: TrackProfile.batterySaver,
          startedAtMs: 0,
        );
        await db.openSegment(id, 0);
      },
    );

    expect(find.text('Félbemaradt rögzítés'), findsOneWidget);
    expect(find.text('Folytatás'), findsOneWidget);
    expect(find.text('Lezárás'), findsOneWidget);
    expect(find.text('Rögzítés'), findsNothing);

    await tester.tap(find.text('Folytatás'));
    await settle(tester, () => stateOf(c) == RecState.recording);
    expect(
      c.read(recordingControllerProvider).profile,
      TrackProfile.batterySaver,
      reason: 'a megszakadt túra a saját profiljával folytatódik',
    );
  });

  testWidgets('félbemaradt túra lezárása', (tester) async {
    late int id;
    final c = await pumpControls(
      tester,
      restore: true,
      seedDb: () async {
        id = await db.createTrack(
          name: 'Kilőtt',
          profile: TrackProfile.precise,
          startedAtMs: 0,
        );
        await db.openSegment(id, 0);
      },
    );

    await tester.tap(find.text('Lezárás'));
    await settle(tester, () => stateOf(c) == RecState.finished);
    final t = (await tester.runAsync(() => db.trackById(id)))!;
    expect(t.status, TrackStatus.finished);
  });
}
