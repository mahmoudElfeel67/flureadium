import XCTest
import ReadiumShared
import ReadiumNavigator
@testable import flureadium

final class FlutterTTSNavigatorTests: XCTestCase {

    // MARK: - Helpers

    private func makeUnspeakablePublication() -> Publication {
        Publication(manifest: Manifest(metadata: Metadata(title: "Unspeakable")))
    }

    private func makeLocator(href: String = "chapter1.xhtml") -> Locator {
        Locator(href: URL(string: href)!, mediaType: .html)
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
}
