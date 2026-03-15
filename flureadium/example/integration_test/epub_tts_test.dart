@Tags(['native'])
library;

import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB TTS', () {
    tearDown(() async {
      final flureadium = Flureadium();
      await flureadium.stop();
      await flureadium.closePublication();
    });

    testWidgets('TTS enable makes sentence nav buttons appear', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('TTS On'));
      // pumpAndSettle would never settle once TTS starts sending timebased state
      // updates that rebuild the widget. Use pump with a fixed duration instead.
      // Android TTS cold-start on API 28 emulator can exceed 30s; 60s is safe.
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Prev Sentence'), findsOneWidget);
      expect(find.text('Next Sentence'), findsOneWidget);
    });

    testWidgets('ttsCanSpeak returns true — TTS On enables without snackbar', (
      tester,
    ) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('TTS Off'), findsOneWidget);
    });

    testWidgets('tts pause then resume restores playing state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Pause TTS'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Resume TTS'), findsOneWidget);
      await tester.tap(find.text('Resume TTS'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Pause TTS'), findsOneWidget);
    });

    testWidgets('tts next sentence does not crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Next Sentence'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('TTS Off'), findsOneWidget);
    });

    testWidgets('tts previous sentence does not crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Prev Sentence'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('TTS Off'), findsOneWidget);
    });

    testWidgets('tts voice cycling does not crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      final voiceButton = find.textContaining('Voice');
      expect(voiceButton, findsOneWidget);
      await tester.tap(voiceButton);
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('TTS Off'), findsOneWidget);
    });

    testWidgets('tts off hides sentence nav buttons', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Prev Sentence'), findsOneWidget);
      await tester.tap(find.text('TTS Off'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Prev Sentence'), findsNothing);
      expect(find.text('TTS On'), findsOneWidget);
    });
  });
}
