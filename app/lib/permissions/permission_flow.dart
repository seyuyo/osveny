import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'permission_gateway.dart';

/// Az engedélykérési folyamat fázisai.
enum PermissionPhase {
  checking,

  /// Még nem kértük (vagy egyszer megtagadta): először magyarázunk.
  needsRationale,
  requesting,
  ready,

  /// A felhasználó megtagadta; újra megpróbálható.
  denied,

  /// „Ne kérdezz újra": a beállításokban adható meg.
  deniedForever,

  /// A telefon helyszolgáltatása ki van kapcsolva.
  serviceOff,
}

@immutable
class PermissionSnapshot {
  const PermissionSnapshot({
    this.phase = PermissionPhase.checking,
    this.notificationGranted = false,
  });

  final PermissionPhase phase;

  /// Az értesítés-engedély hiánya nem blokkol: a rögzítés így is fut, csak a
  /// „Rögzítés folyamatban" értesítés nem látszik.
  final bool notificationGranted;
}

final permissionFlowProvider =
    NotifierProvider<PermissionFlow, PermissionSnapshot>(PermissionFlow.new);

/// Engedélykérés a rögzítés indítása előtt. A felugró ablak csak a magyarázó
/// képernyő után jön; a `check` sosem kér engedélyt.
class PermissionFlow extends Notifier<PermissionSnapshot> {
  PermissionGateway get _gateway => ref.read(permissionGatewayProvider);

  @override
  PermissionSnapshot build() => const PermissionSnapshot();

  /// Az állapot felmérése kérés nélkül (induláskor, és az appba visszatérve).
  Future<void> check() async {
    if (state.phase == PermissionPhase.requesting) return;
    await _apply(await _gateway.locationAccess(), askNotification: false);
  }

  /// A helyengedély és az értesítés kérése (a magyarázó képernyő után).
  Future<void> request() async {
    if (state.phase == PermissionPhase.requesting ||
        state.phase == PermissionPhase.ready) {
      return;
    }
    state = const PermissionSnapshot(phase: PermissionPhase.requesting);
    await _apply(await _gateway.requestLocation(), askNotification: true);
  }

  /// Megnyitja a megfelelő rendszerbeállítást; a hívó az appba visszatérve
  /// újra `check`-el.
  Future<void> openSettings() async {
    switch (state.phase) {
      case PermissionPhase.deniedForever:
        await _gateway.openAppSettings();
      case PermissionPhase.serviceOff:
        await _gateway.openLocationSettings();
      case PermissionPhase.checking:
      case PermissionPhase.needsRationale:
      case PermissionPhase.requesting:
      case PermissionPhase.ready:
      case PermissionPhase.denied:
        break;
    }
  }

  Future<void> _apply(
    LocationAccess access, {
    required bool askNotification,
  }) async {
    switch (access) {
      case LocationAccess.granted:
        var notification = await _gateway.notificationGranted();
        if (askNotification && !notification) {
          notification = await _gateway.requestNotification();
        }
        if (!ref.mounted) return;
        state = PermissionSnapshot(
          phase: PermissionPhase.ready,
          notificationGranted: notification,
        );
      case LocationAccess.denied:
        state = PermissionSnapshot(
          phase: askNotification
              ? PermissionPhase.denied
              : PermissionPhase.needsRationale,
        );
      case LocationAccess.deniedForever:
        state = const PermissionSnapshot(phase: PermissionPhase.deniedForever);
      case LocationAccess.serviceOff:
        state = const PermissionSnapshot(phase: PermissionPhase.serviceOff);
    }
  }
}
