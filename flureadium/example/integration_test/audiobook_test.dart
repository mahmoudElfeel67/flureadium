@Tags(['native'])
library;

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

  group('Audiobook behavioral contracts', () {
    late Flureadium f;

    setUp(() {
      f = Flureadium();
    });

    testWidgets('audio play emits timebased state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await _waitForStatus(f, ReadiumReaderStatus.ready);

      await tester.tap(find.text('Audio Play'));
      final state = await f.onTimebasedPlayerStateChanged.first.timeout(
        const Duration(seconds: 8),
      );
      expect(state.currentOffset, isNotNull);
    });

    testWidgets('audioSeekBy advances currentOffset', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      await tester.tap(find.text('Audio Play'));

      final before = await f.onTimebasedPlayerStateChanged.first.timeout(
        const Duration(seconds: 8),
      );

      await tester.tap(find.text('+30s'));

      final after = await f.onTimebasedPlayerStateChanged
          .firstWhere((s) => s.currentOffset != before.currentOffset)
          .timeout(const Duration(seconds: 5));

      expect(
        after.currentOffset!.inSeconds,
        greaterThan((before.currentOffset?.inSeconds ?? 0) + 20),
      );
    });

    testWidgets('pause then resume restores playback', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.text('Open AudioBook'));
      await _waitForStatus(f, ReadiumReaderStatus.ready);
      await tester.tap(find.text('Audio Play'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Audio Pause'));
      await tester.pumpAndSettle();
      expect(find.text('Audio Resume'), findsOneWidget);

      await tester.tap(find.text('Audio Resume'));
      await tester.pumpAndSettle();
      expect(find.text('Audio Pause'), findsOneWidget);
    });
  });
}
