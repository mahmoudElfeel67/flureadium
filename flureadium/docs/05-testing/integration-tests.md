# Integration Tests

Integration tests run the example app on a real device or simulator and assert widget state and UI contracts.

## Test Files

| File | Platforms | What it asserts |
|---|---|---|
| `all_tests.dart` | All | Combined runner — imports all four files below into a single compilation unit |
| `launch_test.dart` | All | App starts, MaterialApp renders |
| `epub_test.dart` | All | EPUB auto-opens, navigation/prefs/highlight don't crash, TTS sentence nav buttons appear, close removes widget |
| `audiobook_test.dart` | Android, iOS (`@Tags(['native'])`) | Audiobook opens, play changes button label, seek doesn't crash, pause/resume button labels cycle correctly |
| `webpub_test.dart` | All | Remote WebPub manifest opens, `ReadiumReaderWidget` present |

> **Always use `all_tests.dart` when running the full suite.** Running `flutter test integration_test/` without specifying a file compiles and installs each test file as a separate APK batch. On mobile this reinstalls the app mid-run, killing in-progress tests and causing "did not complete" failures for any tests that were running when the new APK landed.

## Note on EventChannel streams

### Android

All four EventChannels (`reader-status`, `error`, `text-locator`, `timebased-state`) are
registered eagerly in `ReadiumReader.attach()` at activity attach time — before
`openPublication` is called.

### iOS

`reader-status`, `text-locator`, and `error` EventChannels are registered lazily inside
`ReadiumReaderView.init()`, which is called from `_onPlatformViewCreated` in the Flutter
widget layer. This means the native handlers do not exist until the platform view has been
created and added to the widget tree.

The example app subscribes to streams only after `_onPlatformViewCreated` has fired (detected
via `FlureadiumPlatform.instance.currentReaderWidget != null` with a 50ms polling loop, 5s
timeout). Subscribing before this point causes `MissingPluginException`, which permanently
closes `receiveBroadcastStream()`'s internal `StreamController`, silently dropping all
subsequent events on that channel.

### Integration test implications

Integration tests use widget-based assertions (widget presence, button label changes) because
streams deliver events asynchronously. Test timing does not guarantee stream delivery within
`pump()` windows. The decoration test specifically relies on `_locator` being populated within
a 5-second `pumpAndSettle` window — this works because the subscription guard ensures the
channel is active before the reader starts emitting locator events.

## Prerequisites

### Android
- Flutter SDK (stable channel)
- Android SDK with a connected device or AVD at API level ≥ 29

### iOS
- Flutter SDK (stable channel)
- Xcode ≥ 15
- CocoaPods
- A connected device or booted simulator (iOS ≥ 16)

### Web
- Flutter SDK (stable channel)
- Chrome or Chromium installed

## Running Tests Locally

```bash
# Android — full suite (one build, one install, no mid-run APK swap)
cd flureadium/example
flutter test integration_test/all_tests.dart -d <device-id>

# Android — exclude audiobook tests (native-only)
flutter test integration_test/all_tests.dart -d <device-id> --exclude-tags native

# iOS simulator — full suite
cd flureadium/example
flutter test integration_test/all_tests.dart -d "iPhone 15"

# Web (Chrome) — copy JS file first, then run excluding native-only tests
cd flureadium/example
dart run flureadium:copy_js_file web/
flutter test integration_test/all_tests.dart -d chrome --exclude-tags native

# Run a single test file (for focused debugging)
flutter test integration_test/epub_test.dart -d <device-id>
```

## CI

Integration tests run automatically on every merge to `main` via `.github/workflows/integration-test.yml`. Pull requests only run build verification and widget tests — integration tests are not triggered on PRs because emulator jobs are slow and expensive.

The CI workflow runs three jobs in parallel: Android (emulator API 33), iOS (simulator), and Web (Chrome). All jobs use `integration_test/all_tests.dart` as the entry point. The iOS job runs all tests including `@Tags(['native'])` audiobook tests. Android and Web jobs exclude native-only tests via `--exclude-tags native` — audiobook tests require ExoPlayer and MediaSession initialization which adds several minutes per test, making them impractical for automated CI. Run them manually against a connected device or emulator.
