# Ösvény

Offline túrarögzítő Androidra, Flutterben. GPS-nyomvonalat rögzít internet
nélkül, és a felvétel akkor is megmarad, ha lekapcsol a képernyő, háttérbe kerül
az app, vagy a rendszer kilövi.

Két részből áll: a Flutter appból (`app/`) és egy tiszta Dart csomagból
(`packages/geo_core`), ami a nyomvonal szűrését és a statisztikákat számolja.
Tanulási projektnek indult, főleg a zajos GPS-adat szűrése és az összeomlás
után is megmaradó rögzítés érdekelt.

> Még fejlesztés alatt van. A rögzítés működik, az offline térkép nagyrészt kész,
> a GPX és a statisztika képernyő még hiányzik.

## Mit tud most

- GPS-rögzítés előtér-szolgáltatással („Rögzítés folyamatban" értesítéssel), így
  zsebben, lezárt képernyővel is megy
- két profil: *Pontos* (1–2 mp) és *Akkukímélő* (5 mp, 5 m)
- szünet, folytatás, befejezés; a szünetek külön szegmensek
- ha az app megszakad, újraindításkor felajánlja a folytatást vagy a lezárást
- offline vektoros térkép saját PMTiles fájlból, világos és sötét témával
- élő nyomvonal és pozíció a térképen, követő móddal; a rögzítés a térképről is
  indítható
- debug képernyő a nyers mérésekkel és CSV-exporttal

## Tervben

- GPX import (pl. egy Kéktúra-szakasz) és figyelmeztetés, ha letérsz róla
- statisztika: táv, szintemelkedés, mozgásidő, magassági profil
- GPX export, túralista

## Hogyan működik

A legfontosabb szabály, amit az elején eldöntöttem: **a nyers GPS-méréseket
mentem el**, minden mást (szűrés, táv, szintemelkedés) ezekből számolok. Így ha
később átállítom a szűrőket, a régi túrák is újraszámolhatók, és a szűrőket
felvett nyomvonalak visszajátszásával tudom tesztelni telefon nélkül.

A mérések legfeljebb 5 másodpercig vannak csak memóriában, utána SQLite-ba
(drift) kerülnek. A rögzítés állapota is az adatbázisban van, ebből tudja az app
induláskor, hogy volt-e félbemaradt túra.

A `geo_core` szűrői:

| Lépés | Szabály |
|---|---|
| Pontosság | ha `hAcc > 25 m`, eldobja |
| Ugrás | 15 m/s feletti sebesség két pont között → eldobja |
| Ritkítás | új pont csak ≥ 3 m vagy ≥ 30 s után |
| Állás | 0,3 m/s alatt 60 s-nál tovább nem számít mozgásidőnek |
| Szintemelkedés | csak az utolsó szélsőértéktől mért ≥ 5 m számít |

A szintemelkedésnél azért kell ez a küszöb, mert a GPS magasság nagyon zajos.
Ha minden kis fel-le mozgást összeadnék, egy sík sétán is több száz méter
emelkedés jönne ki.

```
packages/geo_core/   geometria, szűrők, statisztika, letérés-érzékelő,
                     rögzítési állapotgép, teszt nyomvonalak
app/lib/
  data/              drift adatbázis
  permissions/       engedélykérés
  recording/         helyforrás (GPS vagy CSV-visszajátszás), RecordingController
  map/               offline térkép, élő nyomvonal
  features/debug/    debug képernyő
```

A helyforrás egy interfész mögött van, ezért a rögzítés CSV-ből visszajátszva is
tesztelhető, így fut például egy 30 perces séta integrációs tesztje.

A döntéseket és az okukat a [docs/DECISIONS.md](docs/DECISIONS.md)-be írtam.

## Futtatás

Flutter 3.38 (Dart 3.10) és egy Android eszköz vagy emulátor kell.

```bash
cd packages/geo_core
dart pub get
dart test

cd ../../app
flutter pub get
flutter test
flutter run
```

A drift generált fájljai be vannak commitolva. Ha módosítod az adatbázist:

```bash
cd app
dart run build_runner build --force-jit
```

Térképhez egy PMTiles fájl kell, ezt az appban lehet importálni. Én a
[Protomaps](https://protomaps.com) napi buildjéből vágtam ki Magyarországot:

```bash
pmtiles extract <protomaps build URL> hungary.pmtiles --bbox=16.11,45.74,22.90,48.59 --maxzoom=15
```

 Emulátoron az *Extended
controls → Location* alatt GPX-et lehet visszajátszani, így asztalnál is ki lehet
próbálni a rögzítést.

## Adatvédelem

Az app nem küld és nem tölt le semmit, nincs fiók és nincs analitika, a túrák
csak a telefonon vannak. Háttér-helyengedélyt nem kér, az előtér-szolgáltatás
elég. Google Play Services sem kell hozzá.

## Ismert korlátok

- egyelőre csak Android
- útvonaltervezés nincs
- a Protomaps térképen látszanak az ösvények, de turistajelzés és szintvonal
  nincs rajta

## Licenc

[MIT](LICENSE)
