# Integration Tests

Integration tests run the example app on a real device or simulator and assert widget state and UI contracts.

## Test Files

| File | Platforms | What it asserts |
|---|---|---|
| `launch_test.dart` | All | App starts, MaterialApp renders |
| `epub_test.dart` | All | EPUB auto-opens, navigation/prefs/highlight don't crash, TTS sentence nav buttons appear, close removes widget |
| `audiobook_test.dart` | Android, iOS (`@Tags(['native'])`) | Audiobook opens, play changes button label, seek doesn't crash, pause/resume button labels cycle correctly |
| `webpub_test.dart` | All | Remote WebPub manifest opens, `ReadiumReaderWidget` present |

## Note on EventChannel streams

The native plugin registers EventChannel stream handlers (`reader-status`, `text-locator`, `timebased-state`, etc.) lazily — only after `openPublication` is called. Because `initState` subscribes to these channels before any publication is opened, the subscriptions throw `MissingPluginException` at startup. Tests therefore use widget-based assertions (widget presence, button label changes) rather than direct stream subscriptions.

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
# Android — connected device or running emulator
cd flureadium/example
flutter test integration_test/ -d <device-id>

# Android — exclude audiobook tests (web-incompatible)
flutter test integration_test/ -d <device-id> --exclude-tags native

# iOS simulator
cd flureadium/example
flutter test integration_test/ -d "iPhone 15"

# Web (Chrome) — copy JS file first, then run excluding native-only tests
cd flureadium/example
dart run flureadium:copy_js_file web/
flutter test integration_test/ -d chrome --exclude-tags native

# Run a single test file
flutter test integration_test/epub_test.dart -d <device-id>
```

## CI

Integration tests run automatically on every merge to `main` via `.github/workflows/integration-test.yml`. Pull requests only run build verification and widget tests — integration tests are not triggered on PRs because emulator jobs are slow and expensive.

The CI workflow runs three jobs in parallel: Android (emulator API 33), iOS (simulator), and Web (Chrome). The iOS job runs all tests including `@Tags(['native'])` audiobook tests. Android and Web jobs exclude native-only tests via `--exclude-tags native`.
