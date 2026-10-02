import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_core/geo_core.dart';
import 'package:latlong2/latlong.dart';

import 'follow_mode.dart';
import 'live_layers.dart';
import 'map_store.dart';
import 'offline_map.dart';
import '../recording/recording_controller.dart';
import 'recording_controls.dart';

/// Az offline térkép az élő réteggel: nyomvonal, pozíció és követő mód.
///
/// A követő mód alapból be van kapcsolva: minden új pozícióra a térkép oda
/// áll. Kézi mozgatásra kikapcsol; a „Követés” gomb kapcsolja vissza.
class LiveMap extends ConsumerStatefulWidget {
  const LiveMap({super.key, required this.map});

  final InstalledMap map;

  @override
  ConsumerState<LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends ConsumerState<LiveMap> {
  final _controller = MapController();
  bool _following = true;
  bool _ready = false;

  @override
  void didUpdateWidget(LiveMap old) {
    super.didUpdateWidget(old);
    // Másik térképnél új FlutterMap épül (lásd OfflineMap): újra meg kell
    // várni, hogy a vezérlő használható legyen.
    if (old.map.path != widget.map.path) _ready = false;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _moveTo(Fix fix) {
    if (!_ready) return;
    _controller.move(LatLng(fix.latDeg, fix.lonDeg), _controller.camera.zoom);
  }

  void _onMapReady() {
    _ready = true;
    final fix = ref.read(livePositionProvider);
    if (_following && fix != null) _moveTo(fix);
  }

  void _onMapEvent(MapEvent event) {
    if (_following && stopsFollowing(event.source)) {
      setState(() => _following = false);
    }
  }

  void _follow() {
    setState(() => _following = true);
    final fix = ref.read(livePositionProvider);
    if (fix != null) _moveTo(fix);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Fix?>(livePositionProvider, (previous, next) {
      if (next != null && _following) _moveTo(next);
    });
    // Rögzítés (újra)indulásakor visszakapcsol a követés: a folytatás után a
    // felhasználó a saját pozícióját akarja látni.
    ref.listen<RecState>(
      recordingControllerProvider.select((s) => s.recState),
      (previous, next) {
        if (next == RecState.recording && previous != RecState.recording) {
          setState(() => _following = true);
        }
      },
    );
    final position = ref.watch(livePositionProvider);

    return Stack(
      children: [
        Positioned.fill(
          child: OfflineMap(
            map: widget.map,
            mapController: _controller,
            onMapReady: _onMapReady,
            onMapEvent: _onMapEvent,
            layers: const [LiveTrackLayer(), PositionLayer()],
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            // A forrásmegjelölés fölött.
            padding: EdgeInsets.only(bottom: 32),
            child: RecordingControls(),
          ),
        ),
        if (!_following && position != null)
          Positioned(
            right: 8,
            bottom: 32,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Követés',
              onPressed: _follow,
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }
}
