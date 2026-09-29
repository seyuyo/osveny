import 'package:geo_core/geo_core.dart';
import 'package:test/test.dart';

// Egyenlítői vonal, 100 szakasz, szakaszonként 0,001 fok (~111 m).
final route = [for (var i = 0; i <= 100; i++) LatLon(0, i * 0.001)];

// Északi eltolás méterben -> fok (1 fok ~111 195 m).
double northDeg(double meters) => meters / 111195;

Fix at(int i, double lonDeg, double offsetM) =>
    Fix(tMs: i * 1000, latDeg: northDeg(offsetM), lonDeg: lonDeg, hAccM: 5);

OffRouteResult feed(
  OffRouteDetector d,
  OffRouteState s,
  List<double> offsetsM, {
  double startLon = 0.01,
}) {
  late OffRouteResult r;
  for (var i = 0; i < offsetsM.length; i++) {
    r = d.update(s, at(i, startLon + i * 0.0001, offsetsM[i]));
    s = r.state;
  }
  return r;
}

void main() {
  final detector = OffRouteDetector(route);

  test('a vonalon nincs riasztás', () {
    final r = feed(detector, const OffRouteState(), [0, 5, 10, 5, 0]);
    expect(r.state.isOffRoute, isFalse);
    expect(r.event, OffRouteEvent.none);
  });

  test('30 m-es párhuzamos ösvényen nincs riasztás', () {
    final r = feed(detector, const OffRouteState(), List.filled(30, 30));
    expect(r.state.isOffRoute, isFalse);
  });

  test('60 m-en pontosan a 3. ponton riaszt', () {
    var s = const OffRouteState();
    final events = <OffRouteEvent>[];
    for (var i = 0; i < 4; i++) {
      final r = detector.update(s, at(i, 0.01 + i * 0.0001, 60));
      events.add(r.event);
      s = r.state;
    }
    expect(events, [
      OffRouteEvent.none,
      OffRouteEvent.none,
      OffRouteEvent.alert,
      OffRouteEvent.none,
    ]);
    expect(s.isOffRoute, isTrue);
  });

  test('2 távoli pont, majd visszatérés: nincs riasztás', () {
    final r = feed(detector, const OffRouteState(), [60, 60, 10, 60, 60]);
    expect(r.state.isOffRoute, isFalse);
    expect(r.state.consecutiveFar, 2);
  });

  test('a 30-50 m közötti sáv nem villog', () {
    var s = feed(detector, const OffRouteState(), [70, 70, 70]).state;
    expect(s.isOffRoute, isTrue);
    // 40 m: még a riasztási küszöb alatt, de a feloldásin felül.
    for (var i = 0; i < 5; i++) {
      final r = detector.update(s, at(i, 0.011, 40));
      expect(r.event, OffRouteEvent.none);
      expect(r.state.isOffRoute, isTrue);
      s = r.state;
    }
    final r = detector.update(s, at(9, 0.011, 25));
    expect(r.event, OffRouteEvent.cleared);
    expect(r.state.isOffRoute, isFalse);
  });

  test('újabb riasztás feloldás után újra 3 pontot igényel', () {
    var s = feed(detector, const OffRouteState(), [70, 70, 70, 10]).state;
    expect(s.isOffRoute, isFalse);
    final r = detector.update(s, at(9, 0.011, 70));
    expect(r.event, OffRouteEvent.none);
  });

  test('az ablakon kívüli ugrásnál teljes keresésre esik vissza', () {
    // Az állapot a route elején, a fix a 80. szakasz közelében.
    final r = detector.update(
      const OffRouteState(lastSegment: 2),
      at(0, 0.0805, 5),
    );
    expect(r.distanceM, lessThan(10));
    expect(r.state.lastSegment, 80);
    expect(r.state.isOffRoute, isFalse);
  });

  test('távoli pont nem viszi el az ablakot', () {
    final r = detector.update(
      const OffRouteState(lastSegment: 10),
      at(0, 0.05, 500),
    );
    expect(r.distanceM, closeTo(500, 1));
    expect(r.state.lastSegment, 10);
  });

  test('oda-vissza útvonalon a visszaúton sincs téves riasztás', () {
    final out = [for (var i = 0; i <= 50; i++) LatLon(0, i * 0.001)];
    final back = [for (var i = 49; i >= 0; i--) LatLon(0, i * 0.001)];
    final d = OffRouteDetector([...out, ...back]);
    var s = const OffRouteState();
    for (var i = 0; i <= 50; i++) {
      s = d.update(s, at(i, i * 0.001, 0)).state;
    }
    for (var i = 49; i >= 0; i--) {
      final r = d.update(s, at(100 - i, i * 0.001, 5));
      expect(r.state.isOffRoute, isFalse);
      s = r.state;
    }
  });

  test('túl rövid vonal: nincs eredmény, állapot változatlan', () {
    final d = OffRouteDetector([const LatLon(0, 0)]);
    const s = OffRouteState(consecutiveFar: 1);
    final r = d.update(s, at(0, 0, 500));
    expect(r.distanceM, isNull);
    expect(r.event, OffRouteEvent.none);
    expect(r.state.consecutiveFar, 1);
  });

  test('egyedi küszöbök', () {
    final d = OffRouteDetector(
      route,
      const OffRouteConfig(alertDistanceM: 20, clearDistanceM: 10),
    );
    final r = feed(d, const OffRouteState(), [25, 25, 25]);
    expect(r.event, OffRouteEvent.alert);
  });
}
