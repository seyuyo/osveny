import 'dart:isolate';

import 'package:geo_core/geo_core.dart';
import 'package:latlong2/latlong.dart';

/// Egy pont (szélesség, hosszúság) fokban; isolate-ek között átküldhető.
typedef LatLonDeg = (double, double);

/// Szegmensek ritkítása adott tűréssel (méter). Cserélhető a teszthez.
typedef SegmentSimplifier =
    Future<List<List<LatLonDeg>>> Function(
      List<List<LatLonDeg>> segments,
      double toleranceM,
    );

/// Douglas–Peucker szegmensenként (`geo_core`), tiszta függvény.
List<List<LatLonDeg>> simplifySegments(
  List<List<LatLonDeg>> segments,
  double toleranceM,
) => [
  for (final s in segments)
    [
      for (final i in simplifyDp([
        for (final p in s) LatLon(p.$1, p.$2),
      ], toleranceM))
        s[i],
    ],
];

/// A ritkítás külön isolate-ben, hogy 20 000+ pont se akassza a felületet.
Future<List<List<LatLonDeg>>> isolateSimplify(
  List<List<LatLonDeg>> segments,
  double toleranceM,
) => Isolate.run(() => simplifySegments(segments, toleranceM));

class _SegmentCache {
  _SegmentCache(this.simplified, this.prefixLen);

  /// A szegmens első [prefixLen] pontjának ritkított változata.
  final List<LatLng> simplified;
  final int prefixLen;
}

/// Az élő nyomvonal megjelenítendő vonalai zoomsávonként ritkítva.
///
/// Növekményes: a lezárt szegmenseket egy zoomsávon belül csak egyszer
/// ritkítja; az utolsó szegmens ritkított eleje után az újabb pontok nyersen
/// kerülnek a vonal végére, és csak akkor ritkít újra, ha ez a nyers vég
/// [rawTailLimit] pontnál hosszabb lesz. Zoomsáv- vagy generációváltáskor
/// (új túra, feltöltés) mindent újraritkít.
class TrackLineSimplifier {
  TrackLineSimplifier({this.rawTailLimit = 64, SegmentSimplifier? runner})
    : _runner = runner ?? isolateSimplify;

  final int rawTailLimit;
  final SegmentSimplifier _runner;

  final _cache = <_SegmentCache>[];
  int? _generation;
  int? _band;
  Future<void> _chain = Future.value();

  /// A vonalak szegmensenként. A hívások sorban futnak, így a gyorsítótár
  /// nem keveredik össze.
  Future<List<List<LatLng>>> lines(
    List<List<Fix>> segments, {
    required int generation,
    required int zoomBand,
  }) {
    final result = _chain.then(
      (_) => _lines(segments, generation: generation, zoomBand: zoomBand),
    );
    _chain = result.then((_) {}, onError: (Object _) {});
    return result;
  }

  Future<List<List<LatLng>>> _lines(
    List<List<Fix>> segments, {
    required int generation,
    required int zoomBand,
  }) async {
    if (generation != _generation || zoomBand != _band) {
      _cache.clear();
      _generation = generation;
      _band = zoomBand;
    }

    // Mit kell (újra)ritkítani? A hosszakat most rögzítjük: a szegmensek
    // élő nézetek, közben bővülhetnek.
    final toRun = <int>[];
    final lengths = [for (final s in segments) s.length];
    for (var i = 0; i < segments.length; i++) {
      final isLast = i == segments.length - 1;
      final cached = i < _cache.length ? _cache[i] : null;
      final tail = lengths[i] - (cached?.prefixLen ?? 0);
      if (tail == 0 && cached != null) continue;
      // Lezárt szegmens nyers vége lezáráskor beritkul; az utolsónál csak
      // a határ felett.
      if (!isLast || tail > rawTailLimit) {
        toRun.add(i);
      } else if (cached == null) {
        _setCache(i, _SegmentCache(const [], 0));
      }
    }

    if (toRun.isNotEmpty) {
      final latDeg = _referenceLat(segments);
      final simplified = await _runner([
        for (final i in toRun)
          [
            for (var j = 0; j < lengths[i]; j++)
              (segments[i][j].latDeg, segments[i][j].lonDeg),
          ],
      ], toleranceForZoom(zoomBand.toDouble(), latDeg: latDeg));
      for (var k = 0; k < toRun.length; k++) {
        _setCache(
          toRun[k],
          _SegmentCache([
            for (final p in simplified[k]) LatLng(p.$1, p.$2),
          ], lengths[toRun[k]]),
        );
      }
    }

    return [
      for (var i = 0; i < segments.length; i++)
        _withRawTail(_cache[i], segments[i], lengths[i]),
    ];
  }

  void _setCache(int i, _SegmentCache entry) {
    while (_cache.length <= i) {
      _cache.add(_SegmentCache(const [], 0));
    }
    _cache[i] = entry;
  }

  List<LatLng> _withRawTail(_SegmentCache c, List<Fix> segment, int length) {
    if (c.prefixLen == length) return c.simplified;
    return [
      ...c.simplified,
      for (var j = c.prefixLen; j < length; j++)
        LatLng(segment[j].latDeg, segment[j].lonDeg),
    ];
  }

  static double _referenceLat(List<List<Fix>> segments) {
    for (final s in segments) {
      if (s.isNotEmpty) return s.first.latDeg;
    }
    return 47;
  }
}
