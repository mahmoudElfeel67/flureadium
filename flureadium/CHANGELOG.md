## 0.3.0

- Add `renderFirstPage` API — renders the first page of a PDF as a JPEG image for use as a cover. Uses `PdfRenderer` on Android and `CGPDFDocument` on iOS. No Readium dependency needed.
- Requires `flureadium_platform_interface` ^0.3.0.

## 0.2.0

- Add swipe gesture navigation for EPUB and PDF readers on iOS — swipe left/right to turn pages in edge zones.
- Add `enableEdgeTapNavigation` and `enableSwipeNavigation` preference flags for independently controlling edge tap and swipe page navigation on iOS.
- Requires `flureadium_platform_interface` ^0.2.0.

## 0.1.1

- Fix `.pubignore` excluding `lib/src/web/` which prevented dartdoc generation on pub.dev.

## 0.1.0

- Initial public release of Flureadium.
- Full EPUB 2/3 reading with customizable typography and themes.
- PDF reading support on Android (Pdfium) and iOS (PDFKit).
- Text-to-speech with voice selection, speed, and pitch control.
- Audiobook playback with track navigation and variable speed.
- Media overlay support for synchronized read-along experiences.
- Decoration API for highlights, bookmarks, and annotations.
- ReaderWidget for embedding the reader in Flutter widget trees.
- Position tracking and saving via Locator streams.
- Cross-platform support: Android, iOS, macOS, and Web.
