import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geo_core/geo_core.dart';
import 'package:osveny/data/database.dart';
import 'package:osveny/recording/location_source.dart';
import 'package:osveny/recording/recording_controller.dart';
import 'package:osveny/recording/track_profile.dart';

/// Kézzel vezérelhető forrás. Broadcast, mint a valódi GPS: minden
/// feliratkozás új folyamot kap, és ami hallgató nélkül jön, az elvész.
class FakeSource implements LocationSource {
  final controller = StreamController<Fix>.broadcast();
  TrackProfile? lastProfile;

  @override
  Stream<Fix> fixes(TrackProfile profile) {
    lastProfile = profile;
    return controller.stream;
  }
}

/// Írási hibát tud szimulálni.
class FlakyDb extends AppDatabase {
  FlakyDb(super.e);
  bool failWrites = false;

  @override
  Future<void> insertFixBatch(int trackId, List<Fix> batch) {
    if (failWrites) return Future.error(StateError('lemez tele'));
    return super.insertFixBatch(trackId, batch);
  }
}

Fix fix(int tMs, {double hAccM = 5, double? alt}) => Fix(
  tMs: tMs,
  latDeg: 47.5 + tMs * 1e-7,
  lonDeg: 19.0,
  altM: alt,
  hAccM: hAccM,
);

void main() {
  late FlakyDb db;
  late FakeSource source;
  late int nowMs;
  late ProviderContainer container;
  final made = <ProviderContainer>[];
  final disposed = <ProviderContainer>{};

  ProviderContainer makeContainer({
    BatchConfig batch = const BatchConfig(
      maxAge: Duration(minutes: 10),
      maxCount: 10,
    ),
  }) {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        locationSourceProvider.overrideWithValue(source),
        clockProvider.overrideWithValue(() => nowMs),
        batchConfigProvider.overrideWithValue(batch),
      ],
    );
    made.add(c);
    return c;
  }

  /// A folyamat kilövése: a container megszűnik, a DB marad.
  void kill() {
    if (disposed.add(container)) container.dispose();
  }

  RecordingController ctrl() =>
      container.read(recordingControllerProvider.notifier);
  RecordingSnapshot snap() => container.read(recordingControllerProvider);

  Future<void> feed(Iterable<Fix> fixes) async {
    for (final f in fixes) {
      source.controller.add(f);
    }
    await pumpEventQueue();
    await ctrl().settle();
  }

  setUp(() {
    db = FlakyDb(NativeDatabase.memory());
    source = FakeSource();
    nowMs = 1000000;
    container = makeContainer();
  });

  tearDown(() async {
    for (final c in made) {
      if (disposed.add(c)) c.dispose();
    }
    made.clear();
    disposed.clear();
    await source.controller.close();
    await db.close();
  });

  group('start', () {
    test('track + nyitott szegmens a DB-ben, állapot recording', () async {
      await ctrl().start(profile: TrackProfile.batterySaver);

      expect(snap().recState, RecState.recording);
      final t = (await db.latestTrack())!;
      expect(t.id, snap().trackId);
      expect(t.status, TrackStatus.recording);
      expect(t.profile, TrackProfile.batterySaver);
      expect(t.startedAtMs, 1000000);
      final segs = await db.segmentsFor(t.id);
      expect(segs.single.startTMs, 1000000);
      expect(segs.single.endTMs, isNull);
      expect(source.lastProfile, TrackProfile.batterySaver);
    });

    test(
      'kétszer indítva érvénytelen átmenet, nem lesz második túra',
      () async {
        await ctrl().start(profile: TrackProfile.precise);
        await expectLater(
          ctrl().start(profile: TrackProfile.precise),
          throwsA(isA<InvalidTransitionError>()),
        );
        expect(await db.select(db.tracks).get(), hasLength(1));
      },
    );

    test('pause üres állapotban érvénytelen', () async {
      await expectLater(ctrl().pause(), throwsA(isA<InvalidTransitionError>()));
    });
  });

  group('kötegelt írás', () {
    test('10 pontnál ír; a maradék csak memóriában van', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([for (var i = 0; i < 25; i++) fix(i * 1000)]);

      final id = snap().trackId!;
      expect((await db.fixesFor(id)).length, 20);
      expect(snap().pendingCount, 5);
    });

    test('a kor is köteget zár: maxAge után kiíródik', () async {
      container = makeContainer(
        batch: const BatchConfig(
          maxAge: Duration(milliseconds: 50),
          maxCount: 1000,
        ),
      );
      await ctrl().start(profile: TrackProfile.precise);
      await feed([fix(0), fix(1000), fix(2000)]);
      expect(snap().pendingCount, 3);

      await Future<void>.delayed(const Duration(milliseconds: 200));
      await ctrl().settle();

      expect((await db.fixesFor(snap().trackId!)).length, 3);
      expect(snap().pendingCount, 0);
    });

    test('a nyers fix a szűrőtől függetlenül bekerül a DB-be', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([fix(0), fix(1000, hAccM: 100), fix(2000)]);
      await ctrl().pause();

      expect((await db.fixesFor(snap().trackId!)).length, 3);
      expect(snap().filter.acceptedCount, 2);
      expect(snap().filter.droppedCount, 1);
      expect(snap().dropCounts[DropReason.lowAccuracy], 1);
    });

    test('a recent lista az utolsó fixeket tartja, dropReason-nel', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([fix(0), fix(1000, hAccM: 100)]);

      final recent = snap().recent;
      expect(recent.map((r) => r.fix.tMs), [0, 1000]);
      expect(recent[0].dropReason, isNull);
      expect(recent[1].dropReason, DropReason.lowAccuracy);
    });

    test('a recent lista korlátos', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([for (var i = 0; i < 80; i++) fix(i * 1000)]);
      expect(snap().recent.length, RecordingController.recentLimit);
      expect(snap().recent.last.fix.tMs, 79000);
    });

    test(
      'írási hiba: a fixek nem vesznek el, a következő írás pótolja',
      () async {
        await ctrl().start(profile: TrackProfile.precise);
        db.failWrites = true;
        await feed([for (var i = 0; i < 10; i++) fix(i * 1000)]);

        final id = snap().trackId!;
        expect(await db.fixesFor(id), isEmpty);
        expect(snap().error, isNotNull);
        expect(snap().pendingCount, 10);

        db.failWrites = false;
        await feed([fix(10000)]);
        await ctrl().pause();

        final saved = await db.fixesFor(id);
        expect(saved.map((f) => f.tMs), [
          for (var i = 0; i <= 10; i++) i * 1000,
        ]);
        expect(snap().error, isNull);
      },
    );
  });

  group('pause / resume / finish', () {
    test('pause: kiír mindent, szegmenst zár, státusz paused', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([fix(0), fix(1000), fix(2000)]);
      nowMs = 1005000;
      await ctrl().pause();

      final id = snap().trackId!;
      expect(snap().recState, RecState.paused);
      expect(snap().pendingCount, 0);
      expect((await db.fixesFor(id)).length, 3);
      expect((await db.trackById(id))!.status, TrackStatus.paused);
      expect((await db.segmentsFor(id)).single.endTMs, 1005000);
    });

    test('szünet alatt érkező fix nem kerül be', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([fix(0)]);
      await ctrl().pause();
      await feed([fix(1000)]);
      expect((await db.fixesFor(snap().trackId!)).length, 1);
    });

    test('pause → resume: két szegmens, státusz újra recording', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([fix(0), fix(1000)]);
      nowMs = 1010000;
      await ctrl().pause();
      nowMs = 1020000;
      await ctrl().resume();
      expect(snap().recState, RecState.recording);
      await feed([fix(20000), fix(21000)]);
      await ctrl().pause();

      final id = snap().trackId!;
      final segs = await db.segmentsFor(id);
      expect(segs.length, 2);
      expect(segs[0].endTMs, 1010000);
      expect(segs[1].startTMs, 1020000);
      expect((await db.fixesFor(id)).length, 4);
      expect(
        snap().filter.distanceM,
        lessThan(30),
        reason: 'a szünet előtti és utáni pont közti ugrás nem számít távnak',
      );
    });

    test(
      'finish: kiír, lezár, endedAtMs és újraszámolható statsJson',
      () async {
        await ctrl().start(profile: TrackProfile.precise);
        final fixes = [for (var i = 0; i < 15; i++) fix(i * 1000, alt: 100)];
        await feed(fixes);
        nowMs = 1016000;
        await ctrl().finish();

        final id = snap().trackId!;
        final t = (await db.trackById(id))!;
        expect(snap().recState, RecState.finished);
        expect(t.status, TrackStatus.finished);
        expect(t.endedAtMs, 1016000);
        expect((await db.fixesFor(id)).length, 15);
        expect((await db.segmentsFor(id)).single.endTMs, 1016000);

        final cached = TrackStats.fromJson(
          jsonDecode(t.statsJson!) as Map<String, Object?>,
        );
        final fresh = computeStats(await db.fixesFor(id));
        expect(cached.toJson(), fresh.toJson());
      },
    );

    test('finish után ugyanaz a controller új túrát indít', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await ctrl().finish();
      final first = snap().trackId!;

      await ctrl().start(profile: TrackProfile.batterySaver);
      expect(snap().recState, RecState.recording);
      expect(snap().trackId, isNot(first));
      expect(snap().filter.acceptedCount, 0, reason: 'tiszta állapotról indul');
      expect(snap().recent, isEmpty);
    });
  });

  group('indulási visszaállítás (kilövés után)', () {
    /// Kilövés: a DB marad, a folyamat (container, forrás) új.
    Future<int> seedKilled({TrackStatus status = TrackStatus.recording}) async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([for (var i = 0; i < 10; i++) fix(i * 1000)]);
      final id = snap().trackId!;
      if (status == TrackStatus.paused) {
        await ctrl().pause();
      }
      kill();
      source = FakeSource();
      container = makeContainer();
      return id;
    }

    test('nincs túra: idle', () async {
      await ctrl().restore();
      expect(snap().recState, RecState.idle);
    });

    test('lezárt túra: idle', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await ctrl().finish();
      kill();
      container = makeContainer();

      await ctrl().restore();
      expect(snap().recState, RecState.idle);
    });

    test('recording státusz új folyamatban: interrupted', () async {
      final id = await seedKilled();
      await ctrl().restore();
      expect(snap().recState, RecState.interrupted);
      expect(snap().trackId, id);
      expect(snap().profile, TrackProfile.precise);
    });

    test('paused státusz új folyamatban: interrupted', () async {
      final id = await seedKilled(status: TrackStatus.paused);
      await ctrl().restore();
      expect(snap().recState, RecState.interrupted);
      expect(snap().trackId, id);
    });

    test('kilövéskor legfeljebb a puffer vész el', () async {
      await ctrl().start(profile: TrackProfile.precise);
      await feed([for (var i = 0; i < 13; i++) fix(i * 1000)]);
      final id = snap().trackId!;
      kill();

      expect((await db.fixesFor(id)).length, 10);
    });

    test(
      'resume: a nyitott szegmens az utolsó fixnél záródik, újat nyit',
      () async {
        final id = await seedKilled();
        await ctrl().restore();
        nowMs = 5000000;
        await ctrl().resume();

        expect(snap().recState, RecState.recording);
        expect((await db.trackById(id))!.status, TrackStatus.recording);
        final segs = await db.segmentsFor(id);
        expect(segs.length, 2);
        expect(segs[0].endTMs, 9000, reason: 'az utolsó tárolt fix ideje');
        expect(segs[1].startTMs, 5000000);
        expect(segs[1].endTMs, isNull);
      },
    );

    test('resume: az élő számláló a tárolt fixekből épül újra', () async {
      await seedKilled();
      await ctrl().restore();
      await ctrl().resume();
      expect(snap().filter.acceptedCount, greaterThan(0));
      await feed([fix(600000)]);
      await ctrl().pause();
      expect(
        snap().filter.distanceM,
        lessThan(200),
        reason: 'a kilövés előtti és utáni pont közti ugrás nem táv',
      );
    });

    test('finish interrupted állapotból: a lezárás az utolsó fixnél', () async {
      final id = await seedKilled();
      await ctrl().restore();
      nowMs = 9999999;
      await ctrl().finish();

      final t = (await db.trackById(id))!;
      expect(t.status, TrackStatus.finished);
      expect(t.endedAtMs, 9000, reason: 'az adat vége, nem a mostani idő');
      expect((await db.segmentsFor(id)).single.endTMs, 9000);
      expect(t.statsJson, isNotNull);
    });

    test('finish üres, megszakadt túrán: a kezdés az end', () async {
      await ctrl().start(profile: TrackProfile.precise);
      final id = snap().trackId!;
      kill();
      container = makeContainer();

      await ctrl().restore();
      await ctrl().finish();
      expect((await db.trackById(id))!.endedAtMs, 1000000);
    });
  });

  test(
    'a forrás hibája megjelenik az állapotban, a rögzítés megmarad',
    () async {
      await ctrl().start(profile: TrackProfile.precise);
      source.controller.addError(StateError('helyszolgáltatás kikapcsolva'));
      await pumpEventQueue();
      expect(snap().error, contains('helyszolgáltatás'));
      expect(snap().recState, RecState.recording);
    },
  );

  test('sourceDone: a visszajátszás vége jelezhető', () async {
    await ctrl().start(profile: TrackProfile.precise);
    var done = false;
    unawaited(ctrl().sourceDone.then((_) => done = true));
    await source.controller.close();
    await pumpEventQueue();
    expect(done, isTrue);
  });
}
