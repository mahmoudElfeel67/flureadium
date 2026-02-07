# Troubleshooting

Common issues and solutions when using Flureadium.

## Build Errors

### Android: "MainActivity cannot be cast to FragmentActivity"

**Error:**
```
java.lang.ClassCastException: com.example.app.MainActivity cannot be cast to androidx.fragment.app.FragmentActivity
```

**Solution:**
Change your `MainActivity` to extend `FlutterFragmentActivity`:

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
```

### Android: Minimum SDK Version

**Error:**
```
Manifest merger failed : uses-sdk:minSdkVersion 21 cannot be smaller than version 24
```

**Solution:**
In `android/app/build.gradle`:
```groovy
android {
    defaultConfig {
        minSdkVersion 24
    }
}
```

### iOS: Pod Install Failed

**Error:**
```
[!] Unable to find a specification for `ReadiumShared`
```

**Solution:**
1. Update pod repo:
   ```bash
   cd ios
   pod repo update
   ```

2. Clear cache and reinstall:
   ```bash
   pod deintegrate
   pod cache clean --all
   pod install
   ```

3. Ensure Podfile has correct podspecs (see [Installation](getting-started/installation.md))

### iOS: "No such module 'ReadiumShared'"

**Solution:**
Run pod install with repo update:
```bash
cd ios
pod install --repo-update
```

### Web: JavaScript File Not Found

**Error:**
```
Failed to load readiumReader.js
```

**Solution:**
1. Copy the JS file:
   ```bash
   dart run flureadium:copy_js_file web/
   ```

2. Ensure script tag in `index.html`:
   ```html
   <script src="readiumReader.js" defer></script>
   ```

## Runtime Errors

### Publication Won't Open

**Error:**
```
OpeningReadiumException: formatNotSupported
```

**Possible Causes:**
- File is not a valid EPUB
- File path is incorrect
- File is corrupted

**Solution:**
1. Verify file exists:
   ```dart
   final file = File(path);
   print('Exists: ${file.existsSync()}');
   ```

2. Check file extension and format
3. Try with a known-good EPUB file

### "PublicationNotSetReadiumException"

**Error:**
```
PublicationNotSetReadiumException: Cannot navigate without publication
```

**Cause:**
Trying to navigate before publication is opened.

**Solution:**
Ensure publication is opened before navigation:
```dart
final pub = await flureadium.openPublication(path);
// Now you can navigate
await flureadium.goRight();
```

### Blank Reader Screen

**Possible Causes:**
1. Publication not loaded
2. ReaderWidget not receiving publication
3. Native view not initialized

**Solutions:**
1. Add loading indicator:
   ```dart
   if (_publication == null) {
     return CircularProgressIndicator();
   }
   return ReadiumReaderWidget(publication: _publication!);
   ```

2. Check for errors:
   ```dart
   try {
     final pub = await flureadium.openPublication(path);
   } on ReadiumException catch (e) {
     print('Error: ${e.message}');
   }
   ```

### TTS Not Working

**Possible Causes:**
1. TTS not enabled
2. No voices available
3. Platform-specific issue

**Solutions:**
1. Enable TTS first:
   ```dart
   await flureadium.ttsEnable(TTSPreferences(speed: 1.0));
   await flureadium.play(null);
   ```

2. Check available voices:
   ```dart
   final voices = await flureadium.ttsGetAvailableVoices();
   print('Available voices: ${voices.length}');
   ```

3. On Android, ensure TTS engine is installed

### Audio Not Playing

**Possible Causes:**
1. Not an audiobook publication
2. Audio not enabled
3. Volume is zero

**Solutions:**
1. Check publication type:
   ```dart
   if (pub.conformsToReadiumAudiobook) {
     await flureadium.audioEnable();
   }
   ```

2. Check preferences:
   ```dart
   await flureadium.audioEnable(
     prefs: AudioPreferences(volume: 1.0, speed: 1.0),
   );
   ```

## Platform-Specific Issues

### iOS: Localhost Connection Failed

**Error:**
```
The resource could not be loaded because the App Transport Security policy requires the use of a secure connection.
```

**Solution:**
Add to `ios/Runner/Info.plist`:
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

### Android: WebView Issues

**Symptoms:**
- Content not rendering properly
- JavaScript errors

**Solutions:**
1. Enable hardware acceleration in AndroidManifest.xml:
   ```xml
   <application android:hardwareAccelerated="true">
   ```

2. Check minimum SDK version is 24+

### Web: CORS Errors

**Error:**
```
Access to fetch at 'file://' from origin 'http://localhost' has been blocked by CORS
```

**Cause:**
Loading local files from web.

**Solution:**
Serve files from a web server or use asset bundling.

## Performance Issues

### Slow Page Turns

**Possible Causes:**
1. Large images in EPUB
2. Complex CSS
3. Many decorations

**Solutions:**
1. Use paginated mode instead of scroll:
   ```dart
   EPUBPreferences(verticalScroll: false)
   ```

2. Limit number of decorations
3. Consider EPUB optimization

### High Memory Usage

**Possible Causes:**
1. Large publication
2. Many resources loaded
3. Memory leak

**Solutions:**
1. Close publication when done:
   ```dart
   await flureadium.closePublication();
   ```

2. Dispose of subscriptions:
   ```dart
   @override
   void dispose() {
     _subscription?.cancel();
     super.dispose();
   }
   ```

### Stream Subscription Leaks

**Symptoms:**
- Memory growing over time
- Multiple callbacks firing

**Solution:**
Always cancel subscriptions:
```dart
class _MyState extends State<MyWidget> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = flureadium.onTextLocatorChanged.listen((loc) {
      // handle
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

## Debugging Tips

### Enable Logging

```dart
flureadium.onErrorEvent.listen((error) {
  debugPrint('Flureadium Error: ${error.message}');
  debugPrint('Code: ${error.code}');
  debugPrint('Data: ${error.data}');
});
```

### Check Publication Info

```dart
final pub = await flureadium.openPublication(path);
debugPrint('Title: ${pub.metadata.title}');
debugPrint('Identifier: ${pub.identifier}');
debugPrint('Reading order: ${pub.readingOrder.length} items');
debugPrint('TOC: ${pub.tableOfContents.length} items');
debugPrint('Is audiobook: ${pub.conformsToReadiumAudiobook}');
debugPrint('Has overlays: ${pub.containsMediaOverlays}');
```

### Verify Locator

```dart
flureadium.onTextLocatorChanged.listen((locator) {
  debugPrint('Href: ${locator.href}');
  debugPrint('Type: ${locator.type}');
  debugPrint('Progress: ${locator.locations?.totalProgression}');
  debugPrint('JSON: ${locator.json}');
});
```

## Getting Help

If you can't resolve an issue:

1. Check the [example app](../example/) for working code
2. Review [Error Handling Guide](../../ERROR_HANDLING.md)
3. Search existing [GitHub issues](https://github.com/anthropics/flureadium/issues)
4. Open a new issue with:
   - Flutter version (`flutter --version`)
   - Platform (iOS, Android, Web, macOS)
   - Error messages and stack traces
   - Minimal reproduction code

## See Also

- [Installation](getting-started/installation.md) - Setup guide
- [Error Handling Guide](../../ERROR_HANDLING.md) - Exception types
- [Platform-Specific Docs](platform-specific/) - Platform details
