import 'dart:math' as math;

import 'geo.dart';

/// Douglas–Peucker ritkítás. A megtartott pontok indexeit adja növekvő
/// sorrendben; a végpontokat mindig megtartja. Iteratív, ezért 20 000+ pontra
/// sem fogy el a hívási verem.
List<int> simplifyDp(List<LatLon> points, double toleranceM) {
  final n = points.length;
  if (n <= 2) return List<int>.generate(n, (i) => i);

  final keep = List<bool>.filled(n, false);
  keep[0] = true;
  keep[n - 1] = true;

  final stack = <(int, int)>[(0, n - 1)];
  while (stack.isNotEmpty) {
    final (first, last) = stack.removeLast();
    if (last - first < 2) continue;

    var maxDistM = -1.0;
    var maxIndex = first;
    final a = points[first];
    final b = points[last];
    for (var i = first + 1; i < last; i++) {
      final d = pointToSegmentDistanceM(
        points[i].latDeg,
        points[i].lonDeg,
        a,
        b,
      );
      if (d > maxDistM) {
        maxDistM = d;
        maxIndex = i;
      }
    }

    if (maxDistM > toleranceM) {
      keep[maxIndex] = true;
      stack.add((first, maxIndex));
      stack.add((maxIndex, last));
    }
  }

  return [
    for (var i = 0; i < n; i++)
      if (keep[i]) i,
  ];
}

/// Az egy képpontnak megfelelő méret (Web Mercator, 256 px-es csempe)
/// az adott zoomszinten és szélességen.
double metersPerPixel(double zoom, {double latDeg = 47}) =>
    156543.03392 * math.cos(latDeg * math.pi / 180) / math.pow(2, zoom);

/// Megjelenítési tűrés zoomszintenként: alapból fél képpont.
double toleranceForZoom(
  double zoom, {
  double latDeg = 47,
  double pixels = 0.5,
}) => metersPerPixel(zoom, latDeg: latDeg) * pixels;
