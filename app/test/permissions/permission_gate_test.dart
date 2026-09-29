import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/permissions/permission_gate.dart';
import 'package:osveny/permissions/permission_gateway.dart';

import 'fake_permission_gateway.dart';

void main() {
  late FakeGateway gw;

  Future<void> pumpGate(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [permissionGatewayProvider.overrideWithValue(gw)],
        child: const MaterialApp(
          home: PermissionGate(child: Text('A RÖGZÍTŐ')),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => gw = FakeGateway());

  testWidgets('első indításkor magyarázat, engedélykérés még nincs', (
    tester,
  ) async {
    await pumpGate(tester);

    expect(find.text('A RÖGZÍTŐ'), findsNothing);
    expect(find.textContaining('rögzítés'), findsWidgets);
    expect(find.text('Tovább'), findsOneWidget);
    expect(gw.calls, isNot(contains('requestLocation')));
  });

  testWidgets('a „Tovább” gomb kéri az engedélyt, megadva a rögzítő látszik', (
    tester,
  ) async {
    await pumpGate(tester);
    await tester.tap(find.text('Tovább'));
    await tester.pumpAndSettle();

    expect(gw.calls, contains('requestLocation'));
    expect(find.text('A RÖGZÍTŐ'), findsOneWidget);
  });

  testWidgets('már megadott engedélynél rögtön a rögzítő', (tester) async {
    gw.access = LocationAccess.granted;
    gw.notification = true;
    await pumpGate(tester);

    expect(find.text('A RÖGZÍTŐ'), findsOneWidget);
    expect(find.textContaining('értesítés'), findsNothing);
    expect(gw.calls, isNot(contains('requestLocation')));
  });

  testWidgets('értesítés nélkül a rögzítő látszik, figyelmeztetéssel', (
    tester,
  ) async {
    gw.access = LocationAccess.granted;
    gw.notification = false;
    await pumpGate(tester);

    expect(find.text('A RÖGZÍTŐ'), findsOneWidget);
    expect(find.textContaining('értesítés'), findsOneWidget);
  });

  testWidgets('megtagadás után érthető állapot és újrapróbálás', (
    tester,
  ) async {
    gw.afterRequest = LocationAccess.denied;
    await pumpGate(tester);
    await tester.tap(find.text('Tovább'));
    await tester.pumpAndSettle();

    expect(find.text('A RÖGZÍTŐ'), findsNothing);
    expect(find.textContaining('Enélkül nem tudunk rögzíteni'), findsOneWidget);

    gw.afterRequest = LocationAccess.granted;
    await tester.tap(find.text('Újra megpróbálom'));
    await tester.pumpAndSettle();
    expect(find.text('A RÖGZÍTŐ'), findsOneWidget);
  });

  testWidgets('véglegesen megtagadva: beállítások megnyitása', (tester) async {
    gw.access = LocationAccess.deniedForever;
    await pumpGate(tester);

    expect(find.text('A RÖGZÍTŐ'), findsNothing);
    await tester.tap(find.text('Beállítások megnyitása'));
    await tester.pumpAndSettle();
    expect(gw.calls, contains('openAppSettings'));
  });

  testWidgets('kikapcsolt helyszolgáltatás: helybeállítások', (tester) async {
    gw.access = LocationAccess.serviceOff;
    await pumpGate(tester);

    expect(find.textContaining('Helyszolgáltatás'), findsWidgets);
    await tester.tap(find.text('Helybeállítások megnyitása'));
    await tester.pumpAndSettle();
    expect(gw.calls, contains('openLocationSettings'));
  });

  testWidgets('az alkalmazásba visszatérve újraellenőriz', (tester) async {
    gw.access = LocationAccess.deniedForever;
    await pumpGate(tester);
    expect(find.text('A RÖGZÍTŐ'), findsNothing);

    // A felhasználó a beállításokban megadta, és visszatér az appba.
    gw.access = LocationAccess.granted;
    gw.notification = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('A RÖGZÍTŐ'), findsOneWidget);
  });
}
