//
//  FlutterNavigationConfigTests.swift
//  flureadiumTests
//
//  Unit tests for FlutterNavigationConfig.
//

import XCTest
@testable import flureadium

final class FlutterNavigationConfigTests: XCTestCase {

    // MARK: - Init Tests

    func testInitDefaultsAllNil() {
        let config = FlutterNavigationConfig()
        XCTAssertNil(config.enableEdgeTapNavigation)
        XCTAssertNil(config.enableSwipeNavigation)
        XCTAssertNil(config.edgeTapAreaPoints)
        XCTAssertNil(config.disableDoubleTapZoom)
        XCTAssertNil(config.disableTextSelection)
        XCTAssertNil(config.disableDragGestures)
        XCTAssertNil(config.disableDoubleTapTextSelection)
    }

    func testInitFromMapWithAllValues() {
        let map: [String: Any] = [
            "enableEdgeTapNavigation": true,
            "enableSwipeNavigation": false,
            "edgeTapAreaPoints": 60.0,
            "disableDoubleTapZoom": true,
            "disableTextSelection": false,
            "disableDragGestures": true,
            "disableDoubleTapTextSelection": false,
        ]
        let config = FlutterNavigationConfig(fromMap: map)
        XCTAssertEqual(config.enableEdgeTapNavigation, true)
        XCTAssertEqual(config.enableSwipeNavigation, false)
        XCTAssertEqual(config.edgeTapAreaPoints, 60.0)
        XCTAssertEqual(config.disableDoubleTapZoom, true)
        XCTAssertEqual(config.disableTextSelection, false)
        XCTAssertEqual(config.disableDragGestures, true)
        XCTAssertEqual(config.disableDoubleTapTextSelection, false)
    }

    func testInitFromMapWithPartialValues() {
        let map: [String: Any] = [
            "enableEdgeTapNavigation": false,
            "disableDoubleTapZoom": true,
        ]
        let config = FlutterNavigationConfig(fromMap: map)
        XCTAssertEqual(config.enableEdgeTapNavigation, false)
        XCTAssertNil(config.enableSwipeNavigation)
        XCTAssertNil(config.edgeTapAreaPoints)
        XCTAssertEqual(config.disableDoubleTapZoom, true)
        XCTAssertNil(config.disableTextSelection)
        XCTAssertNil(config.disableDragGestures)
        XCTAssertNil(config.disableDoubleTapTextSelection)
    }

    func testInitFromEmptyMap() {
        let config = FlutterNavigationConfig(fromMap: [:])
        XCTAssertNil(config.enableEdgeTapNavigation)
        XCTAssertNil(config.enableSwipeNavigation)
        XCTAssertNil(config.edgeTapAreaPoints)
        XCTAssertNil(config.disableDoubleTapZoom)
        XCTAssertNil(config.disableTextSelection)
        XCTAssertNil(config.disableDragGestures)
        XCTAssertNil(config.disableDoubleTapTextSelection)
    }

    func testInitFromNilMap() {
        let config = FlutterNavigationConfig(fromMap: nil)
        XCTAssertNil(config.enableEdgeTapNavigation)
        XCTAssertNil(config.enableSwipeNavigation)
        XCTAssertNil(config.edgeTapAreaPoints)
        XCTAssertNil(config.disableDoubleTapZoom)
        XCTAssertNil(config.disableTextSelection)
        XCTAssertNil(config.disableDragGestures)
        XCTAssertNil(config.disableDoubleTapTextSelection)
    }

    func testEdgeTapAreaPointsAsDouble() {
        let map: [String: Any] = ["edgeTapAreaPoints": 88.5]
        let config = FlutterNavigationConfig(fromMap: map)
        XCTAssertEqual(config.edgeTapAreaPoints, 88.5)
    }

    func testBooleansAreTypedNotStrings() {
        // Values come from Dart as Bool, not String
        let map: [String: Any] = [
            "enableEdgeTapNavigation": true,
            "disableDoubleTapZoom": false,
        ]
        let config = FlutterNavigationConfig(fromMap: map)
        XCTAssertEqual(config.enableEdgeTapNavigation, true)
        XCTAssertEqual(config.disableDoubleTapZoom, false)
    }

    func testStringValuesNotParsedAsBools() {
        // String "true" should not be parsed as Bool true
        let map: [String: Any] = [
            "enableEdgeTapNavigation": "true",
        ]
        let config = FlutterNavigationConfig(fromMap: map)
        XCTAssertNil(config.enableEdgeTapNavigation)
    }
}
