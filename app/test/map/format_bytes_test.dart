import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/map/format_bytes.dart';

void main() {
  test('bájt, KB, MB, GB — tizedesvesszővel', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(1023), '1023 B');
    expect(formatBytes(1024), '1,0 KB');
    expect(formatBytes(1536), '1,5 KB');
    expect(formatBytes(5 * 1024 * 1024), '5,0 MB');
    expect(formatBytes((12.34 * 1024 * 1024).round()), '12,3 MB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3,0 GB');
  });

  test('a határon a nagyobb egység jön, nem 1024,0', () {
    // 1048575 bájt = 1023,999 KB, ami kerekítve 1024,0 KB lenne.
    expect(formatBytes(1024 * 1024 - 1), '1,0 MB');
  });

  test('negatív érték nem lehet: 0 B', () {
    expect(formatBytes(-5), '0 B');
  });
}
