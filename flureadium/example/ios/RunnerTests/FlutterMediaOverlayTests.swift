import XCTest
import ReadiumShared
@testable import flureadium

// MARK: - FlutterMediaOverlayItem Tests

final class FlutterMediaOverlayItemTests: XCTestCase {

    // MARK: - Init & Parsing

    func testInitParsesAudioFields() {
        let item = FlutterMediaOverlayItem(
            audio: "audio/chapter1.mp3#t=1.5,5.0",
            text: "text/chapter1.xhtml#para1",
            position: 0
        )
        XCTAssertEqual(item.audioFile, "audio/chapter1.mp3")
        XCTAssertEqual(item.audioStart, 1.5)
        XCTAssertEqual(item.audioEnd, 5.0)
        XCTAssertEqual(item.textFile, "text/chapter1.xhtml")
        XCTAssertEqual(item.textId, "para1")
    }

    func testInitAudioWithoutFragment() {
        let item = FlutterMediaOverlayItem(audio: "audio/ch1.mp3", text: "text/ch1.xhtml#p1", position: 0)
        XCTAssertEqual(item.audioFile, "audio/ch1.mp3")
        XCTAssertNil(item.audioStart)
        XCTAssertNil(item.audioEnd)
    }

    func testInitAudioWithStartOnly() {
        let item = FlutterMediaOverlayItem(audio: "audio/ch1.mp3#t=3.0", text: "text/ch1.xhtml#p1", position: 0)
        XCTAssertEqual(item.audioStart, 3.0)
        XCTAssertNil(item.audioEnd)
    }

    func testAudioDuration() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=1.0,4.0", text: "t.xhtml#p1", position: 0)
        XCTAssertEqual(item.audioDuration, 3.0)
    }

    func testAudioDurationNilWhenNoEnd() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=1.0", text: "t.xhtml#p1", position: 0)
        XCTAssertNil(item.audioDuration)
    }

    func testAudioMediaTypeMP3() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=0,1", text: "t.xhtml#p", position: 0)
        XCTAssertEqual(item.audioMediaType, .mpegAudio)
    }

    func testAudioMediaTypeOpus() {
        let item = FlutterMediaOverlayItem(audio: "a.opus#t=0,1", text: "t.xhtml#p", position: 0)
        XCTAssertEqual(item.audioMediaType, .opus)
    }

    // MARK: - isAudioInRangeOfTime

    func testIsAudioInRangeOfTimeMatches() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=1.0,5.0", text: "t.xhtml#p", position: 0)
        XCTAssertTrue(item.isAudioInRangeOfTime(3.0, inHref: "a.mp3"))
    }

    func testIsAudioInRangeOfTimeOutOfRange() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=1.0,5.0", text: "t.xhtml#p", position: 0)
        XCTAssertFalse(item.isAudioInRangeOfTime(6.0, inHref: "a.mp3"))
    }

    func testIsAudioInRangeOfTimeWrongHref() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=1.0,5.0", text: "t.xhtml#p", position: 0)
        XCTAssertFalse(item.isAudioInRangeOfTime(3.0, inHref: "other.mp3"))
    }

    func testIsAudioInRangeOfTimeStartOnly() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=2.0", text: "t.xhtml#p", position: 0)
        XCTAssertTrue(item.isAudioInRangeOfTime(5.0, inHref: "a.mp3"))
        XCTAssertFalse(item.isAudioInRangeOfTime(1.0, inHref: "a.mp3"))
    }

    // MARK: - Locator creation

    func testAsTextLocator() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=0,1", text: "text/ch1.xhtml#para1", position: 0)
        let locator = item.asTextLocator
        XCTAssertNotNil(locator)
        XCTAssertEqual(locator?.href.string, "text/ch1.xhtml")
        XCTAssertTrue(locator?.locations.fragments.contains("#para1") ?? false)
    }

    func testAsAudioLocator() {
        let item = FlutterMediaOverlayItem(audio: "audio/ch1.mp3#t=1.5,5.0", text: "t.xhtml#p", position: 0)
        let locator = item.asAudioLocator
        XCTAssertNotNil(locator)
        XCTAssertEqual(locator?.href.string, "audio/ch1.mp3")
        XCTAssertTrue(locator?.locations.fragments.contains("t=1.5") ?? false)
    }

    func testToCombinedLocator() {
        let item = FlutterMediaOverlayItem(audio: "a.mp3#t=1.0,5.0", text: "text/ch1.xhtml#para1", position: 0)
        let audioLocator = Locator(
            href: URL(string: "a.mp3")!,
            mediaType: .mpegAudio,
            locations: .init(fragments: ["t=2.5"], progression: 0.5)
        )
        let combined = item.toCombinedLocator(fromPlaybackLocator: audioLocator)
        XCTAssertNotNil(combined)
        XCTAssertEqual(combined?.href.string, "text/ch1.xhtml")
        XCTAssertTrue(combined?.locations.fragments.contains("t=2.5") ?? false)
        XCTAssertEqual(combined?.locations.progression, 0.5)
    }

    // MARK: - JSON parsing

    func testFromJsonValid() {
        let json: [String: Any] = ["audio": "a.mp3#t=0,1", "text": "t.xhtml#p"]
        let item = FlutterMediaOverlayItem.fromJson(json, atPosition: 0)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.audioFile, "a.mp3")
    }

    func testFromJsonMissingAudio() {
        let json: [String: Any] = ["text": "t.xhtml#p"]
        XCTAssertNil(FlutterMediaOverlayItem.fromJson(json, atPosition: 0))
    }

    func testFromJsonMissingText() {
        let json: [String: Any] = ["audio": "a.mp3"]
        XCTAssertNil(FlutterMediaOverlayItem.fromJson(json, atPosition: 0))
    }

    func testFromJsonEmptyStrings() {
        let json: [String: Any] = ["audio": "", "text": "t.xhtml#p"]
        XCTAssertNil(FlutterMediaOverlayItem.fromJson(json, atPosition: 0))
    }

    // MARK: - Equality

    func testEquality() {
        let a = FlutterMediaOverlayItem(audio: "a.mp3#t=0,1", text: "t.xhtml#p", position: 0)
        let b = FlutterMediaOverlayItem(audio: "a.mp3#t=0,1", text: "t.xhtml#p", position: 0)
        XCTAssertTrue(a == b)
    }

    func testInequalityDifferentAudio() {
        let a = FlutterMediaOverlayItem(audio: "a.mp3#t=0,1", text: "t.xhtml#p", position: 0)
        let b = FlutterMediaOverlayItem(audio: "b.mp3#t=0,1", text: "t.xhtml#p", position: 0)
        XCTAssertFalse(a == b)
    }
}

// MARK: - FlutterMediaOverlay Tests

final class FlutterMediaOverlayCollectionTests: XCTestCase {

    private func makeOverlay() -> FlutterMediaOverlay {
        FlutterMediaOverlay(items: [
            FlutterMediaOverlayItem(audio: "a.mp3#t=0.0,5.0", text: "ch1.xhtml#p1", position: 0),
            FlutterMediaOverlayItem(audio: "a.mp3#t=5.0,10.0", text: "ch1.xhtml#p2", position: 0),
            FlutterMediaOverlayItem(audio: "a.mp3#t=10.0,15.0", text: "ch1.xhtml#p3", position: 0),
        ])
    }

    func testAudioFile() {
        XCTAssertEqual(makeOverlay().audioFile, "a.mp3")
    }

    func testTextFile() {
        XCTAssertEqual(makeOverlay().textFile, "ch1.xhtml")
    }

    func testDuration() {
        XCTAssertEqual(makeOverlay().duration, 15.0)
    }

    func testItemInRangeOfTimeFindsMatch() {
        let item = makeOverlay().itemInRangeOfTime(3.0, inHref: "a.mp3")
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.textId, "p1")
    }

    func testItemInRangeOfTimeSecondItem() {
        let item = makeOverlay().itemInRangeOfTime(7.0, inHref: "a.mp3")
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.textId, "p2")
    }

    func testItemInRangeOfTimeWrongHref() {
        XCTAssertNil(makeOverlay().itemInRangeOfTime(3.0, inHref: "other.mp3"))
    }

    func testItemFromTextId() {
        let item = makeOverlay().itemFromTextId("p2", inHref: "ch1.xhtml")
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.audioStart, 5.0)
    }

    func testItemFromTextIdWrongHref() {
        XCTAssertNil(makeOverlay().itemFromTextId("p2", inHref: "other.xhtml"))
    }

    func testItemFromLocatorWithTimeOffset() {
        let locator = Locator(
            href: URL(string: "a.mp3")!,
            mediaType: .mpegAudio,
            locations: .init(fragments: ["t=7.0"])
        )
        let item = makeOverlay().itemFromLocator(locator)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.textId, "p2")
    }

    func testItemFromLocatorWithCssSelector() {
        let locator = Locator(
            href: URL(string: "ch1.xhtml")!,
            mediaType: .xhtml,
            locations: .init(fragments: ["#p3"])
        )
        let item = makeOverlay().itemFromLocator(locator)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.audioStart, 10.0)
    }

    func testItemFromLocatorNoFragmentsHtml() {
        let locator = Locator(
            href: URL(string: "ch1.xhtml")!,
            mediaType: .xhtml
        )
        let item = makeOverlay().itemFromLocator(locator)
        XCTAssertNotNil(item)
        XCTAssertEqual(item?.textId, "p1")
    }

    func testItemFromLocatorWrongHref() {
        let locator = Locator(href: URL(string: "other.xhtml")!, mediaType: .xhtml)
        XCTAssertNil(makeOverlay().itemFromLocator(locator))
    }

    // MARK: - fromJson

    func testFromJsonValid() {
        let json: [String: Any] = [
            "narration": [
                ["audio": "a.mp3#t=0,5", "text": "ch1.xhtml#p1"],
                ["audio": "a.mp3#t=5,10", "text": "ch1.xhtml#p2"],
            ]
        ]
        let overlay = FlutterMediaOverlay.fromJson(json, atPosition: 0)
        XCTAssertNotNil(overlay)
        XCTAssertEqual(overlay?.items.count, 2)
    }

    func testFromJsonMissingNarration() {
        let json: [String: Any] = ["other": "value"]
        XCTAssertNil(FlutterMediaOverlay.fromJson(json, atPosition: 0))
    }

    func testFromJsonEmptyNarration() {
        let json: [String: Any] = ["narration": [[String: Any]]()]
        let overlay = FlutterMediaOverlay.fromJson(json, atPosition: 0)
        XCTAssertNotNil(overlay)
        XCTAssertEqual(overlay?.items.count, 0)
    }

    func testFromJsonNested() {
        let json: [String: Any] = [
            "narration": [
                ["audio": "a.mp3#t=0,5", "text": "ch1.xhtml#p1"],
                [
                    "narration": [
                        ["audio": "a.mp3#t=5,10", "text": "ch1.xhtml#p2"],
                    ]
                ],
            ]
        ]
        let overlay = FlutterMediaOverlay.fromJson(json, atPosition: 0)
        XCTAssertNotNil(overlay)
        XCTAssertEqual(overlay?.items.count, 2)
    }
}
