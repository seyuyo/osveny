import 'package:osveny/permissions/permission_gateway.dart';

/// Kézzel vezérelhető engedély-átjáró a tesztekhez.
class FakeGateway implements PermissionGateway {
  LocationAccess access = LocationAccess.denied;

  /// A felugró ablak eredménye, amit a `requestLocation` ad.
  LocationAccess afterRequest = LocationAccess.granted;
  bool notification = false;
  bool notificationAfterRequest = true;

  final calls = <String>[];

  @override
  Future<LocationAccess> locationAccess() async {
    calls.add('locationAccess');
    return access;
  }

  @override
  Future<LocationAccess> requestLocation() async {
    calls.add('requestLocation');
    access = afterRequest;
    return access;
  }

  @override
  Future<bool> notificationGranted() async => notification;

  @override
  Future<bool> requestNotification() async {
    calls.add('requestNotification');
    notification = notificationAfterRequest;
    return notification;
  }

  @override
  Future<void> openAppSettings() async => calls.add('openAppSettings');

  @override
  Future<void> openLocationSettings() async =>
      calls.add('openLocationSettings');
}
