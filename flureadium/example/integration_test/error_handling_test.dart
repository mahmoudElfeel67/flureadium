import 'dart:io';

import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Error handling', () {
    late Flureadium flureadium;

    setUp(() {
      flureadium = Flureadium();
    });

    tearDown(() async {
      await flureadium.closePublication();
    });

    testWidgets('opening a corrupted file throws ReadiumException', (
      tester,
    ) async {
      // Write garbage bytes to a temp file disguised as an EPUB.
      final tmp = File(
        '${Directory.systemTemp.path}/'
        '${DateTime.now().millisecondsSinceEpoch}_corrupted.epub',
      );
      await tmp.writeAsBytes([0x00, 0x01, 0x02, 0x03]);

      // openPublication must surface a ReadiumException rather than
      // crashing with a codec error (IllegalArgumentException).
      expect(
        () => flureadium.openPublication(tmp.path),
        throwsA(isA<ReadiumException>()),
      );
    });

    testWidgets('opening a non-existent file throws ReadiumException', (
      tester,
    ) async {
      final bogusPath =
          '${Directory.systemTemp.path}/nonexistent_${DateTime.now().millisecondsSinceEpoch}.epub';

      expect(
        () => flureadium.openPublication(bogusPath),
        throwsA(isA<ReadiumException>()),
      );
    });
  });
}
