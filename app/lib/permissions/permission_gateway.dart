import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart'
    hide openAppSettings;

/// A helyengedély és a helyszolgáltatás együttes állapota.
enum LocationAccess {
  /// Használat közbeni (vagy tágabb) engedély megvan, és a helyszolgáltatás be van kapcsolva.
  granted,

  /// Még nem kértük, vagy megtagadta; újra lehet kérni.
  denied,

  /// „Ne kérdezz újra": csak a rendszerbeállításokban adható meg.
  deniedForever,

  /// Az engedély megvan, de a telefon helyszolgáltatása ki van kapcsolva.
  serviceOff,
}

/// A platform engedély-API-jai egy interfész mögött, hogy a folyamat
/// fake-kel tesztelhető legyen. Háttér-helyengedélyt nem kérünk.
abstract interface class PermissionGateway {
  /// Az állapot lekérdezése, felugró ablak nélkül.
  Future<LocationAccess> locationAccess();

  /// A használat közbeni helyengedély kérése (rendszer-párbeszédablak).
  Future<LocationAccess> requestLocation();

  Future<bool> notificationGranted();
  Future<bool> requestNotification();

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

final permissionGatewayProvider = Provider<PermissionGateway>(
  (ref) => const PlatformPermissionGateway(),
);

/// `geolocator` a helyhez, `permission_handler` az értesítéshez.
class PlatformPermissionGateway implements PermissionGateway {
  const PlatformPermissionGateway();

  @override
  Future<LocationAccess> locationAccess() async =>
      _resolve(await Geolocator.checkPermission());

  @override
  Future<LocationAccess> requestLocation() async =>
      _resolve(await Geolocator.requestPermission());

  Future<LocationAccess> _resolve(LocationPermission permission) async {
    switch (permission) {
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationAccess.denied;
      case LocationPermission.deniedForever:
        return LocationAccess.deniedForever;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return await Geolocator.isLocationServiceEnabled()
            ? LocationAccess.granted
            : LocationAccess.serviceOff;
    }
  }

  @override
  Future<bool> notificationGranted() async =>
      (await Permission.notification.status).isGranted;

  @override
  Future<bool> requestNotification() async =>
      (await Permission.notification.request()).isGranted;

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }
}
