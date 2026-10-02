import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_file_picker.dart';
import 'map_store.dart';
import 'pmtiles_header.dart';

/// A térképmappa; az `main` felülírja a dokumentummappa alatti `maps`-szel.
final mapStoreProvider = Provider<MapStore>(
  (ref) => throw UnimplementedError('mapStoreProvider felülírása szükséges'),
);

enum MapLibraryPhase { loading, ready, importing }

@immutable
class MapLibraryState {
  const MapLibraryState({
    this.phase = MapLibraryPhase.loading,
    this.maps = const [],
    this.active,
    this.progress,
    this.error,
  });

  final MapLibraryPhase phase;
  final List<InstalledMap> maps;
  final InstalledMap? active;

  /// Import közben a másolt arány 0 és 1 között; `null`, ha a méret ismeretlen
  /// vagy nem import zajlik.
  final double? progress;

  /// Az utolsó hiba, a felhasználónak szóló szöveggel.
  final String? error;

  MapLibraryState copyWith({
    MapLibraryPhase? phase,
    List<InstalledMap>? maps,
    InstalledMap? active,
    bool clearActive = false,
    double? progress,
    bool clearProgress = false,
    String? error,
    bool clearError = false,
  }) => MapLibraryState(
    phase: phase ?? this.phase,
    maps: maps ?? this.maps,
    active: clearActive ? null : (active ?? this.active),
    progress: clearProgress ? null : (progress ?? this.progress),
    error: clearError ? null : (error ?? this.error),
  );
}

final mapLibraryControllerProvider =
    NotifierProvider<MapLibraryController, MapLibraryState>(
      MapLibraryController.new,
    );

/// A telepített térképek állapota és az import vezérlése.
class MapLibraryController extends Notifier<MapLibraryState> {
  MapStore get _store => ref.read(mapStoreProvider);

  /// Igaz a fájlkiválasztás és az import teljes ideje alatt (a kiválasztó
  /// megnyitásától): ez védi a dupla indítást, nem a `phase`, mert az csak a
  /// másolás kezdetén vált `importing`-re.
  bool _busy = false;

  @override
  MapLibraryState build() {
    Future.microtask(() async {
      if (ref.mounted) await load();
    });
    return const MapLibraryState();
  }

  Future<void>? _loading;

  /// A mappa beolvasása; előtte a megszakadt importok maradékát törli.
  /// Olvasási hiba nem marad kezeletlen: a felület hibaüzenetet kap.
  /// Párhuzamos hívások ugyanahhoz a futó betöltéshez csatlakoznak.
  Future<void> load() =>
      _loading ??= _load().whenComplete(() => _loading = null);

  Future<void> _load() async {
    try {
      await _store.cleanupPartials();
      await _refresh();
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        phase: MapLibraryPhase.ready,
        error: 'A térképek beolvasása nem sikerült: $e',
      );
    }
  }

  /// A lista és az aktív térkép frissítése. Közben futó import állapotát
  /// (`importing`, folyamat) nem írja felül, ezt csak az import vége váltja.
  Future<void> _refresh({bool importDone = false}) async {
    final maps = await _store.list();
    final active = await _store.active();
    if (!ref.mounted) return;
    final keepImporting =
        state.phase == MapLibraryPhase.importing && !importDone;
    state = MapLibraryState(
      phase: keepImporting ? MapLibraryPhase.importing : MapLibraryPhase.ready,
      maps: maps,
      active: active,
      progress: keepImporting ? state.progress : null,
      error: state.error,
    );
  }

  /// A fájl kiválasztása és importálása. Egyszerre csak egy import fut.
  Future<void> importMap() async {
    if (_busy) return;
    _busy = true;
    state = state.copyWith(clearError: true);

    try {
      final source = await ref.read(mapFilePickerProvider).pick();
      if (source == null) return; // a felhasználó megszakította
      if (!ref.mounted) return;

      state = state.copyWith(
        phase: MapLibraryPhase.importing,
        clearProgress: true,
      );
      await _store.import(
        source,
        onProgress: (copied, total) {
          if (!ref.mounted || total == null || total <= 0) return;
          state = state.copyWith(progress: (copied / total).clamp(0.0, 1.0));
        },
      );
      if (!ref.mounted) return;
      await _refresh(importDone: true);
    } on PmtilesFormatException catch (e) {
      _fail(e.message);
    } catch (e) {
      _fail('Az importálás nem sikerült: $e');
    } finally {
      _busy = false;
    }
  }

  void _fail(String message) {
    if (!ref.mounted) return;
    state = state.copyWith(
      phase: MapLibraryPhase.ready,
      clearProgress: true,
      error: message,
    );
  }

  Future<void> setActive(String name) async {
    await _store.setActive(name);
    await _refresh();
  }

  Future<void> delete(String name) async {
    await _store.delete(name);
    await _refresh();
  }

  void clearError() => state = state.copyWith(clearError: true);
}
