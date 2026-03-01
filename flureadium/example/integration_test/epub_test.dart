import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB', () {
    testWidgets('opens bundled EPUB and shows reader widget', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open EPUB'));
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

    testWidgets('close publication', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ReadiumReaderWidget), findsNothing);
    });
  });
}
