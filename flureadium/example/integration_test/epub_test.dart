import 'package:flureadium/flureadium.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB', () {
    setUp(() {
      // EventChannels (reader-status, text-locator, error) are registered
      // lazily by the native plugin, only after openPublication is called.
      // Subscribing in initState before any publication opens throws
      // MissingPluginException. Suppress those so they don't count as
      // test failures — the widget-based assertions below are the real contract.
      final prev = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (details.exception is MissingPluginException) return;
        prev?.call(details);
      };
    });
    testWidgets('app auto-opens EPUB and shows reader widget', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('navigate left and right', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('←'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('→'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('Go To Saved does not crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Go To Saved'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('Load Only does not crash', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Load Only'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // no crash = pass
    });

    testWidgets('apply night theme preferences', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Night'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('apply decoration to current locator', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Highlight'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('TTS enable makes sentence nav buttons appear', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('TTS On'));
      await tester.pumpAndSettle(const Duration(seconds: 8));
      expect(find.text('Prev Sentence'), findsOneWidget);
      expect(find.text('Next Sentence'), findsOneWidget);
    });

    testWidgets('close publication removes reader widget', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Close'));
      // pumpAndSettle would never settle: after close, _publication is null
      // and CircularProgressIndicator keeps animating. Use pump instead.
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(ReadiumReaderWidget), findsNothing);
    });
  });
}
