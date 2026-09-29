import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/permissions/permission_flow.dart';
import 'package:osveny/permissions/permission_gateway.dart';

import 'fake_permission_gateway.dart';

void main() {
  late FakeGateway gw;
  late ProviderContainer container;

  PermissionFlow flow() => container.read(permissionFlowProvider.notifier);
  PermissionSnapshot snap() => container.read(permissionFlowProvider);

  setUp(() {
    gw = FakeGateway();
    container = ProviderContainer(
      overrides: [permissionGatewayProvider.overrideWithValue(gw)],
    );
    addTearDown(container.dispose);
  });

  test('kezdetben checking, és a check() nem kér engedélyt', () async {
    expect(snap().phase, PermissionPhase.checking);
    await flow().check();
    expect(gw.calls, ['locationAccess']);
  });

  group('check', () {
    test('még nem kértük / egyszer megtagadta: magyarázó képernyő', () async {
      gw.access = LocationAccess.denied;
      await flow().check();
      expect(snap().phase, PermissionPhase.needsRationale);
      expect(gw.calls, isNot(contains('requestLocation')));
    });

    test('megadva: ready, az értesítés állapotával', () async {
      gw.access = LocationAccess.granted;
      gw.notification = true;
      await flow().check();
      expect(snap().phase, PermissionPhase.ready);
      expect(snap().notificationGranted, isTrue);
    });

    test('véglegesen megtagadva', () async {
      gw.access = LocationAccess.deniedForever;
      await flow().check();
      expect(snap().phase, PermissionPhase.deniedForever);
    });

    test('kikapcsolt helyszolgáltatás', () async {
      gw.access = LocationAccess.serviceOff;
      await flow().check();
      expect(snap().phase, PermissionPhase.serviceOff);
    });
  });

  group('request', () {
    setUp(() async {
      gw.access = LocationAccess.denied;
      await flow().check();
      gw.calls.clear();
    });

    test('megadva: az értesítést is kéri, és ready', () async {
      await flow().request();
      expect(gw.calls, ['requestLocation', 'requestNotification']);
      expect(snap().phase, PermissionPhase.ready);
      expect(snap().notificationGranted, isTrue);
    });

    test(
      'értesítés megtagadva: a rögzítés nem blokkolt, de jelezzük',
      () async {
        gw.notificationAfterRequest = false;
        await flow().request();
        expect(snap().phase, PermissionPhase.ready);
        expect(snap().notificationGranted, isFalse);
      },
    );

    test('már megadott értesítést nem kér újra', () async {
      gw.notification = true;
      await flow().request();
      expect(gw.calls, ['requestLocation']);
    });

    test('megtagadva: denied, újra megpróbálható', () async {
      gw.afterRequest = LocationAccess.denied;
      await flow().request();
      expect(snap().phase, PermissionPhase.denied);
      expect(gw.calls, isNot(contains('requestNotification')));

      gw.afterRequest = LocationAccess.granted;
      await flow().request();
      expect(snap().phase, PermissionPhase.ready);
    });

    test('„ne kérdezz újra": deniedForever', () async {
      gw.afterRequest = LocationAccess.deniedForever;
      await flow().request();
      expect(snap().phase, PermissionPhase.deniedForever);
    });

    test('közben kikapcsolt helyszolgáltatás: serviceOff', () async {
      gw.afterRequest = LocationAccess.serviceOff;
      await flow().request();
      expect(snap().phase, PermissionPhase.serviceOff);
    });

    test('a kérés alatt requesting', () async {
      final phases = <PermissionPhase>[];
      container.listen(
        permissionFlowProvider,
        (_, next) => phases.add(next.phase),
      );
      await flow().request();
      expect(phases.first, PermissionPhase.requesting);
      expect(phases.last, PermissionPhase.ready);
    });
  });

  group('openSettings', () {
    test('deniedForever: az app beállításait nyitja', () async {
      gw.access = LocationAccess.deniedForever;
      await flow().check();
      await flow().openSettings();
      expect(gw.calls.last, 'openAppSettings');
    });

    test('serviceOff: a helymeghatározás beállításait nyitja', () async {
      gw.access = LocationAccess.serviceOff;
      await flow().check();
      await flow().openSettings();
      expect(gw.calls.last, 'openLocationSettings');
    });

    test('más fázisban nem csinál semmit', () async {
      gw.access = LocationAccess.denied;
      await flow().check();
      gw.calls.clear();
      await flow().openSettings();
      expect(gw.calls, isEmpty);
    });
  });
}
