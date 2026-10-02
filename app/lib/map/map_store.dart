import 'dart:io';
import 'dart:typed_data';

import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

import 'pmtiles_header.dart';

/// Egy importálandó fájl a kiválasztótól függetlenül: név, (ismert) hossz és
/// egy folyam, amiből a tartalom olvasható. A fájlkiválasztó csomag ezt
/// egy vékony adapteren keresztül adja, így az importőr tesztelhető.
class ImportSource {
  const ImportSource({required this.name, required this.open, this.length});

  /// Az eredeti fájlnév (útvonal nélkül vagy azzal; az importőr tisztítja).
  final String name;

  /// A fájl mérete bájtban, ha ismert.
  final int? length;

  /// A tartalom folyama. Egyszer hívjuk; nagy fájlnál nem tölti a memóriába.
  final Stream<List<int>> Function() open;
}

/// Egy telepített (az app mappájában lévő) térkép.
class InstalledMap {
  const InstalledMap({
    required this.name,
    required this.path,
    required this.sizeBytes,
    required this.modified,
    required this.info,
  });

  /// Fájlnév a térképmappán belül (`pilis.pmtiles`).
  final String name;
  final String path;
  final int sizeBytes;
  final DateTime modified;
  final PmtilesInfo info;
}

/// A térképmappa kezelése: import, lista, aktív térkép, törlés.
///
/// Egy importnál a fájl ideiglenes néven (`.import-…part`) készül, a
/// folyamatos másolás után ellenőrizzük (fejléc, majd a gyökérkönyvtár
/// tényleges megnyitása), és csak sikeres ellenőrzés után kapja a végleges
/// nevét. Hiba vagy megszakadás esetén a félkész fájl törlődik, a már
/// telepített térképek érintetlenek maradnak.
class MapStore {
  MapStore(this.dir);

  final Directory dir;

  static const _extension = '.pmtiles';
  static const _activeFile = 'active.txt';
  static const _defaultStem = 'terkep';

  String _child(String name) => '${dir.path}${Platform.pathSeparator}$name';

  /// A fájlnév tisztítása: csak a név marad (útvonal nélkül), a Windows- és
  /// shell-tiltott karakterek `_`-re cserélődnek, a kiterjesztés kisbetűs
  /// `.pmtiles`. `null`, ha a kiterjesztés nem `.pmtiles`.
  static String? _cleanName(String raw) {
    final base = raw.split(RegExp(r'[\\/]')).last.trim();
    if (!base.toLowerCase().endsWith(_extension)) return null;
    var stem = base
        .substring(0, base.length - _extension.length)
        .replaceAll(RegExp(r'[:*?"<>|\x00-\x1f]'), '_')
        // Pont az elején: rejtett fájl lenne, és ütközne a félkész fájlokkal.
        .replaceFirst(RegExp(r'^\.+'), '')
        .trim();
    if (stem.isEmpty) stem = _defaultStem;
    return '$stem$_extension';
  }

  /// A térkép importálása. [onProgress]: eddig másolt bájt és (ha ismert)
  /// az összes. Érvénytelen fájlnál [PmtilesFormatException].
  Future<InstalledMap> import(
    ImportSource source, {
    void Function(int copied, int? total)? onProgress,
  }) async {
    final name = _cleanName(source.name);
    if (name == null) {
      throw const PmtilesFormatException(
        'A fájl kiterjesztése nem .pmtiles; PMTiles-térképet válassz.',
      );
    }

    await dir.create(recursive: true);
    final part = File(
      _child('.import-${DateTime.now().microsecondsSinceEpoch}.part'),
    );
    try {
      await _copy(source, part, onProgress);
      parsePmtilesHeader(await _readHead(part));
      await _openCheck(part.path);

      final target = File(_child(name));
      if (await target.exists()) await target.delete();
      await part.rename(target.path);
      await setActive(name);
      return (await _describe(target))!;
    } catch (_) {
      if (await part.exists()) await part.delete();
      rethrow;
    }
  }

  /// Soronkénti másolás `await`-elt írással: a háttérnyomás miatt a
  /// több száz MB-os fájl sem gyűlik fel a memóriában.
  Future<void> _copy(
    ImportSource source,
    File target,
    void Function(int, int?)? onProgress,
  ) async {
    final raf = await target.open(mode: FileMode.write);
    try {
      var copied = 0;
      await for (final chunk in source.open()) {
        await raf.writeFrom(chunk);
        copied += chunk.length;
        onProgress?.call(copied, source.length);
      }
    } finally {
      await raf.close();
    }
  }

  Future<Uint8List> _readHead(File file) async {
    final raf = await file.open();
    try {
      return await raf.read(pmtilesHeaderLength);
    } finally {
      await raf.close();
    }
  }

  /// A fejléc mellett a gyökérkönyvtárat is megnyitja ugyanazzal a kóddal,
  /// amit a térkép használ: a csonka vagy sérült fájl itt derül ki, nem a
  /// térképen.
  Future<void> _openCheck(String path) async {
    try {
      final provider = await PmTilesVectorTileProvider.fromSource(path);
      await provider.archive.close();
    } catch (_) {
      throw const PmtilesFormatException(
        'A térképfájl sérült vagy nem olvasható.',
      );
    }
  }

  Future<InstalledMap?> _describe(File file) async {
    try {
      final info = parsePmtilesHeader(await _readHead(file));
      final stat = await file.stat();
      return InstalledMap(
        name: file.uri.pathSegments.last,
        path: file.path,
        sizeBytes: stat.size,
        modified: stat.modified,
        info: info,
      );
    } on PmtilesFormatException {
      return null;
    }
  }

  /// A telepített, érvényes térképek, a legújabb elöl.
  Future<List<InstalledMap>> list() async {
    if (!await dir.exists()) return [];
    final maps = <InstalledMap>[];
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final name = entity.uri.pathSegments.last;
      if (name.startsWith('.') || !name.endsWith(_extension)) continue;
      final m = await _describe(entity);
      if (m != null) maps.add(m);
    }
    maps.sort((a, b) => b.modified.compareTo(a.modified));
    return maps;
  }

  /// Az aktív térkép: a kiválasztott, ha még létezik; különben a legújabb.
  Future<InstalledMap?> active() async {
    final maps = await list();
    if (maps.isEmpty) return null;
    final file = File(_child(_activeFile));
    if (await file.exists()) {
      final chosen = (await file.readAsString()).trim();
      for (final m in maps) {
        if (m.name == chosen) return m;
      }
    }
    return maps.first;
  }

  Future<void> setActive(String name) async {
    final clean = _cleanName(name);
    final installed = clean != null && await File(_child(clean)).exists();
    if (!installed) {
      throw ArgumentError.value(name, 'name', 'nem telepített térkép');
    }
    await File(_child(_activeFile)).writeAsString(clean);
  }

  /// Törli a térképet; ha az volt az aktív, a választás is törlődik (az
  /// aktív ilyenkor a legújabb maradék). Nem létező térképnél nem hiba.
  Future<void> delete(String name) async {
    final clean = _cleanName(name);
    if (clean == null) return;
    final file = File(_child(clean));
    if (await file.exists()) await file.delete();

    final activeFile = File(_child(_activeFile));
    if (await activeFile.exists() &&
        (await activeFile.readAsString()).trim() == clean) {
      await activeFile.delete();
    }
  }

  /// A megszakadt importok félkész fájljainak törlése (induláskor).
  Future<void> cleanupPartials() async {
    if (!await dir.exists()) return;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.part')) {
        await entity.delete();
      }
    }
  }
}
