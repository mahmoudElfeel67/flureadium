import XCTest
import Combine
import ReadiumShared
import ReadiumNavigator
@testable import flureadium

// MARK: - Mock Listener

private class MockTimebasedListener: TimebasedListener {
    var reachedLocatorCalls: [(locator: Locator, link: Link?)] = []
    var highlightCalls: [(locator: Locator?, wordLocator: Locator?)] = []
    var stateChanges: [ReadiumTimebasedState] = []
    var errors: [(error: Error, description: String?)] = []

    func timebasedNavigator(_ nav: FlutterTimebasedNavigator, didChangeState state: ReadiumTimebasedState) {
        stateChanges.append(state)
    }
    func timebasedNavigator(_ nav: FlutterTimebasedNavigator, encounteredError error: Error, withDescription desc: String?) {
        errors.append((error, desc))
    }
    func timebasedNavigator(_ nav: FlutterTimebasedNavigator, reachedLocator locator: Locator, readingOrderLink: Link?) {
        reachedLocatorCalls.append((locator, readingOrderLink))
    }
    func timebasedNavigator(_ nav: FlutterTimebasedNavigator, requestsHighlightAt locator: Locator?, withWordLocator wordLocator: Locator?) {
        highlightCalls.append((locator, wordLocator))
    }
}

final class FlutterTTSNavigatorTests: XCTestCase {

    // MARK: - Helpers

    private func makeUnspeakablePublication() -> Publication {
        Publication(manifest: Manifest(metadata: Metadata(title: "Unspeakable")))
    }

    private func makeLocator(href: String = "chapter1.xhtml") -> Locator {
        Locator(href: URL(string: href)!, mediaType: .html)
    }

    /// Creates a navigator with listeners set up and a mock attached.
    private func makeNavigatorWithMock(
        initialLocator: Locator? = nil
    ) -> (FlutterTTSNavigator, MockTimebasedListener) {
        let navigator = FlutterTTSNavigator(
            publication: makeUnspeakablePublication(),
            initialLocator: initialLocator
        )
        let mock = MockTimebasedListener()
        navigator.listener = mock
        navigator.setupNavigatorListeners()
        return (navigator, mock)
    }

    // MARK: - play() initialLocator consumption

    func testPlayConsumesInitialLocator() async {
        let publication = makeUnspeakablePublication()
        let saved = makeLocator(href: "saved-position.xhtml")
        let navigator = FlutterTTSNavigator(
            publication: publication,
            initialLocator: saved
        )

        XCTAssertNotNil(navigator.initialLocator, "initialLocator should be set before play")

        await navigator.play(fromLocator: nil)

        XCTAssertNil(navigator.initialLocator,
                      "initialLocator should be nil after play consumes it")
    }

    func testPlayClearsInitialLocatorWhenFromLocatorProvided() async {
        let publication = makeUnspeakablePublication()
        let saved = makeLocator(href: "saved-position.xhtml")
        let other = makeLocator(href: "other-position.xhtml")
        let navigator = FlutterTTSNavigator(
            publication: publication,
            initialLocator: saved
        )

        await navigator.play(fromLocator: other)

        XCTAssertNil(navigator.initialLocator,
                      "initialLocator should be nil after play, even when fromLocator is provided")
    }

    func testPlayWithNoInitialLocatorKeepsNil() async {
        let publication = makeUnspeakablePublication()
        let navigator = FlutterTTSNavigator(
            publication: publication,
            initialLocator: nil
        )

        await navigator.play(fromLocator: nil)

        XCTAssertNil(navigator.initialLocator,
                      "initialLocator should remain nil when it was never set")
    }

    // MARK: - Suppression: first utterance after play(fromLocator:)

    func testPlayFromLocatorSuppressesFirstUtterance() async {
        let startLocator = makeLocator(href: "page2.xhtml")
        let (navigator, mock) = makeNavigatorWithMock(initialLocator: startLocator)

        await navigator.play(fromLocator: nil) // uses initialLocator

        // Simulate the synthesizer emitting the first utterance
        navigator.playingUtterance = makeLocator(href: "page1.xhtml")

        XCTAssertEqual(mock.reachedLocatorCalls.count, 0,
                        "First utterance after play should be suppressed to prevent backward scroll")
    }

    func testPlayWithExplicitFromLocatorSuppressesFirstUtterance() async {
        let (navigator, mock) = makeNavigatorWithMock(initialLocator: nil)

        await navigator.play(fromLocator: makeLocator(href: "page2.xhtml"))

        navigator.playingUtterance = makeLocator(href: "page1.xhtml")

        XCTAssertEqual(mock.reachedLocatorCalls.count, 0,
                        "First utterance after play(fromLocator:) should be suppressed")
    }

    func testPlayWithoutLocatorDoesNotSuppress() async {
        let (navigator, mock) = makeNavigatorWithMock(initialLocator: nil)

        await navigator.play(fromLocator: nil) // no locator at all

        navigator.playingUtterance = makeLocator(href: "page1.xhtml")

        XCTAssertEqual(mock.reachedLocatorCalls.count, 1,
                        "Utterance should reach listener when no start locator was provided")
    }

    // MARK: - Suppression: second utterance resumes normal behavior

    func testSecondUtteranceAfterSuppressionReachesListener() async {
        let (navigator, mock) = makeNavigatorWithMock(
            initialLocator: makeLocator(href: "page2.xhtml")
        )

        await navigator.play(fromLocator: nil)

        // First utterance — should be suppressed
        navigator.playingUtterance = makeLocator(href: "page1.xhtml")
        // Second utterance — should reach listener
        navigator.playingUtterance = makeLocator(href: "page2.xhtml")

        XCTAssertEqual(mock.reachedLocatorCalls.count, 1,
                        "Second utterance should reach listener after suppression ends")
    }

    // MARK: - Suppression: seek clears suppression

    func testSeekForwardClearsSuppression() async {
        let (navigator, mock) = makeNavigatorWithMock(
            initialLocator: makeLocator(href: "page2.xhtml")
        )

        await navigator.play(fromLocator: nil)
        _ = await navigator.seekForward()

        navigator.playingUtterance = makeLocator(href: "page1.xhtml")

        XCTAssertEqual(mock.reachedLocatorCalls.count, 1,
                        "Utterance should reach listener after seekForward clears suppression")
    }

    func testSeekBackwardClearsSuppression() async {
        let (navigator, mock) = makeNavigatorWithMock(
            initialLocator: makeLocator(href: "page2.xhtml")
        )

        await navigator.play(fromLocator: nil)
        _ = await navigator.seekBackward()

        navigator.playingUtterance = makeLocator(href: "page1.xhtml")

        XCTAssertEqual(mock.reachedLocatorCalls.count, 1,
                        "Utterance should reach listener after seekBackward clears suppression")
    }

    func testSeekToLocatorClearsSuppression() async {
        let (navigator, mock) = makeNavigatorWithMock(
            initialLocator: makeLocator(href: "page2.xhtml")
        )

        await navigator.play(fromLocator: nil)
        _ = await navigator.seek(toLocator: makeLocator(href: "page3.xhtml"))

        navigator.playingUtterance = makeLocator(href: "page3.xhtml")

        XCTAssertEqual(mock.reachedLocatorCalls.count, 1,
                        "Utterance should reach listener after seek(toLocator:) clears suppression")
    }

    // MARK: - Suppression: word range during suppressed utterance

    func testWordRangeSuppressedDuringFirstUtterance() async {
        let (navigator, mock) = makeNavigatorWithMock(
            initialLocator: makeLocator(href: "page2.xhtml")
        )

        await navigator.play(fromLocator: nil)

        // First utterance — suppressed
        navigator.playingUtterance = makeLocator(href: "page1.xhtml")

        // Word range during suppressed utterance
        navigator.playingWordRangeSubject.send(makeLocator(href: "page1.xhtml"))

        // Wait for throttle (100ms) to flush
        let throttleExpectation = expectation(description: "throttle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            throttleExpectation.fulfill()
        }
        await fulfillment(of: [throttleExpectation], timeout: 1.0)

        XCTAssertEqual(mock.reachedLocatorCalls.count, 0,
                        "Word range during suppressed utterance should not reach listener")
    }
}
