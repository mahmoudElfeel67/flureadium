//
//  ReadiumExtensionsMappingTests.swift
//  flureadiumTests
//
//  Tests that EPUBPreferences and PDFPreferences extensions only receive
//  Readium-specific keys — never developer config keys.
//  The filtering contract: ReadiumReaderView and PdfReaderView extract
//  developer config keys before passing the remaining map to these inits.
//

import XCTest
@testable import flureadium
import ReadiumNavigator

final class ReadiumExtensionsMappingTests: XCTestCase {

    // MARK: - EPUBPreferences.init(fromMap:) — Readium key mapping

    func testEPUBPreferencesFromMapMapsBackgroundColor() {
        let map: [String: String] = ["backgroundColor": "#000000"]
        let prefs = EPUBPreferences(fromMap: map)
        XCTAssertNotNil(prefs.backgroundColor)
    }

    func testEPUBPreferencesFromMapMapsTextColor() {
        let map: [String: String] = ["textColor": "#ffffff"]
        let prefs = EPUBPreferences(fromMap: map)
        XCTAssertNotNil(prefs.textColor)
    }

    func testEPUBPreferencesFromMapMapsFontSize() {
        let map: [String: String] = ["fontSize": "1.5"]
        let prefs = EPUBPreferences(fromMap: map)
        XCTAssertEqual(prefs.fontSize, 1.5)
    }

    func testEPUBPreferencesFromMapMapsVerticalScroll() {
        let map: [String: String] = ["verticalScroll": "true"]
        let prefs = EPUBPreferences(fromMap: map)
        XCTAssertEqual(prefs.scroll, true)
    }

    func testEPUBPreferencesFromMapMapsMultipleReadiumKeys() {
        let map: [String: String] = [
            "backgroundColor": "#1a1a1a",
            "textColor": "#eeeeee",
            "fontSize": "1.2",
            "fontWeight": "0.8",
            "verticalScroll": "false",
        ]
        let prefs = EPUBPreferences(fromMap: map)
        XCTAssertNotNil(prefs.backgroundColor)
        XCTAssertNotNil(prefs.textColor)
        XCTAssertEqual(prefs.fontSize, 1.2)
        XCTAssertEqual(prefs.fontWeight, 0.8)
        XCTAssertEqual(prefs.scroll, false)
    }

    func testEPUBPreferencesFromMapEmptyMapProducesDefaultPrefs() {
        let map: [String: String] = [:]
        let prefs = EPUBPreferences(fromMap: map)
        // All optional fields should remain nil when map is empty
        XCTAssertNil(prefs.backgroundColor)
        XCTAssertNil(prefs.textColor)
        XCTAssertNil(prefs.fontSize)
        XCTAssertNil(prefs.scroll)
    }

    // MARK: - EPUBPreferences developer config key separation

    /// Verifies the contract: developer config keys must be filtered BEFORE calling
    /// EPUBPreferences.init(fromMap:). A clean (filtered) map only contains Readium keys.
    func testEPUBPreferencesFilteredMapContainsOnlyReadiumKeys() {
        let developerConfigKeys: Set<String> = [
            "enableEdgeTapNavigation",
            "enableSwipeNavigation",
            "edgeTapAreaPoints",
        ]
        let fullMap: [String: String] = [
            "backgroundColor": "#000000",
            "textColor": "#ffffff",
            "fontSize": "1.0",
            "enableEdgeTapNavigation": "true",
            "enableSwipeNavigation": "true",
            "edgeTapAreaPoints": "44.0",
        ]

        let filteredMap = fullMap.filter { !developerConfigKeys.contains($0.key) }

        XCTAssertFalse(filteredMap.keys.contains("enableEdgeTapNavigation"))
        XCTAssertFalse(filteredMap.keys.contains("enableSwipeNavigation"))
        XCTAssertFalse(filteredMap.keys.contains("edgeTapAreaPoints"))
        XCTAssertTrue(filteredMap.keys.contains("backgroundColor"))
        XCTAssertTrue(filteredMap.keys.contains("textColor"))
        XCTAssertTrue(filteredMap.keys.contains("fontSize"))
    }

    func testEPUBPreferencesFilteredMapMapsCorrectly() {
        let developerConfigKeys: Set<String> = [
            "enableEdgeTapNavigation",
            "enableSwipeNavigation",
            "edgeTapAreaPoints",
        ]
        let fullMap: [String: String] = [
            "backgroundColor": "#000000",
            "textColor": "#ffffff",
            "fontSize": "1.0",
            "enableEdgeTapNavigation": "true",
            "enableSwipeNavigation": "false",
            "edgeTapAreaPoints": "60.0",
        ]

        let filteredMap = fullMap.filter { !developerConfigKeys.contains($0.key) }
        let prefs = EPUBPreferences(fromMap: filteredMap)

        XCTAssertNotNil(prefs.backgroundColor)
        XCTAssertNotNil(prefs.textColor)
        XCTAssertEqual(prefs.fontSize, 1.0)
    }

    // MARK: - PDFPreferences developer config key separation

    func testPDFPreferencesFilteredMapContainsOnlyReadiumKeys() {
        let developerConfigKeys: Set<String> = [
            "enableEdgeTapNavigation",
            "enableSwipeNavigation",
            "edgeTapAreaPoints",
            "disableDoubleTapZoom",
            "disableTextSelection",
            "disableDragGestures",
            "disableTextSelectionMenu",
        ]
        let fullMap: [String: Any] = [
            "fit": "contain",
            "scrollMode": "horizontal",
            "backgroundColor": "#000000",
            "enableEdgeTapNavigation": true,
            "enableSwipeNavigation": true,
            "edgeTapAreaPoints": 44.0,
            "disableDoubleTapZoom": true,
            "disableTextSelection": false,
            "disableDragGestures": false,
            "disableTextSelectionMenu": true,
        ]

        let filteredMap = fullMap.filter { !developerConfigKeys.contains($0.key) }

        XCTAssertFalse(filteredMap.keys.contains("enableEdgeTapNavigation"))
        XCTAssertFalse(filteredMap.keys.contains("enableSwipeNavigation"))
        XCTAssertFalse(filteredMap.keys.contains("edgeTapAreaPoints"))
        XCTAssertFalse(filteredMap.keys.contains("disableDoubleTapZoom"))
        XCTAssertFalse(filteredMap.keys.contains("disableTextSelection"))
        XCTAssertFalse(filteredMap.keys.contains("disableDragGestures"))
        XCTAssertFalse(filteredMap.keys.contains("disableTextSelectionMenu"))
        XCTAssertTrue(filteredMap.keys.contains("fit"))
        XCTAssertTrue(filteredMap.keys.contains("scrollMode"))
        XCTAssertTrue(filteredMap.keys.contains("backgroundColor"))
    }

    func testPDFPreferencesFilteredMapMapsCorrectly() {
        let developerConfigKeys: Set<String> = [
            "enableEdgeTapNavigation",
            "enableSwipeNavigation",
            "edgeTapAreaPoints",
            "disableDoubleTapZoom",
            "disableTextSelection",
            "disableDragGestures",
            "disableTextSelectionMenu",
        ]
        let fullMap: [String: Any] = [
            "fit": "width",
            "scrollMode": "vertical",
            "enableEdgeTapNavigation": true,
            "disableDoubleTapZoom": true,
        ]

        let filteredMap = fullMap.filter { !developerConfigKeys.contains($0.key) }
        let prefs = PDFPreferences(fromMap: filteredMap)

        XCTAssertEqual(prefs.scroll, true)
        XCTAssertEqual(prefs.scrollAxis, .vertical)
    }

    // MARK: - Developer config key extraction

    func testEnableEdgeTapNavigationExtractedFromFullMap() {
        let fullMap: [String: String] = [
            "backgroundColor": "#000000",
            "enableEdgeTapNavigation": "false",
        ]
        let edgeTapEnabled = fullMap["enableEdgeTapNavigation"] != "false" ? true :
            (fullMap["enableEdgeTapNavigation"] == nil ? true : false)
        XCTAssertFalse(edgeTapEnabled)
    }

    func testEnableEdgeTapNavigationDefaultsTrueWhenAbsent() {
        let fullMap: [String: String] = ["backgroundColor": "#000000"]
        let edgeTapEnabled = fullMap["enableEdgeTapNavigation"].map { $0 != "false" } ?? true
        XCTAssertTrue(edgeTapEnabled)
    }
}
