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
      await tester.pumpAndSettle(const Duration(seconds: 8));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('audio play changes button to Audio Pause', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await tester.pumpAndSettle(const Duration(seconds: 8));
      await tester.tap(find.text('Audio Play'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Audio Pause'), findsOneWidget);
    });

    testWidgets('audioSeekBy does not crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await tester.pumpAndSettle(const Duration(seconds: 8));
      await tester.tap(find.text('Audio Play'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('+30s'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.text('Audio Pause'), findsOneWidget);
    });

    testWidgets('pause then resume restores playback', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await tester.pumpAndSettle(const Duration(seconds: 8));
      await tester.tap(find.text('Audio Play'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Audio Pause'));
      await tester.pumpAndSettle();
      expect(find.text('Audio Resume'), findsOneWidget);

      await tester.tap(find.text('Audio Resume'));
      await tester.pumpAndSettle();
      expect(find.text('Audio Pause'), findsOneWidget);
    });
  });
}
