import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/data/database.dart';
import 'package:osveny/map/map_library_controller.dart';
import 'package:osveny/map/map_store.dart';
import 'package:osveny/home_shell.dart';
import 'package:osveny/permissions/permission_gateway.dart';
import 'package:osveny/recording/location_source.dart';
import 'package:osveny/recording/recording_controller.dart';
import 'package:osveny/recording/track_profile.dart';

import 'permissions/fake_permission_gateway.dart';

void main() {
  Future<void> pumpShell(WidgetTester tester) async {
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
          permissionGatewayProvider.overrideWithValue(
            FakeGateway()
              ..access = LocationAccess.granted
              ..notification = true,
          ),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pump();
  }

  testWidgets('két fül: Térkép és Debug, a Térkép a kezdőképernyő', (
    tester,
  ) async {
    await pumpShell(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.destinations.length, 2);
    expect(bar.selectedIndex, 0);
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Térkép'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Debug'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('map-tab')), findsOneWidget);
  });

  testWidgets('a Debug fülre váltva a debug képernyő látszik', (tester) async {
    await pumpShell(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Debug'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Ösvény · debug'), findsOneWidget);
    expect(find.text('Rögzítés indítása'), findsOneWidget);
  });

  testWidgets('fülváltáskor a debug képernyő állapota megmarad', (
    tester,
  ) async {
    await pumpShell(tester);
    NavigationBar bar() =>
        tester.widget<NavigationBar>(find.byType(NavigationBar));

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Debug'),
      ),
    );
    await tester.pump();
    await tester.pump();
    // A profilválasztás a DebugScreen helyi állapota.
    await tester.tap(find.text('Akkukímélő'));
    await tester.pump();

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Térkép'),
      ),
    );
    await tester.pump();
    expect(bar().selectedIndex, 0);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Debug'),
      ),
    );
    await tester.pump();

    final selected = tester
        .widget<SegmentedButton<TrackProfile>>(
          find.byType(SegmentedButton<TrackProfile>),
        )
        .selected;
    expect(selected, {TrackProfile.batterySaver});
  });
}
