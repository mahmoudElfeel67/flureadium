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
      // pumpAndSettle can hang when a PlatformView (WebView) keeps scheduling
      // frames. Poll for the reader widget with bounded pump loops instead.
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('TTS On'));
      // Poll every second — iOS TTS starts in ~5s; Android emulator can take ~30s.
      // Ceiling kept at 60s to match the original safe upper bound.
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Prev Sentence').evaluate().isNotEmpty) break;
      }
      expect(find.text('Prev Sentence'), findsOneWidget);
      expect(find.text('Next Sentence'), findsOneWidget);
      // Let in-flight native play() settle before tearDown cancels the coroutine.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('ttsCanSpeak returns true — TTS On enables without snackbar', (
      tester,
    ) async {
      app.main();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      expect(find.text('TTS Off'), findsOneWidget);
    });

    testWidgets('tts pause then resume restores playing state', (tester) async {
      app.main();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('TTS On'));
      // Poll for 'Pause TTS' — requires _ttsPlaybackState == playing, which
      // arrives via the onTimebasedPlayerStateChanged stream after play().
      for (var i = 0; i < 60; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Pause TTS').evaluate().isNotEmpty) break;
      }
      expect(find.text('Pause TTS'), findsOneWidget);
      await tester.tap(find.text('Pause TTS'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Resume TTS').evaluate().isNotEmpty) break;
      }
      expect(find.text('Resume TTS'), findsOneWidget);
      await tester.tap(find.text('Resume TTS'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Pause TTS').evaluate().isNotEmpty) break;
      }
      expect(find.text('Pause TTS'), findsOneWidget);
      // Let in-flight native resume/play() settle before tearDown cancels the coroutine.
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('tts next sentence does not crash', (tester) async {
      app.main();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Next Sentence'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('TTS Off'), findsOneWidget);
    });

    testWidgets('tts previous sentence does not crash', (tester) async {
      app.main();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.text('Prev Sentence'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('TTS Off'), findsOneWidget);
    });

    testWidgets('tts voice cycling does not crash', (tester) async {
      app.main();
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
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
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
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
