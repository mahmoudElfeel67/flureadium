import XCTest
import ReadiumShared
@testable import flureadium

final class ReadiumTimeBasedStateTests: XCTestCase {

    // MARK: - toJson

    func testToJsonMinimal() {
        let state = ReadiumTimebasedState(state: .playing)
        let json = state.toJson()
        XCTAssertEqual(json["state"] as? String, "playing")
        XCTAssertNil(json["currentOffset"])
        XCTAssertNil(json["currentBuffered"])
        XCTAssertNil(json["currentDuration"])
        XCTAssertNil(json["currentLocator"])
    }

    func testToJsonFull() {
        let locator = Locator(href: URL(string: "ch1.xhtml")!, mediaType: .html)
        let state = ReadiumTimebasedState(
            state: .paused,
            currentOffset: 1.5,
            currentBuffered: 10.0,
            currentDuration: 60.0,
            currentLocator: locator
        )
        let json = state.toJson()
        XCTAssertEqual(json["state"] as? String, "paused")
        XCTAssertEqual(json["currentOffset"] as? Int, 1500)  // seconds → milliseconds
        XCTAssertEqual(json["currentBuffered"] as? Int, 10000)
        XCTAssertEqual(json["currentDuration"] as? Int, 60000)
        XCTAssertNotNil(json["currentLocator"])
    }

    func testToJsonTimeConversion() {
        let state = ReadiumTimebasedState(state: .loading, currentOffset: 2.345)
        let json = state.toJson()
        XCTAssertEqual(json["currentOffset"] as? Int, 2345)
    }

    func testToJsonAllStates() {
        XCTAssertEqual(ReadiumTimebasedState(state: .playing).toJson()["state"] as? String, "playing")
        XCTAssertEqual(ReadiumTimebasedState(state: .paused).toJson()["state"] as? String, "paused")
        XCTAssertEqual(ReadiumTimebasedState(state: .loading).toJson()["state"] as? String, "loading")
        XCTAssertEqual(ReadiumTimebasedState(state: .ended).toJson()["state"] as? String, "ended")
        XCTAssertEqual(ReadiumTimebasedState(state: .failure).toJson()["state"] as? String, "failure")
    }

    // MARK: - toJsonString

    func testToJsonStringReturnsValidJson() {
        let state = ReadiumTimebasedState(state: .playing, currentOffset: 5.0)
        let jsonString = state.toJsonString()
        XCTAssertNotNil(jsonString)

        // Parse it back to verify it's valid JSON
        let data = jsonString!.data(using: .utf8)!
        let parsed = try! JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(parsed["state"] as? String, "playing")
        XCTAssertEqual(parsed["currentOffset"] as? Int, 5000)
    }

    func testToJsonStringPrettyPrinted() {
        let state = ReadiumTimebasedState(state: .paused)
        let pretty = state.toJsonString(pretty: true)
        XCTAssertNotNil(pretty)
        XCTAssertTrue(pretty!.contains("\n"), "Pretty-printed JSON should contain newlines")
    }

    // MARK: - Equatable

    func testEqualitySameValues() {
        let a = ReadiumTimebasedState(state: .playing, currentOffset: 1.0, currentDuration: 60.0)
        let b = ReadiumTimebasedState(state: .playing, currentOffset: 1.0, currentDuration: 60.0)
        XCTAssertEqual(a, b)
    }

    func testInequalityDifferentState() {
        let a = ReadiumTimebasedState(state: .playing)
        let b = ReadiumTimebasedState(state: .paused)
        XCTAssertNotEqual(a, b)
    }

    func testInequalityDifferentOffset() {
        let a = ReadiumTimebasedState(state: .playing, currentOffset: 1.0)
        let b = ReadiumTimebasedState(state: .playing, currentOffset: 2.0)
        XCTAssertNotEqual(a, b)
    }

    func testInequalityNilVsNonNilOffset() {
        let a = ReadiumTimebasedState(state: .playing, currentOffset: nil)
        let b = ReadiumTimebasedState(state: .playing, currentOffset: 1.0)
        XCTAssertNotEqual(a, b)
    }

    func testEqualityBothNilOptionals() {
        let a = ReadiumTimebasedState(state: .ended)
        let b = ReadiumTimebasedState(state: .ended)
        XCTAssertEqual(a, b)
    }
}
