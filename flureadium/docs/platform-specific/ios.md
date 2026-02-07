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
