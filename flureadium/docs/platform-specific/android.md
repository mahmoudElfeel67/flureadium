# Android Platform

Android-specific setup and implementation details.

## Requirements

- Android SDK 24+ (Android 7.0 Nougat)
- Kotlin 1.8+
- Gradle 8.0+

## Setup

### 1. Minimum SDK Version

In `android/app/build.gradle`:

```groovy
android {
    defaultConfig {
        minSdkVersion 24
    }
}
```

### 2. FlutterFragmentActivity

Change your `MainActivity` to extend `FlutterFragmentActivity`:

```kotlin
// android/app/src/main/kotlin/.../MainActivity.kt
package com.example.myapp

import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity: FlutterFragmentActivity() {
}
```

**Why?** Flureadium uses platform views that require Fragment support.

### 3. Permissions

For TTS and audiobook features, add to `AndroidManifest.xml`:

```xml
<manifest>
    <uses-permission android:name="android.permission.WAKE_LOCK" />

    <!-- For network-based publications -->
    <uses-permission android:name="android.permission.INTERNET" />
</manifest>
```

### 4. ProGuard Rules (Optional)

If using ProGuard/R8, add to `android/app/proguard-rules.pro`:

```proguard
# Readium
-keep class org.readium.** { *; }
-keep class org.joda.time.** { *; }

# Flureadium
-keep class dev.mulev.flureadium.** { *; }
```

## Implementation Details

### Plugin Structure

```
android/src/main/kotlin/dev/mulev/flureadium/
├── FlureadiumPlugin.kt          # Plugin registration
├── MethodCallHandler.kt         # Method channel handler
├── ReadiumManager.kt            # Readium lifecycle
├── ReadiumReaderViewFactory.kt  # Platform view factory
├── ReadiumReaderView.kt         # Native reader view
└── NavigatorWrapper.kt          # Navigator abstraction
```

### Platform View

Uses `PlatformViewLink` with `AndroidViewSurface` for high-performance rendering:

```kotlin
class ReadiumReaderViewFactory(
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return ReadiumReaderView(context, viewId, messenger, args as? Map<*, *>)
    }
}
```

### Readium Integration

Uses Readium Kotlin Toolkit:
- `Streamer` for EPUB parsing
- `Navigator` for content display
- `TTS` and `MediaPlayer` for audio

## Troubleshooting

### "MainActivity cannot be cast to FragmentActivity"

Ensure MainActivity extends `FlutterFragmentActivity`.

### Build fails with "Duplicate class"

Add to `android/app/build.gradle`:
```groovy
android {
    packagingOptions {
        exclude 'META-INF/DEPENDENCIES'
        exclude 'META-INF/LICENSE'
    }
}
```

### TTS not working

1. Check TTS engine is installed (Settings > Accessibility > TTS)
2. Download language data if prompted
3. Test with system TTS settings

### WebView rendering issues

Enable hardware acceleration:
```xml
<application android:hardwareAccelerated="true">
```

## See Also

- [Installation Guide](../getting-started/installation.md)
- [Architecture Overview](../architecture/overview.md)
- [Troubleshooting](../troubleshooting.md)
