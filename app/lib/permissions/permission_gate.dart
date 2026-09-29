import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'permission_flow.dart';

/// A rögzítő képernyő kapuja: amíg nincs helyengedély, magyarázó vagy
/// hibaképernyőt mutat, utána a [child]-ot.
class PermissionGate extends ConsumerStatefulWidget {
  const PermissionGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends ConsumerState<PermissionGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(permissionFlowProvider.notifier).check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A beállításokból visszatérve újraellenőrzünk. Megadott engedélynél nem:
  /// rögzítés közben a képernyő ne váltson engedély-nézetre.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (ref.read(permissionFlowProvider).phase == PermissionPhase.ready) return;
    ref.read(permissionFlowProvider.notifier).check();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(permissionFlowProvider);
    final flow = ref.read(permissionFlowProvider.notifier);

    switch (snapshot.phase) {
      case PermissionPhase.checking:
      case PermissionPhase.requesting:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case PermissionPhase.ready:
        return Column(
          children: [
            if (!snapshot.notificationGranted) const _NotificationWarning(),
            Expanded(child: widget.child),
          ],
        );
      case PermissionPhase.needsRationale:
        return _Message(
          icon: Icons.my_location,
          title: 'Helyzet a túra rögzítéséhez',
          body:
              'Az Ösvény a pontos helyzetedet használja a megtett út '
              'rögzítéséhez, és csak amíg a rögzítés fut. Rögzítés közben az '
              'app előtér-szolgáltatásként működik, ezt állandó értesítés '
              'jelzi; így a képernyő lezárása után is folytatódik a felvétel. '
              'Az adataid a telefonodon maradnak.',
          actionLabel: 'Tovább',
          onAction: flow.request,
        );
      case PermissionPhase.denied:
        return _Message(
          icon: Icons.location_disabled,
          title: 'Nincs helyengedély',
          body:
              'Enélkül nem tudunk rögzíteni: az app nem látja, merre jársz. '
              'Az engedélyt bármikor megadhatod.',
          actionLabel: 'Újra megpróbálom',
          onAction: flow.request,
        );
      case PermissionPhase.deniedForever:
        return _Message(
          icon: Icons.location_disabled,
          title: 'A helyengedély le van tiltva',
          body:
              'Az engedélyt a telefon beállításaiban adhatod meg: '
              'Alkalmazások › Ösvény › Engedélyek › Hely › „Csak az app '
              'használata közben”. Utána térj vissza ide.',
          actionLabel: 'Beállítások megnyitása',
          onAction: flow.openSettings,
        );
      case PermissionPhase.serviceOff:
        return _Message(
          icon: Icons.location_off,
          title: 'A helyszolgáltatás ki van kapcsolva',
          body:
              'Helyszolgáltatás nélkül nincs pozíció. Kapcsold be a telefon '
              'gyorsbeállításaiban vagy a helybeállításokban, aztán térj '
              'vissza ide.',
          actionLabel: 'Helybeállítások megnyitása',
          onAction: flow.openSettings,
        );
    }
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String actionLabel;
  final Future<void> Function() onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationWarning extends StatelessWidget {
  const _NotificationWarning();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.tertiaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Az értesítések le vannak tiltva, ezért a „Rögzítés folyamatban” '
            'jelzés nem látszik. A felvétel ettől még működik.',
            style: TextStyle(color: scheme.onTertiaryContainer),
          ),
        ),
      ),
    );
  }
}
