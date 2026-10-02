import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/app.dart';
import 'package:osveny/data/database.dart';
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
