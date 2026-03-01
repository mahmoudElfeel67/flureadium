@Tags(['native'])
library;

import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Audiobook', () {
    testWidgets('opens audiobook and shows reader widget', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('enables audio navigator and plays', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Audio Play'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Audio Pause'), findsOneWidget);
    });

    testWidgets('pause audio', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Audio Play'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Audio Pause'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Audio Play'), findsOneWidget);
    });
  });
}
