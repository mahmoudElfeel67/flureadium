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

void _mockMainChannel({bool ttsCanSpeak = true}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.mulev.flureadium/main'),
        (call) async {
          if (call.method == 'ttsCanSpeak') return ttsCanSpeak;
          return null;
        },
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _mockEventChannel('dev.mulev.flureadium/reader-status');
    _mockEventChannel('dev.mulev.flureadium/text-locator');
    _mockEventChannel('dev.mulev.flureadium/error');
    _mockEventChannel('dev.mulev.flureadium/timebased-state');
    _mockMainChannel();
  });

  testWidgets('app renders MaterialApp with ReaderPage', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(ReaderPage), findsOneWidget);
  });

  testWidgets('tts_can_speak_false_shows_not_supported_snackbar', (
    tester,
  ) async {
    _mockMainChannel(ttsCanSpeak: false);
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();
    await tester.tap(find.text('TTS On'));
    await tester.pump();
    expect(
      find.text('TTS is not supported for this publication'),
      findsOneWidget,
    );
  });

  testWidgets('tts_speed_slider_not_visible_initially', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();
    expect(find.byType(Slider), findsNothing);
  });

  testWidgets('tts_pause_button_not_visible_initially', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();
    expect(find.text('Pause TTS'), findsNothing);
  });
}
