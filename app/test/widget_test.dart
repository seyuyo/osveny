import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/app.dart';
import 'package:osveny/data/database.dart';
import 'package:osveny/map/map_library_controller.dart';
import 'package:osveny/map/map_store.dart';
import 'package:osveny/permissions/permission_gateway.dart';
import 'package:osveny/recording/location_source.dart';
import 'package:osveny/recording/recording_controller.dart';

import 'permissions/fake_permission_gateway.dart';

void main() {
  testWidgets('első indítás: magyarázat, az engedély után a térkép fül', (
    tester,
  ) async {
    final gw = FakeGateway();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => tester.runAsync(db.close));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          mapStoreProvider.overrideWithValue(
            MapStore(
              Directory(
                '${Directory.systemTemp.path}${Platform.pathSeparator}osveny_no_maps',
              ),
            ),
          ),
          locationSourceProvider.overrideWithValue(ReplayLocationSource([])),
          permissionGatewayProvider.overrideWithValue(gw),
        ],
        child: const OsvenyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Helyzet a túra rögzítéséhez'), findsOneWidget);
    expect(find.text('Rögzítés indítása'), findsNothing);
    expect(gw.calls, isNot(contains('requestLocation')));

    await tester.tap(find.text('Tovább'));
    await tester.pump();
    // A térképmappa beolvasása több lépésből álló valódi fájl-I/O: a
    // `runAsync` (valódi idő) és a `pump` (a folytatások lefuttatása)
    // váltogatásával megvárjuk, különben a töltésjelző végtelenül pörögne,
    // és a pumpAndSettle nem csengene le.
    for (var i = 0; i < 50; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
    }
    await tester.pumpAndSettle();

    // A kezdőképernyő a Térkép fül; a rögzítés-vezérlés a Debug fülön van.
    expect(find.byKey(const Key('map-tab')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Debug'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Rögzítés indítása'), findsOneWidget);
    expect(find.text('Ösvény · debug'), findsOneWidget);
  });
}
