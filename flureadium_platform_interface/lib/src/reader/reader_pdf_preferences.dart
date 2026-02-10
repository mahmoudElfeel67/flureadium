// ignore_for_file: public_member_api_docs, sort_constructors_first

/// PDF reader preferences for Flureadium.
///
/// Based on Readium PDF navigator preferences:
/// - fit: How the page fits in the viewport (width, contain)
/// - scrollMode: Scroll orientation (horizontal, vertical)
/// - pageLayout: Single page or double spread
/// - offsetFirstPage: Offset for first page in spreads (for covers)
class PDFPreferences {
  PDFPreferences({
    this.fit,
    this.scrollMode,
    this.pageLayout,
    this.offsetFirstPage,
    this.disableDoubleTapZoom,
    this.disableTextSelection,
    this.disableDragGestures,
    this.disableTextSelectionMenu,
    this.enableEdgeTapNavigation,
    this.enableSwipeNavigation,
  });

  factory PDFPreferences.fromJsonMap(Map<String, dynamic> map) =>
      PDFPreferences(
        fit: map['fit'] != null
            ? PDFFit.values.byName(map['fit'] as String)
            : null,
        scrollMode: map['scrollMode'] != null
            ? PDFScrollMode.values.byName(map['scrollMode'] as String)
            : null,
        pageLayout: map['pageLayout'] != null
            ? PDFPageLayout.values.byName(map['pageLayout'] as String)
            : null,
        offsetFirstPage: map['offsetFirstPage'] as bool?,
        disableDoubleTapZoom: map['disableDoubleTapZoom'] as bool?,
        disableTextSelection: map['disableTextSelection'] as bool?,
        disableDragGestures: map['disableDragGestures'] as bool?,
        disableTextSelectionMenu: map['disableTextSelectionMenu'] as bool?,
        enableEdgeTapNavigation: map['enableEdgeTapNavigation'] as bool?,
        enableSwipeNavigation: map['enableSwipeNavigation'] as bool?,
      );

  /// How the page fits in the viewport.
  PDFFit? fit;

  /// Scroll orientation.
  PDFScrollMode? scrollMode;

  /// Page layout mode.
  PDFPageLayout? pageLayout;

  /// Whether to offset the first page in double-page spreads (for covers).
  bool? offsetFirstPage;

  /// Whether to disable the built-in double-tap-to-zoom gesture (iOS only).
  /// When true, double-tap won't zoom the PDF content.
  /// Defaults to false (zoom enabled).
  bool? disableDoubleTapZoom;

  /// Whether to disable text selection gestures (iOS only).
  /// When true, long-press won't select text in the PDF.
  /// Defaults to false (text selection enabled).
  bool? disableTextSelection;

  /// Whether to disable drag gestures (iOS only).
  /// When true, drag gestures won't trigger text selection or drag-and-drop.
  /// Defaults to false (drag gestures enabled).
  bool? disableDragGestures;

  /// Whether to disable the text selection menu (iOS only).
  /// When true, the Copy/Look Up/Translate menu won't appear when text is selected.
  /// Defaults to false (selection menu enabled).
  bool? disableTextSelectionMenu;

  /// Whether edge tap navigation is enabled (iOS only).
  /// When true, tapping on the left/right edges of the screen navigates pages.
  /// Defaults to true (enabled) when null.
  bool? enableEdgeTapNavigation;

  /// Whether swipe gesture navigation is enabled (iOS only).
  /// When true, swiping left/right navigates pages.
  /// Defaults to true (enabled) when null.
  bool? enableSwipeNavigation;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (fit != null) map['fit'] = fit!.name;
    if (scrollMode != null) map['scrollMode'] = scrollMode!.name;
    if (pageLayout != null) map['pageLayout'] = pageLayout!.name;
    if (offsetFirstPage != null) map['offsetFirstPage'] = offsetFirstPage;
    if (disableDoubleTapZoom != null) {
      map['disableDoubleTapZoom'] = disableDoubleTapZoom;
    }
    if (disableTextSelection != null) {
      map['disableTextSelection'] = disableTextSelection;
    }
    if (disableDragGestures != null) {
      map['disableDragGestures'] = disableDragGestures;
    }
    if (disableTextSelectionMenu != null) {
      map['disableTextSelectionMenu'] = disableTextSelectionMenu;
    }
    if (enableEdgeTapNavigation != null) {
      map['enableEdgeTapNavigation'] = enableEdgeTapNavigation;
    }
    if (enableSwipeNavigation != null) {
      map['enableSwipeNavigation'] = enableSwipeNavigation;
    }
    return map;
  }

  PDFPreferences copyWith({
    PDFFit? fit,
    PDFScrollMode? scrollMode,
    PDFPageLayout? pageLayout,
    bool? offsetFirstPage,
    bool? disableDoubleTapZoom,
    bool? disableTextSelection,
    bool? disableDragGestures,
    bool? disableTextSelectionMenu,
    bool? enableEdgeTapNavigation,
    bool? enableSwipeNavigation,
  }) => PDFPreferences(
    fit: fit ?? this.fit,
    scrollMode: scrollMode ?? this.scrollMode,
    pageLayout: pageLayout ?? this.pageLayout,
    offsetFirstPage: offsetFirstPage ?? this.offsetFirstPage,
    disableDoubleTapZoom: disableDoubleTapZoom ?? this.disableDoubleTapZoom,
    disableTextSelection: disableTextSelection ?? this.disableTextSelection,
    disableDragGestures: disableDragGestures ?? this.disableDragGestures,
    disableTextSelectionMenu:
        disableTextSelectionMenu ?? this.disableTextSelectionMenu,
    enableEdgeTapNavigation:
        enableEdgeTapNavigation ?? this.enableEdgeTapNavigation,
    enableSwipeNavigation: enableSwipeNavigation ?? this.enableSwipeNavigation,
  );
}

/// How a PDF page fits within the viewport.
enum PDFFit {
  /// Fit page width to viewport width.
  width,

  /// Fit entire page in viewport.
  contain,
}

/// Scroll direction for PDF navigation.
enum PDFScrollMode {
  /// Scroll horizontally between pages.
  horizontal,

  /// Scroll vertically through pages.
  vertical,
}

/// Page layout mode for PDF display.
enum PDFPageLayout {
  /// Display one page at a time.
  single,

  /// Display two pages side-by-side (spreads).
  double,

  /// Automatically choose based on viewport.
  automatic,
}
