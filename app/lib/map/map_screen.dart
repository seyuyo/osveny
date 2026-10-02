import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'format_bytes.dart';
import 'map_library_controller.dart';
import 'map_library_screen.dart';
import 'map_widgets.dart';

/// A Térkép fül. Térkép nélkül az importálást ajánlja fel; a térkép
/// megjelenítése az M3.2 lépésben jön, addig az aktív térképet összegzi.
class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapLibraryControllerProvider);
    final controller = ref.read(mapLibraryControllerProvider.notifier);
    final active = state.active;

    final Widget body = switch (state.phase) {
      MapLibraryPhase.loading => const Center(
        child: CircularProgressIndicator(),
      ),
      MapLibraryPhase.importing => Center(
        child: MapImportProgress(progress: state.progress),
      ),
      MapLibraryPhase.ready when active == null => MapEmptyState(
        action: FilledButton.icon(
          onPressed: controller.importMap,
          icon: const Icon(Icons.file_open),
          label: const Text('Térkép importálása'),
        ),
      ),
      MapLibraryPhase.ready => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aktív térkép: ${active!.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${formatBytes(active.sizeBytes)} · '
              'zoom ${active.info.minZoom}–${active.info.maxZoom}',
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MapLibraryScreen(),
                ),
              ),
              child: const Text('Térképek kezelése'),
            ),
          ],
        ),
      ),
    };

    return Scaffold(
      key: const Key('map-tab'),
      body: SafeArea(
        child: Column(
          children: [
            if (state.error != null)
              MapErrorBanner(
                message: state.error!,
                onClose: controller.clearError,
              ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}
