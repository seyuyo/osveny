import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_core/geo_core.dart';
import 'package:osveny/data/database.dart';
import 'package:osveny/recording/track_profile.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Fix fix(int tMs, {double? alt}) => Fix(
    tMs: tMs,
    latDeg: 47.5 + tMs * 1e-6,
    lonDeg: 19.0,
    altM: alt,
    hAccM: 4.5,
    vAccM: alt == null ? null : 8,
    speedMps: 1.3,
    bearingDeg: 90,
  );

  test('schemaVersion 1', () {
    expect(db.schemaVersion, 1);
  });

  test('createTrack: recording státusz, profil és kezdés tárolva', () async {
    final id = await db.createTrack(
      name: 'Teszt',
      profile: TrackProfile.precise,
      startedAtMs: 1000,
    );
    final t = (await db.latestTrack())!;
    expect(t.id, id);
    expect(t.status, TrackStatus.recording);
    expect(t.profile, TrackProfile.precise);
    expect(t.startedAtMs, 1000);
    expect(t.endedAtMs, isNull);
    expect(t.statsJson, isNull);
  });

  test('latestTrack: üres DB-ben null, egyébként a legutóbbi', () async {
    expect(await db.latestTrack(), isNull);
    await db.createTrack(
      name: 'A',
      profile: TrackProfile.precise,
      startedAtMs: 1,
    );
    final b = await db.createTrack(
      name: 'B',
      profile: TrackProfile.batterySaver,
      startedAtMs: 2,
    );
    expect((await db.latestTrack())!.id, b);
  });

  test(
    'insertFixBatch + fixesFor: nyers fix kerek-kerülés nélkül, rendezve',
    () async {
      final id = await db.createTrack(
        name: 'T',
        profile: TrackProfile.precise,
        startedAtMs: 0,
      );
      final input = [fix(3000, alt: 120.5), fix(1000), fix(2000, alt: 121)];
      await db.insertFixBatch(id, input);

      final out = await db.fixesFor(id);
      expect(out.map((f) => f.tMs), [1000, 2000, 3000]);
      expect(out[2], input[0]);
      expect(out[0], input[1]);
    },
  );

  test('fixesFor: csak a saját túra fixei', () async {
    final a = await db.createTrack(
      name: 'A',
      profile: TrackProfile.precise,
      startedAtMs: 0,
    );
    final b = await db.createTrack(
      name: 'B',
      profile: TrackProfile.precise,
      startedAtMs: 0,
    );
    await db.insertFixBatch(a, [fix(1)]);
    await db.insertFixBatch(b, [fix(2), fix(3)]);
    expect((await db.fixesFor(a)).length, 1);
    expect((await db.fixesFor(b)).length, 2);
  });

  test('insertFixBatch: üres köteg nem hiba', () async {
    final id = await db.createTrack(
      name: 'T',
      profile: TrackProfile.precise,
      startedAtMs: 0,
    );
    await db.insertFixBatch(id, const []);
    expect(await db.fixesFor(id), isEmpty);
  });

  test('setStatus: lezáráskor endedAtMs és statsJson', () async {
    final id = await db.createTrack(
      name: 'T',
      profile: TrackProfile.precise,
      startedAtMs: 0,
    );
    await db.setStatus(id, TrackStatus.paused);
    expect((await db.latestTrack())!.status, TrackStatus.paused);

    await db.setStatus(
      id,
      TrackStatus.finished,
      endedAtMs: 5000,
      statsJson: '{"distanceM":12.5}',
    );
    final t = (await db.latestTrack())!;
    expect(t.status, TrackStatus.finished);
    expect(t.endedAtMs, 5000);
    expect(t.statsJson, '{"distanceM":12.5}');
  });

  test('szegmensek: nyitás, zárás, csak a nyitottat zárja', () async {
    final id = await db.createTrack(
      name: 'T',
      profile: TrackProfile.precise,
      startedAtMs: 0,
    );
    await db.openSegment(id, 0);
    await db.closeOpenSegment(id, 1000);
    await db.openSegment(id, 2000);

    var segs = await db.segmentsFor(id);
    expect(segs.length, 2);
    expect(segs[0].startTMs, 0);
    expect(segs[0].endTMs, 1000);
    expect(segs[1].startTMs, 2000);
    expect(segs[1].endTMs, isNull);

    await db.closeOpenSegment(id, 3000);
    segs = await db.segmentsFor(id);
    expect(segs[0].endTMs, 1000, reason: 'a lezárt szegmens nem íródik felül');
    expect(segs[1].endTMs, 3000);
  });
}
