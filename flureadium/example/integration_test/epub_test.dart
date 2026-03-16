import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB', () {
    tearDown(() async {
      final flureadium = Flureadium();
      await flureadium.closePublication();
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

    testWidgets('close publication removes reader widget', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Close'));
      // pumpAndSettle would never settle: after close, _publication is null
      // and CircularProgressIndicator keeps animating. Use pump instead.
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(ReadiumReaderWidget), findsNothing);
    });

    testWidgets('Load Only does not crash', (tester) async {
      app.main();
      // Poll for the reader widget to appear — indicates openPublication() completed.
      // Ceiling 15s (was 10s fixed) for slow emulators.
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(ReadiumReaderWidget).evaluate().isNotEmpty) break;
      }
      await tester.tap(find.text('Load Only'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // no crash = pass
    });
  });
}
