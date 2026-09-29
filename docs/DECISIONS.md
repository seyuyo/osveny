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
