import 'package:geo_core/geo_core.dart';
import 'package:test/test.dart';

// 0,0001 fok hosszúság az Egyenlítőn kb. 11,12 m.
Fix fixAt(int tMs, double lonDeg, {double hAccM = 5, double? speedMps}) =>
    Fix(tMs: tMs, latDeg: 0, lonDeg: lonDeg, hAccM: hAccM, speedMps: speedMps);

void main() {
  const config = FilterConfig();

  test('az első fix elfogadva', () {
    final r = filterUpdate(const FilterState(), fixAt(0, 0));
    expect(r.accepted, isTrue);
    expect(r.state.last, fixAt(0, 0));
    expect(r.state.acceptedCount, 1);
  });

  group('pontossági kapu', () {
    test('25 m még jó, 25,1 m eldob', () {
      var s = const FilterState();
      s = filterUpdate(s, fixAt(0, 0)).state;
      expect(filterUpdate(s, fixAt(1000, 0.0001, hAccM: 25)).accepted, isTrue);
      final r = filterUpdate(s, fixAt(1000, 0.0001, hAccM: 25.1));
      expect(r.dropReason, DropReason.lowAccuracy);
      expect(r.state.droppedCount, 1);
      expect(r.state.last, fixAt(0, 0));
    });

    test('rossz pontosságú első fix sem indítja a láncot', () {
      final r = filterUpdate(const FilterState(), fixAt(0, 0, hAccM: 100));
      expect(r.dropReason, DropReason.lowAccuracy);
      expect(r.state.last, isNull);
    });
  });

  group('ugrásszűrő', () {
    test('15 m/s alatt átmegy, fölötte eldob', () {
      final s = filterUpdate(const FilterState(), fixAt(0, 0)).state;
      // 0,0001 fok ~11,12 m: 1 s alatt 11,12 m/s -> ok.
      expect(filterUpdate(s, fixAt(1000, 0.0001)).accepted, isTrue);
      // 0,00015 fok ~16,7 m: 1 s alatt 16,7 m/s -> ugrás.
      final r = filterUpdate(s, fixAt(1000, 0.00015));
      expect(r.dropReason, DropReason.jump);
    });

    test('ugrás után az előző pont megmarad és a következő jó fix átmegy', () {
      var s = filterUpdate(const FilterState(), fixAt(0, 0)).state;
      s = filterUpdate(s, fixAt(1000, 0.01)).state; // ugrás
      expect(s.last, fixAt(0, 0));
      final r = filterUpdate(s, fixAt(2000, 0.0001));
      expect(r.accepted, isTrue);
    });
  });

  test('időrend-hiba és duplikált idő eldob', () {
    final s = filterUpdate(const FilterState(), fixAt(5000, 0)).state;
    expect(
      filterUpdate(s, fixAt(5000, 0.0001)).dropReason,
      DropReason.outOfOrder,
    );
    expect(
      filterUpdate(s, fixAt(4000, 0.0001)).dropReason,
      DropReason.outOfOrder,
    );
  });

  group('ritkítás', () {
    test('3 m alatt és 30 s alatt eldob', () {
      final s = filterUpdate(const FilterState(), fixAt(0, 0)).state;
      // 0,00002 fok ~2,2 m
      final r = filterUpdate(s, fixAt(10000, 0.00002));
      expect(r.dropReason, DropReason.tooClose);
    });

    test('3 m felett átmegy', () {
      final s = filterUpdate(const FilterState(), fixAt(0, 0)).state;
      // 0,00003 fok ~3,34 m
      expect(filterUpdate(s, fixAt(2000, 0.00003)).accepted, isTrue);
    });

    test('30 s után közelről is átmegy (alagút után is)', () {
      final s = filterUpdate(const FilterState(), fixAt(0, 0)).state;
      expect(filterUpdate(s, fixAt(30000, 0.00002)).accepted, isTrue);
      expect(filterUpdate(s, fixAt(29999, 0.00002)).accepted, isFalse);
    });
  });

  group('távolság és mozgásidő', () {
    test('egyenletes séta: táv és mozgásidő összeadódik', () {
      // 1,4 m/s gyaloglás, 2 s-onként ~2,8 m helyett 4 s-onként ~5,6 m.
      final fixes = [
        for (var i = 0; i < 100; i++) fixAt(i * 4000, i * 0.00005),
      ];
      final run = runFilter(fixes, config);
      expect(run.accepted.length, 100);
      expect(run.state.distanceM, closeTo(99 * 5.56, 1));
      expect(run.state.effectiveMovingTimeMs(config), 99 * 4000);
    });

    test('rövid megállás (<60 s) még mozgásidő', () {
      final fixes = [
        fixAt(0, 0, speedMps: 1.4),
        fixAt(4000, 0.00005, speedMps: 1.4),
        fixAt(34000, 0.00005, speedMps: 0), // 30 s álldogálás
        fixAt(38000, 0.0001, speedMps: 1.4),
      ];
      final run = runFilter(fixes, config);
      expect(run.state.effectiveMovingTimeMs(config), 38000);
    });

    test('hosszú megállás (>60 s) nem számít mozgásidőnek', () {
      final fixes = [
        fixAt(0, 0, speedMps: 1.4),
        fixAt(4000, 0.00005, speedMps: 1.4),
        for (var t = 34000; t <= 154000; t += 30000)
          fixAt(t, 0.00005, speedMps: 0),
        fixAt(158000, 0.0001, speedMps: 1.4),
      ];
      final run = runFilter(fixes, config);
      // csak a két mozgó intervallum: 4 s + 4 s
      expect(run.state.effectiveMovingTimeMs(config), 8000);
    });

    test('lezáratlan hosszú állás a végén sem számít mozgásidőnek', () {
      final fixes = [
        fixAt(0, 0, speedMps: 1.4),
        fixAt(4000, 0.00005, speedMps: 1.4),
        for (var t = 34000; t <= 154000; t += 30000)
          fixAt(t, 0.00005, speedMps: 0),
      ];
      final run = runFilter(fixes, config);
      expect(run.state.effectiveMovingTimeMs(config), 4000);
    });

    test('sebesség nélkül az implikált sebesség dönt', () {
      // 0 m mozgás, 30 s-onként fix: implikált sebesség 0 -> áll.
      final fixes = [for (var t = 0; t <= 180000; t += 30000) fixAt(t, 0)];
      final run = runFilter(fixes, config);
      expect(run.state.effectiveMovingTimeMs(config), 0);
      expect(run.state.distanceM, 0);
    });
  });

  test('runFilter összesíti az eldobás okait', () {
    final run = runFilter([
      fixAt(0, 0),
      fixAt(1000, 0.0001, hAccM: 99),
      fixAt(2000, 0.5),
      fixAt(3000, 0.00001),
    ], config);
    expect(run.accepted.length, 1);
    expect(run.dropCounts[DropReason.lowAccuracy], 1);
    expect(run.dropCounts[DropReason.jump], 1);
    expect(run.dropCounts[DropReason.tooClose], 1);
    expect(run.state.droppedCount, 3);
  });

  test('egyedi küszöbök érvényesülnek', () {
    const strict = FilterConfig(maxHAccM: 5);
    final s = filterUpdate(const FilterState(), fixAt(0, 0), strict).state;
    expect(
      filterUpdate(s, fixAt(1000, 0.0001, hAccM: 6), strict).dropReason,
      DropReason.lowAccuracy,
    );
  });
}
