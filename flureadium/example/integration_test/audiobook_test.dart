@Tags(['native'])
library;

import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Audiobook', () {
    tearDown(() async {
      final flureadium = Flureadium();
      await flureadium.stop();
      await flureadium.closePublication();
    });

    testWidgets('opens audiobook and shows reader widget', (tester) async {
      app.main();
      // app.main() auto-opens an EPUB. CircularProgressIndicator prevents
      // pumpAndSettle from settling, so poll for the reader widget instead.
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('Open AudioBook'));
      // Fixed wait for the publication switch — the ReadiumReaderWidget is
      // already visible from the EPUB so there is no widget-level signal to
      // poll for. 10s covers asset extraction + native openPublication().
      await tester.pump(const Duration(seconds: 10));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('audio play changes button to Audio Pause', (tester) async {
      app.main();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('Open AudioBook'));
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.text('Audio Play'));
      // audioEnable() + play() + setState; poll for the button (max 15s).
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Audio Pause').evaluate().isNotEmpty) break;
      }
      expect(find.text('Audio Pause'), findsOneWidget);
    });

    testWidgets('audioSeekBy does not crash', (tester) async {
      app.main();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('Open AudioBook'));
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.text('Audio Play'));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Audio Pause').evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('+30s'));
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Audio Pause'), findsOneWidget);
    });

    testWidgets('pause then resume restores playback', (tester) async {
      app.main();
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('Open AudioBook'));
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.text('Audio Play'));
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Audio Pause').evaluate().isNotEmpty) break;
      }

      await tester.tap(find.text('Audio Pause'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Audio Resume').evaluate().isNotEmpty) break;
      }
      expect(find.text('Audio Resume'), findsOneWidget);

      await tester.tap(find.text('Audio Resume'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.text('Audio Pause').evaluate().isNotEmpty) break;
      }
      expect(find.text('Audio Pause'), findsOneWidget);
    });
  });
}
