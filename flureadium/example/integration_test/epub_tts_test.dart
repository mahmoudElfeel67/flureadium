@Tags(['native'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB TTS', () {
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
  });
}
