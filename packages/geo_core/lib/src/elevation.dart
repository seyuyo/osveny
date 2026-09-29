/// Szintemelkedés-számítás küszöbei.
class ElevationConfig {
  const ElevationConfig({this.hysteresisM = 5});

  /// Egy emelkedés/lejtés csak akkor számít, ha az utolsó szélsőértéktől
  /// legalább ennyivel eltér.
  final double hysteresisM;
}

/// Összes emelkedés és lejtés méterben.
class ElevationGainLoss {
  const ElevationGainLoss({required this.gainM, required this.lossM});

  final double gainM;
  final double lossM;
}

enum _Trend { unknown, up, down }

/// Hiszterézises szintemelkedés: a magasságsorozatból a `hysteresisM`-nél
/// kisebb fel-le mozgások (GPS-zaj) kiesnek.
ElevationGainLoss elevationGainLoss(
  Iterable<double> altitudesM, [
  ElevationConfig config = const ElevationConfig(),
]) {
  final thr = config.hysteresisM;
  var gain = 0.0;
  var loss = 0.0;
  var trend = _Trend.unknown;
  double? hi;
  double? lo;
  var pivot = 0.0;
  var extreme = 0.0;

  for (final a in altitudesM) {
    switch (trend) {
      case _Trend.unknown:
        hi = hi == null || a > hi ? a : hi;
        lo = lo == null || a < lo ? a : lo;
        if (a - lo >= thr) {
          trend = _Trend.up;
          pivot = lo;
          extreme = a;
        } else if (hi - a >= thr) {
          trend = _Trend.down;
          pivot = hi;
          extreme = a;
        }
      case _Trend.up:
        if (a > extreme) {
          extreme = a;
        } else if (extreme - a >= thr) {
          gain += extreme - pivot;
          pivot = extreme;
          extreme = a;
          trend = _Trend.down;
        }
      case _Trend.down:
        if (a < extreme) {
          extreme = a;
        } else if (a - extreme >= thr) {
          loss += pivot - extreme;
          pivot = extreme;
          extreme = a;
          trend = _Trend.up;
        }
    }
  }

  switch (trend) {
    case _Trend.up:
      gain += extreme - pivot;
    case _Trend.down:
      loss += pivot - extreme;
    case _Trend.unknown:
      break;
  }
  return ElevationGainLoss(gainM: gain, lossM: loss);
}
