import 'package:flutter/foundation.dart';
import 'package:geo_core/geo_core.dart';
import 'package:geolocator/geolocator.dart';

import 'location_source.dart';
import 'track_profile.dart';

/// `Position` → nyers [Fix]. A platform 0.0-t ad, ha egy adat nincs; ezt a
/// `has*` jelzők alapján `null`-lá alakítjuk, hogy a hiányzó magasság vagy
/// sebesség ne látsszon valódi nullának. A `heading` menetirány (course over
/// ground), nem iránytű.
Fix fixFromPosition(Position p) => Fix(
  tMs: p.timestamp.millisecondsSinceEpoch,
  latDeg: p.latitude,
  lonDeg: p.longitude,
  altM: p.hasAltitude ? p.altitude : null,
  hAccM: p.accuracy,
  vAccM: p.hasAltitudeAccuracy ? p.altitudeAccuracy : null,
  speedMps: p.hasSpeed ? p.speed : null,
  bearingDeg: p.hasHeading ? p.heading : null,
);

/// A profil helymeghatározási beállításai (spec 3. fejezet). Androidon
/// előtér-szolgáltatással és wake lockkal: enélkül a rendszer alvó
/// állapotban a fixeket csomagban kézbesítené, és rések lennének a
/// nyomvonalban. Háttér-helyengedélyt nem kérünk.
LocationSettings locationSettingsFor(
  TrackProfile profile, {
  TargetPlatform? platform,
}) {
  final precise = profile == TrackProfile.precise;
  final accuracy = precise ? LocationAccuracy.best : LocationAccuracy.high;
  final distanceFilter = precise ? 0 : 5;

  if ((platform ?? defaultTargetPlatform) != TargetPlatform.android) {
    return LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
  }
  return AndroidSettings(
    accuracy: accuracy,
    distanceFilter: distanceFilter,
    intervalDuration: Duration(seconds: precise ? 1 : 5),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: 'Ösvény',
      notificationText: 'Rögzítés folyamatban',
      notificationChannelName: 'Túra rögzítése',
      enableWakeLock: true,
      setOngoing: true,
    ),
  );
}

/// A `geolocator` csomag helyforrása. Az engedélyeket a hívó (a
/// `PermissionFlow`) intézi a rögzítés indítása előtt.
class GeolocatorLocationSource implements LocationSource {
  const GeolocatorLocationSource();

  @override
  Stream<Fix> fixes(TrackProfile profile) => Geolocator.getPositionStream(
    locationSettings: locationSettingsFor(profile),
  ).map(fixFromPosition);
}
