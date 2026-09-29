import 'dart:io';

import 'package:geo_core/geo_core.dart';
import 'package:geo_core/testing.dart';
import 'package:test/test.dart';

List<Fix> loadTrace(String name) =>
    parseFixCsv(File('test/traces/$name.csv').readAsStringSync());

void main() {
  group('visszajátszás a test/traces nyomvonalain', () {
    test('álló pontfelhő 10 perce: táv < 20 m, mozgásidő 0', () {
      final s = computeStats(loadTrace('stationary_cloud_10min'));
      expect(s.distanceM, lessThan(20));
      expect(s.movingTimeMs, 0);
      expect(s.avgPaceMinPerKm, isNull);
    });

    test('atlétikai pálya, belső sáv, 5 kör: 2000 m ±3%', () {
      final s = computeStats(loadTrace('track_5laps'));
      expect(s.distanceM, closeTo(2000, 2000 * 0.03));
    });

    test('zajos egyenes séta: a táv a valós 840 m fölött, de korlátos', () {
      final s = computeStats(loadTrace('walk_10min'));
      // A zaj felfújja a távot; a felső korlát regressziós védelem.
      expect(s.distanceM, inInclusiveRange(840, 1500));
      expect(s.movingTimeMs, closeTo(600000, 5000));
      expect(s.avgPaceMinPerKm, isNotNull);
    });

    test('a hiszterézis a zajos magasságot a naiv összeg töredékére vágja', () {
      final fixes = loadTrace('walk_10min');
      final alts = [for (final f in fixes) f.altM!];
      var naive = 0.0;
      for (var i = 1; i < alts.length; i++) {
        if (alts[i] > alts[i - 1]) naive += alts[i] - alts[i - 1];
      }
      final s = computeStats(fixes);
      expect(naive, greaterThan(300));
      expect(s.ascentM, lessThan(naive / 3));
      expect(s.ascentM, greaterThan(10)); // a valódi emelkedés kb. 17 m
    });

    test('alagút: a rés után a lánc folytatja a nyomvonalat', () {
      final fixes = loadTrace('tunnel_walk');
      final run = runFilter(fixes);
      final afterGap = run.accepted.where((f) => f.tMs >= 180000);
      expect(afterGap, isNotEmpty);
      expect(run.dropCounts[DropReason.jump], isNull);
      final s = computeStats(fixes);
      expect(s.totalTimeMs, 300000);
    });

    test('kiugró ugrás eldobódik, a táv nem szakad meg', () {
      final fixes = loadTrace('jump_walk');
      final run = runFilter(fixes);
      expect(run.dropCounts[DropReason.jump], 1);
      expect(computeStats(fixes).distanceM, lessThan(500));
    });

    test('oda-vissza út: a táv kb. a kétszerese az egyirányúnak', () {
      final s = computeStats(loadTrace('out_and_back'));
      // 2 x 120 s x 1,4 m/s = 336 m valós út, zajjal több.
      expect(s.distanceM, inInclusiveRange(336, 700));
    });

    test('a visszajátszás determinisztikus', () {
      final a = computeStats(loadTrace('walk_10min')).toJson();
      final b = computeStats(loadTrace('walk_10min')).toJson();
      expect(a, b);
    });
  });
}
