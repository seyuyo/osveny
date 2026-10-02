import 'dart:typed_data';

import 'package:osveny/map/map_file_picker.dart';
import 'package:osveny/map/map_store.dart';

/// Kézzel vezérelhető fájlkiválasztó a tesztekhez.
class FakePicker implements MapFilePicker {
  ImportSource? next;
  Object? error;
  int calls = 0;

  @override
  Future<ImportSource?> pick() async {
    calls++;
    final e = error;
    if (e != null) throw e;
    return next;
  }
}

/// A bájtokból kis darabokban olvasható forrás (a folyamatjelző teszteléséhez).
ImportSource sourceOf(String name, Uint8List bytes, {int chunk = 40}) =>
    ImportSource(
      name: name,
      length: bytes.length,
      open: () => Stream.fromIterable([
        for (var i = 0; i < bytes.length; i += chunk)
          bytes.sublist(i, i + chunk > bytes.length ? bytes.length : i + chunk),
      ]),
    );
