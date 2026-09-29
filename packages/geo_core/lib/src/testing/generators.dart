import 'dart:math' as math;

import '../fix.dart';
import '../geo.dart';

/// Szintetikus nyomvonal-generátorok magolt véletlennel: ugyanaz a `seed`
/// mindig ugyanazt a nyomvonalat adja.

const double _degToRad = math.pi / 180;

double _gaussian(math.Random rnd) {
  final u1 = 1 - rnd.nextDouble();
  final u2 = rnd.nextDouble();
  return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
}

/// Kelet/észak eltolás (méter) a kiinduló pontból, fokban.
LatLon offsetToLatLon(
  double originLatDeg,
  double originLonDeg,
  double eastM,
  double northM,
) {
  final latDeg = originLatDeg + northM / (earthRadiusM * _degToRad);
  final lonDeg =
      originLonDeg +
      eastM / (earthRadiusM * _degToRad * math.cos(originLatDeg * _degToRad));
  return LatLon(latDeg, lonDeg);
}

/// Egyenes vonalú séta zajjal. `headingDeg`: 0 észak, 90 kelet.
List<Fix> genStraightLine({
  int seed = 1,
  double startLatDeg = 47.5,
  double startLonDeg = 19.0,
  double headingDeg = 90,
  double speedMps = 1.4,
  int durationS = 600,
  int intervalMs = 1000,
  int startTMs = 0,
  double noiseM = 1.5,
  double hAccM = 5,
  double? baseAltM,
  double climbMPerKm = 0,
  double altNoiseM = 0,
}) {
  final rnd = math.Random(seed);
  final heading = headingDeg * _degToRad;
  final count = durationS * 1000 ~/ intervalMs + 1;
  final fixes = <Fix>[];
  for (var i = 0; i < count; i++) {
    final s = speedMps * i * intervalMs / 1000; // megtett út méterben
    final p = offsetToLatLon(
      startLatDeg,
      startLonDeg,
      s * math.sin(heading) + _gaussian(rnd) * noiseM,
      s * math.cos(heading) + _gaussian(rnd) * noiseM,
    );
    fixes.add(
      Fix(
        tMs: startTMs + i * intervalMs,
        latDeg: p.latDeg,
        lonDeg: p.lonDeg,
        altM: baseAltM == null
            ? null
            : baseAltM + climbMPerKm * s / 1000 + _gaussian(rnd) * altNoiseM,
        hAccM: hAccM,
        vAccM: baseAltM == null ? null : hAccM * 2,
        speedMps: speedMps,
      ),
    );
  }
  return fixes;
}

/// Álló „pontfelhő”: a telefon egy helyben fekszik, a fixek csak zajlanak.
List<Fix> genStationaryCloud({
  int seed = 1,
  double latDeg = 47.5,
  double lonDeg = 19.0,
  int durationS = 600,
  int intervalMs = 1000,
  int startTMs = 0,
  double noiseM = 1,
  double hAccM = 8,
  double? reportedSpeedMps = 0.05,
  double? altM,
  double altNoiseM = 0,
}) {
  final rnd = math.Random(seed);
  final count = durationS * 1000 ~/ intervalMs + 1;
  return [
    for (var i = 0; i < count; i++)
      () {
        final p = offsetToLatLon(
          latDeg,
          lonDeg,
          _gaussian(rnd) * noiseM,
          _gaussian(rnd) * noiseM,
        );
        return Fix(
          tMs: startTMs + i * intervalMs,
          latDeg: p.latDeg,
          lonDeg: p.lonDeg,
          altM: altM == null ? null : altM + _gaussian(rnd) * altNoiseM,
          hAccM: hAccM,
          speedMps: reportedSpeedMps,
        );
      }(),
  ];
}

/// Adathiány (alagút): a `[fromTMs, toTMs)` idő közti fixek kiesnek.
List<Fix> withGap(List<Fix> fixes, int fromTMs, int toTMs) => [
  for (final f in fixes)
    if (f.tMs < fromTMs || f.tMs >= toTMs) f,
];

/// Kiugró hiba: az `index`-edik fix `eastM` méterrel arrébb kerül.
List<Fix> withJump(List<Fix> fixes, int index, {double eastM = 5000}) {
  return [
    for (var i = 0; i < fixes.length; i++)
      if (i == index)
        () {
          final f = fixes[i];
          final p = offsetToLatLon(f.latDeg, f.lonDeg, eastM, 0);
          return Fix(
            tMs: f.tMs,
            latDeg: p.latDeg,
            lonDeg: p.lonDeg,
            altM: f.altM,
            hAccM: f.hAccM,
            vAccM: f.vAccM,
            speedMps: f.speedMps,
          );
        }()
      else
        fixes[i],
  ];
}

/// Oda-vissza út: kelet felé, majd ugyanazon a vonalon vissza.
List<Fix> genOutAndBack({
  int seed = 1,
  double startLatDeg = 47.5,
  double startLonDeg = 19.0,
  double speedMps = 1.4,
  int halfDurationS = 300,
  int intervalMs = 1000,
  double noiseM = 1.5,
  double hAccM = 5,
}) {
  final out = genStraightLine(
    seed: seed,
    startLatDeg: startLatDeg,
    startLonDeg: startLonDeg,
    speedMps: speedMps,
    durationS: halfDurationS,
    intervalMs: intervalMs,
    noiseM: noiseM,
    hAccM: hAccM,
  );
  final turn = offsetToLatLon(
    startLatDeg,
    startLonDeg,
    speedMps * halfDurationS,
    0,
  );
  final back = genStraightLine(
    seed: seed + 1,
    startLatDeg: turn.latDeg,
    startLonDeg: turn.lonDeg,
    headingDeg: 270,
    speedMps: speedMps,
    durationS: halfDurationS,
    intervalMs: intervalMs,
    startTMs: out.last.tMs + intervalMs,
    noiseM: noiseM,
    hAccM: hAccM,
  );
  return [...out, ...back];
}

/// Atlétikai pálya belső sávja (400 m: 2 x 84,39 m egyenes + 2 x 36,8 m sugarú
/// ív), `laps` kör. Az egyenlő idő közű mintavétel a 400 m-es kör mentén.
List<Fix> genTrack400({
  int seed = 1,
  double centerLatDeg = 47.5,
  double centerLonDeg = 19.0,
  int laps = 5,
  double speedMps = 1.4,
  int intervalMs = 1000,
  double noiseM = 0.3,
  double hAccM = 5,
}) {
  const straightM = 84.39;
  const radiusM = 36.8;
  const arcM = math.pi * radiusM;
  const lapM = 2 * straightM + 2 * arcM;

  // Pont a pálya mentén `s` méternél; az origó a pálya közepe.
  (double, double) pointAt(double sIn) {
    final s = sIn % lapM;
    if (s < straightM) {
      // alsó egyenes, nyugatról keletre
      return (-straightM / 2 + s, -radiusM);
    }
    if (s < straightM + arcM) {
      final a = (s - straightM) / radiusM; // 0..pi, jobb oldali ív
      return (straightM / 2 + radiusM * math.sin(a), -radiusM * math.cos(a));
    }
    if (s < 2 * straightM + arcM) {
      // felső egyenes, keletről nyugatra
      return (straightM / 2 - (s - straightM - arcM), radiusM);
    }
    final a = (s - 2 * straightM - arcM) / radiusM; // bal oldali ív
    return (-straightM / 2 - radiusM * math.sin(a), radiusM * math.cos(a));
  }

  final rnd = math.Random(seed);
  final totalM = laps * lapM;
  final count = (totalM / speedMps * 1000 / intervalMs).floor() + 1;
  final fixes = <Fix>[];
  for (var i = 0; i < count; i++) {
    final s = math.min(speedMps * i * intervalMs / 1000, totalM);
    final (x, y) = pointAt(s);
    final p = offsetToLatLon(
      centerLatDeg,
      centerLonDeg,
      x + _gaussian(rnd) * noiseM,
      y + _gaussian(rnd) * noiseM,
    );
    fixes.add(
      Fix(
        tMs: i * intervalMs,
        latDeg: p.latDeg,
        lonDeg: p.lonDeg,
        hAccM: hAccM,
        speedMps: speedMps,
      ),
    );
  }
  return fixes;
}
