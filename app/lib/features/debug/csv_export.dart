import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A nyers CSV kiadása a felhasználónak; a tesztben cserélhető.
typedef CsvExporter =
    Future<void> Function({required String fileName, required String csv});

final csvExporterProvider = Provider<CsvExporter>((ref) => shareCsv);

/// Ideiglenes fájlba írja a CSV-t, és megnyitja a rendszer megosztó lapját.
Future<void> shareCsv({required String fileName, required String csv}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(csv);
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path, mimeType: 'text/csv')],
      subject: fileName,
    ),
  );
}
