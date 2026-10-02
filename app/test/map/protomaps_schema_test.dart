import 'package:flutter_test/flutter_test.dart';
import 'package:osveny/map/protomaps_schema.dart';

void main() {
  group('schemaFromMetadata', () {
    test('4.x verzió: v4', () {
      expect(schemaFromMetadata({'version': '4.15.2'}), ProtomapsSchema.v4);
      expect(schemaFromMetadata({'version': '4.0.0'}), ProtomapsSchema.v4);
    });

    test('3.x verzió: v3', () {
      expect(schemaFromMetadata({'version': '3.8.0'}), ProtomapsSchema.v3);
      expect(schemaFromMetadata({'version': '3'}), ProtomapsSchema.v3);
    });

    test('későbbi főverzió: v4 (a legújabb ismert séma)', () {
      expect(schemaFromMetadata({'version': '5.1.0'}), ProtomapsSchema.v4);
    });

    test('számként megadott verzió is jó', () {
      expect(schemaFromMetadata({'version': 3}), ProtomapsSchema.v3);
      expect(schemaFromMetadata({'version': 4.2}), ProtomapsSchema.v4);
    });

    test('hiányzó vagy értelmezhetetlen metaadat: v4 (a mostani buildek)', () {
      expect(schemaFromMetadata(null), ProtomapsSchema.v4);
      expect(schemaFromMetadata(<Object?>[1, 2]), ProtomapsSchema.v4);
      expect(schemaFromMetadata(<String, Object?>{}), ProtomapsSchema.v4);
      expect(schemaFromMetadata({'version': ''}), ProtomapsSchema.v4);
      expect(schemaFromMetadata({'version': 'x.y'}), ProtomapsSchema.v4);
      expect(schemaFromMetadata({'version': null}), ProtomapsSchema.v4);
    });
  });
}
