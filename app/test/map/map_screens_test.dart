import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/map/map_file_picker.dart';
import 'package:osveny/map/map_library_controller.dart';
import 'package:osveny/map/map_library_screen.dart';
import 'package:osveny/map/map_screen.dart';
import 'package:osveny/map/map_store.dart';
import 'package:osveny/map/offline_map.dart';
import 'package:osveny/map/tile_source.dart';

import 'map_test_helpers.dart';
import 'pmtiles_fixture.dart';

void main() {
  late Directory tmp;
  late MapStore store;
  late FakePicker picker;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('osveny_screens_test_');
    store = MapStore(Directory('${tmp.path}${Platform.pathSeparator}maps'));
    picker = FakePicker();
  });
  tearDown(() async {
    await Future<void>.delayed(const Duration(milliseconds: 30));
    tmp.deleteSync(recursive: true);
  });

  Future<ProviderContainer> pump(WidgetTester tester, Widget home) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapStoreProvider.overrideWithValue(store),
          mapFilePickerProvider.overrideWithValue(picker),
          tileSourceOpenerProvider.overrideWithValue(fakeTileSourceOpener),
        ],
        child: MaterialApp(home: home),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    return container;
  }

  /// A fájlműveletek valódi időben futnak (`runAsync`), a widgetfa időzítői
  /// (pl. egy lassú forrás `Future.delayed`-je) viszont a teszt hamis órájában:
  /// ezért a `pump` is léptet. Kis lépésekben várunk, amíg az [until] igaz
  /// nem lesz (legfeljebb ~5 s).
  Future<void> settle(WidgetTester tester, bool Function() until) async {
    for (var i = 0; i < 100; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      if (until()) return;
    }
    fail('a várt állapot nem állt be');
  }

  /// A ector_map_tiles réteg initState-je 3 másodperces Future.delayed-et
  /// indít, amit a dispose nem állít le: a fa lebontása után léptetjük az
  /// órát, különben a teszt függő időzítő miatt elbukna.
  Future<void> drainMapTimers(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
  }

  bool shows(String text) => find.text(text).evaluate().isNotEmpty;
  bool showsMap() => find.byType(OfflineMap).evaluate().isNotEmpty;

  bool showsText(String part) =>
      find.textContaining(part).evaluate().isNotEmpty;

  Future<void> installed(
    WidgetTester tester,
    String name, {
    int maxZoom = 14,
  }) => tester.runAsync(
    () => store.import(sourceOf(name, buildPmtilesArchive(maxZoom: maxZoom))),
  );

  group('Térkép fül', () {
    testWidgets('betöltés alatt töltésjelző, a kulcs a térkép fülé', (
      tester,
    ) async {
      await pump(tester, const MapScreen());
      expect(find.byKey(const Key('map-tab')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await settle(tester, () => shows('Még nincs térkép'));
    });

    testWidgets('térkép nélkül: üres állapot magyarázattal és gombbal', (
      tester,
    ) async {
      await pump(tester, const MapScreen());
      await settle(tester, () => shows('Még nincs térkép'));

      expect(find.textContaining('.pmtiles'), findsWidgets);
      expect(find.text('Térkép importálása'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'a gomb a kiválasztót nyitja, siker után az aktív térkép látszik',
      (tester) async {
        picker.next = sourceOf('pilis.pmtiles', buildPmtilesArchive());
        await pump(tester, const MapScreen());
        await settle(tester, () => shows('Még nincs térkép'));

        await tester.tap(find.text('Térkép importálása'));
        await settle(tester, () => showsMap());

        expect(picker.calls, 1);
        expect(find.text('Még nincs térkép'), findsNothing);
        expect(find.byTooltip('Térképek kezelése'), findsOneWidget);
        await drainMapTimers(tester);
      },
    );

    testWidgets('érvénytelen fájl: érthető hiba, az üres állapot marad', (
      tester,
    ) async {
      picker.next = sourceOf('jegyzet.txt', buildPmtilesArchive());
      await pump(tester, const MapScreen());
      await settle(tester, () => shows('Még nincs térkép'));

      await tester.tap(find.text('Térkép importálása'));
      await settle(tester, () => showsText('kiterjesztése'));

      expect(find.text('Még nincs térkép'), findsOneWidget);
    });

    testWidgets('a hibaüzenet elhallgattatható', (tester) async {
      picker.next = sourceOf('jegyzet.txt', buildPmtilesArchive());
      await pump(tester, const MapScreen());
      await settle(tester, () => shows('Még nincs térkép'));
      await tester.tap(find.text('Térkép importálása'));
      await settle(tester, () => showsText('kiterjesztése'));

      await tester.tap(find.byTooltip('Üzenet elrejtése'));
      await tester.pump();
      expect(showsText('kiterjesztése'), isFalse);
    });

    testWidgets('import közben folyamatjelző a másolt aránnyal', (
      tester,
    ) async {
      final bytes = buildPmtilesArchive();
      // Lassú forrás, hogy a folyamat közbülső állapota látszódjon.
      picker.next = ImportSource(
        name: 'lassu.pmtiles',
        length: bytes.length,
        open: () async* {
          for (var i = 0; i < bytes.length; i += 30) {
            await Future<void>.delayed(const Duration(milliseconds: 60));
            yield bytes.sublist(
              i,
              i + 30 > bytes.length ? bytes.length : i + 30,
            );
          }
        },
      );
      await pump(tester, const MapScreen());
      await settle(tester, () => shows('Még nincs térkép'));

      await tester.tap(find.text('Térkép importálása'));
      await settle(
        tester,
        () => find.byType(LinearProgressIndicator).evaluate().isNotEmpty,
      );

      final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(bar.value, anyOf(isNull, inInclusiveRange(0.0, 1.0)));
      expect(showsText('Importálás'), isTrue);

      await settle(tester, () => showsMap());
      await drainMapTimers(tester);
    });

    testWidgets('telepített térképnél a kezelőoldalra visz', (tester) async {
      await installed(tester, 'a.pmtiles');
      await pump(tester, const MapScreen());
      await settle(tester, () => showsMap());

      await tester.tap(find.byTooltip('Térképek kezelése'));
      await tester.pumpAndSettle();
      expect(find.byType(MapLibraryScreen), findsOneWidget);
      await drainMapTimers(tester);
    });
  });

  group('Térképek kezelése', () {
    testWidgets('lista: név, méret, zoomtartomány, az aktív jelölve', (
      tester,
    ) async {
      await installed(tester, 'a.pmtiles');
      await installed(tester, 'b.pmtiles', maxZoom: 12);
      await pump(tester, const MapLibraryScreen());
      await settle(tester, () => shows('b.pmtiles'));

      expect(find.text('a.pmtiles'), findsOneWidget);
      expect(find.textContaining('zoom 0–12'), findsOneWidget);
      expect(find.textContaining('zoom 0–14'), findsOneWidget);
      // Az aktív (az utoljára importált) pipával jelölt.
      final activeTile = find.ancestor(
        of: find.text('b.pmtiles'),
        matching: find.byType(ListTile),
      );
      expect(
        find.descendant(
          of: activeTile,
          matching: find.byIcon(Icons.check_circle),
        ),
        findsOneWidget,
      );
    });

    testWidgets('üres lista: tájékoztatás és importgomb', (tester) async {
      await pump(tester, const MapLibraryScreen());
      await settle(tester, () => shows('Még nincs térkép'));
      expect(find.text('Térkép importálása'), findsOneWidget);
    });

    testWidgets('másik térképre koppintva az lesz az aktív', (tester) async {
      await installed(tester, 'a.pmtiles');
      await installed(tester, 'b.pmtiles');
      final container = await pump(tester, const MapLibraryScreen());
      await settle(tester, () => shows('a.pmtiles'));

      await tester.tap(find.text('a.pmtiles'));
      await settle(
        tester,
        () =>
            container.read(mapLibraryControllerProvider).active?.name ==
            'a.pmtiles',
      );
    });

    testWidgets('törlés: megerősítés nélkül nem töröl, megerősítve igen', (
      tester,
    ) async {
      await installed(tester, 'a.pmtiles');
      await pump(tester, const MapLibraryScreen());
      await settle(tester, () => shows('a.pmtiles'));

      await tester.tap(find.byTooltip('Törlés'));
      await tester.pumpAndSettle();
      expect(find.text('Törlöd a térképet?'), findsOneWidget);

      await tester.tap(find.text('Mégse'));
      await tester.pumpAndSettle();
      expect(shows('a.pmtiles'), isTrue);
      expect(
        (await tester.runAsync(store.list))!.length,
        1,
        reason: 'a „Mégse" nem töröl',
      );

      await tester.tap(find.byTooltip('Törlés'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Törlés'));
      await settle(tester, () => shows('Még nincs térkép'));
      expect((await tester.runAsync(store.list))!, isEmpty);
    });

    testWidgets('az importgomb itt is működik', (tester) async {
      picker.next = sourceOf('uj.pmtiles', buildPmtilesArchive());
      await pump(tester, const MapLibraryScreen());
      await settle(tester, () => shows('Még nincs térkép'));

      await tester.tap(find.text('Térkép importálása'));
      await settle(tester, () => shows('uj.pmtiles'));
    });
  });
}
