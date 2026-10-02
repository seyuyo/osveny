import 'package:flutter_test/flutter_test.dart';
import 'package:geo_core/geo_core.dart';
import 'package:latlong2/latlong.dart';
import 'package:osveny/map/track_line.dart';

/// Egyenes kelet felé: a közbülső pontok ritkításkor kiesnek.
Fix eastFix(int i, {double latDeg = 47.7}) =>
    Fix(tMs: i * 1000, latDeg: latDeg, lonDeg: 18.9 + i * 1e-4);

/// Cikcakk: minden pont megmarad (nagy kitérés).
Fix zigzagFix(int i) => Fix(
  tMs: i * 1000,
  latDeg: 47.7 + (i.isEven ? 0 : 0.01),
  lonDeg: 18.9 + i * 1e-3,
);

void main() {
  late List<int> runnerSizes;
  late TrackLineSimplifier simplifier;

  /// Szinkron futtató a teszthez; számolja, hány pontot ritkított.
  Future<List<List<LatLonDeg>>> syncRunner(
    List<List<LatLonDeg>> segments,
    double toleranceM,
  ) async {
    for (final s in segments) {
      runnerSizes.add(s.length);
    }
    return simplifySegments(segments, toleranceM);
  }

  setUp(() {
    runnerSizes = [];
    simplifier = TrackLineSimplifier(rawTailLimit: 10, runner: syncRunner);
  });

  List<int> lengths(List<List<LatLng>> lines) => [
    for (final l in lines) l.length,
  ];

  group('simplifySegments (tiszta függvény)', () {
    test('egyenes: csak a két végpont marad', () {
      final pts = [for (var i = 0; i < 50; i++) eastFix(i)];
      final out = simplifySegments([
        [for (final f in pts) (f.latDeg, f.lonDeg)],
      ], 1);
      expect(out.single.length, 2);
      expect(out.single.first, (pts.first.latDeg, pts.first.lonDeg));
      expect(out.single.last, (pts.last.latDeg, pts.last.lonDeg));
    });

    test('nagy kitérés: minden pont marad', () {
      final pts = [for (var i = 0; i < 20; i++) zigzagFix(i)];
      final out = simplifySegments([
        [for (final f in pts) (f.latDeg, f.lonDeg)],
      ], 1);
      expect(out.single.length, 20);
    });
  });

  test('üres nyomvonal: nincs vonal', () async {
    expect(await simplifier.lines([<Fix>[]], generation: 1, zoomBand: 12), [
      <LatLng>[],
    ]);
  });

  test('első hívás: mindent ritkít', () async {
    final seg = [for (var i = 0; i < 50; i++) eastFix(i)];
    final lines = await simplifier.lines([seg], generation: 1, zoomBand: 14);
    expect(lengths(lines), [2]);
    expect(runnerSizes, [50]);
  });

  test('kis bővülés: nincs újraritkítás, a nyers vég hozzáfűződik', () async {
    final seg = [for (var i = 0; i < 50; i++) eastFix(i)];
    await simplifier.lines([seg], generation: 1, zoomBand: 14);
    runnerSizes.clear();

    final grown = [...seg, for (var i = 50; i < 55; i++) eastFix(i)];
    final lines = await simplifier.lines([grown], generation: 1, zoomBand: 14);

    expect(runnerSizes, isEmpty);
    expect(lengths(lines), [2 + 5], reason: '2 ritkított + 5 nyers pont');
    expect(lines.single.last, LatLng(grown.last.latDeg, grown.last.lonDeg));
  });

  test('a nyers vég a határ felett újraritkít', () async {
    final seg = [for (var i = 0; i < 50; i++) eastFix(i)];
    await simplifier.lines([seg], generation: 1, zoomBand: 14);
    runnerSizes.clear();

    final grown = [...seg, for (var i = 50; i < 61; i++) eastFix(i)];
    final lines = await simplifier.lines([grown], generation: 1, zoomBand: 14);

    expect(runnerSizes, [61]);
    expect(lengths(lines), [2]);
  });

  test('zoomsáv-váltás: mindent újraritkít', () async {
    final seg = [for (var i = 0; i < 50; i++) eastFix(i)];
    await simplifier.lines([seg], generation: 1, zoomBand: 14);
    runnerSizes.clear();

    await simplifier.lines([seg], generation: 1, zoomBand: 10);
    expect(runnerSizes, [50]);
  });

  test('ugyanaz a zoomsáv és változatlan pontok: nincs munka', () async {
    final seg = [for (var i = 0; i < 50; i++) eastFix(i)];
    await simplifier.lines([seg], generation: 1, zoomBand: 14);
    runnerSizes.clear();

    await simplifier.lines([seg], generation: 1, zoomBand: 14);
    expect(runnerSizes, isEmpty);
  });

  test('új generáció (új túra / feltöltés): mindent újraritkít', () async {
    final seg = [for (var i = 0; i < 50; i++) eastFix(i)];
    await simplifier.lines([seg], generation: 1, zoomBand: 14);
    runnerSizes.clear();

    final other = [for (var i = 0; i < 30; i++) eastFix(i, latDeg: 47.6)];
    final lines = await simplifier.lines([other], generation: 2, zoomBand: 14);
    expect(runnerSizes, [30]);
    expect(lines.single.first.latitude, 47.6);
  });

  test('új szegmens: az előző lezárul, a vonalak külön maradnak', () async {
    final a = [for (var i = 0; i < 50; i++) eastFix(i)];
    await simplifier.lines([a], generation: 1, zoomBand: 14);
    runnerSizes.clear();

    final b = [for (var i = 100; i < 103; i++) eastFix(i)];
    final lines = await simplifier.lines([a, b], generation: 1, zoomBand: 14);

    expect(lengths(lines), [2, 3], reason: 'két külön vonal, nincs összekötve');
    expect(runnerSizes, isEmpty, reason: 'a lezárt szegmens már ritkított');
  });

  test('lezárt szegmens nyers vége lezáráskor beritkul', () async {
    final a = [for (var i = 0; i < 50; i++) eastFix(i)];
    await simplifier.lines([a], generation: 1, zoomBand: 14);
    final aGrown = [...a, for (var i = 50; i < 55; i++) eastFix(i)];
    await simplifier.lines([aGrown], generation: 1, zoomBand: 14);
    runnerSizes.clear();

    final lines = await simplifier.lines(
      [aGrown, <Fix>[]],
      generation: 1,
      zoomBand: 14,
    );
    expect(runnerSizes, [55]);
    expect(lengths(lines), [2, 0]);
  });

  test('a tűrés zoomszinttől függ: kisebb zoomon kevesebb pont', () async {
    final seg = [
      for (var i = 0; i < 200; i++)
        Fix(
          tMs: i * 1000,
          latDeg: 47.7 + 0.0002 * ((i % 7) - 3),
          lonDeg: 18.9 + i * 1e-4,
        ),
    ];
    final near = await TrackLineSimplifier(
      runner: syncRunner,
    ).lines([seg], generation: 1, zoomBand: 17);
    final far = await TrackLineSimplifier(
      runner: syncRunner,
    ).lines([seg], generation: 1, zoomBand: 9);
    expect(far.single.length, lessThan(near.single.length));
  });

  test('alapból isolate-ben fut, ugyanazzal az eredménnyel', () async {
    final seg = [for (var i = 0; i < 50; i++) eastFix(i)];
    // A futtató az alapértelmezett (isolate); a határ kicsi, hogy ritkítson.
    final lines = await TrackLineSimplifier(
      rawTailLimit: 10,
    ).lines([seg], generation: 1, zoomBand: 14);
    expect(lengths(lines), [2]);
  });
}
