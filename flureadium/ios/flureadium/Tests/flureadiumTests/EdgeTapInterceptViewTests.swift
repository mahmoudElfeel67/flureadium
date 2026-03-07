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
        XCTAssertEqual(view.edgeThresholdPoints, 44.0)
    }

    func testCallbacksDefaultToNil() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertNil(view.onLeftEdgeTap)
        XCTAssertNil(view.onRightEdgeTap)
    }

    func testCustomEdgeThreshold() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.edgeThresholdPoints = 60.0
        XCTAssertEqual(view.edgeThresholdPoints, 60.0)
    }

    // MARK: - Edge Detection Calculation Tests

    func testLeftEdgeDetection() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        // With 44pt threshold, left edge is x < 44

        // Point at x=20 should be in left edge (20 < 44)
        let leftEdgePoint = CGPoint(x: 20, y: 50)
        let edgeSize = view.edgeThresholdPoints
        XCTAssertTrue(leftEdgePoint.x < edgeSize, "Point at x=20 should be in left edge zone")

        // Point at x=60 should NOT be in left edge (60 < 44 is false)
        let outerPoint = CGPoint(x: 60, y: 50)
        XCTAssertFalse(outerPoint.x < edgeSize, "Point at x=60 should not be in left edge zone")
    }

    func testRightEdgeDetection() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        // With 44pt threshold, right edge is x > 56 (100 - 44 = 56)

        // Point at x=75 should be in right edge (75 > 56)
        let rightEdgePoint = CGPoint(x: 75, y: 50)
        let edgeSize = view.edgeThresholdPoints
        XCTAssertTrue(rightEdgePoint.x > view.bounds.width - edgeSize, "Point at x=75 should be in right edge zone")

        // Point at x=40 should NOT be in right edge (40 > 56 is false)
        let outerPoint = CGPoint(x: 40, y: 50)
        XCTAssertFalse(outerPoint.x > view.bounds.width - edgeSize, "Point at x=40 should not be in right edge zone")
    }

    func testCenterZoneNotInEdge() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let edgeSize = view.edgeThresholdPoints

        // Point at x=50 (center) should not be in any edge
        // Left edge: x < 44. Right edge: x > 56. x=50 is in neither.
        let centerPoint = CGPoint(x: 50, y: 50)
        let isInLeftEdge = centerPoint.x < edgeSize
        let isInRightEdge = centerPoint.x > view.bounds.width - edgeSize

        XCTAssertFalse(isInLeftEdge, "Center point should not be in left edge")
        XCTAssertFalse(isInRightEdge, "Center point should not be in right edge")
    }

    // MARK: - Hit Test Tests

    func testHitTestReturnsNilWhenNoCallbacks() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.interceptEdgeTaps = false  // pass-through is gated on interceptEdgeTaps, not callback presence
        // No callbacks set

        let leftEdgePoint = CGPoint(x: 5, y: 50)
        let rightEdgePoint = CGPoint(x: 95, y: 50)

        XCTAssertNil(view.hitTest(leftEdgePoint, with: nil), "Hit test should return nil for left edge when interceptEdgeTaps=false")
        XCTAssertNil(view.hitTest(rightEdgePoint, with: nil), "Hit test should return nil for right edge when interceptEdgeTaps=false")
    }

    func testHitTestReturnsSelfForLeftEdgeWithCallback() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }

        let leftEdgePoint = CGPoint(x: 20, y: 50)
        XCTAssertEqual(view.hitTest(leftEdgePoint, with: nil), view, "Hit test should return self for left edge with callback")
    }

    func testHitTestReturnsSelfForRightEdgeWithCallback() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.interceptEdgeTaps = true
        view.onRightEdgeTap = { }

        let rightEdgePoint = CGPoint(x: 75, y: 50)
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
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }
        let edgeSize = view.edgeThresholdPoints // 44

        // Point exactly at boundary (x=44) should NOT be in left edge (44 < 44 is false)
        let boundaryPoint = CGPoint(x: edgeSize, y: 50)
        XCTAssertNil(view.hitTest(boundaryPoint, with: nil), "Point exactly at left boundary should not trigger")
    }

    func testExactlyOnRightEdgeBoundary() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.interceptEdgeTaps = true
        view.onRightEdgeTap = { }
        let edgeSize = view.edgeThresholdPoints // 44
        let rightBoundary = view.bounds.width - edgeSize // 56

        // Point exactly at boundary (x=56) should NOT be in right edge (56 > 56 is false)
        let boundaryPoint = CGPoint(x: rightBoundary, y: 50)
        XCTAssertNil(view.hitTest(boundaryPoint, with: nil), "Point exactly at right boundary should not trigger")
    }

    // MARK: - Different View Sizes Tests

    func testEdgeDetectionWithLargeView() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        // With 44pt threshold on 1000px width, left edge is 0-44, right edge is 956-1000
        let leftEdgePoint = CGPoint(x: 20, y: 400)
        let rightEdgePoint = CGPoint(x: 975, y: 400)
        let centerPoint = CGPoint(x: 500, y: 400)

        XCTAssertEqual(view.hitTest(leftEdgePoint, with: nil), view, "Left edge detection should work on large view")
        XCTAssertEqual(view.hitTest(rightEdgePoint, with: nil), view, "Right edge detection should work on large view")
        XCTAssertNil(view.hitTest(centerPoint, with: nil), "Center detection should work on large view")
    }

    func testEdgeDetectionWithSmallView() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
        view.edgeThresholdPoints = 10.0  // Use a small threshold for this small view test
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        // With 10pt threshold on 50px width, left edge is 0-10, right edge is 40-50
        let leftEdgePoint = CGPoint(x: 5, y: 25)
        let rightEdgePoint = CGPoint(x: 45, y: 25)
        let centerPoint = CGPoint(x: 25, y: 25)

        XCTAssertEqual(view.hitTest(leftEdgePoint, with: nil), view, "Left edge detection should work on small view")
        XCTAssertEqual(view.hitTest(rightEdgePoint, with: nil), view, "Right edge detection should work on small view")
        XCTAssertNil(view.hitTest(centerPoint, with: nil), "Center detection should work on small view")
    }

    // MARK: - Custom Threshold Tests

    func testEdgeThresholdAcceptsAnyValue() {
        // The view is a dumb component - clamping happens in reader views, not here
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.edgeThresholdPoints = 20.0
        XCTAssertEqual(view.edgeThresholdPoints, 20.0, "View should accept values below 44pt range")

        view.edgeThresholdPoints = 200.0
        XCTAssertEqual(view.edgeThresholdPoints, 200.0, "View should accept values above 120pt range")
    }

    func testDefaultThresholdIsExactly44Points() {
        // Default is 44pt — the iOS HIG minimum tap target size
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        XCTAssertEqual(view.edgeThresholdPoints, 44.0, "Default threshold should be exactly 44pt (iOS HIG minimum)")
    }

    func testCustomThresholdChangesEdgeZones() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.edgeThresholdPoints = 30.0  // 30pt threshold
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        // With 30pt threshold on 100px width, left edge is 0-30, right edge is 70-100
        let leftEdgePoint = CGPoint(x: 15, y: 50)
        let rightEdgePoint = CGPoint(x: 85, y: 50)
        let outsideLeftEdge = CGPoint(x: 40, y: 50)   // Not in 30pt left edge
        let outsideRightEdge = CGPoint(x: 60, y: 50)  // Not in 30pt right edge

        XCTAssertEqual(view.hitTest(leftEdgePoint, with: nil), view, "Point in 30pt left edge should trigger")
        XCTAssertEqual(view.hitTest(rightEdgePoint, with: nil), view, "Point in 30pt right edge should trigger")
        XCTAssertNil(view.hitTest(outsideLeftEdge, with: nil), "Point outside 30pt left edge should not trigger")
        XCTAssertNil(view.hitTest(outsideRightEdge, with: nil), "Point outside 30pt right edge should not trigger")
    }

    // MARK: - Dynamic Threshold Update Tests

    func testThresholdUpdateExpandsEdgeZone() {
        // Simulates configureEdgeTapHandlers() updating edgeThresholdPoints at runtime
        // (the behavior relied on by ReadiumReaderView and PdfReaderView after setPreferences)
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }

        // Default 44pt threshold: x=50 is outside left edge (50 >= 44)
        XCTAssertNil(view.hitTest(CGPoint(x: 50, y: 50), with: nil), "x=50 should not be in left edge with 44pt threshold")

        // Update threshold to 80pt
        view.edgeThresholdPoints = 80.0

        // Now x=50 IS inside left edge (50 < 80)
        XCTAssertEqual(view.hitTest(CGPoint(x: 50, y: 50), with: nil), view, "x=50 should be in left edge after updating threshold to 80pt")
    }

    func testThresholdUpdateShrinksEdgeZone() {
        // Verify that shrinking the threshold takes effect immediately
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }
        view.edgeThresholdPoints = 80.0

        // With 80pt threshold: x=50 is in left edge (50 < 80)
        XCTAssertEqual(view.hitTest(CGPoint(x: 50, y: 50), with: nil), view, "x=50 should be in left edge with 80pt threshold")

        // Reduce threshold to 44pt
        view.edgeThresholdPoints = 44.0

        // Now x=50 is no longer in left edge (50 >= 44)
        XCTAssertNil(view.hitTest(CGPoint(x: 50, y: 50), with: nil), "x=50 should not be in left edge after reducing threshold to 44pt")
    }

    func testThresholdUpdateAffectsBothEdgesSynchronously() {
        // Verify both left and right edge zones update when threshold changes
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        // Default 44pt: on 200px view, left=0-44, right=156-200. x=50 and x=150 are center.
        XCTAssertNil(view.hitTest(CGPoint(x: 50, y: 50), with: nil), "x=50 should not trigger with 44pt threshold")
        XCTAssertNil(view.hitTest(CGPoint(x: 150, y: 50), with: nil), "x=150 should not trigger with 44pt threshold")

        // Update to 80pt: left=0-80, right=120-200
        view.edgeThresholdPoints = 80.0

        XCTAssertEqual(view.hitTest(CGPoint(x: 50, y: 50), with: nil), view, "x=50 should be in left edge after updating to 80pt")
        XCTAssertEqual(view.hitTest(CGPoint(x: 150, y: 50), with: nil), view, "x=150 should be in right edge after updating to 80pt")
    }

    func testThresholdCanBeUpdatedMultipleTimes() {
        // Verify multiple sequential updates all take effect (regression check for var mutation)
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }

        let testPoint = CGPoint(x: 60, y: 50)

        view.edgeThresholdPoints = 44.0  // 60 >= 44 → not in edge
        XCTAssertNil(view.hitTest(testPoint, with: nil), "x=60 not in left edge at 44pt")

        view.edgeThresholdPoints = 80.0  // 60 < 80 → in edge
        XCTAssertEqual(view.hitTest(testPoint, with: nil), view, "x=60 in left edge at 80pt")

        view.edgeThresholdPoints = 50.0  // 60 >= 50 → not in edge
        XCTAssertNil(view.hitTest(testPoint, with: nil), "x=60 not in left edge at 50pt")

        view.edgeThresholdPoints = 70.0  // 60 < 70 → in edge
        XCTAssertEqual(view.hitTest(testPoint, with: nil), view, "x=60 in left edge at 70pt")
    }

    // MARK: - interceptEdgeTaps Property Tests

    func testInterceptEdgeTapsDefaultIsFalse() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        XCTAssertFalse(view.interceptEdgeTaps, "interceptEdgeTaps should default to false")
    }

    func testHitTestReturnsSelfWithInterceptEnabledAndNoCallback() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.interceptEdgeTaps = true
        // No callbacks set

        XCTAssertEqual(view.hitTest(CGPoint(x: 5, y: 50), with: nil), view,
            "Left edge should return self when interceptEdgeTaps=true even with no callback")
        XCTAssertEqual(view.hitTest(CGPoint(x: 95, y: 50), with: nil), view,
            "Right edge should return self when interceptEdgeTaps=true even with no callback")
    }

    func testHitTestPassesThroughWithInterceptDisabledRegardlessOfCallbacks() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        view.interceptEdgeTaps = false
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        // With interceptEdgeTaps=false, hitTest falls through to super even if callbacks are set.
        // super.hitTest in XCTest (no window) returns nil for edge points — assert not self.
        let leftResult = view.hitTest(CGPoint(x: 5, y: 50), with: nil)
        let rightResult = view.hitTest(CGPoint(x: 95, y: 50), with: nil)
        XCTAssertNotEqual(leftResult, view, "Should not return self for left edge when interceptEdgeTaps=false")
        XCTAssertNotEqual(rightResult, view, "Should not return self for right edge when interceptEdgeTaps=false")
    }

    func testHitTestReturnsSelfForBothEdgesWhenInterceptEnabled() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        view.interceptEdgeTaps = true

        XCTAssertEqual(view.hitTest(CGPoint(x: 9, y: 400), with: nil), view,
            "Left edge (x=9) intercepted on iPhone-sized view")
        XCTAssertEqual(view.hitTest(CGPoint(x: 366, y: 400), with: nil), view,
            "Right edge (x=366) intercepted on iPhone-sized view")
    }

    func testCenterZoneAlwaysPassesThroughWhenInterceptEnabled() {
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        view.interceptEdgeTaps = true
        view.onLeftEdgeTap = { }
        view.onRightEdgeTap = { }

        let centerResult = view.hitTest(CGPoint(x: 187, y: 400), with: nil)
        XCTAssertNotEqual(centerResult, view,
            "Center zone should never be intercepted even when interceptEdgeTaps=true")
    }

    func testInterceptDisabledByDefaultPreventsAccidentalBlocking() {
        // Regression: freshly created view (before configureEdgeTapHandlers) must not intercept.
        let view = EdgeTapInterceptView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))

        XCTAssertNotEqual(view.hitTest(CGPoint(x: 9, y: 400), with: nil), view,
            "Edge zones should not be intercepted in default state")
        XCTAssertNotEqual(view.hitTest(CGPoint(x: 366, y: 400), with: nil), view,
            "Edge zones should not be intercepted in default state")
    }
}
