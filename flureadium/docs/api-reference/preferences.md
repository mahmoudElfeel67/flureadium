# Preferences

Flureadium provides three preference classes for customizing the reader experience: EPUB visual preferences, TTS preferences, and Audio preferences.

## EPUBPreferences

Controls visual appearance of EPUB content.

**Source:** [reader_epub_preferences.dart](../../../flureadium_platform_interface/lib/src/reader/reader_epub_preferences.dart)

### Constructor

```dart
EPUBPreferences({
  required String fontFamily,
  required int fontSize,
  required double? fontWeight,
  required bool? verticalScroll,
  required Color? backgroundColor,
  required Color? textColor,
  double? pageMargins,
})
```

### Properties

#### fontFamily

**Type:** `String` (required)

The font family name. Use system fonts or fonts bundled with the EPUB.

```dart
fontFamily: 'Georgia'
fontFamily: 'Helvetica'
fontFamily: 'OpenDyslexic'
```

#### fontSize

**Type:** `int` (required)

Font size as a percentage. 100 = normal size (1em).

```dart
fontSize: 80   // 0.8em (smaller)
fontSize: 100  // 1.0em (normal)
fontSize: 120  // 1.2em (larger)
fontSize: 150  // 1.5em (much larger)
```

#### fontWeight

**Type:** `double?`

Font weight value. Common values:

```dart
fontWeight: 300  // Light
fontWeight: 400  // Normal
fontWeight: 500  // Medium
fontWeight: 700  // Bold
```

#### verticalScroll

**Type:** `bool?`

Whether to use vertical scrolling instead of pagination.

```dart
verticalScroll: false  // Paginated (default)
verticalScroll: true   // Continuous scroll
```

#### backgroundColor

**Type:** `Color?`

Page background color.

```dart
backgroundColor: Color(0xFFFFFFFF)  // White
backgroundColor: Color(0xFFF5E6D3)  // Sepia
backgroundColor: Color(0xFF1A1A1A)  // Dark
```

#### textColor

**Type:** `Color?`

Text color.

```dart
textColor: Color(0xFF000000)  // Black
textColor: Color(0xFF5C4033)  // Brown (sepia)
textColor: Color(0xFFE0E0E0)  // Light gray (dark mode)
```

#### pageMargins

**Type:** `double?`

Page margins as a decimal (0.0 to 1.0).

```dart
pageMargins: 0.05  // 5% margins
pageMargins: 0.1   // 10% margins
pageMargins: 0.15  // 15% margins
```

### Methods

#### toJson

Converts to JSON for platform communication.

```dart
Map<String, dynamic> toJson()
```

### Example Usage

```dart
// Light mode
final lightPrefs = EPUBPreferences(
  fontFamily: 'Georgia',
  fontSize: 100,
  fontWeight: 400,
  verticalScroll: false,
  backgroundColor: Color(0xFFFFFFFF),
  textColor: Color(0xFF000000),
  pageMargins: 0.1,
);

// Sepia mode
final sepiaPrefs = EPUBPreferences(
  fontFamily: 'Palatino',
  fontSize: 110,
  fontWeight: 400,
  verticalScroll: false,
  backgroundColor: Color(0xFFF5E6D3),
  textColor: Color(0xFF5C4033),
  pageMargins: 0.1,
);

// Dark mode
final darkPrefs = EPUBPreferences(
  fontFamily: 'Helvetica',
  fontSize: 100,
  fontWeight: 400,
  verticalScroll: false,
  backgroundColor: Color(0xFF1A1A1A),
  textColor: Color(0xFFE0E0E0),
  pageMargins: 0.1,
);

// Apply
await flureadium.setEPUBPreferences(lightPrefs);
```

## TTSPreferences

Controls text-to-speech behavior.

**Source:** [reader_tts_preferences.dart](../../../flureadium_platform_interface/lib/src/reader/reader_tts_preferences.dart)

### Constructor

```dart
TTSPreferences({
  double? speed,
  double? pitch,
  String? voiceIdentifier,
  String? languageOverride,
  ControlPanelInfoType? controlPanelInfoType,
})
```

### Properties

#### speed

**Type:** `double?`

Speech rate multiplier. Typical range: 0.5 to 2.0.

```dart
speed: 0.5   // Half speed
speed: 1.0   // Normal
speed: 1.25  // 25% faster
speed: 1.5   // 50% faster
speed: 2.0   // Double speed
```

#### pitch

**Type:** `double?`

Voice pitch multiplier. Typical range: 0.5 to 2.0.

```dart
pitch: 0.8  // Lower pitch
pitch: 1.0  // Normal
pitch: 1.2  // Higher pitch
```

#### voiceIdentifier

**Type:** `String?`

Platform-specific voice identifier. Get available voices with `ttsGetAvailableVoices()`.

```dart
voiceIdentifier: 'com.apple.voice.compact.en-US.Samantha'  // iOS
voiceIdentifier: 'en-US-Standard-A'                         // Android
```

#### languageOverride

**Type:** `String?`

Override the publication's language for voice selection.

```dart
languageOverride: 'en-US'
languageOverride: 'en-GB'
languageOverride: 'fr-FR'
```

#### controlPanelInfoType

**Type:** `ControlPanelInfoType?`

What information to show in system media controls.

### Example Usage

```dart
// Enable TTS with preferences
await flureadium.ttsEnable(TTSPreferences(
  speed: 1.2,
  pitch: 1.0,
));

// Get available voices
final voices = await flureadium.ttsGetAvailableVoices();
for (final voice in voices) {
  print('${voice.name} (${voice.language}): ${voice.identifier}');
}

// Set a specific voice
final englishVoice = voices.firstWhere(
  (v) => v.language.startsWith('en'),
);
await flureadium.ttsSetVoice(englishVoice.identifier, 'en');

// Update preferences during playback
await flureadium.ttsSetPreferences(TTSPreferences(
  speed: 1.5,  // Speed up
));
```

## AudioPreferences

Controls audiobook playback behavior.

**Source:** [reader_audio_preferences.dart](../../../flureadium_platform_interface/lib/src/reader/reader_audio_preferences.dart)

### Constructor

```dart
AudioPreferences({
  double? volume,
  double? speed,
  double? pitch,
  double? seekInterval,
  bool? allowExternalSeeking,
  ControlPanelInfoType? controlPanelInfoType,
})
```

### Properties

#### volume

**Type:** `double?`

Playback volume (0.0 to 1.0).

```dart
volume: 0.5  // 50%
volume: 1.0  // 100%
```

#### speed

**Type:** `double?`

Playback speed multiplier.

```dart
speed: 0.75  // 75% speed
speed: 1.0   // Normal
speed: 1.5   // 1.5x speed
speed: 2.0   // 2x speed
```

#### pitch

**Type:** `double?`

Audio pitch multiplier.

```dart
pitch: 1.0  // Normal
```

#### seekInterval

**Type:** `double?`

Skip interval in seconds for next/previous controls.

```dart
seekInterval: 10   // Skip 10 seconds
seekInterval: 30   // Skip 30 seconds
seekInterval: 60   // Skip 1 minute
```

#### allowExternalSeeking

**Type:** `bool?`

Whether to allow seeking from system controls (lockscreen, etc.).

```dart
allowExternalSeeking: true  // Allow
allowExternalSeeking: false // Disable
```

#### controlPanelInfoType

**Type:** `ControlPanelInfoType?`

What information to show in system media controls.

### Example Usage

```dart
// Enable audiobook with preferences
await flureadium.audioEnable(
  prefs: AudioPreferences(
    volume: 1.0,
    speed: 1.0,
    seekInterval: 30,
    allowExternalSeeking: true,
  ),
  fromLocator: savedPosition,
);

// Update preferences during playback
await flureadium.audioSetPreferences(AudioPreferences(
  speed: 1.5,  // Speed up
));

// Seek forward
await flureadium.audioSeekBy(Duration(seconds: 30));
```

## ControlPanelInfoType

Enum for system media control display options.

**Source:** [reader_audio_preferences.dart](../../../flureadium_platform_interface/lib/src/reader/reader_audio_preferences.dart)

### Values

```dart
enum ControlPanelInfoType {
  standard,           // Default display
  standardWCh,        // Standard with chapter
  chapterTitleAuthor, // Chapter, Title, Author
  chapterTitle,       // Chapter and Title
  titleChapter,       // Title and Chapter
}
```

## Common Patterns

### Theme Presets

```dart
class ReaderTheme {
  final String name;
  final EPUBPreferences preferences;

  const ReaderTheme(this.name, this.preferences);

  static final light = ReaderTheme('Light', EPUBPreferences(
    fontFamily: 'Georgia',
    fontSize: 100,
    fontWeight: 400,
    verticalScroll: false,
    backgroundColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF000000),
  ));

  static final sepia = ReaderTheme('Sepia', EPUBPreferences(
    fontFamily: 'Georgia',
    fontSize: 100,
    fontWeight: 400,
    verticalScroll: false,
    backgroundColor: Color(0xFFF5E6D3),
    textColor: Color(0xFF5C4033),
  ));

  static final dark = ReaderTheme('Dark', EPUBPreferences(
    fontFamily: 'Georgia',
    fontSize: 100,
    fontWeight: 400,
    verticalScroll: false,
    backgroundColor: Color(0xFF1A1A1A),
    textColor: Color(0xFFE0E0E0),
  ));
}
```

### Persisting Preferences

```dart
class PreferencesManager {
  Future<void> saveEPUBPreferences(EPUBPreferences prefs) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('fontFamily', prefs.fontFamily);
    await sp.setInt('fontSize', prefs.fontSize);
    // ... save other properties
  }

  Future<EPUBPreferences> loadEPUBPreferences() async {
    final sp = await SharedPreferences.getInstance();
    return EPUBPreferences(
      fontFamily: sp.getString('fontFamily') ?? 'Georgia',
      fontSize: sp.getInt('fontSize') ?? 100,
      fontWeight: 400,
      verticalScroll: sp.getBool('verticalScroll') ?? false,
      backgroundColor: Color(sp.getInt('backgroundColor') ?? 0xFFFFFFFF),
      textColor: Color(sp.getInt('textColor') ?? 0xFF000000),
    );
  }
}
```

### Font Size Slider

```dart
Widget buildFontSizeSlider(int currentSize, Function(int) onChanged) {
  return Slider(
    min: 50,
    max: 200,
    divisions: 15,
    value: currentSize.toDouble(),
    onChanged: (value) => onChanged(value.round()),
    label: '${currentSize}%',
  );
}
```

## See Also

- [Preferences Guide](../guides/preferences.md) - Detailed customization guide
- [Flureadium Class](flureadium-class.md) - API for applying preferences
- [Text-to-Speech Guide](../guides/text-to-speech.md) - TTS configuration
- [Audiobook Guide](../guides/audiobook-playback.md) - Audio configuration
