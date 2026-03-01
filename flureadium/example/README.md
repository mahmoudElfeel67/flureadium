# Flureadium Example

A minimal single-screen Flutter app that exercises all flureadium plugin capabilities. Suitable for build verification and integration tests on Android, iOS, and Web.

## Structure

```
lib/
└── main.dart           # Single file — ExampleApp + ReaderPage
integration_test/
├── launch_test.dart    # App launches without crash
├── epub_test.dart      # Open EPUB, navigate, preferences, highlight, close
├── audiobook_test.dart # Open audiobook, play/pause (native only)
└── webpub_test.dart    # Open remote WebPub manifest
test/
└── widget_test.dart    # Widget smoke test
```

The app auto-opens `moby_dick.epub` on launch. A control panel at the bottom lets you switch publication types, navigate, adjust preferences, control TTS and audio, and add highlights. Tap the reader to toggle the panel.

## Running the Example

```bash
cd flureadium/example
flutter run
```

## Running Integration Tests

```bash
# Android
flutter test integration_test/ -d <android_device_id>

# iOS
flutter test integration_test/ -d <ios_device_id>
```

> **Note:** `audiobook_test.dart` is tagged `native` and should be skipped on Web.

## Features Demonstrated

### Opening Publications

```dart
// From local file
final pub = await flureadium.openPublication('file:///path/to/book.epub');

// From URL with authentication
await flureadium.setCustomHeaders({'Authorization': 'Bearer token'});
final pub = await flureadium.openPublication('https://example.com/book.epub');
```

### Visual Reading

```dart
// Customize appearance
await flureadium.setEPUBPreferences(EPUBPreferences(
  fontFamily: 'Georgia',
  fontSize: 120,  // 1.2em
  backgroundColor: Color(0xFFF5E6D3),  // Sepia
  pageMargins: 0.1,  // 10% margins
));

// Navigate
await flureadium.goLeft();
await flureadium.goRight();
await flureadium.goToLocator(savedLocator);

// Jump to TOC entry
await flureadium.goByLink(tocLink, publication);
```

### Text-to-Speech

```dart
// Get available voices
final voices = await flureadium.ttsGetAvailableVoices();

// Enable TTS with preferences
await flureadium.ttsEnable(TTSPreferences(
  rate: 1.2,   // 20% faster
  pitch: 1.0,  // Normal pitch
));

// Select voice
await flureadium.ttsSetVoice(voices.first.id, 'en-US');

// Control playback
await flureadium.play(null);
await flureadium.pause();
await flureadium.next();  // Skip to next sentence
```

### Audiobook Playback

```dart
// Enable audio navigator
await flureadium.audioEnable(
  prefs: AudioPreferences(playbackRate: 1.0),
  fromLocator: savedPosition,
);

// Control playback
await flureadium.play(null);
await flureadium.audioSeekBy(Duration(seconds: 30));  // Skip forward

// Listen for position updates
flureadium.onTimebasedPlayerStateChanged.listen((state) {
  print('Position: ${state.currentOffset}');
  print('Duration: ${state.currentDuration}');
});
```

### Highlighting

```dart
// Add a highlight
await flureadium.applyDecorations('highlights', [
  ReaderDecoration(
    id: 'highlight-1',
    locator: selectedLocator,
    style: DecorationStyle.highlight,
  ),
]);

// Add a bookmark
await flureadium.applyDecorations('bookmarks', [
  ReaderDecoration(
    id: 'bookmark-1',
    locator: currentLocator,
    style: DecorationStyle.underline,
  ),
]);
```

### Saving Reading Position

```dart
// Listen for position changes
flureadium.onTextLocatorChanged.listen((locator) {
  // Save to persistent storage
  prefs.setString('lastPosition', jsonEncode(locator.toJson()));
});

// Restore position on next launch
final savedJson = prefs.getString('lastPosition');
if (savedJson != null) {
  final locator = Locator.fromJson(jsonDecode(savedJson));
  await flureadium.goToLocator(locator);
}
```

## Platform-Specific Setup

See the main [README](../README.md) for platform setup instructions.
