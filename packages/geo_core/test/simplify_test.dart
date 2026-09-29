import 'dart:math' as math;

import 'package:geo_core/geo_core.dart';
import 'package:test/test.dart';

void main() {
  test('üres és rövid bemenet változatlan', () {
    expect(simplifyDp([], 5), isEmpty);
    expect(simplifyDp([const LatLon(0, 0)], 5), [0]);
    expect(simplifyDp([const LatLon(0, 0), const LatLon(1, 1)], 5), [0, 1]);
  });

  test('egyenes vonal két pontra egyszerűsödik', () {
    final line = [for (var i = 0; i <= 100; i++) LatLon(0, i * 0.0001)];
    expect(simplifyDp(line, 1), [0, 100]);
  });

  test('a csúcs megmarad, ha kilóg a tűrésből', () {
    // Egyenlítői vonal, közepén ~111 m-es kitérés.
    final line = [
      const LatLon(0, 0),
      const LatLon(0, 0.005),
      const LatLon(0.001, 0.01),
      const LatLon(0, 0.015),
      const LatLon(0, 0.02),
    ];
    expect(simplifyDp(line, 20), contains(2));
    expect(simplifyDp(line, 500), [0, 4]);
  });

  test('zárt hurok: a végpontok azonosak, mégis megmarad a forma', () {
    final loop = [
      for (var i = 0; i <= 36; i++)
        LatLon(
          0.001 * math.sin(i * math.pi / 18),
          0.001 * math.cos(i * math.pi / 18),
        ),
    ];
    final kept = simplifyDp(loop, 5);
    expect(kept.length, greaterThan(4));
    expect(kept.first, 0);
    expect(kept.last, 36);
  });

  test('nagyobb tűrés nem ad több pontot', () {
    final rnd = math.Random(1);
    final line = [
      for (var i = 0; i < 500; i++)
        LatLon(47 + rnd.nextDouble() * 0.0005, 19 + i * 0.00005),
    ];
    var previous = 1 << 30;
    for (final tol in [1.0, 3.0, 10.0, 30.0]) {
      final n = simplifyDp(line, tol).length;
      expect(n, lessThanOrEqualTo(previous));
      previous = n;
    }
  });

  test('minden eredeti pont a tűrésen belül van a ritkított vonaltól', () {
    final rnd = math.Random(7);
    final line = [
      for (var i = 0; i < 800; i++)
        LatLon(
          47 + 0.002 * math.sin(i / 40) + rnd.nextDouble() * 0.0001,
          19 + i * 0.00004,
        ),
    ];
    const tol = 8.0;
    final kept = simplifyDp(line, tol);
    final simplified = [for (final i in kept) line[i]];
    for (final p in line) {
      final d = pointToPolylineDistanceM(p.latDeg, p.lonDeg, simplified)!;
      expect(d, lessThanOrEqualTo(tol + 0.5));
    }
  });

  test('20 000 pont hívási verem nélkül is lefut', () {
    final line = [
      for (var i = 0; i < 20000; i++)
        LatLon(47 + i * 0.000001, 19 + 0.0005 * math.sin(i / 500)),
    ];
    final kept = simplifyDp(line, 2);
    expect(kept.length, lessThan(20000));
    expect(kept.first, 0);
    expect(kept.last, 19999);
  });

  test('zoom-tűrés csökken a zoommal', () {
    expect(metersPerPixel(0, latDeg: 0), closeTo(156543, 1));
    expect(toleranceForZoom(10), greaterThan(toleranceForZoom(14)));
    expect(toleranceForZoom(14, pixels: 1), closeTo(metersPerPixel(14), 1e-9));
  });
}
