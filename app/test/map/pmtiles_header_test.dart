import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/map/pmtiles_header.dart';

import 'pmtiles_fixture.dart';

void main() {
  Matcher rejects(String messagePart) => throwsA(
    isA<PmtilesFormatException>().having(
      (e) => e.message,
      'message',
      contains(messagePart),
    ),
  );

  test('érvényes fejléc: zoom, határok és középpont', () {
    final info = parsePmtilesHeader(buildPmtilesHeader());

    expect(info.minZoom, 0);
    expect(info.maxZoom, 14);
    expect(info.minLonDeg, closeTo(18.8, 1e-7));
    expect(info.minLatDeg, closeTo(47.6, 1e-7));
    expect(info.maxLonDeg, closeTo(19.1, 1e-7));
    expect(info.maxLatDeg, closeTo(47.8, 1e-7));
    expect(info.centerZoom, 8);
    expect(info.centerLonDeg, closeTo(18.95, 1e-7));
    expect(info.centerLatDeg, closeTo(47.7, 1e-7));
  });

  test('a 127 bájton túli rész nem számít (a fájl eleje elég)', () {
    final header = buildPmtilesHeader();
    final more = Uint8List.fromList([...header, ...List.filled(500, 7)]);
    expect(parsePmtilesHeader(more).maxZoom, 14);
  });

  test('negatív koordináták (nyugati/déli félgömb) is jók', () {
    final info = parsePmtilesHeader(
      buildPmtilesHeader(
        minLonDeg: -70.5,
        minLatDeg: -34.25,
        maxLonDeg: -70.0,
        maxLatDeg: -33.5,
      ),
    );
    expect(info.minLonDeg, closeTo(-70.5, 1e-7));
    expect(info.minLatDeg, closeTo(-34.25, 1e-7));
  });

  group('elutasítás, érthető hibával', () {
    test('üres fájl', () {
      expect(() => parsePmtilesHeader(Uint8List(0)), rejects('túl rövid'));
    });

    test('127 bájtnál rövidebb fájl', () {
      expect(() => parsePmtilesHeader(Uint8List(126)), rejects('túl rövid'));
    });

    test('rossz mágikus szöveg (nem PMTiles)', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(magic: 'NotPMTi')),
        rejects('nem PMTiles'),
      );
    });

    test('szöveges fájl átnevezve .pmtiles-re', () {
      final text = Uint8List.fromList(
        List.generate(300, (i) => 'szoveg '.codeUnitAt(i % 7)),
      );
      expect(() => parsePmtilesHeader(text), rejects('nem PMTiles'));
    });

    test('2-es verzió', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(version: 2)),
        rejects('2-es'),
      );
    });

    test('raszter csempék (png)', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(tileType: 2)),
        rejects('vektoros'),
      );
    });

    test('ismeretlen csempetípus', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(tileType: 0)),
        rejects('vektoros'),
      );
    });

    test('nem csoportosított (unclustered) archívum', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(clustered: 0)),
        rejects('csoportosított'),
      );
    });

    test('brotli belső tömörítés (a pmtiles csomag nem tudja)', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(internalCompression: 3)),
        rejects('tömörítés'),
      );
    });

    test('zstd csempetömörítés', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(tileCompression: 4)),
        rejects('tömörítés'),
      );
    });

    test('ismeretlen tömörítés', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(tileCompression: 0)),
        rejects('tömörítés'),
      );
    });

    test('minimális zoom nagyobb a maximálisnál', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(minZoom: 10, maxZoom: 5)),
        rejects('zoom'),
      );
    });

    test('szélesség a tartományon kívül', () {
      expect(
        () => parsePmtilesHeader(buildPmtilesHeader(maxLatDeg: 95)),
        rejects('határ'),
      );
    });

    test('a minimum nagyobb a maximumnál', () {
      expect(
        () => parsePmtilesHeader(
          buildPmtilesHeader(minLonDeg: 20, maxLonDeg: 19),
        ),
        rejects('határ'),
      );
    });
  });

  test('gzip tömörítés elfogadott (a valódi kivágatok ilyenek)', () {
    final info = parsePmtilesHeader(
      buildPmtilesHeader(internalCompression: 2, tileCompression: 2),
    );
    expect(info.maxZoom, 14);
  });
}
