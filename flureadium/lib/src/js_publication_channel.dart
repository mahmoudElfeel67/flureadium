import 'dart:js_interop';
import 'package:flutter/services.dart';
import 'package:flureadium_platform_interface/flureadium_platform_interface.dart';

@JS('ReadiumReader')
extension type ReadiumReader._(JSObject _) implements JSObject {
  external ReadiumReader();
  external JSPromise openPublication(
    JSString publicationURL,
    JSString pubId,
    JSString? initialPositionJson,
    JSString preferencesJson,
  );
  external JSPromise getPublication(JSString link);
  external JSPromise goTo(JSString location);
  external void goLeft();
  external void goRight();
  external void closePublication();
  external JSPromise getResource(JSString linkString, JSBoolean? asBytes);
  external void setEPUBPreferences(JSString newPreferencesString);
  external JSBoolean get isNavigatorReady;

  // TTS API
  external void ttsEnable(JSString? prefsJson);
  external void ttsPlay(JSString? fromLocatorJson);
  external void ttsPause();
  external void ttsResume();
  external void ttsStop();
  external void ttsNext();
  external void ttsPrevious();
  external JSString ttsGetAvailableVoices();
  external void ttsSetVoice(JSString voiceId, JSString? language);
  external void ttsSetPreferences(JSString prefsJson);
  external JSBoolean ttsCanSpeak();
}

@JS()
external set updateTextLocator(JSFunction f);

@JS()
external set updateReaderStatus(JSFunction f);

@JS()
external set updateTtsState(JSFunction f);

class JsPublicationChannel {
  static final ReadiumReader _readiumReader = ReadiumReader();

  Future<void> openPublication(
    String publicationURL, {
    required String pubId,
    required String initialPreferences,
    String? initialPositionJson,
  }) async {
    try {
      await _readiumReader
          .openPublication(
            publicationURL.toJS,
            pubId.toJS,
            initialPositionJson?.toJS,
            initialPreferences.toJS,
          )
          .toDart;
    } on Object catch (jsError, stackTrace) {
      String errorString = jsError.toString();
      int? statusCode = _extractStatusCode(errorString);
      String nativeCode = _convertToNativeCode(statusCode);
      throw PlatformException(
        code: nativeCode,
        message: errorString,
        details: statusCode,
        stacktrace: stackTrace.toString(),
      );
    }
  }

  Future<String> getPublication(String link) async {
    try {
      final publicationPromise = _readiumReader.getPublication(link.toJS);
      // ignore: invalid_runtime_check_with_js_interop_types
      final publicationString = await publicationPromise.toDart as String;

      return publicationString;
    } on Object catch (jsError, stackTrace) {
      String errorString = jsError.toString();
      int? statusCode = _extractStatusCode(errorString);
      String nativeCode = _convertToNativeCode(statusCode);

      throw PlatformException(
        code: nativeCode,
        message: errorString,
        details: statusCode,
        stacktrace: stackTrace.toString(),
      );
    }
  }

  static int? _extractStatusCode(String errorMessage) {
    final regex = RegExp(r'HTTP status code (\d{3})');
    final match = regex.firstMatch(errorMessage);
    return match != null ? int.parse(match.group(1)!) : null;
  }

  static String _convertToNativeCode(int? statusCode) {
    switch (statusCode) {
      case 415:
        return '0';
      case 404:
        return '1';
      case 400:
        return '2';
      case 403:
        return '3';
      case 500:
        return '4';
      case 401:
        return '5';
      default:
        return '';
    }
  }

  static Future<void> goToLocation(String locationHref) async {
    try {
      if (locationHref.startsWith('/')) {
        locationHref = locationHref.substring(1);
      }
      await _readiumReader.goTo(locationHref.toJS).toDart;
    } on Object catch (jsError, stackTrace) {
      String errorString = jsError.toString();
      int? statusCode = _extractStatusCode(errorString);
      String nativeCode = _convertToNativeCode(statusCode);

      throw PlatformException(
        code: nativeCode,
        message: errorString,
        details: statusCode,
        stacktrace: stackTrace.toString(),
      );
    }
  }

  static void goLeft() {
    _readiumReader.goLeft();
  }

  static void goRight() {
    _readiumReader.goRight();
  }

  void closePublication() {
    _readiumReader.closePublication();
  }

  Future<String> getResource(String link, {bool? asBytes}) async {
    try {
      final resourceJS = _readiumReader.getResource(link.toJS, asBytes?.toJS);
      // ignore: invalid_runtime_check_with_js_interop_types
      var resourceString = await resourceJS.toDart as String;
      return resourceString;
    } on Object catch (jsError, stackTrace) {
      String errorString = jsError.toString();
      int? statusCode = _extractStatusCode(errorString);
      String nativeCode = _convertToNativeCode(statusCode);

      throw PlatformException(
        code: nativeCode,
        message: errorString,
        details: statusCode,
        stacktrace: stackTrace.toString(),
      );
    }
  }

  // TTS API
  static void ttsEnable(String? prefsJson) {
    _readiumReader.ttsEnable(prefsJson?.toJS);
  }

  static void ttsPlay(String? fromLocatorJson) {
    _readiumReader.ttsPlay(fromLocatorJson?.toJS);
  }

  static void ttsPause() {
    _readiumReader.ttsPause();
  }

  static void ttsResume() {
    _readiumReader.ttsResume();
  }

  static void ttsStop() {
    _readiumReader.ttsStop();
  }

  static void ttsNext() {
    _readiumReader.ttsNext();
  }

  static void ttsPrevious() {
    _readiumReader.ttsPrevious();
  }

  static String ttsGetAvailableVoices() {
    return _readiumReader.ttsGetAvailableVoices().toDart;
  }

  static void ttsSetVoice(String voiceId, String? language) {
    _readiumReader.ttsSetVoice(voiceId.toJS, language?.toJS);
  }

  static void ttsSetPreferences(String prefsJson) {
    _readiumReader.ttsSetPreferences(prefsJson.toJS);
  }

  static bool ttsCanSpeak() {
    return _readiumReader.ttsCanSpeak().toDart;
  }

  Future<void> setEPUBPreferences(String newPreferencesString) async {
    try {
      final isReady = _readiumReader.isNavigatorReady.toDart;
      if (isReady) {
        _readiumReader.setEPUBPreferences(newPreferencesString.toJS);
      } else {
        R2Log.w('ReadiumReader is not ready yet, skipping setEPUBPreferences');
      }
    } on Object catch (jsError, stackTrace) {
      String errorString = jsError.toString();
      int? statusCode = _extractStatusCode(errorString);
      String nativeCode = _convertToNativeCode(statusCode);

      throw PlatformException(
        code: nativeCode,
        message: errorString,
        details: statusCode,
        stacktrace: stackTrace.toString(),
      );
    }
  }
}
