import 'dart:math' as math;

/// Középső földsugár méterben (IUGG).
const double earthRadiusM = 6371008.8;

const double _degToRad = math.pi / 180;

/// Földrajzi pont, fokban.
class LatLon {
  const LatLon(this.latDeg, this.lonDeg);

  final double latDeg;
  final double lonDeg;

  @override
  bool operator ==(Object other) =>
      other is LatLon && other.latDeg == latDeg && other.lonDeg == lonDeg;

  @override
  int get hashCode => Object.hash(latDeg, lonDeg);

  @override
  String toString() => 'LatLon($latDeg, $lonDeg)';
}

/// Nagykör-távolság méterben (haversine).
double haversineM(
  double lat1Deg,
  double lon1Deg,
  double lat2Deg,
  double lon2Deg,
) {
  final lat1 = lat1Deg * _degToRad;
  final lat2 = lat2Deg * _degToRad;
  final dLat = lat2 - lat1;
  final dLon = (lon2Deg - lon1Deg) * _degToRad;
  final sinDLat = math.sin(dLat / 2);
  final sinDLon = math.sin(dLon / 2);
  final a =
      sinDLat * sinDLat + math.cos(lat1) * math.cos(lat2) * sinDLon * sinDLon;
  return 2 * earthRadiusM * math.asin(math.sqrt(a.clamp(0.0, 1.0)));
}

/// Egy pont vetülete egy szakaszra vagy töröttvonalra.
class Projection {
  const Projection({
    required this.distanceM,
    required this.segmentIndex,
    required this.t,
  });

  /// A pont és a legközelebbi vonalpont távolsága méterben.
  final double distanceM;

  /// A legközelebbi szakasz indexe (a szakasz az `i` és `i+1` pont között).
  final int segmentIndex;

  /// A vetület helye a szakaszon, 0 (kezdőpont) és 1 (végpont) között.
  final double t;
}

/// Pont–szakasz vetület helyi ekvirektangulárius vetítéssel: a pont körül
/// síkba vetítünk, néhány km-es környezetben a hiba elhanyagolható.
Projection projectOnSegment(
  double latDeg,
  double lonDeg,
  LatLon a,
  LatLon b, {
  int segmentIndex = 0,
}) {
  final cosLat = math.cos(latDeg * _degToRad);
  final k = earthRadiusM * _degToRad;
  double dx(double lon) {
    var d = lon - lonDeg;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    return d * cosLat * k;
  }

  final ax = dx(a.lonDeg);
  final ay = (a.latDeg - latDeg) * k;
  final bx = dx(b.lonDeg);
  final by = (b.latDeg - latDeg) * k;
  final sx = bx - ax;
  final sy = by - ay;
  final lenSq = sx * sx + sy * sy;
  var t = 0.0;
  if (lenSq > 0) {
    t = (-(ax * sx + ay * sy) / lenSq).clamp(0.0, 1.0);
  }
  final cx = ax + t * sx;
  final cy = ay + t * sy;
  return Projection(
    distanceM: math.sqrt(cx * cx + cy * cy),
    segmentIndex: segmentIndex,
    t: t,
  );
}

/// Pont–szakasz távolság méterben.
double pointToSegmentDistanceM(
  double latDeg,
  double lonDeg,
  LatLon a,
  LatLon b,
) => projectOnSegment(latDeg, lonDeg, a, b).distanceM;

/// A legközelebbi szakasz a `[fromSegment, toSegment)` tartományban.
/// Ha a tartományban nincs szakasz, `null`.
Projection? nearestOnPolyline(
  double latDeg,
  double lonDeg,
  List<LatLon> line, {
  int fromSegment = 0,
  int? toSegment,
}) {
  final segCount = line.length - 1;
  final from = math.max(0, fromSegment);
  final to = math.min(segCount, toSegment ?? segCount);
  Projection? best;
  for (var i = from; i < to; i++) {
    final p = projectOnSegment(
      latDeg,
      lonDeg,
      line[i],
      line[i + 1],
      segmentIndex: i,
    );
    if (best == null || p.distanceM < best.distanceM) best = p;
  }
  return best;
}

/// Pont–töröttvonal távolság méterben; kevesebb mint két pontnál `null`.
double? pointToPolylineDistanceM(
  double latDeg,
  double lonDeg,
  List<LatLon> line,
) => nearestOnPolyline(latDeg, lonDeg, line)?.distanceM;

/// A töröttvonal hossza méterben.
double polylineLengthM(List<LatLon> line) {
  var sum = 0.0;
  for (var i = 1; i < line.length; i++) {
    sum += haversineM(
      line[i - 1].latDeg,
      line[i - 1].lonDeg,
      line[i].latDeg,
      line[i].lonDeg,
    );
  }
  return sum;
}
