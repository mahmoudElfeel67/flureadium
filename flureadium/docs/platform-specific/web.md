# Web Platform

Web-specific setup and implementation details.

## Requirements

- Modern browser with JavaScript ES6+ support
- Flutter Web

## Setup

### 1. Copy JavaScript File

Run from your project root:

```bash
dart run flureadium:copy_js_file web/
```

This copies `readiumReader.js` to your web directory.

### 2. Add Script Tags

In `web/index.html`, add to the `<head>` section:

```html
<head>
  <!-- Other head content -->

  <!-- Flutter initialization -->
  <script src="flutter.js" defer></script>

  <!-- Flureadium reader -->
  <script src="readiumReader.js" defer></script>
</head>
```

If you placed the JS file in a subdirectory:
```html
<script src="scripts/readiumReader.js" defer></script>
```

## Implementation Details

### Architecture

```
Web Implementation
├── Dart Layer
│   ├── flureadium_web.dart      # Web plugin registration
│   ├── reader_widget_web.dart   # Web reader widget
│   └── js_publication_channel.dart # JS interop
└── TypeScript Layer
    ├── ReadiumReader.ts         # Main entry point
    ├── epubNavigator.ts         # EPUB navigation
    ├── webpubNavigator.ts       # WebPub navigation
    ├── preferences.ts           # CSS preferences
    └── decorations.ts           # Highlight handling
```

### JavaScript Interop

Uses `dart:js_interop` for communication:

```dart
@JS('ReadiumReader')
external JSObject get readiumReader;

void goLeft() {
  readiumReader.callMethod('goLeft'.toJS, []);
}
```

### Readium CSS

Web uses Readium CSS for styling. Preferences map to CSS variables:

| Preference | CSS Variable |
|------------|--------------|
| fontFamily | `--USER__fontFamily` |
| fontSize | `--USER__fontSize` |
| textColor | `--USER__textColor` |
| backgroundColor | `--USER__backgroundColor` |

See [Readium CSS documentation](https://github.com/readium/css) for all options.

### Publication Rendering

1. EPUB is fetched and parsed
2. Content extracted to HTML
3. Readium CSS injected
4. Rendered in iframe/container
5. Navigation via JavaScript API

## Preferences

Web preferences support additional Readium CSS options:

```dart
// Basic preferences work the same
await flureadium.setEPUBPreferences(EPUBPreferences(
  fontFamily: 'Georgia',
  fontSize: 120,
  backgroundColor: Color(0xFFFFFFFF),
  textColor: Color(0xFF000000),
));
```

For advanced CSS options, see [Readium CSS Types](https://github.com/readium/ts-toolkit/blob/develop/navigator/src/preferences/Types.ts).

## Limitations

### Features Not Available on Web

| Feature | Status | Notes |
|---------|--------|-------|
| TTS | Limited | Uses Web Speech API (browser-dependent) |
| Audiobook | Limited | Basic HTML5 audio |
| Background Audio | No | Browser limitation |
| Lock Screen | No | Browser limitation |
| File System | Limited | Must use URLs or fetch |

### Browser Compatibility

| Browser | Support |
|---------|---------|
| Chrome | Full |
| Firefox | Full |
| Safari | Full |
| Edge | Full |
| IE11 | Not supported |

## Loading Publications

### From URL

```dart
final pub = await flureadium.openPublication('https://example.com/book.epub');
```

### From Assets

Serve from web server:
```dart
final pub = await flureadium.openPublication('/assets/books/sample.epub');
```

### CORS Considerations

For cross-origin publications, ensure server sends:
```
Access-Control-Allow-Origin: *
```

## Troubleshooting

### JavaScript File Not Found

1. Verify file exists in `web/` directory
2. Check script tag path in `index.html`
3. Clear browser cache

### "ReadiumReader is not defined"

Script loading order issue. Ensure:
1. `flutter.js` loads first
2. `readiumReader.js` loads before Flutter app

### CORS Errors

```
Access to fetch at 'file://' from origin 'http://localhost' has been blocked
```

Solution: Serve files via HTTP server, not file:// protocol.

### TTS Not Working

Web Speech API availability varies:
```dart
final voices = await flureadium.ttsGetAvailableVoices();
if (voices.isEmpty) {
  print('TTS not available in this browser');
}
```

### Slow Performance

1. Optimize EPUB size
2. Use paginated mode
3. Limit decorations
4. Consider lazy loading

## Development Tips

### Hot Reload

Web hot reload works with Flureadium:
```bash
flutter run -d chrome
```

### DevTools

Use browser DevTools to:
- Inspect rendered content
- Debug JavaScript
- Check network requests
- Profile performance

### Building for Production

```bash
flutter build web --release
```

Ensure `readiumReader.js` is included in build output.

## See Also

- [Installation Guide](../getting-started/installation.md)
- [Architecture Overview](../architecture/overview.md)
- [Troubleshooting](../troubleshooting.md)
