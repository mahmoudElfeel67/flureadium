# iOS Platform

iOS-specific setup and implementation details.

## Requirements

- iOS 13.0+
- Xcode 14+
- CocoaPods

## Setup

### 1. Podfile Configuration

Add Readium pods to `ios/Podfile`:

```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # PromiseKit dependency
  pod 'PromiseKit', '~> 8.1'

  # Readium toolkit pods (version 3.5.0)
  pod 'ReadiumShared', podspec: 'https://raw.githubusercontent.com/readium/swift-toolkit/3.5.0/Support/CocoaPods/ReadiumShared.podspec'
  pod 'ReadiumInternal', podspec: 'https://raw.githubusercontent.com/readium/swift-toolkit/3.5.0/Support/CocoaPods/ReadiumInternal.podspec'
  pod 'ReadiumStreamer', podspec: 'https://raw.githubusercontent.com/readium/swift-toolkit/3.5.0/Support/CocoaPods/ReadiumStreamer.podspec'
  pod 'ReadiumNavigator', podspec: 'https://raw.githubusercontent.com/readium/swift-toolkit/3.5.0/Support/CocoaPods/ReadiumNavigator.podspec'
  pod 'ReadiumOPDS', podspec: 'https://raw.githubusercontent.com/readium/swift-toolkit/3.5.0/Support/CocoaPods/ReadiumOPDS.podspec'
  pod 'ReadiumAdapterGCDWebServer', podspec: 'https://raw.githubusercontent.com/readium/swift-toolkit/3.5.0/Support/CocoaPods/ReadiumAdapterGCDWebServer.podspec'
  pod 'ReadiumZIPFoundation', podspec: 'https://raw.githubusercontent.com/readium/podspecs/refs/heads/main/ReadiumZIPFoundation/3.0.1/ReadiumZIPFoundation.podspec'

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end
```

Then run:
```bash
cd ios
pod install
```

### 2. App Transport Security

Add to `ios/Runner/Info.plist` for local content server:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Why?** Readium uses a local web server to serve EPUB content.

### 3. Background Audio (Optional)

For audiobook background playback, add to `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
</array>
```

## Implementation Details

### Plugin Structure

```
ios/Sources/flureadium/
├── FlureadiumPlugin.swift       # Plugin registration
├── MethodCallHandler.swift      # Method channel handler
├── ReadiumManager.swift         # Readium lifecycle
├── ReadiumReaderViewFactory.swift # Platform view factory
├── ReadiumReaderView.swift      # Native reader view
└── NavigatorController.swift    # Navigation handling
```

### Platform View

Uses `UiKitView` for embedding UIKit views:

```swift
class ReadiumReaderViewFactory: NSObject, FlutterPlatformViewFactory {
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return ReadiumReaderView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger
        )
    }
}
```

### Readium Integration

Uses Readium Swift Toolkit 3.5.0:
- `Streamer` for EPUB parsing
- `EPUBNavigatorViewController` for content display
- `AVSpeechSynthesizer` for TTS
- `AVPlayer` for audio

### Local Server

Uses GCDWebServer to serve EPUB resources:
- Runs on localhost (127.0.0.1)
- Requires NSAppTransportSecurity exception
- Automatically starts/stops with publication

### Edge Tap and Swipe Navigation

The flureadium iOS plugin supports both edge tap and swipe gesture navigation for EPUB and PDF readers.

**How It Works:**

The `EdgeTapInterceptView` is a transparent UIView overlay that:
- Intercepts single taps on the left 30% of the screen width → triggers `goLeft()` (previous page)
- Intercepts single taps on the right 30% of the screen width → triggers `goRight()` (next page)
- Intercepts swipe left gestures → triggers `goRight()` (next page)
- Intercepts swipe right gestures → triggers `goLeft()` (previous page)
- Passes through all other touches to the underlying reader view

**Configuring from Dart:**

Both edge tap and swipe navigation can be independently controlled via preferences. Both default to enabled (`true`).

```dart
// PDF: control navigation gestures
PDFPreferences(
  enableEdgeTapNavigation: true,   // Edge taps navigate (default)
  enableSwipeNavigation: false,    // Disable swipe navigation
)

// EPUB: control navigation gestures
EPUBPreferences(
  fontFamily: 'Georgia',
  fontSize: 100,
  fontWeight: 400,
  verticalScroll: false,
  backgroundColor: null,
  textColor: null,
  enableEdgeTapNavigation: false,  // Disable edge taps
  enableSwipeNavigation: true,     // Keep swipe navigation
)
```

**Note:** In EPUB scroll mode, both gestures are automatically disabled regardless of preference values.

**Developer Config vs Readium Preferences:**

`enableEdgeTapNavigation`, `enableSwipeNavigation`, and `edgeTapAreaPoints` are **developer config keys** — they control navigation UX behaviour defined by the app developer, not user-facing reading appearance. They are serialized alongside Readium preferences in the same `setPreferences` call for convenience, but the native `ReadiumReaderView` and `PdfReaderView` handlers extract and consume these keys before forwarding the remaining map to `EPUBPreferences.init(fromMap:)` / `PDFPreferences.init(fromMap:)`. This keeps Readium's preference mapping clean and prevents spurious "Cannot map property" warnings.

**Edge Threshold:**

The edge threshold defaults to 44pt (iOS HIG minimum tap target) and is controlled via the `edgeTapAreaPoints` preference (44–120pt range, clamped automatically). The raw property on `EdgeTapInterceptView` can also be set directly in Swift:

```swift
edgeTapView.edgeThresholdPoints = 80.0 // 80pt per side
```

**Files:**
- `EdgeTapInterceptView.swift` - Shared edge tap and swipe detection view
- `ReadiumReaderView.swift` - EPUB reader using EdgeTapInterceptView
- `PdfReaderView.swift` - PDF reader using EdgeTapInterceptView

### Stream and View Lifecycle

Flureadium iOS uses `EventStreamHandler` to manage Flutter EventChannel streams (text locator, reader status, errors). Proper lifecycle management is critical:

- **Stream disposal** (sending `FlutterEndOfEventStream` and clearing handlers) must happen in the `"dispose"` method call from Dart, while the Flutter engine is still alive
- **`deinit`** only nils out references as a safety net — it must NOT send messages on Flutter channels, as `deinit` may be triggered during engine teardown when channels are no longer valid

This separation prevents crashes during app termination, where `FlutterEngine.destroyContext` triggers deallocation of native views after the message channels are already torn down.

**Files:**
- `EventStreamHandler.swift` - Stream handler with `dispose()` that sends `FlutterEndOfEventStream`
- `ReadiumReaderView.swift` - Calls stream `dispose()` in method call handler, not in `deinit`

## Troubleshooting

### Pod Install Fails

```bash
cd ios
pod deintegrate
pod cache clean --all
pod repo update
pod install
```

### "No such module" Error

Clean build and reinstall:
```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
flutter clean
flutter build ios
```

### Localhost Connection Refused

Ensure NSAppTransportSecurity is configured in Info.plist.

### TTS Voice Quality

iOS provides high-quality voices. To check available voices:
```dart
final voices = await flureadium.ttsGetAvailableVoices();
// Look for "Enhanced" or "Premium" voices
```

### Memory Warnings

Close publication when not in use:
```dart
@override
void dispose() {
  flureadium.closePublication();
  super.dispose();
}
```

## Privacy Manifest

For App Store submission, the plugin includes `PrivacyInfo.xcprivacy` declaring:
- No user data collection
- Local file access only

## See Also

- [Installation Guide](../getting-started/installation.md)
- [Architecture Overview](../architecture/overview.md)
- [Troubleshooting](../troubleshooting.md)
