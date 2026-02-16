//
//  EdgeTapInterceptViewTests.swift
//  flureadiumTests
//
//  Unit tests for EdgeTapInterceptView.
//

import XCTest
@testable import flureadium

final class EdgeTapInterceptViewTests: XCTestCase {

    // MARK: - Initialization Tests

    func testDefaultEdgeThreshold() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertEqual(view.edgeThresholdPercent, 0.12)
    }

    func testCallbacksDefaultToNil() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertNil(view.onLeftEdgeTap)
        XCTAssertNil(view.onRightEdgeTap)
    }

    func testCustomEdgeThreshold() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.edgeThresholdPercent = 0.2
        XCTAssertEqual(view.edgeThresholdPercent, 0.2)
    }

    // MARK: - Edge Detection Calculation Tests

    func testLeftEdgeDetection() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        // With 12% threshold, left edge is 0-12 pixels

        // Point at x=5 should be in left edge (5 < 12)
        let leftEdgePoint = CGPoint(x: 5, y: 50)
        let edgeSize = view.bounds.width * view.edgeThresholdPercent
        XCTAssertTrue(leftEdgePoint.x < edgeSize, "Point at x=5 should be in left edge zone")

        // Point at x=50 should NOT be in left edge (50 > 12)
        let centerPoint = CGPoint(x: 50, y: 50)
        XCTAssertFalse(centerPoint.x < edgeSize, "Point at x=50 should not be in left edge zone")
    }

    func testRightEdgeDetection() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        // With 12% threshold, right edge is 88-100 pixels

        // Point at x=95 should be in right edge (95 > 88)
        let rightEdgePoint = CGPoint(x: 95, y: 50)
        let edgeSize = view.bounds.width * view.edgeThresholdPercent
        XCTAssertTrue(rightEdgePoint.x > view.bounds.width - edgeSize, "Point at x=95 should be in right edge zone")

        // Point at x=50 should NOT be in right edge (50 < 88)
        let centerPoint = CGPoint(x: 50, y: 50)
        XCTAssertFalse(centerPoint.x > view.bounds.width - edgeSize, "Point at x=50 should not be in right edge zone")
    }

    func testCenterZoneNotInEdge() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let edgeSize = view.bounds.width * view.edgeThresholdPercent

        // Point at x=50 (center) should not be in any edge
        let centerPoint = CGPoint(x: 50, y: 50)
        let isInLeftEdge = centerPoint.x < edgeSize
        let isInRightEdge = centerPoint.x > view.bounds.width - edgeSize

        XCTAssertFalse(isInLeftEdge, "Center point should not be in left edge")
        XCTAssertFalse(isInRightEdge, "Center point should not be in right edge")
    }

    // MARK: - Hit Test Tests

    func testHitTestReturnsNilWhenNoCallbacks() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        // No callbacks set

        let leftEdgePoint = CGPoint(x: 5, y: 50)
        let rightEdgePoint = CGPoint(x: 95, y: 50)

        XCTAssertNil(view.hitTest(leftEdgePoint, with: nil), "Hit test should return nil for left edge when no callback")
        XCTAssertNil(view.hitTest(rightEdgePoint, with: nil), "Hit test should return nil for right edge when no callback")
    }

    func testHitTestReturnsSelfForLeftEdgeWithCallback() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.onLeftEdgeTap = { }

        let leftEdgePoint = CGPoint(x: 5, y: 50)
        XCTAssertEqual(view.hitTest(leftEdgePoint, with: nil), view, "Hit test should return self for left edge with callback")
    }

    func testHitTestReturnsSelfForRightEdgeWithCallback() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.onRightEdgeTap = { }

        let rightEdgePoint = CGPoint(x: 95, y: 50)
        XCTAssertEqual(view.hitTest(rightEdgePoint, with: nil), view, "Hit test should return self for right edge with callback")
    }

    func testHitTestReturnsNilForCenter() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        let centerPoint = CGPoint(x: 50, y: 50)
        XCTAssertNil(view.hitTest(centerPoint, with: nil), "Hit test should return nil for center even with callbacks")
    }

    // MARK: - Callback Configuration Tests

    func testLeftEdgeCallbackCanBeSet() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        var callbackInvoked = false

        view.onLeftEdgeTap = { callbackInvoked = true }
        view.onLeftEdgeTap?()

        XCTAssertTrue(callbackInvoked, "Left edge callback should be invocable")
    }

    func testRightEdgeCallbackCanBeSet() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        var callbackInvoked = false

        view.onRightEdgeTap = { callbackInvoked = true }
        view.onRightEdgeTap?()

        XCTAssertTrue(callbackInvoked, "Right edge callback should be invocable")
    }

    func testCallbacksCanBeCleared() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        view.onLeftEdgeTap = nil
        view.onRightEdgeTap = nil

        XCTAssertNil(view.onLeftEdgeTap, "Left callback should be clearable")
        XCTAssertNil(view.onRightEdgeTap, "Right callback should be clearable")
    }

    // MARK: - Edge Threshold Boundary Tests

    func testExactlyOnLeftEdgeBoundary() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.onLeftEdgeTap = { }
        let edgeSize = view.bounds.width * view.edgeThresholdPercent // 12

        // Point exactly at boundary (x=12) should NOT be in left edge (12 < 12 is false)
        let boundaryPoint = CGPoint(x: edgeSize, y: 50)
        XCTAssertNil(view.hitTest(boundaryPoint, with: nil), "Point exactly at left boundary should not trigger")
    }

    func testExactlyOnRightEdgeBoundary() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.onRightEdgeTap = { }
        let edgeSize = view.bounds.width * view.edgeThresholdPercent // 12
        let rightBoundary = view.bounds.width - edgeSize // 88

        // Point exactly at boundary (x=88) should NOT be in right edge (88 > 88 is false)
        let boundaryPoint = CGPoint(x: rightBoundary, y: 50)
        XCTAssertNil(view.hitTest(boundaryPoint, with: nil), "Point exactly at right boundary should not trigger")
    }

    // MARK: - Different View Sizes Tests

    func testEdgeDetectionWithLargeView() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        // With 12% threshold on 1000px width, left edge is 0-120, right edge is 880-1000
        let leftEdgePoint = CGPoint(x: 60, y: 400)
        let rightEdgePoint = CGPoint(x: 950, y: 400)
        let centerPoint = CGPoint(x: 500, y: 400)

        XCTAssertEqual(view.hitTest(leftEdgePoint, with: nil), view, "Left edge detection should work on large view")
        XCTAssertEqual(view.hitTest(rightEdgePoint, with: nil), view, "Right edge detection should work on large view")
        XCTAssertNil(view.hitTest(centerPoint, with: nil), "Center detection should work on large view")
    }

    func testEdgeDetectionWithSmallView() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        // With 12% threshold on 50px width, left edge is 0-6, right edge is 44-50
        let leftEdgePoint = CGPoint(x: 3, y: 25)
        let rightEdgePoint = CGPoint(x: 47, y: 25)
        let centerPoint = CGPoint(x: 25, y: 25)

        XCTAssertEqual(view.hitTest(leftEdgePoint, with: nil), view, "Left edge detection should work on small view")
        XCTAssertEqual(view.hitTest(rightEdgePoint, with: nil), view, "Right edge detection should work on small view")
        XCTAssertNil(view.hitTest(centerPoint, with: nil), "Center detection should work on small view")
    }

    // MARK: - Custom Threshold Tests

    func testEdgeThresholdAcceptsAnyValue() {
        // The view is a dumb component - clamping happens in reader views, not here
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.edgeThresholdPercent = 0.05
        XCTAssertEqual(view.edgeThresholdPercent, 0.05, "View should accept values below 10% range")

        view.edgeThresholdPercent = 0.50
        XCTAssertEqual(view.edgeThresholdPercent, 0.50, "View should accept values above 30% range")
    }

    func testDefaultThresholdGivesMinimum44ptOnSmallestDevice() {
        // iPhone SE has 375pt width. 12% of 375 = 45pt, which is >= 44pt minimum tap target
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let edgeSize = view.bounds.width * view.edgeThresholdPercent
        XCTAssertGreaterThanOrEqual(edgeSize, 44.0, "Default 12% threshold should give >= 44pt on iPhone SE (375pt width)")
    }

    func testCustomThresholdChangesEdgeZones() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.edgeThresholdPercent = 0.1 // 10% threshold
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        // With 10% threshold, left edge is 0-10, right edge is 90-100
        let leftEdgePoint = CGPoint(x: 5, y: 50)
        let rightEdgePoint = CGPoint(x: 95, y: 50)
        let outsideLeftEdge = CGPoint(x: 15, y: 50) // Would be in edge with 30%, but not with 10%
        let outsideRightEdge = CGPoint(x: 85, y: 50) // Would be in edge with 30%, but not with 10%

        XCTAssertEqual(view.hitTest(leftEdgePoint, with: nil), view, "Point in 10% left edge should trigger")
        XCTAssertEqual(view.hitTest(rightEdgePoint, with: nil), view, "Point in 10% right edge should trigger")
        XCTAssertNil(view.hitTest(outsideLeftEdge, with: nil), "Point outside 10% left edge should not trigger")
        XCTAssertNil(view.hitTest(outsideRightEdge, with: nil), "Point outside 10% right edge should not trigger")
    }
}
