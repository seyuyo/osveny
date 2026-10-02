import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_store.dart';

/// A térképfájl kiválasztása. Interfész mögött, hogy a vezérlő hamis
/// kiválasztóval tesztelhető legyen.
abstract interface class MapFilePicker {
  /// A kiválasztott fájl, vagy `null`, ha a felhasználó megszakította.
  Future<ImportSource?> pick();
}

final mapFilePickerProvider = Provider<MapFilePicker>(
  (ref) => const PlatformMapFilePicker(),
);

/// A rendszer fájlkiválasztója a `file_picker` csomaggal. A `.pmtiles`
/// kiterjesztésnek nincs ismert MIME-típusa, ezért `FileType.any`-t kérünk;
/// a kiterjesztést és a tartalmat az importőr ellenőrzi.
class PlatformMapFilePicker implements MapFilePicker {
  const PlatformMapFilePicker();

  @override
  Future<ImportSource?> pick() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'PMTiles-térkép kiválasztása',
    );
    if (file == null) return null;
    // A tartalmat folyamként olvassuk: egy térkép több száz MB is lehet.
    return ImportSource(
      name: file.name,
      length: await file.length(),
      open: file.readAsByteStream,
    );
  }
}
