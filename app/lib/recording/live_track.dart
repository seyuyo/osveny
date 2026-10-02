import 'dart:collection';

import 'package:geo_core/geo_core.dart';

/// Az éppen rögzített túra elfogadott fixei szegmensenként (szünet/folytatás
/// között), a térkép élő nyomvonalához. Csak megjelenítésre: nem tároljuk,
/// a nyers fixekből bármikor újraépíthető.
///
/// Belül módosítható, hogy fixenként ne kelljen 20 000+ elemű listát
/// másolni; a változást a [version] jelzi, kifelé csak olvasható nézetet ad.
class LiveTrack {
  final _segments = <List<Fix>>[];
  int _version = 0;

  /// Minden módosítás után nő; a figyelők ez alapján rajzolnak újra.
  int get version => _version;

  /// A szegmensek, a régebbi elöl. Csak olvasható nézet.
  List<List<Fix>> get segments => UnmodifiableListView([
    for (final s in _segments) UnmodifiableListView(s),
  ]);

  /// Az összes pont száma.
  int get pointCount => _segments.fold(0, (n, s) => n + s.length);

  /// A legutóbbi elfogadott fix, ha van.
  Fix? get last {
    for (var i = _segments.length - 1; i >= 0; i--) {
      if (_segments[i].isNotEmpty) return _segments[i].last;
    }
    return null;
  }

  /// Új túra: minden korábbi pont törlődik, egy üres szegmens nyílik.
  void reset() {
    _segments
      ..clear()
      ..add(<Fix>[]);
    _version++;
  }

  /// Új szegmens (folytatás szünet vagy megszakadás után).
  void startSegment() {
    _segments.add(<Fix>[]);
    _version++;
  }

  void add(Fix fix) {
    if (_segments.isEmpty) _segments.add(<Fix>[]);
    _segments.last.add(fix);
    _version++;
  }

  /// Feltöltés a tárolt (már szűrt) pontokból, egyetlen szegmensként.
  void seed(Iterable<Fix> accepted) {
    _segments
      ..clear()
      ..add(List<Fix>.of(accepted));
    _version++;
  }
}
