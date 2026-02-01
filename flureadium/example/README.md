# Flureadium Example

This example demonstrates all major features of the Flureadium plugin.

## Running the Example

```bash
cd flureadium/example
flutter run
```

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

## State Management

The example uses BLoC pattern for state management. Key blocs:

- `PublicationBloc`: Manages publication loading/closing
- `PlayerControlsBloc`: Handles playback state
- `TextSettingsBloc`: Manages visual preferences
- `TTSSettingsBloc`: Manages TTS configuration

## Platform-Specific Setup

See the main [README](../README.md) for platform setup instructions.
