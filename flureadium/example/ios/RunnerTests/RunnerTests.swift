import XCTest
import Flutter
@testable import flureadium

class RunnerTests: XCTestCase {

  func testTtsCanSpeakReturnsFalseWhenNoPublicationLoaded() {
    currentPublication = nil

    let plugin = FlureadiumPlugin()
    let expectation = expectation(description: "result called")

    let call = FlutterMethodCall(methodName: "ttsCanSpeak", arguments: nil)
    plugin.handle(call) { response in
      XCTAssertEqual(response as? Bool, false,
                     "ttsCanSpeak should return false when no publication is loaded")
      expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
  }

  override func tearDown() {
    currentPublication = nil
    super.tearDown()
  }
}
