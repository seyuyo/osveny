// M2 „Kész, ha" feltétel: egy 30 perces CSV végigjátszása után a DB pontosan
// a várt sorokat tartalmazza.
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_core/geo_core.dart';
import 'package:geo_core/testing.dart';
import 'package:osveny/data/database.dart';
import 'package:osveny/recording/location_source.dart';
import 'package:osveny/recording/recording_controller.dart';
import 'package:osveny/recording/track_profile.dart';

const _tracePath = '../packages/geo_core/test/traces/walk_30min.csv';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late List<Fix> trace;
  late AppDatabase db;
  var nowMs = 0;

  setUpAll(() => trace = parseFixCsv(File(_tracePath).readAsStringSync()));
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    nowMs = trace.first.tMs;
  });
  tearDown(() => db.close());

  /// Új „folyamat": friss container, a DB ugyanaz.
  ProviderContainer process(List<Fix> playback) {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        locationSourceProvider.overrideWithValue(
          ReplayLocationSource(playback),
        ),
        clockProvider.overrideWithValue(() => nowMs),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  RecordingController controllerOf(ProviderContainer c) =>
      c.read(recordingControllerProvider.notifier);

  test('a fixture 30 perces és a szűrő is dolgozik rajta', () {
    expect(trace.last.tMs - trace.first.tMs, 1800000);
    final run = runFilter(trace);
    expect(run.dropCounts[DropReason.jump], greaterThan(0));
    expect(run.state.distanceM, greaterThan(1000));
  });

  test('végigjátszás: a DB pontosan a CSV sorait tartalmazza', () async {
    final c = process(trace);
    final ctrl = controllerOf(c);

    await ctrl.start(profile: TrackProfile.precise);
    await ctrl.sourceDone;
    nowMs = trace.last.tMs + 1000;
    await ctrl.finish();

    final track = (await db.latestTrack())!;
    expect(await db.select(db.tracks).get(), hasLength(1));
    expect(track.status, TrackStatus.finished);
    expect(track.endedAtMs, trace.last.tMs + 1000);

    // Nyersen, szűretlenül, sorrendben, bitre pontosan.
    final stored = await db.fixesFor(track.id);
    expect(stored.length, trace.length);
    expect(stored, trace);

    final segments = await db.segmentsFor(track.id);
    expect(segments, hasLength(1));
    expect(segments.single.startTMs, trace.first.tMs);
    expect(segments.single.endTMs, trace.last.tMs + 1000);

    // A statsJson csak gyorsítótár: a nyers sorokból pontosan újraszámolható.
    final cached = jsonDecode(track.statsJson!) as Map<String, Object?>;
    expect(cached, computeStats(stored).toJson());
  });

  test('kilövés a séta közben: legfeljebb egy köteg vész el, a folytatás '
      'a szegmenseket helyesen kezeli', () async {
    // Az első folyamat 1005 fixet kap: 100 köteg kiíródik, 5 még memóriában.
    const beforeKill = 1005;
    const stored = 1000;
    final first = process(trace.sublist(0, beforeKill));
    final ctrl1 = controllerOf(first);
    await ctrl1.start(profile: TrackProfile.precise);
    await ctrl1.sourceDone;
    await Future<void>.delayed(Duration.zero);
    await ctrl1.settle();
    final trackId = first.read(recordingControllerProvider).trackId!;
    expect(first.read(recordingControllerProvider).pendingCount, 5);
    first.dispose(); // a folyamat kilövése

    expect(await db.fixesFor(trackId), trace.sublist(0, stored));
    expect(
      (await db.latestTrack())!.status,
      TrackStatus.recording,
      reason: 'a kilőtt folyamat nem zárta le a túrát',
    );

    // Új folyamat: felajánlja a folytatást.
    final resumeAt = trace[1200].tMs;
    final second = process(trace.sublist(1200));
    final ctrl2 = controllerOf(second);
    await ctrl2.restore();
    expect(
      second.read(recordingControllerProvider).recState,
      RecState.interrupted,
    );
    expect(second.read(recordingControllerProvider).trackId, trackId);

    nowMs = resumeAt;
    await ctrl2.resume();
    await ctrl2.sourceDone;
    nowMs = trace.last.tMs + 1000;
    await ctrl2.finish();

    // A kilövéskor csak a memóriában lévő 5 fix veszett el, a kihagyott
    // szakasz (kilövés és folytatás között) pedig nem volt rögzítve.
    expect(await db.fixesFor(trackId), [
      ...trace.sublist(0, stored),
      ...trace.sublist(1200),
    ]);

    final segments = await db.segmentsFor(trackId);
    expect(segments, hasLength(2));
    expect(
      segments[0].endTMs,
      trace[stored - 1].tMs,
      reason: 'a megszakadt szegmens az utolsó tárolt fixnél záródik',
    );
    expect(segments[1].startTMs, resumeAt);
    expect(segments[1].endTMs, trace.last.tMs + 1000);
    expect((await db.latestTrack())!.status, TrackStatus.finished);
  });
}
