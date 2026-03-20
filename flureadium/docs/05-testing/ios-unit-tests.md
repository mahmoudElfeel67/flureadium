# iOS Unit Tests

Native Swift/XCTest unit tests for the flureadium iOS plugin. These test Swift code that runs on the iOS platform (navigators, plugin handlers, TTS logic, etc.) and are separate from `flutter test`, which only covers Dart code.

## How It Works

Flutter iOS plugins are Swift Packages, but their tests cannot run via `swift test` because:

1. The plugin imports the `Flutter` framework, which is not an SPM dependency — it is injected by the Flutter build system via the example app's Xcode workspace.
2. Readium Swift Toolkit declares iOS-only platform support, so SPM cannot resolve dependencies for a macOS host target.

Instead, tests live in the **example app's RunnerTests target** and run via `xcodebuild test`. The example app's Xcode workspace already links the plugin package and all its dependencies, so tests have full access to plugin internals via `@testable import flureadium`.

## Test File Location

```
flureadium/example/ios/RunnerTests/
├── RunnerTests.swift                  # Plugin handler tests
├── FlutterTTSNavigatorTests.swift     # TTS navigator tests
└── <YourNewTests>.swift               # Add new files here
```

All test files go in `flureadium/example/ios/RunnerTests/`. Do NOT put tests in the SPM test target at `ios/flureadium/Tests/flureadiumTests/` — those cannot be executed.

## Adding a New Test File

Two things are required when you add a new `.swift` file to RunnerTests:

### 1. Create the file

Place it in `flureadium/example/ios/RunnerTests/`. Use the standard XCTest structure:

```swift
import XCTest
import ReadiumShared      // Readium types: Publication, Locator, Manifest, etc.
import ReadiumNavigator   // Readium navigator types: PublicationSpeechSynthesizer, etc.
@testable import flureadium

final class YourTests: XCTestCase {

    func testSomething() async {
        // Arrange
        let publication = Publication(manifest: Manifest(metadata: Metadata(title: "Test")))
        // Act & Assert
        XCTAssertNotNil(publication)
    }
}
```

Available imports:
- `XCTest` — test framework
- `Flutter` — FlutterMethodCall, FlutterError, FlutterResult, etc.
- `ReadiumShared` — Publication, Locator, Manifest, Metadata, MediaType, Link, etc.
- `ReadiumNavigator` — PublicationSpeechSynthesizer, EPUBNavigatorViewController, etc.
- `@testable import flureadium` — all plugin internals (FlutterTTSNavigator, FlureadiumPlugin, etc.)

### 2. Register the file in the Xcode project

New `.swift` files are NOT automatically discovered by `xcodebuild`. You must add three entries to `flureadium/example/ios/Runner.xcodeproj/project.pbxproj`:

1. **PBXFileReference** — declares the file exists:
```
{UNIQUE_ID_1} /* YourTests.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = YourTests.swift; sourceTree = "<group>"; };
```

2. **PBXBuildFile** — declares the file should be compiled:
```
{UNIQUE_ID_2} /* YourTests.swift in Sources */ = {isa = PBXBuildFile; fileRef = {UNIQUE_ID_1} /* YourTests.swift */; };
```

3. **Add to two sections**:
   - The **RunnerTests group** (search for `/* RunnerTests */` children list) — add the PBXFileReference ID
   - The **RunnerTests Sources build phase** (search for `331C807D294A63A400263BE5 /* Sources */`) — add the PBXBuildFile ID

Generate unique IDs as 24-character hex strings. They must not collide with existing IDs in the file.

Alternatively, open `Runner.xcworkspace` in Xcode once, drag the file into RunnerTests, and the project file is updated automatically.

## Running Tests

### Prerequisites

The example app must be built for the iOS simulator at least once before running tests. This generates Flutter build artifacts that `xcodebuild` depends on:

```bash
cd flureadium/example
flutter build ios --simulator --debug
```

You only need to re-run this when Flutter dependencies change (pubspec.yaml, plugin registration, etc.). Subsequent test runs reuse the cached build.

### Finding a Simulator

List available iOS simulators:

```bash
xcrun simctl list devices available | grep iPhone
```

Pick any simulator. For best compatibility, choose one running the latest installed iOS runtime. If you need a specific runtime version:

```bash
# List installed runtimes
xcrun simctl list runtimes | grep iOS

# Filter devices by runtime
xcrun simctl list devices available "iOS 18.3"
```

The simulator does not need to be booted — `xcodebuild` boots it automatically.

### Run All iOS Unit Tests

```bash
cd flureadium/example/ios
xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=<simulator-name>' \
  -only-testing:RunnerTests \
  2>&1 | grep -E '(Test Case|TEST |Executed|error:)' | tail -30
```

Replace `<simulator-name>` with a simulator from the list above (e.g., `iPhone 16 Pro`).

### Run a Specific Test Class

```bash
xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=<simulator-name>' \
  -only-testing:RunnerTests/FlutterTTSNavigatorTests \
  2>&1 | grep -E '(Test Case|TEST |Executed|error:)' | tail -30
```

### Run a Single Test Method

```bash
xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=<simulator-name>' \
  -only-testing:RunnerTests/FlutterTTSNavigatorTests/testPlayConsumesInitialLocator \
  2>&1 | grep -E '(Test Case|TEST |Executed|error:)' | tail -30
```

### Reading Output

The `grep` filter at the end shows pass/fail lines. Full xcodebuild output is extremely verbose. Key patterns:

- `Test case '...' passed` — test passed
- `Test case '...' failed` — test failed
- `** TEST SUCCEEDED **` — all requested tests passed
- `** TEST FAILED **` — at least one test failed

For full output (debugging build failures), drop the `grep` pipe:

```bash
xcodebuild test \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=<simulator-name>' \
  -only-testing:RunnerTests \
  2>&1 | tail -50
```

## Deployment Target

The RunnerTests target's `IPHONEOS_DEPLOYMENT_TARGET` must match the flureadium package's minimum (currently 13.4). If you see an error like:

```
compiling for iOS 13.0, but module 'flureadium' has a minimum deployment target of iOS 13.4
```

Add `IPHONEOS_DEPLOYMENT_TARGET = 13.4;` to all three RunnerTests build configurations (Debug, Release, Profile) in `project.pbxproj`.

## Writing Good Tests

### Test patterns established in this project

**Testing plugin internals directly** (preferred for logic tests):
```swift
// Create a minimal Publication — no ContentService, so TTS/streamer won't initialize,
// but the object is valid for testing navigator logic.
let publication = Publication(manifest: Manifest(metadata: Metadata(title: "Test")))

// Create a Locator for position-related tests
let locator = Locator(href: URL(string: "chapter1.xhtml")!, mediaType: .html)

// Instantiate the navigator directly
let navigator = FlutterTTSNavigator(publication: publication, initialLocator: locator)

// Call methods and assert
await navigator.play(fromLocator: nil)
XCTAssertNil(navigator.initialLocator)
```

**Testing plugin method handlers** (for testing the Dart-to-native boundary):
```swift
let plugin = FlureadiumPlugin()
let expectation = expectation(description: "result called")

let call = FlutterMethodCall(methodName: "ttsCanSpeak", arguments: nil)
plugin.handle(call) { response in
    XCTAssertEqual(response as? Bool, false)
    expectation.fulfill()
}

wait(for: [expectation], timeout: 2.0)
```

### Async tests

Use `async` test methods for any code that calls `async` functions:

```swift
func testSomethingAsync() async {
    await navigator.play(fromLocator: nil)
    XCTAssertNil(navigator.initialLocator)
}
```

### What NOT to test here

- Dart code — use `flutter test` for that
- Full end-to-end flows with a real reader — use integration tests (`flutter test integration_test/`)
- Android native code — use the Android unit tests (Kotlin/Robolectric)
