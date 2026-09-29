import 'dart:math' as math;

import 'package:geo_core/geo_core.dart';
import 'package:test/test.dart';

double naiveGain(List<double> alts) {
  var g = 0.0;
  for (var i = 1; i < alts.length; i++) {
    if (alts[i] > alts[i - 1]) g += alts[i] - alts[i - 1];
  }
  return g;
}

void main() {
  group('elevationGainLoss', () {
    test('üres és egyelemű bemenet', () {
      expect(elevationGainLoss([]).gainM, 0);
      expect(elevationGainLoss([100]).lossM, 0);
    });

    test('zajos lapos terep: ~0 emelkedés, a naiv összeg sokszorosa', () {
      final rnd = math.Random(3);
      final alts = [for (var i = 0; i < 1000; i++) 200 + rnd.nextDouble() * 6 - 3];
      final r = elevationGainLoss(alts);
      expect(r.gainM, lessThan(10));
      expect(naiveGain(alts), greaterThan(500));
    });

    test('tiszta hegymenet', () {
      final alts = [for (var i = 0; i <= 100; i++) 100.0 + i * 2];
      final r = elevationGainLoss(alts);
      expect(r.gainM, closeTo(200, 1e-9));
      expect(r.lossM, 0);
    });

    test('tiszta lejtő', () {
      final alts = [for (var i = 0; i <= 100; i++) 500.0 - i * 2];
      final r = elevationGainLoss(alts);
      expect(r.gainM, 0);
      expect(r.lossM, closeTo(200, 1e-9));
    });

    test('fűrészfog: mindkét irány összeadódik', () {
      final r = elevationGainLoss([0, 20, 5, 25, 10]);
      expect(r.gainM, closeTo(20 + 20, 1e-9));
      expect(r.lossM, closeTo(15 + 15, 1e-9));
    });

    test('küszöb alatti lépés nem számít, felette igen', () {
      expect(elevationGainLoss([0, 4.9, 0, 4.9]).gainM, 0);
      expect(elevationGainLoss([0, 5, 0]).gainM, 5);
    });

    test('lefelé induló sorozat, majd emelkedés', () {
      final r = elevationGainLoss([100, 90, 80, 95]);
      expect(r.lossM, closeTo(20, 1e-9));
      expect(r.gainM, closeTo(15, 1e-9));
    });

    test('egyedi küszöb', () {
      final r = elevationGainLoss([
        0,
        3,
        0,
      ], const ElevationConfig(hysteresisM: 2));
      expect(r.gainM, 3);
    });
  });

  group('computeStats', () {
    test('üres bemenet: nullák, nem NaN', () {
      final s = computeStats([]);
      expect(s.distanceM, 0);
      expect(s.totalTimeMs, 0);
      expect(s.avgPaceMinPerKm, isNull);
      expect(s.maxAltM, isNull);
    });

    test('egyenletes séta', () {
      // 1 s-onként 0,00002 fok (~2,22 m): 2,2 m/s.
      final fixes = [
        for (var i = 0; i < 200; i++)
          Fix(
            tMs: i * 1000,
            latDeg: 0,
            lonDeg: i * 0.00002,
            altM: 100.0 + i * 0.1,
            hAccM: 5,
            speedMps: 2.2,
          ),
      ];
      final s = computeStats(fixes);
      expect(s.distanceM, closeTo(199 * 2.224, 3));
      expect(s.totalTimeMs, 199000);
      expect(s.movingTimeMs, 199000);
      expect(s.avgPaceMinPerKm, closeTo(199 / 60 / (s.distanceM / 1000), 1e-6));
      expect(s.ascentM, closeTo(19.9, 0.1));
      expect(s.maxAltM, closeTo(119.9, 1e-9));
      expect(s.acceptedCount + s.droppedCount, 200);
    });

    test('JSON oda-vissza', () {
      final s = computeStats([
        const Fix(tMs: 0, latDeg: 0, lonDeg: 0, altM: 10),
        const Fix(tMs: 5000, latDeg: 0, lonDeg: 0.0001, altM: 30),
      ]);
      final back = TrackStats.fromJson(s.toJson());
      expect(back.toJson(), s.toJson());
      final empty = TrackStats.fromJson(computeStats([]).toJson());
      expect(empty.avgPaceMinPerKm, isNull);
    });
  });
}
