//
//  ReadiumExtensionsMappingTests.swift
//  flureadiumTests
//
//  Tests that EPUBPreferences and PDFPreferences extensions correctly map
//  Readium-specific keys from the channel arguments.
//  Navigation UX config is now handled separately via setNavigationConfig.
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

    // MARK: - PDFPreferences.init(fromMap:) — Readium key mapping

    func testPDFPreferencesFromMapMapsFitWidth() {
        let map: [String: Any] = ["fit": "width"]
        let prefs = PDFPreferences(fromMap: map)
        XCTAssertEqual(prefs.scroll, true)
    }

    func testPDFPreferencesFromMapMapsFitContain() {
        let map: [String: Any] = ["fit": "contain"]
        let prefs = PDFPreferences(fromMap: map)
        XCTAssertEqual(prefs.scroll, false)
    }

    func testPDFPreferencesFromMapMapsScrollModeVertical() {
        let map: [String: Any] = ["scrollMode": "vertical"]
        let prefs = PDFPreferences(fromMap: map)
        XCTAssertEqual(prefs.scrollAxis, .vertical)
    }

    func testPDFPreferencesFromMapMapsScrollModeHorizontal() {
        let map: [String: Any] = ["scrollMode": "horizontal"]
        let prefs = PDFPreferences(fromMap: map)
        XCTAssertEqual(prefs.scrollAxis, .horizontal)
    }

    func testPDFPreferencesFromMapMapsMultipleReadiumKeys() {
        let map: [String: Any] = [
            "fit": "width",
            "scrollMode": "vertical",
        ]
        let prefs = PDFPreferences(fromMap: map)
        XCTAssertEqual(prefs.scroll, true)
        XCTAssertEqual(prefs.scrollAxis, .vertical)
    }

    func testPDFPreferencesFromMapEmptyMapProducesDefaultPrefs() {
        let map: [String: Any] = [:]
        let prefs = PDFPreferences(fromMap: map)
        XCTAssertNil(prefs.scroll)
        XCTAssertNil(prefs.scrollAxis)
    }
}
