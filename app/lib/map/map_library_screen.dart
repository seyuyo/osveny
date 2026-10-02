import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'format_bytes.dart';
import 'map_library_controller.dart';
import 'map_store.dart';
import 'map_widgets.dart';

/// A telepített térképek kezelése: lista, aktív térkép választása, törlés,
/// új térkép importálása.
class MapLibraryScreen extends ConsumerWidget {
  const MapLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapLibraryControllerProvider);
    final controller = ref.read(mapLibraryControllerProvider.notifier);
    final importing = state.phase == MapLibraryPhase.importing;

    return Scaffold(
      appBar: AppBar(title: const Text('Térképek')),
      floatingActionButton: importing
          ? null
          : FloatingActionButton.extended(
              onPressed: controller.importMap,
              icon: const Icon(Icons.file_open),
              label: const Text('Térkép importálása'),
            ),
      body: Column(
        children: [
          if (state.error != null)
            MapErrorBanner(
              message: state.error!,
              onClose: controller.clearError,
            ),
          if (importing) MapImportProgress(progress: state.progress),
          Expanded(
            child: switch (state.phase) {
              MapLibraryPhase.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              _ when state.maps.isEmpty => const MapEmptyState(),
              _ => ListView(
                children: [
                  for (final m in state.maps)
                    _MapTile(
                      map: m,
                      active: m.name == state.active?.name,
                      onSelect: () => controller.setActive(m.name),
                      onDelete: () => _confirmDelete(context, controller, m),
                    ),
                ],
              ),
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MapLibraryController controller,
    InstalledMap map,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Törlöd a térképet?'),
        content: Text(
          '${map.name} (${formatBytes(map.sizeBytes)}) törlődik a '
          'telefonról. Később újra importálhatod.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mégse'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Törlés'),
          ),
        ],
      ),
    );
    if (ok == true) await controller.delete(map.name);
  }
}

class _MapTile extends StatelessWidget {
  const _MapTile({
    required this.map,
    required this.active,
    required this.onSelect,
    required this.onDelete,
  });

  final InstalledMap map;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        active ? Icons.check_circle : Icons.radio_button_unchecked,
        color: active ? scheme.primary : null,
      ),
      title: Text(map.name),
      subtitle: Text(
        '${formatBytes(map.sizeBytes)} · '
        'zoom ${map.info.minZoom}–${map.info.maxZoom}',
      ),
      trailing: IconButton(
        tooltip: 'Törlés',
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      onTap: onSelect,
    );
  }
}
