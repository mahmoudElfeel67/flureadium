## 0.3.0

- Add `renderFirstPage` method to `FlureadiumPlatform` and `MethodChannelFlureadium` — renders the first page of a PDF as a JPEG image for cover generation.

## 0.2.0

- Add `enableEdgeTapNavigation` and `enableSwipeNavigation` to `PDFPreferences` — allows independently controlling edge tap and swipe page navigation on iOS.
- Add `enableEdgeTapNavigation` and `enableSwipeNavigation` to `EPUBPreferences` — same controls for EPUB reader on iOS.

## 0.1.0

- Initial public release of the Flureadium platform interface.
- Abstract `FlureadiumPlatform` class with full API for EPUB, PDF, and audiobook reading.
- Method channel implementation (`MethodChannelFlureadium`).
- Readium shared models: `Publication`, `Locator`, `Metadata`, `Link`, `MediaType`, and more.
- Reader preference models: `EPUBPreferences`, `PDFPreferences`, `TTSPreferences`, `AudioPreferences`.
- Reader decoration API for highlights and annotations.
- TTS voice model and platform-specific voice name mappings.
- Exception types for structured error handling.
- OPDS feed and publication models.
- Extension utilities for colors, durations, locators, and strings.
