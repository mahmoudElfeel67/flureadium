import 'package:flureadium_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void _mockEventChannel(String channelName) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(MethodChannel(channelName), (call) async {
        return null;
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockEventChannel('dev.mulev.flureadium/reader-status');
    _mockEventChannel('dev.mulev.flureadium/text-locator');
    _mockEventChannel('dev.mulev.flureadium/error');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.mulev.flureadium/main'),
          (call) async => null,
        );
  });

  testWidgets('app renders MaterialApp with ReaderPage', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ReaderPage), findsOneWidget);
  });
}
