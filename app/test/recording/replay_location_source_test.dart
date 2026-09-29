import 'package:flutter_test/flutter_test.dart';
import 'package:geo_core/geo_core.dart';
import 'package:geo_core/testing.dart';
import 'package:osveny/recording/location_source.dart';
import 'package:osveny/recording/track_profile.dart';

void main() {
  const fixes = [
    Fix(tMs: 0, latDeg: 47.5, lonDeg: 19.0, hAccM: 5),
    Fix(tMs: 1000, latDeg: 47.5001, lonDeg: 19.0, altM: 100, hAccM: 4),
    Fix(tMs: 2000, latDeg: 47.5002, lonDeg: 19.0, hAccM: 30),
  ];

  test('minden fixet sorrendben, változtatás nélkül ad, majd lezár', () async {
    final source = ReplayLocationSource(fixes);
    final out = await source.fixes(TrackProfile.precise).toList();
    expect(out, fixes);
  });

  test('a profil nem szűr: visszajátszásnál minden fix megjön', () async {
    final source = ReplayLocationSource(fixes);
    final out = await source.fixes(TrackProfile.batterySaver).toList();
    expect(out.length, fixes.length);
  });

  test('fromCsv a geo_core CSV-formátumát olvassa', () async {
    final source = ReplayLocationSource.fromCsv(fixesToCsv(fixes));
    expect(await source.fixes(TrackProfile.precise).toList(), fixes);
  });

  test('újrafeliratkozás elölről játssza', () async {
    final source = ReplayLocationSource(fixes);
    await source.fixes(TrackProfile.precise).toList();
    expect((await source.fixes(TrackProfile.precise).toList()).length, 3);
  });

  test('a felirat lemondása leállítja a lejátszást', () async {
    final source = ReplayLocationSource(fixes, delay: const Duration(days: 1));
    final received = <Fix>[];
    final sub = source.fixes(TrackProfile.precise).listen(received.add);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(received.length, lessThan(fixes.length));
  });
}
