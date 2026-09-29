import 'fix.dart';
import 'geo.dart';

/// Letérés-érzékelés küszöbei.
class OffRouteConfig {
  const OffRouteConfig({
    this.alertDistanceM = 50,
    this.clearDistanceM = 30,
    this.consecutiveFixes = 3,
    this.windowSegments = 20,
  });

  /// Ennél messzebbi pont „távoli”.
  final double alertDistanceM;

  /// Riasztás után ezen belülre kell visszatérni a feloldáshoz. A két küszöb
  /// közti sáv (hiszterézis) akadályozza meg a villogást.
  final double clearDistanceM;

  /// Ennyi egymást követő távoli pont kell a riasztáshoz.
  final int consecutiveFixes;

  /// Az utoljára illeszkedett szakasz körüli keresési ablak fél szélessége.
  final int windowSegments;
}

enum OffRouteEvent { none, alert, cleared }

/// A letérés-érzékelő állapota; immutable.
class OffRouteState {
  const OffRouteState({
    this.isOffRoute = false,
    this.consecutiveFar = 0,
    this.lastSegment = 0,
  });

  final bool isOffRoute;
  final int consecutiveFar;
  final int lastSegment;
}

class OffRouteResult {
  const OffRouteResult({
    required this.state,
    required this.event,
    required this.distanceM,
  });

  final OffRouteState state;
  final OffRouteEvent event;

  /// A vonaltól mért távolság; `null`, ha a vonalnak nincs szakasza.
  final double? distanceM;
}

/// Letérés-érzékelő egy tervezett útvonalhoz. Az állapotot a hívó tartja,
/// `update` új állapotot ad vissza.
class OffRouteDetector {
  const OffRouteDetector(
    this.route, [
    this.config = const OffRouteConfig(),
  ]);

  final List<LatLon> route;
  final OffRouteConfig config;

  /// Egy elfogadott fix feldolgozása.
  OffRouteResult update(OffRouteState state, Fix fix) {
    if (route.length < 2) {
      return OffRouteResult(
        state: state,
        event: OffRouteEvent.none,
        distanceM: null,
      );
    }

    final nearest = _nearest(state.lastSegment, fix);
    final d = nearest.distanceM;
    // Csak közeli találat léptetheti az ablakot, távolról ne ugráljon.
    final lastSegment = d <= config.alertDistanceM
        ? nearest.segmentIndex
        : state.lastSegment;

    var isOff = state.isOffRoute;
    var far = state.consecutiveFar;
    var event = OffRouteEvent.none;

    if (isOff) {
      if (d <= config.clearDistanceM) {
        isOff = false;
        far = 0;
        event = OffRouteEvent.cleared;
      }
    } else if (d > config.alertDistanceM) {
      far++;
      if (far >= config.consecutiveFixes) {
        isOff = true;
        event = OffRouteEvent.alert;
      }
    } else {
      far = 0;
    }

    return OffRouteResult(
      state: OffRouteState(
        isOffRoute: isOff,
        consecutiveFar: far,
        lastSegment: lastSegment,
      ),
      event: event,
      distanceM: d,
    );
  }

  Projection _nearest(int lastSegment, Fix fix) {
    final windowed = nearestOnPolyline(
      fix.latDeg,
      fix.lonDeg,
      route,
      fromSegment: lastSegment - config.windowSegments,
      toSegment: lastSegment + config.windowSegments + 1,
    );
    if (windowed != null && windowed.distanceM <= config.alertDistanceM) {
      return windowed;
    }
    // Az ablakban nincs találat: teljes keresés.
    return nearestOnPolyline(fix.latDeg, fix.lonDeg, route)!;
  }
}
