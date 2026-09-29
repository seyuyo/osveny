/// Egy nyers GPS-mérés (fix). Fok a koordinátákra, méter a távolságokra.
class Fix {
  const Fix({
    required this.tMs,
    required this.latDeg,
    required this.lonDeg,
    this.altM,
    this.hAccM = 0,
    this.vAccM,
    this.speedMps,
    this.bearingDeg,
  });

  final int tMs;
  final double latDeg;
  final double lonDeg;
  final double? altM;
  final double hAccM;
  final double? vAccM;
  final double? speedMps;
  final double? bearingDeg;

  @override
  bool operator ==(Object other) =>
      other is Fix &&
      other.tMs == tMs &&
      other.latDeg == latDeg &&
      other.lonDeg == lonDeg &&
      other.altM == altM &&
      other.hAccM == hAccM &&
      other.vAccM == vAccM &&
      other.speedMps == speedMps &&
      other.bearingDeg == bearingDeg;

  @override
  int get hashCode => Object.hash(
    tMs,
    latDeg,
    lonDeg,
    altM,
    hAccM,
    vAccM,
    speedMps,
    bearingDeg,
  );

  @override
  String toString() => 'Fix(t=$tMs, $latDeg, $lonDeg, alt=$altM, hAcc=$hAccM)';
}
