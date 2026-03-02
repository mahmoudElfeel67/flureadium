import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB', () {
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
      // pump (not pumpAndSettle) to wait a fixed 10s for auto-open openPublication()
      // to complete before calling loadPublication(). pumpAndSettle returns after the
      // timeout regardless because CircularProgressIndicator never settles. At 10s the
      // native Readium open is safely done (widget appears at ~8s on emulator API 28).
      await tester.pump(const Duration(seconds: 10));
      await tester.tap(find.text('Load Only'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // no crash = pass
    });
  });
}
