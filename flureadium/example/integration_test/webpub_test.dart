import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('opens remote WebPub manifest and shows reader widget', (
    tester,
  ) async {
    app.main();
    // pumpAndSettle would never settle: CircularProgressIndicator keeps
    // animating while the EPUB auto-open runs (and fails on web). Use pump
    // with a fixed duration instead.
    await tester.pump(const Duration(seconds: 2));
    await tester.tap(find.text('Open WebPub'));
    // Wait for the async JS fetch of the remote WebPub manifest to complete.
    await tester.pump(const Duration(seconds: 10));
    expect(find.byType(ReadiumReaderWidget), findsOneWidget);
  });
}
