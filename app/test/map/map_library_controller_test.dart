import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/map/map_file_picker.dart';
import 'package:osveny/map/map_library_controller.dart';
import 'package:osveny/map/map_store.dart';

import 'pmtiles_fixture.dart';

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

ImportSource sourceOf(String name, Uint8List bytes) => ImportSource(
  name: name,
  length: bytes.length,
  open: () => Stream.fromIterable([
    for (var i = 0; i < bytes.length; i += 40)
      bytes.sublist(i, i + 40 > bytes.length ? bytes.length : i + 40),
  ]),
);

void main() {
  late Directory tmp;
  late MapStore store;
  late FakePicker picker;
  late ProviderContainer container;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('osveny_lib_test_');
    store = MapStore(Directory('${tmp.path}${Platform.pathSeparator}maps'));
    picker = FakePicker();
    container = ProviderContainer(
      overrides: [
        mapStoreProvider.overrideWithValue(store),
        mapFilePickerProvider.overrideWithValue(picker),
      ],
    );
  });
  tearDown(() async {
    // A háttérben induló betöltésnek le kell csengenie: Windowson a nyitott
    // könyvtárbejárás miatt a mappa addig nem törölhető.
    await pumpEventQueue();
    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    tmp.deleteSync(recursive: true);
  });

  MapLibraryController ctrl() =>
      container.read(mapLibraryControllerProvider.notifier);
  MapLibraryState state() => container.read(mapLibraryControllerProvider);

  /// A vezérlő első betöltésének megvárása.
  Future<void> loaded() async {
    container.read(mapLibraryControllerProvider);
    await ctrl().load();
  }

  test('kezdetben betöltés alatt van, aztán kész', () async {
    expect(state().phase, MapLibraryPhase.loading);
    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(state().phase, MapLibraryPhase.ready);
  });

  test('üres mappa: kész, nincs térkép', () async {
    await loaded();
    expect(state().phase, MapLibraryPhase.ready);
    expect(state().maps, isEmpty);
    expect(state().active, isNull);
    expect(state().error, isNull);
  });

  test('betöltés: a már telepített térkép aktív', () async {
    await store.import(sourceOf('a.pmtiles', buildPmtilesArchive()));
    await loaded();
    expect(state().maps.single.name, 'a.pmtiles');
    expect(state().active!.name, 'a.pmtiles');
  });

  test('betöltés takarítja a megszakadt importok maradékát', () async {
    final dir = Directory('${tmp.path}${Platform.pathSeparator}maps')
      ..createSync(recursive: true);
    final part = File('${dir.path}${Platform.pathSeparator}.import-1.part')
      ..writeAsBytesSync([1]);
    await loaded();
    expect(part.existsSync(), isFalse);
  });

  group('importálás', () {
    test('sikeres: az új térkép aktív, a folyamat 100%', () async {
      await loaded();
      picker.next = sourceOf('pilis.pmtiles', buildPmtilesArchive());

      final progresses = <double?>[];
      container.listen(
        mapLibraryControllerProvider,
        (_, next) => progresses.add(next.progress),
      );
      await ctrl().importMap();

      expect(state().phase, MapLibraryPhase.ready);
      expect(state().active!.name, 'pilis.pmtiles');
      expect(state().maps.length, 1);
      expect(state().error, isNull);
      expect(progresses.whereType<double>().isNotEmpty, isTrue);
      expect(
        progresses.whereType<double>().every((p) => p >= 0 && p <= 1),
        isTrue,
      );
    });

    test('közben importing fázis', () async {
      await loaded();
      final gate = Completer<void>();
      final bytes = buildPmtilesArchive();
      picker.next = ImportSource(
        name: 'p.pmtiles',
        length: bytes.length,
        open: () async* {
          await gate.future;
          yield bytes;
        },
      );

      final running = ctrl().importMap();
      await pumpEventQueue();
      expect(state().phase, MapLibraryPhase.importing);

      gate.complete();
      await running;
      expect(state().phase, MapLibraryPhase.ready);
    });

    test('a kiválasztó megszakítása (null): semmi sem változik', () async {
      await store.import(sourceOf('a.pmtiles', buildPmtilesArchive()));
      await loaded();
      picker.next = null;

      await ctrl().importMap();

      expect(state().phase, MapLibraryPhase.ready);
      expect(state().error, isNull);
      expect(state().maps.length, 1);
    });

    test('érvénytelen fájl: érthető hiba, a régi térkép marad', () async {
      await store.import(sourceOf('a.pmtiles', buildPmtilesArchive()));
      await loaded();
      picker.next = sourceOf('hamis.pmtiles', Uint8List(300));

      await ctrl().importMap();

      expect(state().phase, MapLibraryPhase.ready);
      expect(state().error, contains('nem PMTiles'));
      expect(state().active!.name, 'a.pmtiles');
      expect(state().maps.length, 1);
    });

    test('rossz kiterjesztés: hiba', () async {
      await loaded();
      picker.next = sourceOf('jegyzet.txt', buildPmtilesArchive());
      await ctrl().importMap();
      expect(state().error, contains('.pmtiles'));
    });

    test('váratlan hiba (pl. I/O): általános üzenet a szöveggel', () async {
      await loaded();
      picker.error = const FileSystemException('nincs hely');
      await ctrl().importMap();

      expect(state().phase, MapLibraryPhase.ready);
      expect(state().error, contains('nem sikerült'));
      expect(state().error, contains('nincs hely'));
    });

    test('a következő sikeres import törli a hibát', () async {
      await loaded();
      picker.next = sourceOf('jegyzet.txt', buildPmtilesArchive());
      await ctrl().importMap();
      expect(state().error, isNotNull);

      picker.next = sourceOf('jo.pmtiles', buildPmtilesArchive());
      await ctrl().importMap();
      expect(state().error, isNull);
    });

    test('folyamatban lévő import közben a második hívás nem indul', () async {
      await loaded();
      final gate = Completer<void>();
      final bytes = buildPmtilesArchive();
      picker.next = ImportSource(
        name: 'p.pmtiles',
        open: () async* {
          await gate.future;
          yield bytes;
        },
      );

      final first = ctrl().importMap();
      await pumpEventQueue();
      await ctrl().importMap();
      expect(picker.calls, 1);

      gate.complete();
      await first;
    });
  });

  test('setActive átvált az aktív térképre', () async {
    await store.import(sourceOf('a.pmtiles', buildPmtilesArchive()));
    await store.import(sourceOf('b.pmtiles', buildPmtilesArchive()));
    await loaded();
    expect(state().active!.name, 'b.pmtiles');

    await ctrl().setActive('a.pmtiles');
    expect(state().active!.name, 'a.pmtiles');
  });

  test('törlés: a lista és az aktív frissül', () async {
    await store.import(sourceOf('a.pmtiles', buildPmtilesArchive()));
    await store.import(sourceOf('b.pmtiles', buildPmtilesArchive()));
    await loaded();

    await ctrl().delete('b.pmtiles');
    expect(state().maps.map((m) => m.name), ['a.pmtiles']);
    expect(state().active!.name, 'a.pmtiles');

    await ctrl().delete('a.pmtiles');
    expect(state().maps, isEmpty);
    expect(state().active, isNull);
  });

  test('clearError törli a hibát', () async {
    await loaded();
    picker.next = sourceOf('x.txt', buildPmtilesArchive());
    await ctrl().importMap();
    expect(state().error, isNotNull);

    ctrl().clearError();
    expect(state().error, isNull);
  });
}
