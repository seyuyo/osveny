import 'package:geo_core/geo_core.dart';
import 'package:test/test.dart';

void main() {
  group('haversineM', () {
    test('Budapest-Bécs kb. 214 km', () {
      final d = haversineM(47.4979, 19.0402, 48.2082, 16.3738);
      expect(d, closeTo(214000, 214000 * 0.005));
    });

    test('nulla távolság', () {
      expect(haversineM(47.5, 19, 47.5, 19), 0);
    });

    test('1 fok szélesség kb. 111,2 km', () {
      expect(haversineM(0, 0, 1, 0), closeTo(111195, 50));
    });

    test('dátumvonalon át a rövid úton mér', () {
      expect(haversineM(0, 179.5, 0, -179.5), closeTo(111195, 50));
    });

    test('pólusok között fél kerület', () {
      expect(haversineM(90, 0, -90, 0), closeTo(20015087, 100));
    });
  });

  group('szakasz és töröttvonal', () {
    // Egyenlítői szakasz: 0,01 fok kb. 1112 m.
    const a = LatLon(0, 0);
    const b = LatLon(0, 0.01);

    test('oldalirányú távolság ismert értékkel', () {
      // 0,0003 fok északra kb. 33,36 m a szakasz közepén.
      final d = pointToSegmentDistanceM(0.0003, 0.005, a, b);
      expect(d, closeTo(33.36, 0.1));
    });

    test('végpontra clamp', () {
      final p = projectOnSegment(0, 0.02, a, b);
      expect(p.t, 1);
      expect(p.distanceM, closeTo(haversineM(0, 0.01, 0, 0.02), 0.5));
    });

    test('kezdőpont előtt clamp', () {
      final p = projectOnSegment(0, -0.01, a, b);
      expect(p.t, 0);
    });

    test('degenerált (0 hosszú) szakasz', () {
      final d = pointToSegmentDistanceM(0.0001, 0, a, a);
      expect(d, closeTo(11.12, 0.1));
    });

    test('dátumvonal melletti szakasz', () {
      final d = pointToSegmentDistanceM(
        0.0001,
        -179.9995,
        const LatLon(0, 179.999),
        const LatLon(0, -179.999),
      );
      expect(d, closeTo(11.12, 0.2));
    });

    const line = [LatLon(0, 0), LatLon(0, 0.01), LatLon(0.01, 0.01)];

    test('töröttvonal: legközelebbi szakasz indexe', () {
      final p = nearestOnPolyline(0.005, 0.0101, line)!;
      expect(p.segmentIndex, 1);
      expect(p.distanceM, closeTo(11.12, 0.2));
    });

    test('töröttvonal: tartomány korlátozása', () {
      final p = nearestOnPolyline(0.005, 0.0101, line, toSegment: 1)!;
      expect(p.segmentIndex, 0);
      expect(nearestOnPolyline(0, 0, line, fromSegment: 5), isNull);
    });

    test('túl rövid vonalra null', () {
      expect(pointToPolylineDistanceM(0, 0, [a]), isNull);
      expect(pointToPolylineDistanceM(0, 0, []), isNull);
      expect(
        pointToPolylineDistanceM(0.0003, 0.005, [a, b]),
        closeTo(33.36, 0.1),
      );
    });

    test('hossz', () {
      expect(polylineLengthM(line), closeTo(2 * 1111.95, 1));
      expect(polylineLengthM([a]), 0);
    });
  });

  group('Fix és LatLon', () {
    test('egyenlőség és hash', () {
      const f1 = Fix(tMs: 1, latDeg: 2, lonDeg: 3, altM: 4);
      const f2 = Fix(tMs: 1, latDeg: 2, lonDeg: 3, altM: 4);
      expect(f1, f2);
      expect(f1.hashCode, f2.hashCode);
      expect(f1 == const Fix(tMs: 2, latDeg: 2, lonDeg: 3), isFalse);
      expect(f1.toString(), contains('Fix'));
      expect(const LatLon(1, 2), const LatLon(1, 2));
      expect(const LatLon(1, 2).hashCode, const LatLon(1, 2).hashCode);
      expect(const LatLon(1, 2).toString(), contains('LatLon'));
    });
  });
}
