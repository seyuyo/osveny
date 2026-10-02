import 'package:flutter/material.dart';

/// Hibaüzenet-sáv elrejthető üzenettel.
class MapErrorBanner extends StatelessWidget {
  const MapErrorBanner({
    super.key,
    required this.message,
    required this.onClose,
  });

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            IconButton(
              tooltip: 'Üzenet elrejtése',
              icon: Icon(Icons.close, color: scheme.onErrorContainer),
              onPressed: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

/// Import közbeni folyamatjelző; a [progress] `null`, ha a méret ismeretlen.
class MapImportProgress extends StatelessWidget {
  const MapImportProgress({super.key, required this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    final percent = progress == null ? '' : ' ${(progress! * 100).round()}%';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Importálás…$percent',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 12),
          const Text(
            'A térkép az app saját tárhelyére másolódik; nagy fájlnál ez '
            'eltarthat egy ideig.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Üres állapot: nincs importált térkép.
class MapEmptyState extends StatelessWidget {
  const MapEmptyState({super.key, this.action});

  /// Az importgomb; a kezelőoldalon a lebegő gomb váltja ki, ott `null`.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Még nincs térkép',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Az Ösvény offline térképet használ: egy .pmtiles fájlt kell '
              'importálnod (Protomaps-kivágat). A fájl a telefonodon marad, '
              'a térkép internet nélkül is működik.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
