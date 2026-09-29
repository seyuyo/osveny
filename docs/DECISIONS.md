# Döntésnapló

| Döntés | Választás | Alternatíva | Indok |
|---|---|---|---|
| Helymeghatározás | `geolocator` előtér-szolgáltatással | `flutter_background_geolocation` | Ingyenes; az alternatíva Androidon kiadáshoz fizetős licencet kér |
| Térkép | `flutter_map` + PMTiles | `maplibre_gl` offline régiók | Tisztán Flutter-oldali renderelés; egyetlen hordozható fájl |
| Csempe-gyorsítótár | nincs, saját PMTiles-fájl | `flutter_map_tile_caching` | Az alternatíva GPL-licencű, és a csempeszerverek irányelveibe ütközhet |
| Tárolás | drift | sqflite, isar | Típusos lekérdezések, migrációk, háttér-isolate beépítve |
| Mit tárolunk | nyers fixeket | szűrt pontokat | Újraszámolható, újrahangolható, visszajátszással tesztelhető |
| Háttér-engedély | nem kérünk | `ACCESS_BACKGROUND_LOCATION` | Előtérből indított előtér-szolgáltatás mellett nem kell |
| Állapotkezelés | Riverpod, kódgenerálás nélkül | Provider | Tanulási cél |

## Javasolt eltérések és pontosítások (M0–M1)

| Téma | Javaslat | Indok |
|---|---|---|
| Flutter-import tiltása `geo_core`-ban | Fájl-alapú teszt (`test/no_flutter_import_test.dart`) lint plugin helyett | Nincs extra függőség, stabil, egyszerű |
| `lib/testing.dart` | Külön belépő a CSV-parszernek és generátoroknak | Az app tesztjei és a `ReplayLocationSource` is használja; a `lib` I/O-mentes marad |
| Állásérzékelés sebességforrása | Az eszköz által mért `speed` előnyben, hiányában implikált sebesség | A helyzetzaj álló telefonnál implikált sebességként mozgásnak látszik; a 10 perces pontfelhő <20 m kritérium csak így teljesül |
| Táv álló szakaszban | Lassú (<0,3 m/s) szakaszon a táv nem nő | Ugyanaz: a zaj ne halmozódjon távvá |
| `interrupted` levezetése | `recording` **és `paused`** státuszú túrára, új folyamatban (M2-ben eldöntve; a spec 8. fejezete csak a `recording`-ot említi). Új átmenet: `paused --foundUnfinished--> interrupted` | A szüneteltetett, majd kilőtt túra különben árván maradna: a lista nem ajánlaná fel, új túra indítása pedig örökre nyitva hagyná. A folytatás/lezárás választása ugyanaz, mint `recording`-nál |
| M2 függőségek: drift | `drift` és `drift_dev` `>=2.23.0 <2.32.0`, `sqlite3_flutter_libs ^0.5.0` + `path_provider`; `drift_flutter` nincs | `drift ≥2.35` / `drift_flutter ≥0.3` `sqlite3 ^3`-at, a `drift_dev` pedig `analyzer`-t húz, ami `meta ^1.18`-at kér; a jelenlegi Flutter SDK `meta 1.17`-re pinnel, így nem oldható fel. A `sqlite3_flutter_libs 0.6.0+eol` már üres csomag: `sqlite3 2.x` mellett a `0.5.x` kell a natív SQLite-hoz. Flutter SDK frissítésekor újra kell értékelni (`sqlite3 3.x`, `drift_flutter`) |
| Android-build: `permission_handler` | `^12.0.1` (`permission_handler_android 13.x`), nem a 13.x/14.x | A `permission_handler_android 14.1.0` build-szkriptje AGP 9-re készült (`kotlin {}` blokk Kotlin-plugin nélkül), az app viszont AGP 8.11.1 + Kotlin 2.2.20: `flutter build apk` elbukik. Az AGP 9-re váltás a projekt egészét érintené; az újraértékelés a Flutter SDK frissítésekor esedékes |
| Android-build: `sqlite3_flutter_libs` | `^0.5.0`, lockfájlban `0.5.42` | A `0.5.0` még nem ad meg `namespace`-t, AGP 8-cal nem konfigurálható; a `0.5.x` későbbi kiadásai igen |
| Kódgenerálás parancsa | `dart run build_runner build --force-jit`; a generált `*.g.dart` be van commitolva | Az AOT build-script nem fordul (`'dart compile' does not support build hooks`), a `--delete-conflicting-outputs` kapcsolót az új `build_runner` eltávolította. A commitolt kimenettel a CI-nek nem kell generálnia |
| M2 függőségek: egyéb | `flutter_riverpod`, `geolocator`, `permission_handler`, `path_provider`, `share_plus`, dev: `build_runner` | Riverpod: állapotkezelés (fent); `geolocator`: helyforrás; `permission_handler`: értesítés-engedély; `share_plus`: nyers CSV-export megosztása |
| Mértékegység-nevek | `hAccM`, `speedMps` a kódban; a CSV-fejléc a specé (`hAcc`, `speed`) | a projekt névkonvenciója |
