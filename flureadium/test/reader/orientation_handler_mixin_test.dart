import 'package:flutter/material.dart' as mq show Orientation;
import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';
import 'package:flureadium/src/reader/orientation_handler_mixin.dart';
import 'package:flureadium/reader_channel.dart';

// Test class that uses the mixin
class TestOrientationHandler with OrientationHandlerMixin {}

// Mock ReadiumReaderChannel for testing
class MockReaderChannel extends ReadiumReaderChannel {
  MockReaderChannel() : super('test-channel', onPageChanged: (_) {});

  final List<Map<String, dynamic>> goCallLog = [];

  @override
  Future<void> go(
    Locator locator, {
    bool animated = false,
    required bool isAudioBookWithText,
  }) async {
    goCallLog.add({
      'locator': locator,
      'animated': animated,
      'isAudioBookWithText': isAudioBookWithText,
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrientationHandlerMixin', () {
    late TestOrientationHandler handler;

    setUp(() {
      handler = TestOrientationHandler();
    });

    test('stores last orientation', () {
      expect(handler.lastOrientation, isNull);

      handler.lastOrientation = mq.Orientation.portrait;
      expect(handler.lastOrientation, equals(mq.Orientation.portrait));

      handler.lastOrientation = mq.Orientation.landscape;
      expect(handler.lastOrientation, equals(mq.Orientation.landscape));
    });

    test('initializes orientation on first call', () {
      handler.handleOrientationChange(
        currentOrientation: mq.Orientation.portrait,
        isReady: true,
        currentLocator: null,
        channel: null,
      );

      expect(handler.lastOrientation, equals(mq.Orientation.portrait));
    });

    test('does nothing when not ready', () {
      final mockChannel = MockReaderChannel();
      final testLocator = Locator(href: 'test.html', type: 'text/html');

      handler.handleOrientationChange(
        currentOrientation: mq.Orientation.landscape,
        isReady: false,
        currentLocator: testLocator,
        channel: mockChannel,
      );

      // Should initialize orientation but not navigate
      expect(handler.lastOrientation, equals(mq.Orientation.landscape));
      expect(mockChannel.goCallLog, isEmpty);
    });

    test('does nothing when orientation unchanged', () async {
      final mockChannel = MockReaderChannel();
      final testLocator = Locator(href: 'test.html', type: 'text/html');

      handler.lastOrientation = mq.Orientation.portrait;

      handler.handleOrientationChange(
        currentOrientation: mq.Orientation.portrait,
        isReady: true,
        currentLocator: testLocator,
        channel: mockChannel,
      );

      // Wait to ensure no navigation triggered
      await Future.delayed(const Duration(milliseconds: 600));

      expect(mockChannel.goCallLog, isEmpty);
    });

    test('navigates when orientation changes', () async {
      final mockChannel = MockReaderChannel();
      final testLocator = Locator(href: 'chapter1.html', type: 'text/html');

      handler.lastOrientation = mq.Orientation.portrait;

      handler.handleOrientationChange(
        currentOrientation: mq.Orientation.landscape,
        isReady: true,
        currentLocator: testLocator,
        channel: mockChannel,
      );

      // Wait for delayed navigation (500ms delay)
      await Future.delayed(const Duration(milliseconds: 600));

      expect(mockChannel.goCallLog, hasLength(1));
      expect(mockChannel.goCallLog[0]['locator'].href, equals('chapter1.html'));
      expect(mockChannel.goCallLog[0]['animated'], isFalse);
      expect(mockChannel.goCallLog[0]['isAudioBookWithText'], isFalse);
      expect(handler.lastOrientation, equals(mq.Orientation.landscape));
    });

    test('does not navigate when locator is null', () async {
      final mockChannel = MockReaderChannel();

      handler.lastOrientation = mq.Orientation.portrait;

      handler.handleOrientationChange(
        currentOrientation: mq.Orientation.landscape,
        isReady: true,
        currentLocator: null,
        channel: mockChannel,
      );

      await Future.delayed(const Duration(milliseconds: 600));

      expect(mockChannel.goCallLog, isEmpty);
      expect(handler.lastOrientation, equals(mq.Orientation.landscape));
    });

    test('does not navigate when channel is null', () async {
      final testLocator = Locator(href: 'test.html', type: 'text/html');

      handler.lastOrientation = mq.Orientation.portrait;

      handler.handleOrientationChange(
        currentOrientation: mq.Orientation.landscape,
        isReady: true,
        currentLocator: testLocator,
        channel: null,
      );

      await Future.delayed(const Duration(milliseconds: 600));

      // Should update orientation but not crash
      expect(handler.lastOrientation, equals(mq.Orientation.landscape));
    });
  });
}
