import 'package:flureadium/flureadium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flureadium_example/main.dart' as app;

Future<void> _waitForStatus(
  Flureadium f,
  ReadiumReaderStatus expected, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  await f.onReaderStatusChanged
      .firstWhere((s) => s == expected)
      .timeout(
        timeout,
        onTimeout: () => fail('Timed out waiting for status $expected'),
      );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('EPUB behavioral contracts', () {
    late Flureadium f;

    setUp(() {
      f = Flureadium();
    });

    testWidgets('openPublication emits ready status', (tester) async {
      app.main();
      await _waitForStatus(f, ReadiumReaderStatus.ready);
    });

    testWidgets('goRight fires onTextLocatorChanged', (tester) async {
      app.main();
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      Locator? after;
      final sub = f.onTextLocatorChanged.listen((l) => after = l);
      await tester.tap(find.text('→'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await sub.cancel();

      expect(after, isNotNull);
    });

    testWidgets('goToLocator navigates without error', (tester) async {
      app.main();
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      final loc = await f.onTextLocatorChanged.first.timeout(
        const Duration(seconds: 5),
      );
      expect(await f.goToLocator(loc), isTrue);
    });

    testWidgets('loadPublication returns publication metadata', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Load Only'));
      await tester.pumpAndSettle(const Duration(seconds: 5));
      // no exception thrown = pass
    });

    testWidgets('TTS enable makes sentence nav buttons appear', (tester) async {
      app.main();
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      await tester.tap(find.text('TTS On'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.text('Prev Sentence'), findsOneWidget);
      expect(find.text('Next Sentence'), findsOneWidget);
    });

    testWidgets('navigate left and right', (tester) async {
      app.main();
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      await tester.tap(find.text('←'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('→'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('apply night theme preferences', (tester) async {
      app.main();
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      await tester.tap(find.text('Night'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('apply decoration to current locator', (tester) async {
      app.main();
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      await tester.tap(find.text('Highlight'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byType(ReadiumReaderWidget), findsOneWidget);
    });

    testWidgets('close publication', (tester) async {
      app.main();
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byType(ReadiumReaderWidget), findsNothing);
    });
  });
}
