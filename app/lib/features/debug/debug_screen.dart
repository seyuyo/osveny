import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_core/geo_core.dart';
import 'package:geo_core/testing.dart';

import '../../recording/recording_controller.dart';
import '../../recording/track_profile.dart';
import 'csv_export.dart';

/// Debug képernyő (M2.5): rögzítés-vezérlés, élő fix-lista,
/// elfogadott/eldobott arány és nyers CSV-export. Az exportált CSV az
/// `packages/geo_core/test/traces/` visszajátszásos tesztjeinek bemenete.
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  TrackProfile _profile = TrackProfile.precise;

  RecordingController get _controller =>
      ref.read(recordingControllerProvider.notifier);

  /// A művelet hibája ne nyelődjön el.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
    }
  }

  Future<void> _export(int trackId) => _run(() async {
    final fixes = await ref.read(databaseProvider).fixesFor(trackId);
    await ref.read(csvExporterProvider)(
      fileName: 'osveny_track_$trackId.csv',
      csv: fixesToCsv(fixes),
    );
  });

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(recordingControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ösvény · debug')),
      // Stretch: a gyerekek teljes szélességet kapnak, így a saját
      // bal oldali igazításuk érvényesül (alapból középre csúsznának).
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusBar(snap: snap),
          if (snap.recState == RecState.interrupted)
            _InterruptedCard(
              onResume: () => _run(_controller.resume),
              onFinish: () => _run(_controller.finish),
            )
          else
            _Controls(
              snap: snap,
              profile: _profile,
              onProfile: (p) => setState(() => _profile = p),
              onStart: () => _run(() => _controller.start(profile: _profile)),
              onPause: () => _run(_controller.pause),
              onResume: () => _run(_controller.resume),
              onFinish: () => _run(_controller.finish),
            ),
          _Stats(snap: snap),
          if (snap.trackId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  // Bal belső margó nélkül az ikon a többi elemmel egy vonalba esik.
                  style: TextButton.styleFrom(
                    padding: const EdgeInsetsDirectional.only(end: 12),
                  ),
                  onPressed: () => _export(snap.trackId!),
                  icon: const Icon(Icons.ios_share),
                  label: const Text('CSV exportálás'),
                ),
              ),
            ),
          const Divider(height: 1),
          Expanded(child: _FixList(recent: snap.recent)),
        ],
      ),
    );
  }
}

String _stateLabel(RecState s) => switch (s) {
  RecState.idle => 'Nem rögzít',
  RecState.recording => 'Rögzítés folyamatban',
  RecState.paused => 'Szüneteltetve',
  RecState.interrupted => 'Félbemaradt',
  RecState.finished => 'Lezárva',
};

String dropReasonLabel(DropReason r) => switch (r) {
  DropReason.lowAccuracy => 'Pontatlan',
  DropReason.outOfOrder => 'Sorrenden kívül',
  DropReason.jump => 'Ugrás',
  DropReason.tooClose => 'Túl közel',
};

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.snap});

  final RecordingSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: scheme.secondaryContainer,
      padding: const EdgeInsets.all(12),
      child: Text(
        _stateLabel(snap.recState),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: scheme.onSecondaryContainer),
      ),
    );
  }
}

class _InterruptedCard extends StatelessWidget {
  const _InterruptedCard({required this.onResume, required this.onFinish});

  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Félbemaradt rögzítés',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Az előző rögzítés nem záródott le. Folytathatod, vagy '
              'lezárhatod a már mentett pontokkal.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton(
                  onPressed: onResume,
                  child: const Text('Folytatás'),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: onFinish,
                  child: const Text('Lezárás'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.snap,
    required this.profile,
    required this.onProfile,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onFinish,
  });

  final RecordingSnapshot snap;
  final TrackProfile profile;
  final ValueChanged<TrackProfile> onProfile;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final canStart =
        snap.recState == RecState.idle || snap.recState == RecState.finished;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (canStart) ...[
            SegmentedButton<TrackProfile>(
              segments: const [
                ButtonSegment(
                  value: TrackProfile.precise,
                  label: Text('Pontos'),
                ),
                ButtonSegment(
                  value: TrackProfile.batterySaver,
                  label: Text('Akkukímélő'),
                ),
              ],
              selected: {profile},
              onSelectionChanged: (s) => onProfile(s.single),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onStart,
              child: const Text('Rögzítés indítása'),
            ),
          ] else
            Wrap(
              spacing: 12,
              children: [
                if (snap.recState == RecState.recording)
                  FilledButton(onPressed: onPause, child: const Text('Szünet')),
                if (snap.recState == RecState.paused)
                  FilledButton(
                    onPressed: onResume,
                    child: const Text('Folytatás'),
                  ),
                OutlinedButton(
                  onPressed: onFinish,
                  child: const Text('Befejezés'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.snap});

  final RecordingSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final accepted = snap.filter.acceptedCount;
    final dropped = snap.filter.droppedCount;
    final total = accepted + dropped;
    final ratio = total == 0 ? '–' : '${(100 * dropped / total).round()}%';
    final reasons = [
      for (final r in DropReason.values)
        if ((snap.dropCounts[r] ?? 0) > 0)
          '${dropReasonLabel(r)}: ${snap.dropCounts[r]}',
    ];
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Elfogadva: $accepted · Eldobva: $dropped ($ratio)'),
          if (reasons.isNotEmpty) Text(reasons.join(' · ')),
          Text(
            'Táv (élő, becsült): ${snap.filter.distanceM.round()} m · '
            'Memóriában: ${snap.pendingCount} fix',
          ),
          if (snap.error != null)
            Text(snap.error!, style: TextStyle(color: scheme.error)),
        ],
      ),
    );
  }
}

class _FixList extends StatelessWidget {
  const _FixList({required this.recent});

  final List<RecordedFix> recent;

  @override
  Widget build(BuildContext context) {
    if (recent.isEmpty) {
      return const Center(child: Text('Még nincs fix.'));
    }
    final scheme = Theme.of(context).colorScheme;
    return ListView.builder(
      itemCount: recent.length,
      itemBuilder: (context, i) {
        // A legújabb legfelül.
        final r = recent[recent.length - 1 - i];
        final f = r.fix;
        final reason = r.dropReason;
        return ListTile(
          key: Key('fix-${f.tMs}'),
          dense: true,
          leading: Icon(
            reason == null ? Icons.check_circle : Icons.cancel,
            color: reason == null ? scheme.primary : scheme.error,
          ),
          title: Text(
            '${_time(f.tMs)}  ${f.latDeg.toStringAsFixed(5)}, '
            '${f.lonDeg.toStringAsFixed(5)}',
          ),
          subtitle: Text(
            'hAcc ${f.hAccM.toStringAsFixed(1)} m'
            '${f.speedMps == null ? '' : ' · ${f.speedMps!.toStringAsFixed(1)} m/s'}'
            '${reason == null ? '' : ' · ${dropReasonLabel(reason)}'}',
          ),
        );
      },
    );
  }

  static String _time(int tMs) {
    final d = DateTime.fromMillisecondsSinceEpoch(tMs);
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }
}
