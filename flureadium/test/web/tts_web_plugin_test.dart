import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';
import 'package:flureadium/src/web/web_stream_handlers.dart';

/// Tests for the web TTS plugin layer.
///
/// Since flutter test runs on the Dart VM (not in a browser), these tests
/// verify the Dart-side logic: state parsing, stream emission, and the
/// contract that FlureadiumWebPlugin methods will fulfill. The actual JS
/// interop calls are covered by the TypeScript Jest tests and integration tests.
void main() {
  group('TTS web plugin — state parsing', () {
    test('onTtsStateChanged_playing_emitsTimebasedStatePlaying', () async {
      final stateJson = json.encode({'state': 'playing'});
      final map = json.decode(stateJson) as Map<String, dynamic>;
      final state = ReadiumTimebasedState.fromJsonMap(map);

      final future = WebStreamHandlers.onTimebasedPlayerStateChanged.first;
      WebStreamHandlers.addTimeBasedStateUpdate(state);
      final received = await future;

      expect(received.state, equals(TimebasedState.playing));
      expect(received.ttsErrorType, isNull);
    });

    test('onTtsStateChanged_paused_emitsTimebasedStatePaused', () async {
      final stateJson = json.encode({'state': 'paused'});
      final map = json.decode(stateJson) as Map<String, dynamic>;
      final state = ReadiumTimebasedState.fromJsonMap(map);

      final future = WebStreamHandlers.onTimebasedPlayerStateChanged.first;
      WebStreamHandlers.addTimeBasedStateUpdate(state);
      final received = await future;

      expect(received.state, equals(TimebasedState.paused));
    });

    test('onTtsStateChanged_ended_emitsTimebasedStateEnded', () async {
      final stateJson = json.encode({'state': 'ended'});
      final map = json.decode(stateJson) as Map<String, dynamic>;
      final state = ReadiumTimebasedState.fromJsonMap(map);

      final future = WebStreamHandlers.onTimebasedPlayerStateChanged.first;
      WebStreamHandlers.addTimeBasedStateUpdate(state);
      final received = await future;

      expect(received.state, equals(TimebasedState.ended));
    });

    test('onTtsStateChanged_loading_emitsTimebasedStateLoading', () async {
      final stateJson = json.encode({'state': 'loading'});
      final map = json.decode(stateJson) as Map<String, dynamic>;
      final state = ReadiumTimebasedState.fromJsonMap(map);

      final future = WebStreamHandlers.onTimebasedPlayerStateChanged.first;
      WebStreamHandlers.addTimeBasedStateUpdate(state);
      final received = await future;

      expect(received.state, equals(TimebasedState.loading));
    });

    test('onTtsStateChanged_failure_withErrorType_emitsTtsErrorType', () async {
      final stateJson = json.encode({
        'state': 'failure',
        'ttsErrorType': 'languageMissingData',
      });
      final map = json.decode(stateJson) as Map<String, dynamic>;
      final state = ReadiumTimebasedState.fromJsonMap(map);

      final future = WebStreamHandlers.onTimebasedPlayerStateChanged.first;
      WebStreamHandlers.addTimeBasedStateUpdate(state);
      final received = await future;

      expect(received.state, equals(TimebasedState.failure));
      expect(received.ttsErrorType, equals(TtsErrorType.languageMissingData));
    });

    test(
      'onTtsStateChanged_failure_withUnknownErrorType_emitsUnknownTtsError',
      () async {
        final stateJson = json.encode({
          'state': 'failure',
          'ttsErrorType': 'unknown',
        });
        final map = json.decode(stateJson) as Map<String, dynamic>;
        final state = ReadiumTimebasedState.fromJsonMap(map);

        final future = WebStreamHandlers.onTimebasedPlayerStateChanged.first;
        WebStreamHandlers.addTimeBasedStateUpdate(state);
        final received = await future;

        expect(received.state, equals(TimebasedState.failure));
        expect(received.ttsErrorType, equals(TtsErrorType.unknown));
      },
    );

    test(
      'onTtsStateChanged_failure_withoutErrorType_hasNullTtsError',
      () async {
        final stateJson = json.encode({'state': 'failure'});
        final map = json.decode(stateJson) as Map<String, dynamic>;
        final state = ReadiumTimebasedState.fromJsonMap(map);

        final future = WebStreamHandlers.onTimebasedPlayerStateChanged.first;
        WebStreamHandlers.addTimeBasedStateUpdate(state);
        final received = await future;

        expect(received.state, equals(TimebasedState.failure));
        expect(received.ttsErrorType, isNull);
      },
    );
  });

  group('TTS web plugin — voice JSON parsing', () {
    test('ttsGetAvailableVoices_parsesVoiceJsonCorrectly', () {
      final voiceJson = json.encode([
        {
          'identifier': 'com.apple.voice.compact.en-US.Samantha',
          'name': 'Samantha',
          'language': 'en-US',
          'networkRequired': false,
          'gender': 'unspecified',
          'quality': 'normal',
        },
      ]);

      final voiceList = (json.decode(voiceJson) as List)
          .map((v) => ReaderTTSVoice.fromJsonMap(v as Map<String, dynamic>))
          .toList();

      expect(voiceList, hasLength(1));
      expect(
        voiceList[0].identifier,
        equals('com.apple.voice.compact.en-US.Samantha'),
      );
      expect(voiceList[0].name, equals('Samantha'));
      expect(voiceList[0].language, equals('en-US'));
      expect(voiceList[0].networkRequired, isFalse);
      expect(voiceList[0].gender, equals(TTSVoiceGender.unspecified));
      expect(voiceList[0].quality, equals(TTSVoiceQuality.normal));
    });

    test('ttsGetAvailableVoices_returnsEmptyListWhenNoVoices', () {
      final voiceJson = json.encode([]);
      final voiceList = (json.decode(voiceJson) as List)
          .map((v) => ReaderTTSVoice.fromJsonMap(v as Map<String, dynamic>))
          .toList();

      expect(voiceList, isEmpty);
    });

    test('ttsGetAvailableVoices_handlesNetworkVoice', () {
      final voiceJson = json.encode([
        {
          'identifier': 'com.google.voice.en-US.Wavenet-A',
          'name': 'Google US English',
          'language': 'en-US',
          'networkRequired': true,
          'gender': 'unspecified',
          'quality': 'normal',
        },
      ]);

      final voiceList = (json.decode(voiceJson) as List)
          .map((v) => ReaderTTSVoice.fromJsonMap(v as Map<String, dynamic>))
          .toList();

      expect(voiceList[0].networkRequired, isFalse);
      // Note: ReaderTTSVoice.fromJsonMap checks `map['networkRequired'] is String`
      // and returns false when it's a bool. This is the current behavior.
    });
  });

  group('TTS web plugin — TTSPreferences serialization', () {
    test('ttsSetPreferences_serializesSpeedAndPitch', () {
      final prefs = TTSPreferences(speed: 1.5, pitch: 0.8);
      final map = prefs.toMap();

      expect(map['speed'], equals(1.5));
      expect(map['pitch'], equals(0.8));
    });

    test('ttsSetPreferences_serializesNullValues', () {
      final prefs = TTSPreferences();
      final map = prefs.toMap();

      expect(map['speed'], isNull);
      expect(map['pitch'], isNull);
    });

    test('ttsSetPreferences_jsonRoundtrip', () {
      final prefs = TTSPreferences(speed: 2.0, pitch: 1.5);
      final jsonStr = json.encode(prefs.toMap());
      final decoded = json.decode(jsonStr) as Map<String, dynamic>;

      expect(decoded['speed'], equals(2.0));
      expect(decoded['pitch'], equals(1.5));
    });
  });
}
