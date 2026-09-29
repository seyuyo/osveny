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
| `interrupted` levezetése | Csak `recording` státuszú túrára (spec 8. fejezet); `paused` státusz új folyamatban `idle` | Nyitott: a szüneteltetett, majd kilőtt túra így árván marad — érdemes az M2-ben eldönteni |
| Mértékegység-nevek | `hAccM`, `speedMps` a kódban; a CSV-fejléc a specé (`hAcc`, `speed`) | a projekt névkonvenciója |
