import 'dart:convert';
import 'dart:typed_data';

/// Az importált fájl nem használható térképként; az üzenet a
/// felhasználónak szól.
class PmtilesFormatException implements Exception {
  const PmtilesFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// A PMTiles v3 fejlécének (az első 127 bájt) számunkra fontos mezői.
class PmtilesInfo {
  const PmtilesInfo({
    required this.minZoom,
    required this.maxZoom,
    required this.minLonDeg,
    required this.minLatDeg,
    required this.maxLonDeg,
    required this.maxLatDeg,
    required this.centerZoom,
    required this.centerLonDeg,
    required this.centerLatDeg,
  });

  final int minZoom;
  final int maxZoom;
  final double minLonDeg;
  final double minLatDeg;
  final double maxLonDeg;
  final double maxLatDeg;
  final int centerZoom;
  final double centerLonDeg;
  final double centerLatDeg;
}

/// A fejléc hossza bájtban (PMTiles v3).
const pmtilesHeaderLength = 127;

// A `pmtiles` csomag (1.3.0) csak ezeket a tömörítéseket tudja olvasni.
const _compressionNone = 1;
const _compressionGzip = 2;
const _tileTypeMvt = 1;

/// A fájl első bájtjainak ellenőrzése és értelmezése. A `pmtiles` csomag
/// `Header`-je helyett saját olvasó: a csomagot nem importáljuk közvetlenül
/// (tranzitív függőség), és a hibákat így felhasználóbarát szöveggel adjuk.
///
/// [bytes] a fájl eleje (legalább 127 bájt); a többi nem számít.
/// Érvénytelen fájlnál [PmtilesFormatException].
PmtilesInfo parsePmtilesHeader(Uint8List bytes) {
  if (bytes.length < pmtilesHeaderLength) {
    throw const PmtilesFormatException(
      'A fájl túl rövid ahhoz, hogy PMTiles-térkép legyen.',
    );
  }
  final data = ByteData.view(bytes.buffer, bytes.offsetInBytes, 127);

  final magic = utf8.decode(bytes.sublist(0, 7), allowMalformed: true);
  if (magic != 'PMTiles') {
    throw const PmtilesFormatException('A fájl nem PMTiles-térkép.');
  }

  final version = data.getUint8(0x07);
  if (version != 3) {
    throw PmtilesFormatException(
      'Nem támogatott PMTiles-verzió: a fájl $version-es, a 3-as kell.',
    );
  }

  if (data.getUint8(0x60) != 1) {
    throw const PmtilesFormatException(
      'A nem csoportosított (clustered) PMTiles-archívum nem támogatott.',
    );
  }

  for (final offset in [0x61, 0x62]) {
    final c = data.getUint8(offset);
    if (c != _compressionNone && c != _compressionGzip) {
      throw const PmtilesFormatException(
        'Nem támogatott tömörítés a térképfájlban (csak a gzip és a '
        'tömörítetlen megy).',
      );
    }
  }

  if (data.getUint8(0x63) != _tileTypeMvt) {
    throw const PmtilesFormatException(
      'A térkép nem vektoros (MVT) csempéket tartalmaz; az app vektoros '
      'térképet jelenít meg.',
    );
  }

  final minZoom = data.getUint8(0x64);
  final maxZoom = data.getUint8(0x65);
  if (minZoom > maxZoom) {
    throw PmtilesFormatException(
      'Hibás zoomtartomány a térképfájlban: $minZoom–$maxZoom.',
    );
  }

  double e7(int offset) => data.getInt32(offset, Endian.little) / 1e7;
  final minLon = e7(0x66);
  final minLat = e7(0x6A);
  final maxLon = e7(0x6E);
  final maxLat = e7(0x72);
  final inRange =
      minLon >= -180 &&
      maxLon <= 180 &&
      minLat >= -90 &&
      maxLat <= 90 &&
      minLon <= maxLon &&
      minLat <= maxLat;
  if (!inRange) {
    throw const PmtilesFormatException(
      'Hibás földrajzi határ a térképfájlban.',
    );
  }

  return PmtilesInfo(
    minZoom: minZoom,
    maxZoom: maxZoom,
    minLonDeg: minLon,
    minLatDeg: minLat,
    maxLonDeg: maxLon,
    maxLatDeg: maxLat,
    centerZoom: data.getUint8(0x76),
    centerLonDeg: e7(0x77),
    centerLatDeg: e7(0x7B),
  );
}
