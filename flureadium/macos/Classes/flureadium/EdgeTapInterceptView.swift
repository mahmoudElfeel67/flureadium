//
//  EdgeTapInterceptView.swift
//  flureadium (macOS)
//
//  Edge click detection overlay for reader navigation.
//  macOS port: Uses NSClickGestureRecognizer instead of UITapGestureRecognizer,
//  and mouse tracking instead of UISwipeGestureRecognizer.
//

import AppKit

/// View that intercepts edge clicks for page navigation when Readium's
/// gesture recognizers fail to receive events through Flutter's platform view.
class EdgeTapInterceptView: NSView {
    /// Callback for left edge click
    var onLeftEdgeTap: (() -> Void)?
    /// Callback for right edge click
    var onRightEdgeTap: (() -> Void)?
    /// Callback for swipe left gesture (trackpad)
    var onSwipeLeft: (() -> Void)?
    /// Callback for swipe right gesture (trackpad)
    var onSwipeRight: (() -> Void)?
    /// Edge threshold in absolute points (default 44pt)
    var edgeThresholdPoints: CGFloat = 44.0
    /// When true, hitTest returns self for any click in an edge zone,
    /// preventing downstream gesture recognizers from seeing those events.
    var interceptEdgeTaps: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestureRecognizer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestureRecognizer()
    }

    private func setupGestureRecognizer() {
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        clickGesture.delaysPrimaryMouseButtonEvents = false
        addGestureRecognizer(clickGesture)
    }

    @objc private func handleClick(_ gesture: NSClickGestureRecognizer) {
        let location = gesture.location(in: self)
        let edgeSize = edgeThresholdPoints

        // macOS coordinate system: origin is bottom-left
        // But in a flipped view the origin is top-left (same as iOS)
        if location.x < edgeSize {
            onLeftEdgeTap?()
        } else if location.x > bounds.width - edgeSize {
            onRightEdgeTap?()
        }
    }

    // macOS trackpad swipe detection via scroll events
    override func scrollWheel(with event: NSEvent) {
        // Only handle momentum/gesture scroll (trackpad swipes), not mouse wheel
        if event.phase == .changed || event.momentumPhase == .changed {
            if event.scrollingDeltaX > 20 {
                onSwipeRight?()
            } else if event.scrollingDeltaX < -20 {
                onSwipeLeft?()
            }
        }
        super.scrollWheel(with: event)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let result = super.hitTest(point)

        let edgeSize = edgeThresholdPoints
        let isLeftEdge = point.x < edgeSize
        let isRightEdge = point.x > bounds.width - edgeSize

        if interceptEdgeTaps && (isLeftEdge || isRightEdge) {
            return self
        }

        return result
    }

    override var isFlipped: Bool {
        return true
    }
}
