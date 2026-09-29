import 'elevation.dart';
import 'filter_pipeline.dart';
import 'fix.dart';

/// Egy túra statisztikája. A nyers fixekből bármikor újraszámolható;
/// a `statsJson` az adatbázisban csak gyorsítótár.
class TrackStats {
  const TrackStats({
    required this.distanceM,
    required this.movingTimeMs,
    required this.totalTimeMs,
    required this.avgPaceMinPerKm,
    required this.ascentM,
    required this.descentM,
    required this.maxAltM,
    required this.acceptedCount,
    required this.droppedCount,
  });

  factory TrackStats.fromJson(Map<String, Object?> json) => TrackStats(
    distanceM: (json['distanceM']! as num).toDouble(),
    movingTimeMs: (json['movingTimeMs']! as num).toInt(),
    totalTimeMs: (json['totalTimeMs']! as num).toInt(),
    avgPaceMinPerKm: (json['avgPaceMinPerKm'] as num?)?.toDouble(),
    ascentM: (json['ascentM']! as num).toDouble(),
    descentM: (json['descentM']! as num).toDouble(),
    maxAltM: (json['maxAltM'] as num?)?.toDouble(),
    acceptedCount: (json['acceptedCount']! as num).toInt(),
    droppedCount: (json['droppedCount']! as num).toInt(),
  );

  final double distanceM;
  final int movingTimeMs;

  /// Az első és utolsó elfogadott fix között eltelt idő.
  final int totalTimeMs;

  /// Perc/km a mozgásidőre vetítve; `null`, ha nincs táv vagy mozgásidő.
  final double? avgPaceMinPerKm;
  final double ascentM;
  final double descentM;

  /// `null`, ha egyetlen elfogadott fixnek sincs magassága.
  final double? maxAltM;
  final int acceptedCount;
  final int droppedCount;

  Map<String, Object?> toJson() => {
    'distanceM': distanceM,
    'movingTimeMs': movingTimeMs,
    'totalTimeMs': totalTimeMs,
    'avgPaceMinPerKm': avgPaceMinPerKm,
    'ascentM': ascentM,
    'descentM': descentM,
    'maxAltM': maxAltM,
    'acceptedCount': acceptedCount,
    'droppedCount': droppedCount,
  };
}

/// A teljes láncot (szűrés, táv, szintemelkedés) újrafuttatja a nyers fixeken.
TrackStats computeStats(
  Iterable<Fix> rawFixes, {
  FilterConfig filterConfig = const FilterConfig(),
  ElevationConfig elevationConfig = const ElevationConfig(),
}) {
  final run = runFilter(rawFixes, filterConfig);
  final accepted = run.accepted;

  final altitudes = [
    for (final f in accepted)
      if (f.altM != null) f.altM!,
  ];
  final elevation = elevationGainLoss(altitudes, elevationConfig);

  final movingTimeMs = run.state.effectiveMovingTimeMs(filterConfig);
  final distanceM = run.state.distanceM;
  final totalTimeMs = accepted.length < 2
      ? 0
      : accepted.last.tMs - accepted.first.tMs;

  double? pace;
  if (distanceM > 0 && movingTimeMs > 0) {
    pace = (movingTimeMs / 60000) / (distanceM / 1000);
  }

  return TrackStats(
    distanceM: distanceM,
    movingTimeMs: movingTimeMs,
    totalTimeMs: totalTimeMs,
    avgPaceMinPerKm: pace,
    ascentM: elevation.gainM,
    descentM: elevation.lossM,
    maxAltM: altitudes.isEmpty
        ? null
        : altitudes.reduce((a, b) => a > b ? a : b),
    acceptedCount: run.state.acceptedCount,
    droppedCount: run.state.droppedCount,
  );
}
