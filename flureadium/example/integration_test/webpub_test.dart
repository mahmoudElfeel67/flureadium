import 'package:flureadium/flureadium.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    final prev = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exception is MissingPluginException) return;
      prev?.call(details);
    };
  });

  testWidgets('opens remote WebPub manifest and shows reader widget', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.text('Open WebPub'));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(find.byType(ReadiumReaderWidget), findsOneWidget);
  });
}
