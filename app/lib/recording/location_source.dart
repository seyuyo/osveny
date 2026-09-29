import 'dart:async';

import 'package:geo_core/geo_core.dart';
import 'package:geo_core/testing.dart';

import 'track_profile.dart';

/// A rögzítés helyforrása: nyers fixek folyama. Két megvalósítása van: a
/// `GeolocatorLocationSource` és a CSV-ből játszó [ReplayLocationSource].
abstract interface class LocationSource {
  /// A fixek folyama a profilnak megfelelő beállításokkal. A feliratkozás
  /// indítja, a lemondás állítja le a forrást (és az előtér-szolgáltatást).
  Stream<Fix> fixes(TrackProfile profile);
}

/// A helyforrás felhasználónak megjeleníthető hibája.
class LocationSourceException implements Exception {
  const LocationSourceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Felvett vagy szintetikus nyomvonal visszajátszása: integrációs tesztekhez
/// és GPS nélküli demóhoz. A fixeket változtatás nélkül adja, a `tMs` a
/// bemeneté.
class ReplayLocationSource implements LocationSource {
  ReplayLocationSource(this._fixes, {this.delay});

  /// A `geo_core` CSV-formátumából (`tMs,lat,lon,alt,hAcc,vAcc,speed`).
  ReplayLocationSource.fromCsv(String csv, {this.delay})
    : _fixes = parseFixCsv(csv);

  final List<Fix> _fixes;

  /// Két fix között várt idő; `null`: amilyen gyorsan a fogyasztó veszi.
  final Duration? delay;

  /// Nem `async*`: annak a `cancel()`-je a következő `yield`-ig vár, így egy
  /// késleltetett lejátszás lemondása is lógna.
  @override
  Stream<Fix> fixes(TrackProfile profile) {
    final d = delay;
    if (d == null) return Stream.fromIterable(_fixes);
    return Stream.periodic(d, (i) => _fixes[i]).take(_fixes.length);
  }
}
