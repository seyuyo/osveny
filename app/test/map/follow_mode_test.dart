import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/map/follow_mode.dart';

void main() {
  test('a kézi mozgatás minden fajtája kikapcsolja a követést', () {
    for (final s in [
      MapEventSource.dragStart,
      MapEventSource.onDrag,
      MapEventSource.dragEnd,
      MapEventSource.multiFingerGestureStart,
      MapEventSource.onMultiFinger,
      MapEventSource.multiFingerEnd,
      MapEventSource.flingAnimationController,
      MapEventSource.doubleTap,
      MapEventSource.doubleTapHold,
      MapEventSource.doubleTapZoomAnimationController,
      MapEventSource.scrollWheel,
      MapEventSource.cursorKeyboardRotation,
    ]) {
      expect(stopsFollowing(s), isTrue, reason: '$s');
    }
  });

  test('a programból jövő és a nem mozgató események nem', () {
    for (final s in [
      MapEventSource.mapController,
      MapEventSource.fitCamera,
      MapEventSource.custom,
      MapEventSource.nonRotatedSizeChange,
      MapEventSource.interactiveFlagsChanged,
      MapEventSource.tap,
      MapEventSource.secondaryTap,
      MapEventSource.longPress,
    ]) {
      expect(stopsFollowing(s), isFalse, reason: '$s');
    }
  });

  test('minden forrás besorolt (új flutter_map-érték ne maradjon ki)', () {
    // Ha a flutter_map új forrást vezet be, ez a teszt jelez, és dönteni kell.
    expect(
      MapEventSource.values.length,
      12 + 8,
      reason: 'a fenti két listával együtt minden érték le van fedve',
    );
  });
}
