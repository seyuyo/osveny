import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/map/map_store.dart';
import 'package:osveny/map/pmtiles_header.dart';

import 'pmtiles_fixture.dart';

Stream<List<int>> chunked(Uint8List bytes, int size) async* {
  for (var i = 0; i < bytes.length; i += size) {
    yield bytes.sublist(i, i + size > bytes.length ? bytes.length : i + size);
  }
}

ImportSource source(String name, Uint8List bytes, {int chunk = 64}) =>
    ImportSource(
      name: name,
      length: bytes.length,
      open: () => chunked(bytes, chunk),
    );

void main() {
  late Directory tmp;
  late Directory mapsDir;
  late MapStore store;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('osveny_maps_test_');
    mapsDir = Directory('${tmp.path}${Platform.pathSeparator}maps');
    store = MapStore(mapsDir);
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  List<String> filesInDir() => mapsDir.existsSync()
      ? mapsDir.listSync().map((e) => e.uri.pathSegments.last).toList()
      : <String>[];

  Matcher rejects(String part) => throwsA(
    isA<PmtilesFormatException>().having(
      (e) => e.message,
      'message',
      contains(part),
    ),
  );

  group('import', () {
    test('érvényes archívum: bájtra pontos másolat, adatok, aktív', () async {
      final bytes = buildPmtilesArchive();
      final m = await store.import(source('pilis.pmtiles', bytes));

      expect(m.name, 'pilis.pmtiles');
      expect(m.sizeBytes, bytes.length);
      expect(m.info.maxZoom, 14);
      expect(File(m.path).readAsBytesSync(), bytes);
      expect(filesInDir(), unorderedEquals(['pilis.pmtiles', 'active.txt']));
      expect((await store.active())!.name, 'pilis.pmtiles');
    });

    test('gzip tömörítésű belső könyvtárral is megnyílik', () async {
      final m = await store.import(
        source('gz.pmtiles', buildPmtilesArchive(gzipInternal: true)),
      );
      expect(m.info.minZoom, 0);
    });

    test('a folyamatjelző növekszik és a teljes méretnél ér véget', () async {
      final bytes = buildPmtilesArchive();
      final calls = <(int, int?)>[];
      await store.import(
        source('p.pmtiles', bytes, chunk: 7),
        onProgress: (copied, total) => calls.add((copied, total)),
      );

      expect(calls, isNotEmpty);
      expect(calls.last, (bytes.length, bytes.length));
      for (var i = 1; i < calls.length; i++) {
        expect(calls[i].$1, greaterThan(calls[i - 1].$1));
      }
    });

    test('ismeretlen hossz: a total null', () async {
      final bytes = buildPmtilesArchive();
      int? total = -1;
      await store.import(
        ImportSource(name: 'p.pmtiles', open: () => chunked(bytes, 50)),
        onProgress: (_, t) => total = t,
      );
      expect(total, isNull);
    });

    test('a kiterjesztés kisbetűs .pmtiles lesz', () async {
      final m = await store.import(
        source('PILIS.PMTILES', buildPmtilesArchive()),
      );
      expect(m.name, 'PILIS.pmtiles');
    });

    group('elutasítás: nem marad félkész fájl', () {
      test('rossz kiterjesztés', () async {
        await expectLater(
          store.import(source('terkep.txt', buildPmtilesArchive())),
          throwsA(
            isA<PmtilesFormatException>().having(
              (e) => e.message,
              'message',
              contains('.pmtiles'),
            ),
          ),
        );
        expect(filesInDir(), isEmpty);
      });

      test('.pmtiles-nek átnevezett szöveges fájl', () async {
        final text = Uint8List.fromList(List.filled(400, 65));
        await expectLater(
          store.import(source('hamis.pmtiles', text)),
          rejects('nem PMTiles'),
        );
        expect(filesInDir(), isEmpty);
      });

      test('raszter térkép', () async {
        await expectLater(
          store.import(
            source('raszter.pmtiles', buildPmtilesArchive(tileType: 2)),
          ),
          rejects('vektoros'),
        );
        expect(filesInDir(), isEmpty);
      });

      test('érvényes fejléc, de csonka fájl (sérült gyökérkönyvtár)', () async {
        final truncated = buildPmtilesArchive().sublist(0, 130);
        await expectLater(
          store.import(source('csonka.pmtiles', truncated)),
          rejects('sérült'),
        );
        expect(filesInDir(), isEmpty);
      });

      test(
        'megszakadt másolás: hiba kifelé, takarítás, a régi térkép él',
        () async {
          final good = await store.import(
            source('regi.pmtiles', buildPmtilesArchive()),
          );

          Stream<List<int>> failing() async* {
            yield buildPmtilesArchive().sublist(0, 100);
            throw const FileSystemException('a kártya eltávolítva');
          }

          await expectLater(
            store.import(ImportSource(name: 'uj.pmtiles', open: failing)),
            throwsA(isA<FileSystemException>()),
          );
          expect(
            filesInDir(),
            unorderedEquals(['regi.pmtiles', 'active.txt']),
            reason: 'sem .part, sem új fájl',
          );
          expect(File(good.path).existsSync(), isTrue);
          expect((await store.active())!.name, 'regi.pmtiles');
        },
      );
    });

    group('fájlnév', () {
      test('útvonal-bejárás kiszűrve: csak a térképmappába írunk', () async {
        final m = await store.import(
          source('../../kint/gonosz.pmtiles', buildPmtilesArchive()),
        );
        expect(m.name, 'gonosz.pmtiles');
        expect(File(m.path).parent.path, mapsDir.path);
        expect(
          Directory('${tmp.path}${Platform.pathSeparator}kint').existsSync(),
          isFalse,
        );
      });

      test('visszaper-jeles és tiltott karakterek cserélve', () async {
        final m = await store.import(
          source(r'a\b:c*d.pmtiles', buildPmtilesArchive()),
        );
        // A `\` is útvonal-elválasztó: csak az utolsó elem marad.
        expect(m.name, 'b_c_d.pmtiles');
        final m2 = await store.import(
          source('t:e*s?t.pmtiles', buildPmtilesArchive()),
        );
        expect(m2.name, 't_e_s_t.pmtiles');
      });

      test(
        'rejtett fájlnak látszó név nem ütközik a félkész fájlokkal',
        () async {
          final m = await store.import(
            source('.import-1.pmtiles', buildPmtilesArchive()),
          );
          expect(m.name.startsWith('.'), isFalse);
        },
      );

      test('üres név a kiterjesztés előtt: alapértelmezett', () async {
        final m = await store.import(source('.pmtiles', buildPmtilesArchive()));
        expect(m.name, 'terkep.pmtiles');
      });
    });

    test(
      'azonos nevű térkép cseréje: egy fájl marad, az új tartalommal',
      () async {
        await store.import(
          source('p.pmtiles', buildPmtilesArchive(maxZoom: 10)),
        );
        final m = await store.import(
          source('p.pmtiles', buildPmtilesArchive(maxZoom: 14)),
        );

        expect(m.info.maxZoom, 14);
        expect((await store.list()).length, 1);
        expect((await store.list()).single.info.maxZoom, 14);
      },
    );
  });

  group('list', () {
    test('nem létező mappa: üres lista, nincs hiba', () async {
      expect(await store.list(), isEmpty);
      expect(await store.active(), isNull);
    });

    test('csak az érvényes .pmtiles fájlok, a legújabb elöl', () async {
      await store.import(source('a.pmtiles', buildPmtilesArchive()));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await store.import(source('b.pmtiles', buildPmtilesArchive()));

      File(
        '${mapsDir.path}${Platform.pathSeparator}jegyzet.txt',
      ).writeAsStringSync('x');
      File(
        '${mapsDir.path}${Platform.pathSeparator}.import-1.part',
      ).writeAsBytesSync([1, 2, 3]);
      File(
        '${mapsDir.path}${Platform.pathSeparator}rossz.pmtiles',
      ).writeAsBytesSync(List.filled(300, 9));

      expect((await store.list()).map((m) => m.name), [
        'b.pmtiles',
        'a.pmtiles',
      ]);
    });
  });

  group('aktív térkép', () {
    test('az utoljára importált az aktív', () async {
      await store.import(source('a.pmtiles', buildPmtilesArchive()));
      await store.import(source('b.pmtiles', buildPmtilesArchive()));
      expect((await store.active())!.name, 'b.pmtiles');
    });

    test('setActive átvált, és újraindítás után is megmarad', () async {
      await store.import(source('a.pmtiles', buildPmtilesArchive()));
      await store.import(source('b.pmtiles', buildPmtilesArchive()));
      await store.setActive('a.pmtiles');

      final reopened = MapStore(mapsDir);
      expect((await reopened.active())!.name, 'a.pmtiles');
    });

    test('nem telepített térkép nem lehet aktív', () async {
      await expectLater(
        store.setActive('nincs.pmtiles'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('ha az aktív fájl eltűnt, a legújabb a tartalék', () async {
      await store.import(source('a.pmtiles', buildPmtilesArchive()));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final b = await store.import(source('b.pmtiles', buildPmtilesArchive()));
      File(b.path).deleteSync();

      expect((await store.active())!.name, 'a.pmtiles');
    });
  });

  group('törlés', () {
    test('törli a fájlt, és az aktívat átállítja a maradékra', () async {
      await store.import(source('a.pmtiles', buildPmtilesArchive()));
      await store.import(source('b.pmtiles', buildPmtilesArchive()));
      await store.delete('b.pmtiles');

      expect(filesInDir(), isNot(contains('b.pmtiles')));
      expect((await store.active())!.name, 'a.pmtiles');
    });

    test('az utolsó törlése után nincs aktív térkép', () async {
      await store.import(source('a.pmtiles', buildPmtilesArchive()));
      await store.delete('a.pmtiles');
      expect(await store.active(), isNull);
      expect(filesInDir(), isEmpty);
    });

    test('nem létező térkép törlése nem hiba', () async {
      await store.delete('nincs.pmtiles');
    });

    test('útvonal-bejárással nem törölhető a mappán kívüli fájl', () async {
      final outside = File('${tmp.path}${Platform.pathSeparator}kint.pmtiles')
        ..writeAsBytesSync([1]);
      await store.delete('../kint.pmtiles');
      expect(outside.existsSync(), isTrue);
    });
  });

  test('cleanupPartials: a megszakadt importok maradékát törli', () async {
    mapsDir.createSync(recursive: true);
    final part = File('${mapsDir.path}${Platform.pathSeparator}.import-9.part')
      ..writeAsBytesSync([1, 2, 3]);
    await store.import(source('a.pmtiles', buildPmtilesArchive()));

    await store.cleanupPartials();

    expect(part.existsSync(), isFalse);
    expect((await store.list()).single.name, 'a.pmtiles');
  });
}
