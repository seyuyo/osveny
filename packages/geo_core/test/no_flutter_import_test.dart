import 'dart:io';

import 'package:test/test.dart';

/// A geo_core tiszta Dart: nem importálhat Flutter-t vagy dart:ui-t.
void main() {
  final forbidden = RegExp(
    r'''^\s*(import|export)\s+['"](package:flutter(_[a-z]+)?/|dart:ui)''',
    multiLine: true,
  );

  test('nincs Flutter import a lib/ és test/ mappákban', () {
    final offenders = <String>[];
    for (final dir in ['lib', 'test']) {
      for (final entity in Directory(dir).listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          if (forbidden.hasMatch(entity.readAsStringSync())) {
            offenders.add(entity.path);
          }
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Tiltott Flutter-import: $offenders');
  });
}
