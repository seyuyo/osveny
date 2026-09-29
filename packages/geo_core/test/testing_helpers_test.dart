import 'package:geo_core/geo_core.dart';
import 'package:geo_core/testing.dart';
import 'package:test/test.dart';

void main() {
  group('CSV', () {
    test('oda-vissza alakítás', () {
      final fixes = [
        const Fix(
          tMs: 0,
          latDeg: 47.5,
          lonDeg: 19,
          altM: 120.5,
          hAccM: 4,
          vAccM: 8,
          speedMps: 1.2,
        ),
        const Fix(tMs: 1000, latDeg: 47.6, lonDeg: 19.1, hAccM: 6),
      ];
      final csv = fixesToCsv(fixes);
      expect(csv, startsWith(fixCsvHeader));
      expect(parseFixCsv(csv), fixes);
    });

    test('fejléc nélkül, üres sorokkal és CRLF-fel is jó', () {
      final fixes = parseFixCsv(
        '0,47.5,19.0,,5,,\r\n\r\n1000,47.5,19.0,,5,,\r\n',
      );
      expect(fixes.length, 2);
      expect(fixes.first.altM, isNull);
    });

    test('hibás oszlopszám', () {
      expect(
        () => parseFixCsv('$fixCsvHeader\n0,1,2'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'msg',
            contains('2. sor'),
          ),
        ),
      );
    });

    test('hibás szám és hiányzó kötelező mező', () {
      expect(() => parseFixCsv('x,1,2,,5,,'), throwsFormatException);
      expect(() => parseFixCsv('0,abc,2,,5,,'), throwsFormatException);
      expect(() => parseFixCsv('0,,2,,5,,'), throwsFormatException);
      expect(() => parseFixCsv('0,1,2,,,,'), throwsFormatException);
    });
  });

  group('generátorok', () {
    test('ugyanaz a seed ugyanazt adja, más seed mást', () {
      expect(genStraightLine(seed: 5), genStraightLine(seed: 5));
      expect(genStraightLine(seed: 5), isNot(genStraightLine(seed: 6)));
    });

    test('egyenes vonal: darabszám, idő és magasság', () {
      final f = genStraightLine(durationS: 10, baseAltM: 100, climbMPerKm: 10);
      expect(f.length, 11);
      expect(f.first.tMs, 0);
      expect(f.last.tMs, 10000);
      expect(f.first.altM, isNotNull);
      expect(genStraightLine(durationS: 5).first.altM, isNull);
    });

    test('álló felhő magassággal és sebesség nélkül', () {
      final f = genStationaryCloud(
        durationS: 5,
        altM: 200,
        altNoiseM: 1,
        reportedSpeedMps: null,
      );
      expect(f.length, 6);
      expect(f.first.speedMps, isNull);
      expect(f.first.altM, isNotNull);
      expect(genStationaryCloud(durationS: 2).first.altM, isNull);
    });

    test('withGap kivágja a tartományt', () {
      final f = withGap(genStraightLine(durationS: 10), 3000, 6000);
      expect(f.map((e) => e.tMs), isNot(contains(3000)));
      expect(f.map((e) => e.tMs), isNot(contains(5000)));
      expect(f.map((e) => e.tMs), contains(6000));
      expect(f.length, 8);
    });

    test('withJump csak egy pontot mozgat', () {
      final base = genStraightLine(durationS: 10, noiseM: 0);
      final j = withJump(base, 4, eastM: 1000);
      expect(j.length, base.length);
      expect(j[3], base[3]);
      expect(
        haversineM(base[4].latDeg, base[4].lonDeg, j[4].latDeg, j[4].lonDeg),
        closeTo(1000, 1),
      );
    });

    test('oda-vissza: folytonos idő, és visszaér a kiindulóhoz', () {
      final f = genOutAndBack(noiseM: 0, halfDurationS: 100);
      for (var i = 1; i < f.length; i++) {
        expect(f[i].tMs, greaterThan(f[i - 1].tMs));
      }
      expect(
        haversineM(
          f.first.latDeg,
          f.first.lonDeg,
          f.last.latDeg,
          f.last.lonDeg,
        ),
        lessThan(5),
      );
    });

    test('pálya: zajmentesen a kör 400 m', () {
      final f = genTrack400(noiseM: 0, laps: 1, speedMps: 2);
      var len = 0.0;
      for (var i = 1; i < f.length; i++) {
        len += haversineM(
          f[i - 1].latDeg,
          f[i - 1].lonDeg,
          f[i].latDeg,
          f[i].lonDeg,
        );
      }
      expect(len, closeTo(400, 2));
    });
  });
}
