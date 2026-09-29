import 'fix.dart';
import 'geo.dart';

/// A szűrőlánc küszöbei (gyalogos profil alapértékekkel).
class FilterConfig {
  const FilterConfig({
    this.maxHAccM = 25,
    this.maxSpeedMps = 15,
    this.minDistanceM = 3,
    this.maxIntervalMs = 30000,
    this.stationarySpeedMps = 0.3,
    this.stationaryAfterMs = 60000,
  });

  /// Ennél rosszabb vízszintes pontosságú fix eldobódik.
  final double maxHAccM;

  /// Ennél nagyobb implikált sebességű fix (ugrás) eldobódik.
  final double maxSpeedMps;

  /// Ritkítás: ennél közelebbi pont nem kerül a nyomvonalba...
  final double minDistanceM;

  /// ...kivéve, ha ennyi idő eltelt az előző elfogadott pont óta.
  final int maxIntervalMs;

  /// Ez alatti sebesség az „áll” állapot.
  final double stationarySpeedMps;

  /// Ennél hosszabb „áll” állapot ideje nem számít mozgásidőnek.
  final int stationaryAfterMs;
}

/// Miért dobott el a lánc egy fixet.
enum DropReason { lowAccuracy, outOfOrder, jump, tooClose }

/// A szűrőlánc állapota; immutable, a `filterUpdate` új példányt ad.
class FilterState {
  const FilterState({
    this.last,
    this.distanceM = 0,
    this.movingTimeMs = 0,
    this.pendingSlowMs = 0,
    this.acceptedCount = 0,
    this.droppedCount = 0,
  });

  /// Az utolsó elfogadott fix.
  final Fix? last;

  /// A mozgással megtett táv az elfogadott pontok között (álló szakaszok nélkül).
  final double distanceM;

  /// Lezárt mozgásidő; a még el nem döntött lassú szakasz nélkül.
  final int movingTimeMs;

  /// A folyamatban lévő lassú szakasz hossza (még nem tudjuk, hogy állás-e).
  final int pendingSlowMs;

  final int acceptedCount;
  final int droppedCount;

  /// A mozgásidő a folyamatban lévő lassú szakasszal együtt, ha az még
  /// nem érte el az állásküszöböt.
  int effectiveMovingTimeMs(FilterConfig config) =>
      movingTimeMs +
      (pendingSlowMs <= config.stationaryAfterMs ? pendingSlowMs : 0);
}

/// Egy `filterUpdate` eredménye.
class FilterResult {
  const FilterResult({required this.state, this.dropReason});

  final FilterState state;

  /// `null`, ha a fix elfogadva.
  final DropReason? dropReason;

  bool get accepted => dropReason == null;
}

/// Egy fix átengedése a szűrőláncon. Tiszta függvény: nincs mellékhatás.
FilterResult filterUpdate(
  FilterState state,
  Fix fix, [
  FilterConfig config = const FilterConfig(),
]) {
  FilterResult drop(DropReason reason) => FilterResult(
    dropReason: reason,
    state: FilterState(
      last: state.last,
      distanceM: state.distanceM,
      movingTimeMs: state.movingTimeMs,
      pendingSlowMs: state.pendingSlowMs,
      acceptedCount: state.acceptedCount,
      droppedCount: state.droppedCount + 1,
    ),
  );

  // 1. Pontossági kapu.
  if (fix.hAccM > config.maxHAccM) return drop(DropReason.lowAccuracy);

  final last = state.last;
  if (last == null) {
    return FilterResult(
      state: FilterState(
        last: fix,
        acceptedCount: state.acceptedCount + 1,
        droppedCount: state.droppedCount,
      ),
    );
  }

  final dtMs = fix.tMs - last.tMs;
  if (dtMs <= 0) return drop(DropReason.outOfOrder);

  final dM = haversineM(last.latDeg, last.lonDeg, fix.latDeg, fix.lonDeg);
  final impliedSpeedMps = dM / (dtMs / 1000);

  // 2. Ugrásszűrő.
  if (impliedSpeedMps > config.maxSpeedMps) return drop(DropReason.jump);

  // 3. Ritkítás.
  if (dM < config.minDistanceM && dtMs < config.maxIntervalMs) {
    return drop(DropReason.tooClose);
  }

  // 4. Állásérzékelés: az eszköz által mért sebességet részesítjük előnyben,
  // mert az álló pontfelhő helyzetzaja implikált sebességnek mozgásnak látszik.
  final speedMps = fix.speedMps ?? impliedSpeedMps;
  final slow = speedMps < config.stationarySpeedMps;

  var distanceM = state.distanceM;
  var movingTimeMs = state.movingTimeMs;
  var pendingSlowMs = state.pendingSlowMs;
  if (slow) {
    pendingSlowMs += dtMs;
  } else {
    // 5. Táv: csak mozgás közben adjuk hozzá.
    distanceM += dM;
    movingTimeMs += dtMs;
    if (pendingSlowMs <= config.stationaryAfterMs) {
      movingTimeMs += pendingSlowMs;
    }
    pendingSlowMs = 0;
  }

  return FilterResult(
    state: FilterState(
      last: fix,
      distanceM: distanceM,
      movingTimeMs: movingTimeMs,
      pendingSlowMs: pendingSlowMs,
      acceptedCount: state.acceptedCount + 1,
      droppedCount: state.droppedCount,
    ),
  );
}

/// A szűrőlánc teljes lefuttatása egy nyers fixlistán (újraszámolás).
class FilterRun {
  const FilterRun({
    required this.accepted,
    required this.state,
    required this.dropCounts,
  });

  final List<Fix> accepted;
  final FilterState state;
  final Map<DropReason, int> dropCounts;
}

FilterRun runFilter(
  Iterable<Fix> fixes, [
  FilterConfig config = const FilterConfig(),
]) {
  var state = const FilterState();
  final accepted = <Fix>[];
  final dropCounts = <DropReason, int>{};
  for (final fix in fixes) {
    final r = filterUpdate(state, fix, config);
    state = r.state;
    final reason = r.dropReason;
    if (reason == null) {
      accepted.add(fix);
    } else {
      dropCounts[reason] = (dropCounts[reason] ?? 0) + 1;
    }
  }
  return FilterRun(accepted: accepted, state: state, dropCounts: dropCounts);
}
