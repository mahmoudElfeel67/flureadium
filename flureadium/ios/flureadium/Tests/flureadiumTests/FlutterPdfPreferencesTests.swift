//
//  FlutterPdfPreferencesTests.swift
//  flureadiumTests
//
//  Unit tests for FlutterPdfPreferences.
//

import XCTest
@testable import flureadium
import ReadiumNavigator

final class FlutterPdfPreferencesTests: XCTestCase {

    // MARK: - Enum Tests

    func testFlutterPdfFitFromString() {
        XCTAssertEqual(FlutterPdfFit.fromString("width"), .width)
        XCTAssertEqual(FlutterPdfFit.fromString("contain"), .contain)
        XCTAssertEqual(FlutterPdfFit.fromString("WIDTH"), .width)
        XCTAssertEqual(FlutterPdfFit.fromString("CONTAIN"), .contain)
        XCTAssertNil(FlutterPdfFit.fromString("invalid"))
        XCTAssertNil(FlutterPdfFit.fromString(nil))
    }

    func testFlutterPdfScrollModeFromString() {
        XCTAssertEqual(FlutterPdfScrollMode.fromString("horizontal"), .horizontal)
        XCTAssertEqual(FlutterPdfScrollMode.fromString("vertical"), .vertical)
        XCTAssertEqual(FlutterPdfScrollMode.fromString("HORIZONTAL"), .horizontal)
        XCTAssertEqual(FlutterPdfScrollMode.fromString("VERTICAL"), .vertical)
        XCTAssertNil(FlutterPdfScrollMode.fromString("invalid"))
        XCTAssertNil(FlutterPdfScrollMode.fromString(nil))
    }

    func testFlutterPdfPageLayoutFromString() {
        XCTAssertEqual(FlutterPdfPageLayout.fromString("single"), .single)
        XCTAssertEqual(FlutterPdfPageLayout.fromString("double"), .double)
        XCTAssertEqual(FlutterPdfPageLayout.fromString("automatic"), .automatic)
        XCTAssertEqual(FlutterPdfPageLayout.fromString("SINGLE"), .single)
        XCTAssertEqual(FlutterPdfPageLayout.fromString("DOUBLE"), .double)
        XCTAssertEqual(FlutterPdfPageLayout.fromString("AUTOMATIC"), .automatic)
        XCTAssertNil(FlutterPdfPageLayout.fromString("invalid"))
        XCTAssertNil(FlutterPdfPageLayout.fromString(nil))
    }

    // MARK: - Enum Conversion Tests

    func testFlutterPdfFitToReadiumScroll() {
        XCTAssertTrue(FlutterPdfFit.width.toReadiumScroll())
        XCTAssertFalse(FlutterPdfFit.contain.toReadiumScroll())
    }

    func testFlutterPdfScrollModeToReadiumScrollAxis() {
        XCTAssertEqual(FlutterPdfScrollMode.horizontal.toReadiumScrollAxis(), .horizontal)
        XCTAssertEqual(FlutterPdfScrollMode.vertical.toReadiumScrollAxis(), .vertical)
    }

    func testFlutterPdfPageLayoutToReadiumSpread() {
        XCTAssertEqual(FlutterPdfPageLayout.single.toReadiumSpread(), .never)
        XCTAssertEqual(FlutterPdfPageLayout.double.toReadiumSpread(), .always)
        XCTAssertEqual(FlutterPdfPageLayout.automatic.toReadiumSpread(), .auto)
    }

    // MARK: - Preferences Init Tests

    func testInitFromMapWithAllValues() {
        let map: [String: Any] = [
            "fit": "width",
            "scrollMode": "vertical",
            "pageLayout": "double",
            "offsetFirstPage": true
        ]

        let prefs = FlutterPdfPreferences(fromMap: map)

        XCTAssertEqual(prefs.fit, .width)
        XCTAssertEqual(prefs.scrollMode, .vertical)
        XCTAssertEqual(prefs.pageLayout, .double)
        XCTAssertEqual(prefs.offsetFirstPage, true)
    }

    func testInitFromMapWithPartialValues() {
        let map: [String: Any] = [
            "fit": "contain",
            "offsetFirstPage": false
        ]

        let prefs = FlutterPdfPreferences(fromMap: map)

        XCTAssertEqual(prefs.fit, .contain)
        XCTAssertNil(prefs.scrollMode)
        XCTAssertNil(prefs.pageLayout)
        XCTAssertEqual(prefs.offsetFirstPage, false)
    }

    func testInitFromEmptyMap() {
        let map: [String: Any] = [:]

        let prefs = FlutterPdfPreferences(fromMap: map)

        XCTAssertNil(prefs.fit)
        XCTAssertNil(prefs.scrollMode)
        XCTAssertNil(prefs.pageLayout)
        XCTAssertNil(prefs.offsetFirstPage)
    }

    func testInitFromNilMap() {
        let prefs = FlutterPdfPreferences(fromMap: nil)

        XCTAssertNil(prefs.fit)
        XCTAssertNil(prefs.scrollMode)
        XCTAssertNil(prefs.pageLayout)
        XCTAssertNil(prefs.offsetFirstPage)
    }

    func testInitFromMapWithInvalidValues() {
        let map: [String: Any] = [
            "fit": "invalid",
            "scrollMode": 123,
            "pageLayout": true,
            "offsetFirstPage": "notabool"
        ]

        let prefs = FlutterPdfPreferences(fromMap: map)

        // Invalid enum values should result in nil
        XCTAssertNil(prefs.fit)
        XCTAssertNil(prefs.scrollMode)
        XCTAssertNil(prefs.pageLayout)
        // Wrong type for bool should also be nil
        XCTAssertNil(prefs.offsetFirstPage)
    }

    // MARK: - toReadiumPreferences Tests

    func testToReadiumPreferencesWithAllValues() {
        let prefs = FlutterPdfPreferences(
            fit: .width,
            scrollMode: .vertical,
            pageLayout: .double,
            offsetFirstPage: true
        )

        let readiumPrefs = prefs.toReadiumPreferences()

        XCTAssertEqual(readiumPrefs.scroll, true)
        XCTAssertEqual(readiumPrefs.scrollAxis, .vertical)
        XCTAssertEqual(readiumPrefs.spread, .always)
        XCTAssertEqual(readiumPrefs.offsetFirstPage, true)
    }

    func testToReadiumPreferencesWithPartialValues() {
        let prefs = FlutterPdfPreferences(
            fit: .contain,
            scrollMode: nil,
            pageLayout: .single,
            offsetFirstPage: nil
        )

        let readiumPrefs = prefs.toReadiumPreferences()

        XCTAssertEqual(readiumPrefs.scroll, false)
        XCTAssertNil(readiumPrefs.scrollAxis)
        XCTAssertEqual(readiumPrefs.spread, .never)
        XCTAssertNil(readiumPrefs.offsetFirstPage)
    }

    func testToReadiumPreferencesWithNoValues() {
        let prefs = FlutterPdfPreferences()

        let readiumPrefs = prefs.toReadiumPreferences()

        XCTAssertNil(readiumPrefs.scroll)
        XCTAssertNil(readiumPrefs.scrollAxis)
        XCTAssertNil(readiumPrefs.spread)
        XCTAssertNil(readiumPrefs.offsetFirstPage)
    }

    // MARK: - toMap Tests

    func testToMapWithAllValues() {
        let prefs = FlutterPdfPreferences(
            fit: .width,
            scrollMode: .horizontal,
            pageLayout: .automatic,
            offsetFirstPage: false
        )

        let map = prefs.toMap()

        XCTAssertEqual(map["fit"] as? String, "width")
        XCTAssertEqual(map["scrollMode"] as? String, "horizontal")
        XCTAssertEqual(map["pageLayout"] as? String, "automatic")
        XCTAssertEqual(map["offsetFirstPage"] as? Bool, false)
    }

    func testToMapWithNoValues() {
        let prefs = FlutterPdfPreferences()

        let map = prefs.toMap()

        XCTAssertTrue(map.isEmpty)
    }
}
