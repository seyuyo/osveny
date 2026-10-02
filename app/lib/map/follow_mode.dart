import 'package:flutter_map/flutter_map.dart';

/// Az esemény a felhasználó kézi mozdulatából jön-e (húzás, kétujjas mozdulat,
/// lendítés, dupla koppintásos nagyítás, görgő, billentyűzetes forgatás). Ilyenkor a
/// követő mód kikapcsol (spec M3.3). A programból jövő mozgás (követés, kezdő
/// illesztés) és a koppintás nem.
bool stopsFollowing(MapEventSource source) => _userMoves.contains(source);

const _userMoves = {
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
};
