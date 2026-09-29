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
}
