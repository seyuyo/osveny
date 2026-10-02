import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_core/geo_core.dart';

import '../permissions/permission_flow.dart';
import '../permissions/permission_gate.dart';
import '../recording/recording_controller.dart';
import '../recording/track_profile.dart';

/// Rögzítés-vezérlés a térképen: indítás, szünet, folytatás, befejezés, és
/// félbemaradt túránál folytatás vagy lezárás.
///
/// Indítás és folytatás előtt a helyengedélyt ellenőrzi; ha nincs, a
/// meglévő engedélykaput nyitja meg külön oldalon, és engedély után folytatja.
class RecordingControls extends ConsumerWidget {
  const RecordingControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recState = ref.watch(
      recordingControllerProvider.select((s) => s.recState),
    );
    final controller = ref.read(recordingControllerProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hiba: $e')));
      }
    }

    Future<void> withPermission(Future<void> Function() action) async {
      if (await _ensurePermission(context, ref)) await run(action);
    }

    Future<void> confirmFinish() async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Befejezed a túrát?'),
          content: const Text(
            'A rögzítés lezárul, és ez a túra nem folytatható tovább.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Mégse'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Befejezés'),
            ),
          ],
        ),
      );
      if (ok == true) await run(controller.finish);
    }

    final finish = OutlinedButton.icon(
      onPressed: confirmFinish,
      icon: const Icon(Icons.stop),
      label: const Text('Befejezés'),
    );

    final Widget content = switch (recState) {
      RecState.idle || RecState.finished => FilledButton.icon(
        onPressed: () => withPermission(
          () => controller.start(profile: TrackProfile.precise),
        ),
        icon: const Icon(Icons.fiber_manual_record),
        label: const Text('Rögzítés'),
      ),
      RecState.recording => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => run(controller.pause),
            icon: const Icon(Icons.pause),
            label: const Text('Szünet'),
          ),
          const SizedBox(width: 8),
          finish,
        ],
      ),
      RecState.paused => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: () => withPermission(controller.resume),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Folytatás'),
          ),
          const SizedBox(width: 8),
          finish,
        ],
      ),
      RecState.interrupted => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Félbemaradt rögzítés'),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.icon(
                onPressed: () => withPermission(controller.resume),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Folytatás'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () => run(controller.finish),
                child: const Text('Lezárás'),
              ),
            ],
          ),
        ],
      ),
    };

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(28),
      elevation: 3,
      child: Padding(padding: const EdgeInsets.all(8), child: content),
    );
  }
}

/// Helyengedély a rögzítéshez. Ha már megvan, azonnal igaz; különben az
/// engedélykaput nyitja meg külön oldalon. Igaz, ha az engedély megvan.
Future<bool> _ensurePermission(BuildContext context, WidgetRef ref) async {
  await ref.read(permissionFlowProvider.notifier).check();
  if (ref.read(permissionFlowProvider).phase == PermissionPhase.ready) {
    return true;
  }
  if (!context.mounted) return false;
  final granted = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      // Fejléc a vissza gombbal: a felhasználó engedély nélkül is ki tud lépni.
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Helyengedély')),
        body: const PermissionGate(child: _PopWhenGranted()),
      ),
    ),
  );
  return granted ?? false;
}

/// A kapu ezt akkor mutatja, amikor az engedély megvan: azonnal visszalép,
/// és jelzi, hogy indulhat a rögzítés.
class _PopWhenGranted extends StatefulWidget {
  const _PopWhenGranted();

  @override
  State<_PopWhenGranted> createState() => _PopWhenGrantedState();
}

class _PopWhenGrantedState extends State<_PopWhenGranted> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
