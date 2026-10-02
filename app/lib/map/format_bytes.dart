/// Méret olvasható alakban: `12,3 MB` (tizedesvessző, 1024-es váltás).
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  if (bytes < 1024) return '$bytes B';

  const units = ['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unit = 0;
  // Kerekítés után ne maradjon `1024,0 KB`: a nagyobb egységre váltunk.
  while (double.parse(value.toStringAsFixed(1)) >= 1024 &&
      unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(1).replaceAll('.', ',')} ${units[unit]}';
}
