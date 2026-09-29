import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:osveny/recording/geolocator_location_source.dart';
import 'package:osveny/recording/track_profile.dart';

void main() {
  final ts = DateTime.fromMillisecondsSinceEpoch(1700000123456, isUtc: true);

  Position position({
    bool hasAltitude = true,
    bool hasAltitudeAccuracy = true,
    bool hasSpeed = true,
    bool hasHeading = true,
  }) => Position(
    longitude: 19.05,
    latitude: 47.55,
    timestamp: ts,
    accuracy: 6.5,
    altitude: 210.25,
    altitudeAccuracy: 9,
    heading: 270,
    headingAccuracy: 5,
    speed: 1.4,
    speedAccuracy: 0.5,
    hasAccuracy: true,
    hasAltitude: hasAltitude,
    hasAltitudeAccuracy: hasAltitudeAccuracy,
    hasHeading: hasHeading,
    hasSpeed: hasSpeed,
  );

  group('fixFromPosition', () {
    test('minden mező átkerül; az idő epoch ms', () {
      final f = fixFromPosition(position());
      expect(f.tMs, 1700000123456);
      expect(f.latDeg, 47.55);
      expect(f.lonDeg, 19.05);
      expect(f.altM, 210.25);
      expect(f.hAccM, 6.5);
      expect(f.vAccM, 9);
      expect(f.speedMps, 1.4);
      expect(f.bearingDeg, 270);
    });

    test('a hiányzó adat null, nem a platform 0.0 kitöltése', () {
      final f = fixFromPosition(
        position(
          hasAltitude: false,
          hasAltitudeAccuracy: false,
          hasSpeed: false,
          hasHeading: false,
        ),
      );
      expect(f.altM, isNull);
      expect(f.vAccM, isNull);
      expect(f.speedMps, isNull);
      expect(f.bearingDeg, isNull);
    });
  });

  group('locationSettingsFor (Android)', () {
    AndroidSettings settings(TrackProfile p) =>
        locationSettingsFor(p, platform: TargetPlatform.android)
            as AndroidSettings;

    test('Pontos: 1 s, legjobb pontosság, nincs távolság-szűrő', () {
      final s = settings(TrackProfile.precise);
      expect(s.intervalDuration, const Duration(seconds: 1));
      expect(s.accuracy, LocationAccuracy.best);
      expect(s.distanceFilter, 0);
    });

    test('Akkukímélő: 5 s, 5 m távolság-szűrő', () {
      final s = settings(TrackProfile.batterySaver);
      expect(s.intervalDuration, const Duration(seconds: 5));
      expect(s.distanceFilter, 5);
    });

    test('mindkét profil előtér-szolgáltatással és wake lockkal fut', () {
      for (final p in TrackProfile.values) {
        final n = settings(p).foregroundNotificationConfig;
        expect(n, isNotNull, reason: '$p');
        expect(n!.enableWakeLock, isTrue, reason: 'képernyőzár alatt is kell');
        expect(n.setOngoing, isTrue);
        expect(n.notificationTitle, isNotEmpty);
      }
    });
  });

  test('nem Androidon sima LocationSettings, előtér-szolgáltatás nélkül', () {
    final s = locationSettingsFor(
      TrackProfile.precise,
      platform: TargetPlatform.iOS,
    );
    expect(s, isNot(isA<AndroidSettings>()));
    expect(s.accuracy, LocationAccuracy.best);
  });
}
