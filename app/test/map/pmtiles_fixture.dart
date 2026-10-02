import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// Egy minimális, de valódi PMTiles v3 archívum a teszteknek: fejléc,
/// gyökérkönyvtár egyetlen csempével, metaadat és a csempe adata. A
/// `pmtiles` csomag ezt ugyanúgy olvassa, mint egy valódi kivágatot.
///
/// A paraméterekkel egyenként elronthatók a fejléc mezői.
Uint8List buildPmtilesHeader({
  String magic = 'PMTiles',
  int version = 3,
  int rootOffset = 127,
  int rootLength = 0,
  int metadataOffset = 127,
  int metadataLength = 0,
  int leafOffset = 127,
  int leafLength = 0,
  int tileDataOffset = 127,
  int tileDataLength = 0,
  int clustered = 1,
  int internalCompression = 1,
  int tileCompression = 1,
  int tileType = 1,
  int minZoom = 0,
  int maxZoom = 14,
  double minLonDeg = 18.8,
  double minLatDeg = 47.6,
  double maxLonDeg = 19.1,
  double maxLatDeg = 47.8,
  int centerZoom = 8,
  double centerLonDeg = 18.95,
  double centerLatDeg = 47.7,
}) {
  final bytes = Uint8List(127);
  final data = ByteData.view(bytes.buffer);
  final m = ascii.encode(magic);
  for (var i = 0; i < 7 && i < m.length; i++) {
    bytes[i] = m[i];
  }
  data.setUint8(0x07, version);
  void u64(int offset, int v) => data.setUint64(offset, v, Endian.little);
  u64(0x08, rootOffset);
  u64(0x10, rootLength);
  u64(0x18, metadataOffset);
  u64(0x20, metadataLength);
  u64(0x28, leafOffset);
  u64(0x30, leafLength);
  u64(0x38, tileDataOffset);
  u64(0x40, tileDataLength);
  u64(0x48, 1); // addressed tiles
  u64(0x50, 1); // tile entries
  u64(0x58, 1); // tile contents
  data.setUint8(0x60, clustered);
  data.setUint8(0x61, internalCompression);
  data.setUint8(0x62, tileCompression);
  data.setUint8(0x63, tileType);
  data.setUint8(0x64, minZoom);
  data.setUint8(0x65, maxZoom);
  void e7(int offset, double lonDeg, double latDeg) {
    data.setInt32(offset, (lonDeg * 1e7).round(), Endian.little);
    data.setInt32(offset + 4, (latDeg * 1e7).round(), Endian.little);
  }

  e7(0x66, minLonDeg, minLatDeg);
  e7(0x6E, maxLonDeg, maxLatDeg);
  data.setUint8(0x76, centerZoom);
  e7(0x77, centerLonDeg, centerLatDeg);
  return bytes;
}

/// Teljes archívum. `gzipInternal`: a gyökérkönyvtár és a metaadat gzip
/// tömörítésű (a valódi kivágatok ilyenek).
Uint8List buildPmtilesArchive({
  bool gzipInternal = false,
  int tileLength = 10,
  int version = 3,
  int tileType = 1,
  int minZoom = 0,
  int maxZoom = 14,
  double minLonDeg = 18.8,
  double minLatDeg = 47.6,
  double maxLonDeg = 19.1,
  double maxLatDeg = 47.8,
}) {
  assert(tileLength > 0 && tileLength < 128, 'egybájtos varint');
  // Gyökérkönyvtár: 1 bejegyzés (tileId 0, futamhossz 1, hossz, offset+1).
  var root = Uint8List.fromList([1, 0, 1, tileLength, 1]);
  var metadata = Uint8List.fromList(utf8.encode('{}'));
  if (gzipInternal) {
    root = Uint8List.fromList(gzip.encode(root));
    metadata = Uint8List.fromList(gzip.encode(metadata));
  }
  final tile = Uint8List.fromList(List.generate(tileLength, (i) => i + 1));

  final rootOffset = 127;
  final metadataOffset = rootOffset + root.length;
  final leafOffset = metadataOffset + metadata.length;
  final tileDataOffset = leafOffset;

  final header = buildPmtilesHeader(
    version: version,
    rootOffset: rootOffset,
    rootLength: root.length,
    metadataOffset: metadataOffset,
    metadataLength: metadata.length,
    leafOffset: leafOffset,
    leafLength: 0,
    tileDataOffset: tileDataOffset,
    tileDataLength: tile.length,
    internalCompression: gzipInternal ? 2 : 1,
    tileCompression: 1,
    tileType: tileType,
    minZoom: minZoom,
    maxZoom: maxZoom,
    minLonDeg: minLonDeg,
    minLatDeg: minLatDeg,
    maxLonDeg: maxLonDeg,
    maxLatDeg: maxLatDeg,
    centerZoom: (minZoom + maxZoom) ~/ 2,
  );
  return Uint8List.fromList([...header, ...root, ...metadata, ...tile]);
}
