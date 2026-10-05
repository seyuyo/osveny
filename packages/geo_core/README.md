# geo_core

Tiszta Dart csomag (Flutter és I/O nélkül) az Ösvény nyomvonal-feldolgozásához:

- távolság (haversine), pont–töröttvonal távolság, Douglas–Peucker ritkítás
- szűrőlánc a zajos GPS-mérésekhez
- statisztika: táv, mozgásidő, szintemelkedés hiszterézissel
- letérés-érzékelő (50 m-nél jelez, 30 m-en belül old)
- a rögzítés állapotgépe

A `package:geo_core/testing.dart` CSV-visszajátszót és szintetikus nyomvonal-generátorokat ad a tesztekhez.

```sh
dart pub get
dart test
```
