import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:geo_core/geo_core.dart';
import 'package:path_provider/path_provider.dart';

import '../recording/track_profile.dart';

part 'database.g.dart';

@DataClassName('TrackRow')
class Tracks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get status => textEnum<TrackStatus>()();
  TextColumn get profile => textEnum<TrackProfile>()();
  IntColumn get startedAtMs => integer()();
  IntColumn get endedAtMs => integer().nullable()();
  IntColumn get plannedRouteId => integer().nullable()();

  /// Csak gyorsítótár: lezáráskor számolva, a nyers fixekből bármikor
  /// újraszámolható.
  TextColumn get statsJson => text().nullable()();
}

/// Nyers GPS-mérések. Szűrt pontot, távot, szintemelkedést nem tárolunk.
@DataClassName('FixRow')
@TableIndex(name: 'fixes_track_t', columns: {#trackId, #tMs})
class Fixes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer().references(Tracks, #id)();
  IntColumn get tMs => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get alt => real().nullable()();
  RealColumn get hAcc => real()();
  RealColumn get vAcc => real().nullable()();
  RealColumn get speed => real().nullable()();
  RealColumn get bearing => real().nullable()();
}

/// Szünet/folytatás határai.
@DataClassName('SegmentRow')
class Segments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get trackId => integer().references(Tracks, #id)();
  IntColumn get startTMs => integer()();
  IntColumn get endTMs => integer().nullable()();
}

@DriftDatabase(tables: [Tracks, Fixes, Segments])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Az alkalmazás adatbázisa háttér-isolate-ben (spec 7. fejezet).
  factory AppDatabase.open() => AppDatabase(
    LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      return NativeDatabase.createInBackground(
        File('${dir.path}${Platform.pathSeparator}osveny.sqlite'),
      );
    }),
  );

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<int> createTrack({
    required String name,
    required TrackProfile profile,
    required int startedAtMs,
  }) => into(tracks).insert(
    TracksCompanion.insert(
      name: name,
      status: TrackStatus.recording,
      profile: profile,
      startedAtMs: startedAtMs,
    ),
  );

  Future<TrackRow?> latestTrack() =>
      (select(tracks)
            ..orderBy([(t) => OrderingTerm.desc(t.id)])
            ..limit(1))
          .getSingleOrNull();

  Future<void> setStatus(
    int trackId,
    TrackStatus status, {
    int? endedAtMs,
    String? statsJson,
  }) => (update(tracks)..where((t) => t.id.equals(trackId))).write(
    TracksCompanion(
      status: Value(status),
      endedAtMs: endedAtMs == null ? const Value.absent() : Value(endedAtMs),
      statsJson: statsJson == null ? const Value.absent() : Value(statsJson),
    ),
  );

  /// Egy köteg nyers fix egyetlen tranzakcióban.
  Future<void> insertFixBatch(int trackId, List<Fix> batch) async {
    if (batch.isEmpty) return;
    await this.batch((b) {
      b.insertAll(fixes, [
        for (final f in batch)
          FixesCompanion.insert(
            trackId: trackId,
            tMs: f.tMs,
            lat: f.latDeg,
            lon: f.lonDeg,
            alt: Value(f.altM),
            hAcc: f.hAccM,
            vAcc: Value(f.vAccM),
            speed: Value(f.speedMps),
            bearing: Value(f.bearingDeg),
          ),
      ]);
    });
  }

  Future<List<Fix>> fixesFor(int trackId) async {
    final rows =
        await (select(fixes)
              ..where((f) => f.trackId.equals(trackId))
              ..orderBy([(f) => OrderingTerm.asc(f.tMs)]))
            .get();
    return [
      for (final r in rows)
        Fix(
          tMs: r.tMs,
          latDeg: r.lat,
          lonDeg: r.lon,
          altM: r.alt,
          hAccM: r.hAcc,
          vAccM: r.vAcc,
          speedMps: r.speed,
          bearingDeg: r.bearing,
        ),
    ];
  }

  Future<int> openSegment(int trackId, int startTMs) => into(
    segments,
  ).insert(SegmentsCompanion.insert(trackId: trackId, startTMs: startTMs));

  /// A túra nyitott szegmensének lezárása; a már lezártakat nem érinti.
  Future<void> closeOpenSegment(int trackId, int endTMs) =>
      (update(segments)
            ..where((s) => s.trackId.equals(trackId) & s.endTMs.isNull()))
          .write(SegmentsCompanion(endTMs: Value(endTMs)));

  Future<List<SegmentRow>> segmentsFor(int trackId) =>
      (select(segments)
            ..where((s) => s.trackId.equals(trackId))
            ..orderBy([(s) => OrderingTerm.asc(s.startTMs)]))
          .get();
}
