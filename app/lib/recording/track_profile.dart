/// A helymeghatározás profilja; a túra rekordjában is rögzítjük (spec 3. fejezet).
enum TrackProfile {
  /// 1–2 s, nagy pontosság.
  precise,

  /// 5 s, 5 m távolság-szűrő.
  batterySaver,
}
