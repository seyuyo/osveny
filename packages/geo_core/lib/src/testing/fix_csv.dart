import '../fix.dart';

/// A nyers nyomvonal-CSV fejléce (a debug export és a visszajátszás formátuma).
const String fixCsvHeader = 'tMs,lat,lon,alt,hAcc,vAcc,speed';

/// CSV szöveg fixekké alakítása. Az üres mező `null`. A fejléc elhagyható.
/// Hibás sornál [FormatException] a sor számával.
List<Fix> parseFixCsv(String csv) {
  final fixes = <Fix>[];
  final lines = csv.split(RegExp(r'\r?\n'));
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    if (line.isEmpty) continue;
    if (i == 0 && line.startsWith('tMs')) continue;

    final cols = line.split(',');
    if (cols.length != 7) {
      throw FormatException(
        '${i + 1}. sor: 7 oszlop kell, ${cols.length} van.',
        line,
      );
    }

    double? number(String s, String name, {bool required = false}) {
      final t = s.trim();
      if (t.isEmpty) {
        if (required) {
          throw FormatException('${i + 1}. sor: hiányzó $name.', line);
        }
        return null;
      }
      final v = double.tryParse(t);
      if (v == null) {
        throw FormatException('${i + 1}. sor: hibás $name: "$t".', line);
      }
      return v;
    }

    final tMs = int.tryParse(cols[0].trim());
    if (tMs == null) {
      throw FormatException('${i + 1}. sor: hibás tMs: "${cols[0]}".', line);
    }
    fixes.add(
      Fix(
        tMs: tMs,
        latDeg: number(cols[1], 'lat', required: true)!,
        lonDeg: number(cols[2], 'lon', required: true)!,
        altM: number(cols[3], 'alt'),
        hAccM: number(cols[4], 'hAcc', required: true)!,
        vAccM: number(cols[5], 'vAcc'),
        speedMps: number(cols[6], 'speed'),
      ),
    );
  }
  return fixes;
}

/// Fixek CSV-vé alakítása; a `parseFixCsv` inverze (a bearing nem szerepel).
String fixesToCsv(Iterable<Fix> fixes) {
  final b = StringBuffer(fixCsvHeader)..write('\n');
  String opt(double? v) => v == null ? '' : '$v';
  for (final f in fixes) {
    b.write(
      '${f.tMs},${f.latDeg},${f.lonDeg},${opt(f.altM)},${f.hAccM},'
      '${opt(f.vAccM)},${opt(f.speedMps)}\n',
    );
  }
  return b.toString();
}
