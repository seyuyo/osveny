import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'map_library_controller.dart';
import 'map_library_screen.dart';
import 'map_widgets.dart';
import 'live_map.dart';

/// A Térkép fül. Térkép nélkül az importálást ajánlja fel; aktív térképnél a
/// térkép tölti ki a képernyőt, jobb felül a térképek kezelésének gombjával.
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
      MapLibraryPhase.ready => Stack(
        children: [
          Positioned.fill(child: LiveMap(map: active!)),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton.filledTonal(
                tooltip: 'Térképek kezelése',
                icon: const Icon(Icons.layers),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const MapLibraryScreen(),
                  ),
                ),
              ),
            ),
          ),
        ],
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
