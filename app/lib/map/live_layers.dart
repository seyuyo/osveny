import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_core/geo_core.dart';
import 'package:latlong2/latlong.dart';

import '../recording/recording_controller.dart';
import 'track_line.dart';

/// A nyomvonal színe: élénk narancs, világos és sötét térképen is látszik.
const trackColor = Color(0xFFFF6D00);
const _trackBorder = Color(0x99000000);
const positionColor = Color(0xFF1E88E5);

/// A rögzítés alatti pozíció: a legutóbbi (nyers) fix, csak rögzítés közben.
final livePositionProvider = Provider<Fix?>((ref) {
  final s = ref.watch(recordingControllerProvider);
  if (s.recState != RecState.recording || s.recent.isEmpty) return null;
  return s.recent.last.fix;
});

/// Az élő nyomvonal rétege (a FlutterMap gyereke). A vonalakat zoomsávonként
/// ritkítva rajzolja; csak akkor számol újra, ha a nyomvonal vagy a zoomsáv
/// változott (pásztázáskor nem).
class LiveTrackLayer extends ConsumerStatefulWidget {
  const LiveTrackLayer({super.key});

  @override
  ConsumerState<LiveTrackLayer> createState() => _LiveTrackLayerState();
}

class _LiveTrackLayerState extends ConsumerState<LiveTrackLayer> {
  final _simplifier = TrackLineSimplifier();
  List<List<LatLng>> _lines = const [];
  (int, int, int)? _requested;

  void _schedule(int version, int band) {
    final live = ref.read(recordingControllerProvider.notifier).liveTrack;
    final key = (version, live.generation, band);
    if (key == _requested) return;
    _requested = key;
    _simplifier
        .lines(live.segments, generation: live.generation, zoomBand: band)
        .then((lines) {
          if (!mounted || _requested != key) return;
          setState(() => _lines = lines);
        });
  }

  @override
  Widget build(BuildContext context) {
    final version = ref.watch(
      recordingControllerProvider.select((s) => s.liveVersion),
    );
    final band = MapCamera.of(context).zoom.floor();
    _schedule(version, band);

    final drawable = [
      for (final l in _lines)
        if (l.length >= 2) l,
    ];
    if (drawable.isEmpty) return const SizedBox.shrink();
    return PolylineLayer(
      polylines: [
        for (final points in drawable)
          Polyline(
            points: points,
            strokeWidth: 5,
            color: trackColor,
            borderStrokeWidth: 1.5,
            borderColor: _trackBorder,
          ),
      ],
    );
  }
}

/// A pozíció rétege: pontossági kör (méterben) és a pozíciót jelölő pötty.
class PositionLayer extends ConsumerWidget {
  const PositionLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fix = ref.watch(livePositionProvider);
    if (fix == null) return const SizedBox.shrink();
    final point = LatLng(fix.latDeg, fix.lonDeg);
    return CircleLayer(
      circles: [
        CircleMarker(
          point: point,
          radius: fix.hAccM,
          useRadiusInMeter: true,
          color: positionColor.withValues(alpha: 0.15),
          borderColor: positionColor.withValues(alpha: 0.5),
          borderStrokeWidth: 1,
        ),
        CircleMarker(
          point: point,
          radius: 7,
          color: positionColor,
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ],
    );
  }
}
