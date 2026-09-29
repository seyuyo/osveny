// Az újragenerálás: `dart run tool/gen_traces.dart` a geo_core mappában.
// A test/traces/ fájljai golden adatok: a visszajátszásos tesztek ezekre épülnek.
import 'dart:io';

import 'package:geo_core/geo_core.dart';
import 'package:geo_core/testing.dart';

void main() {
  final out = Directory('test/traces')..createSync(recursive: true);

  void write(String name, List<Fix> fixes) {
    File('${out.path}/$name.csv').writeAsStringSync(fixesToCsv(fixes));
    stdout.writeln('$name.csv: ${fixes.length} fix');
  }

  write(
    'walk_10min',
    genStraightLine(seed: 11, baseAltM: 300, climbMPerKm: 20, altNoiseM: 1.5),
  );
  write('stationary_cloud_10min', genStationaryCloud(seed: 12));
  write(
    'tunnel_walk',
    withGap(genStraightLine(seed: 13, durationS: 300), 120000, 180000),
  );
  write('jump_walk', withJump(genStraightLine(seed: 14, durationS: 120), 60));
  write('out_and_back', genOutAndBack(seed: 15, halfDurationS: 120));
  write('track_5laps', genTrack400(seed: 16));
  write('walk_30min', _walk30min());
}

/// 30 perc valódi epoch időbélyegekkel: 12 perc séta emelkedővel, 5 perc
/// állás, 13 perc séta alagúttal és egy kiugró ugrással. Az app M2
/// integrációs tesztje játssza vissza.
List<Fix> _walk30min() {
  const t0 = 1758000000000;
  final a = genStraightLine(
    seed: 21,
    durationS: 720,
    startTMs: t0,
    baseAltM: 300,
    climbMPerKm: 30,
    altNoiseM: 1.5,
  );
  final stop = genStationaryCloud(
    seed: 22,
    latDeg: a.last.latDeg,
    lonDeg: a.last.lonDeg,
    durationS: 299,
    startTMs: t0 + 721000,
    altM: a.last.altM,
    altNoiseM: 1.5,
  );
  final b = genStraightLine(
    seed: 23,
    startLatDeg: a.last.latDeg,
    startLonDeg: a.last.lonDeg,
    headingDeg: 60,
    durationS: 779,
    startTMs: t0 + 1021000,
    baseAltM: a.last.altM,
    climbMPerKm: -20,
    altNoiseM: 1.5,
  );
  final bWithFaults = withGap(withJump(b, 200), t0 + 1500000, t0 + 1560000);
  return [...a, ...stop, ...bWithFaults];
}
