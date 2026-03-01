import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium/flureadium.dart';
import 'package:flureadium/reader_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channelName = 'test-reader-channel';
  late ReadiumReaderChannel channel;
  final List<MethodCall> log = [];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), (
          call,
        ) async {
          log.add(call);
          return null;
        });
    channel = ReadiumReaderChannel(channelName, onPageChanged: (_) {});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel(channelName), null);
  });

  group('applyDecorations', () {
    test('encodes empty decoration list without throwing', () async {
      await channel.applyDecorations('highlights', []);

      expect(log, hasLength(1));
      expect(log.first.method, equals('applyDecorations'));
    });

    test('encodes non-empty decoration list without throwing', () async {
      final decoration = ReaderDecoration(
        id: 'test-id',
        locator: Locator(href: 'chapter1.xhtml', type: 'application/xhtml+xml'),
        style: ReaderDecorationStyle(
          style: DecorationStyle.highlight,
          tint: const Color(0xFFFFFF00),
        ),
      );

      await channel.applyDecorations('highlights', [decoration]);

      expect(log, hasLength(1));
      expect(log.first.method, equals('applyDecorations'));
    });

    test('passes a List (not MappedListIterable) to the codec', () async {
      final decorations = [
        ReaderDecoration(
          id: 'id-1',
          locator: Locator(
            href: 'chapter1.xhtml',
            type: 'application/xhtml+xml',
          ),
          style: ReaderDecorationStyle(
            style: DecorationStyle.highlight,
            tint: const Color(0xFFFFFF00),
          ),
        ),
        ReaderDecoration(
          id: 'id-2',
          locator: Locator(
            href: 'chapter2.xhtml',
            type: 'application/xhtml+xml',
          ),
          style: ReaderDecorationStyle(
            style: DecorationStyle.underline,
            tint: const Color(0xFF0000FF),
          ),
        ),
      ];

      await channel.applyDecorations('highlights', decorations);

      final args = log.first.arguments as List;
      final decorationList = args[1];
      expect(decorationList, isA<List>());
      expect(decorationList, hasLength(2));
    });

    test('passes the group id as first argument', () async {
      await channel.applyDecorations('my-group', []);

      final args = log.first.arguments as List;
      expect(args[0], equals('my-group'));
    });

    test('each decoration map contains required fields', () async {
      final locator = Locator(
        href: 'chapter1.xhtml',
        type: 'application/xhtml+xml',
        locations: Locations(position: 1, totalProgression: 0.5),
        text: LocatorText(highlight: 'some text'),
      );
      final decoration = ReaderDecoration(
        id: 'highlight-xyz',
        locator: locator,
        style: ReaderDecorationStyle(
          style: DecorationStyle.highlight,
          tint: const Color(0xFFFFFF00),
        ),
      );

      await channel.applyDecorations('highlights', [decoration]);

      final args = log.first.arguments as List;
      final decorationList = args[1] as List;
      final decoMap = decorationList[0] as Map;

      expect(decoMap['id'], equals('highlight-xyz'));
      expect(decoMap['locator'], isA<Map>());
      expect(decoMap['style'], isA<Map>());
    });
  });
}
