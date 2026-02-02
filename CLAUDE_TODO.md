# Flureadium TODO Tracking

This file tracks technical debt, pending features, and known issues in the Flureadium project.
Created during Milestone 4: Code Quality Refactoring.

---

## Critical TODOs (Priority: High)

### 1. lastVisibleLocator Alternative
**File**: `flureadium/lib/reader_widget.dart:127`
**Context**: Navigation logic needs improvement
```dart
// TODO: Find a better way to do this, maybe a `lastVisibleLocator` ?
if (readium.defaultPreferences?.verticalScroll != true) {
  await _channel?.goRight(animated: false);
  final loc = await _channel?.getCurrentLocator();
  currentHref = getTextLocatorHrefWithTocFragment(loc);
}
```

**Issue**: Current workaround moves one page right to ensure we're not on the first page of a chapter in paginated mode.
**Recommended Solution**: Implement `lastVisibleLocator` tracking to avoid the extra navigation step.
**Impact**: Medium - affects UX when navigating TOC in paginated mode.

---

### 2. Orientation Change Workaround
**File**: `flureadium/lib/src/reader/orientation_handler_mixin.dart:23`
**Context**: Page alignment fix on orientation change
```dart
// TODO: Remove this workaround if the underlying issue is completely fixed in Readium.
```

**Issue**: Re-navigation required after orientation change to fix page alignment (e.g., avoids staying on "page 5½").
**Action Required**: Monitor Readium upstream fixes for orientation handling.
**Upstream**: Check https://github.com/readium/swift-toolkit/issues
**Impact**: Low - workaround is functional but adds 500ms delay.

---

### 3. isAudioBookWithText Detection
**File**: `flureadium/lib/src/reader/orientation_handler_mixin.dart:51`
**Context**: Navigation parameter hardcoded
```dart
isAudioBookWithText: false, // TODO: isAudioBookWithText - we don't know atm.
```

**Issue**: Cannot detect if current publication is an audiobook with text synchronization.
**Recommended Solution**:
1. Add property to `Publication` model checking for both:
   - `conformsToReadiumAudiobook`
   - Presence of `readingOrder` items with text media types
2. Pass this information down to orientation handler

**Impact**: Medium - affects text highlighting in audio books with karaoke-style features.

---

### 4. Language Tag Validation
**File**: `flureadium/lib/src/web/json_transformer.dart:116`
**Context**: Translation validation incomplete
```dart
// TODO: unknown if other languages also fails the validation, needs better handling
translationsMap.forEach((final key, final value) {
  if (key.length > 3) {
    R2Log.d('PUBLICATION WEB: Translations map key "$key" is longer than three letters.');
  }
});
```

**Issue**:
- Only checks key length (> 3 chars)
- Doesn't validate BCP 47 format
- Unknown if other languages fail validation besides 'undefined'

**Recommended Solution**:
1. Implement proper BCP 47 validation using regex or package
2. Document which language tags are supported
3. Add fallback handling for invalid tags

**Reference**: BCP 47 spec: https://tools.ietf.org/html/bcp47
**Impact**: Low - currently just logs warnings, doesn't break functionality.

---

### 5. Audio Book Resource Fetching
**File**: `flureadium/lib/src/flureadium_web.dart:114`
**Context**: Uncertainty about getBytes usage
```dart
// TODO: Is this still needed for audio books with the new implementation
static Future<Uint8List> getBytes(final Link link) async {
  final linkString = json.encode(link);
  final resourceBytesString = await JsPublicationChannel().getResource(linkString, asBytes: true);
  final byteList = jsonDecode(resourceBytesString).cast<int>();
  return Uint8List.fromList(byteList);
}
```

**Action Required**: Verify if `getBytes` is still used by audiobook implementation.
**Investigation**: Search for usages of this method in audiobook code paths.
**Impact**: Unknown - may be legacy code that can be removed.

---

## Medium Priority TODOs

### 6. Karaoke Book Support
**File**: `flureadium/lib/src/flureadium_web.dart:231`
**Context**: Feature not yet implemented
```dart
// TODO: Implement when karaoke books are supported
```

**Status**: Awaiting karaoke book feature implementation.
**Dependency**: Requires Readium support for media overlays or similar.

---

### 7. Reader State Restoration
**File**: `flureadium/example/lib/pages/player.page.dart:116`
**Context**: Example app functionality
```dart
// TODO: implement restoreState
```

**Issue**: Reader state (position, preferences) not restored on app restart in example.
**Scope**: Example app only, not core library.
**Impact**: Low - example app limitation.

---

### 8. TTS Voice Language Mapping
**File**: `flureadium/example/lib/state/player_controls_bloc.dart:175`
**Context**: Voice selection demo code
```dart
// TODO: Demo: change to first voice matching "da-DK" language.
```

**Scope**: Demo/example code only.
**Related**: See TODO about web-speech-voices mapping below.

---

## Low Priority / Future Enhancements

### 9. Opacity Support for ReadiumColor
**File**: `flureadium_platform_interface/lib/src/extensions/readium_color_extension.dart:8`
**Context**: Platform limitation
```dart
// TODO: Find out if it is our implementation of the Readium Swift-toolkit or if it is a limitation of the toolkit itself that opacity is not supported.
```

**Issue**: Opacity not supported in color handling.
**Action**: Investigate if limitation is in Swift toolkit or our implementation.
**Impact**: Low - colors work without opacity.

---

### 10. TTS Voice Name Mapping
**File**: `flureadium_platform_interface/lib/src/reader/reader_tts_voice_names.dart:5`
**Context**: Better voice mapping needed
```dart
// TODO: Map voices using Hadrien's excellent web-speech-voices
```

**Resource**: https://github.com/hadriengardeur/web-speech-voices
**Impact**: Low - current voice handling works but could be improved.

---

### 11. EPUB Preferences Expansion
**File**: `flureadium_platform_interface/lib/src/reader/reader_epub_preferences.dart:34`
**Context**: Feature expansion
```dart
// TODO: Add more preferences
```

**Status**: Awaiting requirements for additional EPUB preferences.

---

### 12. Multi-language OPDS Titles
**File**: `flureadium_platform_interface/lib/src/shared/opds/opds_metadata.dart:29`
**Context**: OPDS metadata handling
```dart
// TODO: handle multi-language titles
```

**Issue**: OPDS titles currently assume single language.
**Impact**: Low - OPDS metadata usually has single primary title.

---

### 13. Video Format Support
**File**: `flureadium_platform_interface/lib/src/shared/publication/format.dart:29,39`
**Context**: Format detection
```dart
// FIXME: video MIME types?
// FIXME: video file extensions?
```

**Status**: Video publication format detection not fully implemented.
**Impact**: Very Low - video publications not common in Readium ecosystem.

---

### 14. belongsTo Property (Incomplete)
**File**: `flureadium_platform_interface/lib/src/shared/publication/metadata.dart:116`
**Context**: Metadata model
```dart
// TODO: belongsTo should be a proper...
```

**Note**: Comment appears truncated in source.
**Action**: Review metadata implementation for belongsTo handling.

---

### 15. Encryption Property Implementation
**File**: `flureadium_platform_interface/lib/src/shared/publication/encryption/property_extensions.dart:31`
**Context**: Equatable props
```dart
// TODO: implement props
```

**Issue**: Encryption properties don't implement Equatable props correctly.
**Impact**: Very Low - equality comparison may not work correctly for encryption properties.

---

### 16. TTS Paragraph Highlighting
**File**: `flureadium/example/lib/widgets/tts_settings.widget.dart:54`
**Context**: Example UI feature
```dart
// TODO: Remember that it will only highlight paragraphs if google network voices are used. Implement this in the UI.
```

**Scope**: Example app UI.
**Impact**: Very Low - documentation/UI improvement for example.

---

## Test & Infrastructure TODOs

### 17. Storage Initialization in Integration Test
**File**: `flureadium/example/integration_test/plugin_integration_test.dart:19`
**Context**: Test failure
```dart
// TODO: Fix this, get err Storage was accessed before it was initialized.
```

**Issue**: Storage must be initialized before test execution.
**Impact**: Low - integration test skipped/failing.

---

### 18. Temporary ignore directive
**File**: `flureadium_platform_interface/lib/src/index.dart:9`
**Context**: Code organization
```dart
/// TODO: remove ignore when r2_navigator is moved to a separate repo
```

**Status**: Waiting for r2_navigator repository split.

---

### 19. Platform Support Message
**File**: `flureadium/lib/reader_widget.dart:232`
**Context**: Unsupported platform fallback
```dart
child: Center(child: Text('TODO — Implement ReadiumReaderWidget on ${Platform.operatingSystem}.')),
```

**Issue**: Desktop platforms show TODO message.
**Impact**: Low - not targeting desktop platforms currently.

---

### 20. Stream Debounce Demo Code
**File**: `flureadium/lib/reader_widget.dart:256`
**Context**: Example/demo code
```dart
// TODO: This is just to demo how to use and debounce the Stream, remove when appropriate.
```

**Action**: Remove or formalize stream debouncing pattern.
**Scope**: Demo code in production file.

---

### 21. Deprecation Warning
**File**: `flureadium/lib/reader_channel.dart:147`
**Context**: Deprecated function
```dart
/// TODO: Nuke this function from orbit if/when that happens.
```

**Action**: Review if function can be removed.
**Impact**: Unknown - check for usages first.

---

## Summary

**Total TODOs**: 21
- **Critical**: 5 (require investigation or implementation)
- **Medium**: 3 (feature enhancements)
- **Low**: 8 (nice-to-have improvements)
- **Test/Infra**: 5 (development environment issues)

**Next Steps**:
1. Prioritize investigation of critical TODOs #1-5
2. Monitor Readium upstream for orientation fix (#2)
3. Implement audiobook detection (#3)
4. Validate language tag handling (#4)
5. Clean up demo/example code TODOs

---

**Last Updated**: 2026-02-01
**Maintained By**: Development Team
**Related**: See PHASE3_ASSESSMENT.md for JSON serialization decision
