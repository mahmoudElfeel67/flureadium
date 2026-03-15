@Tags(['web'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

/// Web TTS integration tests.
///
/// Packed EPUB files cannot be served via HTTP URL (web limitation), so the
/// default auto-open of moby_dick.epub fails silently. Each test taps
/// "Open WebPub" first to load a remote manifest that the web navigator
/// can handle.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB TTS — Web', () {
    testWidgets('ttsCanSpeak returns true — TTS On enables without snackbar', (
      tester,
    ) async {
      app.main();
      // Wait for initial UI (EPUB auto-open fails on web, that's expected).
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Open WebPub'));
      // Wait for remote manifest fetch + navigator initialization.
      await tester.pump(const Duration(seconds: 15));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('TTS Off'), findsOneWidget);
    });

    testWidgets('ttsGetAvailableVoices — voice counter shown after enable', (
      tester,
    ) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Open WebPub'));
      await tester.pump(const Duration(seconds: 15));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 5));
      expect(find.textContaining('Voice'), findsOneWidget);
    });

    testWidgets('tts enable then stop does not throw', (tester) async {
      app.main();
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('Open WebPub'));
      await tester.pump(const Duration(seconds: 15));
      await tester.tap(find.text('TTS On'));
      await tester.pump(const Duration(seconds: 5));
      await tester.tap(find.text('TTS Off'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('TTS On'), findsOneWidget);
    });
  });
}
