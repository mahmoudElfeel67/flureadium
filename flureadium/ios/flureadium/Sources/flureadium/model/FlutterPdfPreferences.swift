//
//  FlutterPdfPreferences.swift
//  flureadium
//
//  PDF preferences for Flutter Readium.
//  Maps to PDFPreferences in Flutter's reader_pdf_preferences.dart.
//

import Foundation
import ReadiumNavigator
import ReadiumShared

/// How a PDF page fits within the viewport.
/// Maps to PDFFit enum in Flutter.
public enum FlutterPdfFit: String {
    case width
    case contain

    /// Converts to Readium scroll mode.
    /// - width: continuous scroll mode (scroll=true)
    /// - contain: paginated mode (scroll=false)
    func toReadiumScroll() -> Bool {
        switch self {
        case .width:
            return true
        case .contain:
            return false
        }
    }

    static func fromString(_ value: String?) -> FlutterPdfFit? {
        guard let value = value else { return nil }
        return FlutterPdfFit(rawValue: value.lowercased())
    }
}

/// Scroll direction for PDF navigation.
/// Maps to PDFScrollMode enum in Flutter.
public enum FlutterPdfScrollMode: String {
    case horizontal
    case vertical

    /// Converts to Readium scroll axis.
    func toReadiumScrollAxis() -> Axis {
        switch self {
        case .horizontal:
            return .horizontal
        case .vertical:
            return .vertical
        }
    }

    static func fromString(_ value: String?) -> FlutterPdfScrollMode? {
        guard let value = value else { return nil }
        return FlutterPdfScrollMode(rawValue: value.lowercased())
    }
}

/// Page layout mode for PDF display.
/// Maps to PDFPageLayout enum in Flutter.
public enum FlutterPdfPageLayout: String {
    case single
    case double
    case automatic

    /// Converts to Readium spread mode.
    func toReadiumSpread() -> Spread {
        switch self {
        case .single:
            return .never
        case .double:
            return .always
        case .automatic:
            return .auto
        }
    }

    static func fromString(_ value: String?) -> FlutterPdfPageLayout? {
        guard let value = value else { return nil }
        return FlutterPdfPageLayout(rawValue: value.lowercased())
    }
}

/// PDF preferences for Flutter Readium.
/// Maps to PDFPreferences class in Flutter's reader_pdf_preferences.dart.
public struct FlutterPdfPreferences {
    /// How the page fits in the viewport.
    var fit: FlutterPdfFit?

    /// Scroll orientation.
    var scrollMode: FlutterPdfScrollMode?

    /// Page layout mode.
    var pageLayout: FlutterPdfPageLayout?

    /// Whether to offset the first page in double-page spreads (for covers).
    var offsetFirstPage: Bool?

    /// Whether to disable the built-in double-tap-to-zoom gesture (iOS only).
    /// When true, double-tap won't zoom the PDF content.
    /// Defaults to false (zoom enabled).
    var disableDoubleTapZoom: Bool?

    /// Whether to disable text selection gestures (iOS only).
    /// When true, long-press won't select text in the PDF.
    /// Defaults to false (text selection enabled).
    var disableTextSelection: Bool?

    /// Whether to disable drag gestures (iOS only).
    /// When true, drag gestures won't trigger text selection or drag-and-drop.
    /// Defaults to false (drag gestures enabled).
    var disableDragGestures: Bool?

    /// Whether to disable the text selection menu (iOS only).
    /// When true, the Copy/Look Up/Translate menu won't appear when text is selected.
    /// Defaults to false (selection menu enabled).
    var disableTextSelectionMenu: Bool?

    /// Whether edge tap navigation is enabled (iOS only).
    /// When true, tapping on the left/right edges of the screen navigates pages.
    /// Defaults to true (enabled) when nil.
    var enableEdgeTapNavigation: Bool?

    /// Whether swipe gesture navigation is enabled (iOS only).
    /// When true, swiping left/right navigates pages.
    /// Defaults to true (enabled) when nil.
    var enableSwipeNavigation: Bool?

    /// Edge tap area as a percentage of screen width (10–30). iOS only.
    /// Defaults to 12 when nil.
    var edgeTapAreaPercent: Double?

    /// Creates FlutterPdfPreferences with default values.
    init(
        fit: FlutterPdfFit? = nil,
        scrollMode: FlutterPdfScrollMode? = nil,
        pageLayout: FlutterPdfPageLayout? = nil,
        offsetFirstPage: Bool? = nil,
        disableDoubleTapZoom: Bool? = nil,
        disableTextSelection: Bool? = nil,
        disableDragGestures: Bool? = nil,
        disableTextSelectionMenu: Bool? = nil,
        enableEdgeTapNavigation: Bool? = nil,
        enableSwipeNavigation: Bool? = nil,
        edgeTapAreaPercent: Double? = nil
    ) {
        self.fit = fit
        self.scrollMode = scrollMode
        self.pageLayout = pageLayout
        self.offsetFirstPage = offsetFirstPage
        self.disableDoubleTapZoom = disableDoubleTapZoom
        self.disableTextSelection = disableTextSelection
        self.disableDragGestures = disableDragGestures
        self.disableTextSelectionMenu = disableTextSelectionMenu
        self.enableEdgeTapNavigation = enableEdgeTapNavigation
        self.enableSwipeNavigation = enableSwipeNavigation
        self.edgeTapAreaPercent = edgeTapAreaPercent
    }

    /// Creates FlutterPdfPreferences from a Flutter dictionary.
    init(fromMap map: [String: Any]?) {
        guard let map = map else {
            self.init()
            return
        }

        self.init(
            fit: FlutterPdfFit.fromString(map["fit"] as? String),
            scrollMode: FlutterPdfScrollMode.fromString(map["scrollMode"] as? String),
            pageLayout: FlutterPdfPageLayout.fromString(map["pageLayout"] as? String),
            offsetFirstPage: map["offsetFirstPage"] as? Bool,
            disableDoubleTapZoom: map["disableDoubleTapZoom"] as? Bool,
            disableTextSelection: map["disableTextSelection"] as? Bool,
            disableDragGestures: map["disableDragGestures"] as? Bool,
            disableTextSelectionMenu: map["disableTextSelectionMenu"] as? Bool,
            enableEdgeTapNavigation: map["enableEdgeTapNavigation"] as? Bool,
            enableSwipeNavigation: map["enableSwipeNavigation"] as? Bool,
            edgeTapAreaPercent: map["edgeTapAreaPercent"] as? Double
        )
    }

    /// Converts to Readium PDFPreferences.
    func toReadiumPreferences() -> PDFPreferences {
        var prefs = PDFPreferences()

        // Map fit to scroll mode
        if let fit = fit {
            prefs.scroll = fit.toReadiumScroll()
        }

        // Map scrollMode to scrollAxis
        if let scrollMode = scrollMode {
            prefs.scrollAxis = scrollMode.toReadiumScrollAxis()
        }

        // Map pageLayout to spread
        if let pageLayout = pageLayout {
            prefs.spread = pageLayout.toReadiumSpread()
        }

        // Direct mapping for offsetFirstPage
        if let offsetFirstPage = offsetFirstPage {
            prefs.offsetFirstPage = offsetFirstPage
        }

        return prefs
    }

    /// Converts to a dictionary for Flutter.
    func toMap() -> [String: Any] {
        var map: [String: Any] = [:]
        if let fit = fit { map["fit"] = fit.rawValue }
        if let scrollMode = scrollMode { map["scrollMode"] = scrollMode.rawValue }
        if let pageLayout = pageLayout { map["pageLayout"] = pageLayout.rawValue }
        if let offsetFirstPage = offsetFirstPage { map["offsetFirstPage"] = offsetFirstPage }
        if let disableDoubleTapZoom = disableDoubleTapZoom {
            map["disableDoubleTapZoom"] = disableDoubleTapZoom
        }
        if let disableTextSelection = disableTextSelection {
            map["disableTextSelection"] = disableTextSelection
        }
        if let disableDragGestures = disableDragGestures {
            map["disableDragGestures"] = disableDragGestures
        }
        if let disableTextSelectionMenu = disableTextSelectionMenu {
            map["disableTextSelectionMenu"] = disableTextSelectionMenu
        }
        if let enableEdgeTapNavigation = enableEdgeTapNavigation {
            map["enableEdgeTapNavigation"] = enableEdgeTapNavigation
        }
        if let enableSwipeNavigation = enableSwipeNavigation {
            map["enableSwipeNavigation"] = enableSwipeNavigation
        }
        if let edgeTapAreaPercent = edgeTapAreaPercent {
            map["edgeTapAreaPercent"] = edgeTapAreaPercent
        }
        return map
    }
}
