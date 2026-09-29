import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_core/geo_core.dart';

import '../data/database.dart';
import 'location_source.dart';
import 'track_profile.dart';

/// Az adatbázis; az `main` felülírja a valódival.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider felülírása szükséges'),
);

/// A helyforrás; az `main` felülírja a `GeolocatorLocationSource`-szal.
final locationSourceProvider = Provider<LocationSource>(
  (ref) =>
      throw UnimplementedError('locationSourceProvider felülírása szükséges'),
);

/// Az óra epoch ezredmásodpercben; injektálható a teszthez.
final clockProvider = Provider<int Function()>(
  (ref) =>
      () => DateTime.now().millisecondsSinceEpoch,
);

final batchConfigProvider = Provider<BatchConfig>((ref) => const BatchConfig());

/// Mikor kerül ki a memóriából a köteg: legfeljebb [maxAge] után vagy
/// [maxCount] pontnál (spec 2. és 10. fejezet: legfeljebb 5 s adat lehet csak
/// memóriában).
class BatchConfig {
  const BatchConfig({
    this.maxAge = const Duration(seconds: 5),
    this.maxCount = 10,
  });

  final Duration maxAge;
  final int maxCount;
}

/// Egy fix és a szűrőlánc döntése (a debug listához).
class RecordedFix {
  const RecordedFix(this.fix, this.dropReason);

  final Fix fix;

  /// `null`, ha a szűrőlánc elfogadta.
  final DropReason? dropReason;
}

/// A rögzítés megjeleníthető állapota. Az élő számlálók csak megjelenítésre
/// valók, nem tároljuk őket; a végleges statisztika a nyers fixekből számolódik.
@immutable
class RecordingSnapshot {
  const RecordingSnapshot({
    this.recState = RecState.idle,
    this.trackId,
    this.profile,
    this.filter = const FilterState(),
    this.dropCounts = const {},
    this.recent = const [],
    this.pendingCount = 0,
    this.error,
  });

  final RecState recState;
  final int? trackId;
  final TrackProfile? profile;
  final FilterState filter;
  final Map<DropReason, int> dropCounts;

  /// Az utolsó [RecordingController.recentLimit] fix, a régebbi elöl.
  final List<RecordedFix> recent;

  /// A még csak memóriában lévő fixek száma.
  final int pendingCount;

  /// Az utolsó hiba (mentés vagy helyforrás); sikeres mentés törli.
  final String? error;

  RecordingSnapshot copyWith({
    RecState? recState,
    int? trackId,
    TrackProfile? profile,
    FilterState? filter,
    Map<DropReason, int>? dropCounts,
    List<RecordedFix>? recent,
    int? pendingCount,
    String? error,
    bool clearError = false,
  }) => RecordingSnapshot(
    recState: recState ?? this.recState,
    trackId: trackId ?? this.trackId,
    profile: profile ?? this.profile,
    filter: filter ?? this.filter,
    dropCounts: dropCounts ?? this.dropCounts,
    recent: recent ?? this.recent,
    pendingCount: pendingCount ?? this.pendingCount,
    error: clearError ? null : (error ?? this.error),
  );
}

final recordingControllerProvider =
    NotifierProvider<RecordingController, RecordingSnapshot>(
      RecordingController.new,
    );

/// A rögzítés vezérlője: a `geo_core` állapotgépére építve fogadja a helyforrás
/// fixeit, nyersen, kötegelve az adatbázisba írja őket, és megszakadás után
/// folytatást vagy lezárást kínál.
class RecordingController extends Notifier<RecordingSnapshot> {
  /// A `recent` lista hossza.
  static const recentLimit = 50;

  StreamSubscription<Fix>? _sub;
  Completer<void> _sourceDone = Completer<void>()..complete();
  final _buffer = <Fix>[];
  Timer? _flushTimer;
  Future<void> _writeChain = Future.value();

  AppDatabase get _db => ref.read(databaseProvider);
  int get _now => ref.read(clockProvider)();

  @override
  RecordingSnapshot build() {
    ref.onDispose(() {
      _flushTimer?.cancel();
      _flushTimer = null;
      _sub?.cancel();
      _sub = null;
    });
    return const RecordingSnapshot();
  }

  /// Teljesül, amikor az aktuális helyforrás-folyam véget ért (visszajátszás
  /// vége). Élő GPS-nél nem ér véget.
  Future<void> get sourceDone => _sourceDone.future;

  /// Megvárja a folyamatban lévő mentéseket.
  @visibleForTesting
  Future<void> settle() => _writeChain;

  /// Indulási visszaállítás: ha a legutóbbi túra félbemaradt (`recording` vagy
  /// `paused`), az állapot `interrupted`, és a felhasználó dönt.
  Future<void> restore() async {
    if (state.recState != RecState.idle) return;
    final track = await _db.latestTrack();
    final derived = deriveOnStartup(
      latestTrackStatus: track?.status,
      isNewProcess: true,
    );
    if (derived == RecState.interrupted && ref.mounted) {
      state = RecordingSnapshot(
        recState: derived,
        trackId: track!.id,
        profile: track.profile,
      );
    }
  }

  Future<void> start({required TrackProfile profile, String? name}) async {
    // Lezárt túra után új munkamenet indul.
    final from = state.recState == RecState.finished
        ? RecState.idle
        : state.recState;
    final next = nextState(from, RecEvent.start);
    state = RecordingSnapshot(recState: next, profile: profile);

    final now = _now;
    final id = await _db.createTrack(
      name: name ?? _defaultName(now),
      profile: profile,
      startedAtMs: now,
    );
    await _db.openSegment(id, now);
    if (!ref.mounted) return;
    state = state.copyWith(trackId: id);
    _listen(profile);
  }

  Future<void> pause() async {
    state = state.copyWith(recState: nextState(state.recState, RecEvent.pause));
    await _stopSource();
    await _flush();
    final id = state.trackId!;
    await _db.closeOpenSegment(id, _now);
    await _db.setStatus(id, TrackStatus.paused);
  }

  /// Folytatás szünet vagy megszakadás után. Új szegmens nyílik; a szűrő a
  /// szegmenshatáron nem köti össze a két oldal pontjait.
  Future<void> resume() async {
    final from = state.recState;
    state = state.copyWith(recState: nextState(from, RecEvent.resume));
    final id = state.trackId!;
    final profile = state.profile!;

    if (from == RecState.interrupted) {
      // A kilőtt folyamat szegmense nyitva maradt: az utolsó tárolt fixnél zárjuk.
      final lastT = await _db.lastFixTMs(id);
      final track = await _db.trackById(id);
      await _db.closeOpenSegment(id, lastT ?? track!.startedAtMs);
      final run = runFilter(await _db.fixesFor(id));
      if (!ref.mounted) return;
      state = state.copyWith(
        filter: _withoutLast(run.state),
        dropCounts: run.dropCounts,
      );
    } else {
      state = state.copyWith(filter: _withoutLast(state.filter));
    }

    await _db.openSegment(id, _now);
    await _db.setStatus(id, TrackStatus.recording);
    if (!ref.mounted) return;
    _listen(profile);
  }

  Future<void> finish() async {
    final from = state.recState;
    state = state.copyWith(recState: nextState(from, RecEvent.finish));
    await _stopSource();
    await _flush();

    final id = state.trackId!;
    final fixes = await _db.fixesFor(id);
    // Megszakadt túránál az adat vége a lezárás ideje, nem a mostani idő.
    final int endMs;
    if (from == RecState.interrupted) {
      endMs = fixes.isEmpty
          ? (await _db.trackById(id))!.startedAtMs
          : fixes.last.tMs;
    } else {
      endMs = _now;
    }
    await _db.closeOpenSegment(id, endMs);
    final statsJson = await Isolate.run(() => _statsJson(fixes));
    await _db.setStatus(
      id,
      TrackStatus.finished,
      endedAtMs: endMs,
      statsJson: statsJson,
    );
  }

  void _listen(TrackProfile profile) {
    _sourceDone = Completer<void>();
    final done = _sourceDone;
    _sub = ref
        .read(locationSourceProvider)
        .fixes(profile)
        .listen(
          _onFix,
          onError: (Object e) => _setError('Helyforrás: $e'),
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
        );
  }

  Future<void> _stopSource() async {
    final sub = _sub;
    _sub = null;
    await sub?.cancel();
  }

  void _onFix(Fix fix) {
    if (!ref.mounted) return;
    final r = filterUpdate(state.filter, fix);
    final reason = r.dropReason;

    // A nyers fix mindenképp a pufferbe kerül; a szűrő csak a megjelenítést érinti.
    _buffer.add(fix);
    _armTimer();

    final dropCounts = reason == null
        ? state.dropCounts
        : {...state.dropCounts, reason: (state.dropCounts[reason] ?? 0) + 1};
    final recent = [...state.recent, RecordedFix(fix, reason)];
    state = state.copyWith(
      filter: r.state,
      dropCounts: dropCounts,
      recent: recent.length > recentLimit
          ? recent.sublist(recent.length - recentLimit)
          : recent,
      pendingCount: _buffer.length,
    );

    if (_buffer.length >= ref.read(batchConfigProvider).maxCount) {
      unawaited(_flush());
    }
  }

  void _armTimer() {
    if (_flushTimer != null) return;
    _flushTimer = Timer(ref.read(batchConfigProvider).maxAge, () {
      _flushTimer = null;
      if (ref.mounted) unawaited(_flush());
    });
  }

  /// A puffer kiírása. A mentések sorban futnak; hiba esetén a fixek
  /// visszakerülnek a puffer elejére, és a következő köteg pótolja őket.
  Future<void> _flush() {
    _flushTimer?.cancel();
    _flushTimer = null;
    if (_buffer.isEmpty) return _writeChain;

    final batch = List<Fix>.of(_buffer);
    _buffer.clear();
    final id = state.trackId!;
    state = state.copyWith(pendingCount: 0);

    return _writeChain = _writeChain.then((_) async {
      try {
        await _db.insertFixBatch(id, batch);
        if (ref.mounted && state.error != null) {
          state = state.copyWith(clearError: true);
        }
      } catch (e) {
        _buffer.insertAll(0, batch);
        if (ref.mounted) {
          state = state.copyWith(
            pendingCount: _buffer.length,
            error: 'Mentés sikertelen: $e',
          );
          _armTimer();
        }
      }
    });
  }

  void _setError(String message) {
    if (ref.mounted) state = state.copyWith(error: message);
  }
}

/// Szegmenshatáron a szűrő ne kösse össze a két oldal pontjait: az utolsó
/// elfogadott pontot elfelejtjük, a számlálókat megtartjuk.
FilterState _withoutLast(FilterState s) => FilterState(
  distanceM: s.distanceM,
  movingTimeMs: s.effectiveMovingTimeMs(const FilterConfig()),
  acceptedCount: s.acceptedCount,
  droppedCount: s.droppedCount,
);

String _statsJson(List<Fix> fixes) => jsonEncode(computeStats(fixes).toJson());

String _defaultName(int nowMs) {
  final d = DateTime.fromMillisecondsSinceEpoch(nowMs);
  String two(int v) => v.toString().padLeft(2, '0');
  return 'Túra ${d.year}-${two(d.month)}-${two(d.day)} '
      '${two(d.hour)}:${two(d.minute)}';
}
