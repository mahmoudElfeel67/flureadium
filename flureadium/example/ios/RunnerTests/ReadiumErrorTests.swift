import XCTest
import Flutter
import ReadiumShared
@testable import flureadium

final class ReadiumErrorTests: XCTestCase {

    func testFormatNotSupportedToFlutterError() {
        let error = ReadiumError.formatNotSupported("PDF 2.0")
        let flutterError = error.toFlutterError()
        XCTAssertEqual(flutterError.code, "formatNotSupported")
    }

    func testNotFoundToFlutterError() {
        let error = ReadiumError.notFound("book.epub")
        let flutterError = error.toFlutterError()
        XCTAssertEqual(flutterError.code, "notFound")
        XCTAssertEqual(flutterError.details as? String, "book.epub")
    }

    func testNotFoundNilDetailsToFlutterError() {
        let error = ReadiumError.notFound(nil)
        let flutterError = error.toFlutterError()
        XCTAssertEqual(flutterError.code, "notFound")
    }

    func testReaderViewNotFoundToFlutterError() {
        let error = ReadiumError.readerViewNotFound
        let flutterError = error.toFlutterError()
        XCTAssertEqual(flutterError.code, "readerViewNotFound")
    }

    func testVoiceNotFoundToFlutterError() {
        let error = ReadiumError.voiceNotFound
        let flutterError = error.toFlutterError()
        XCTAssertEqual(flutterError.code, "voiceNotFound")
    }

    func testUnknownToFlutterError() {
        let error = ReadiumError.unknown(nil)
        let flutterError = error.toFlutterError()
        XCTAssertEqual(flutterError.code, "unknown")
    }

    func testReadingErrorToFlutterError() {
        let inner = NSError(domain: "test", code: 42)
        let error = ReadiumError.readingError(inner)
        let flutterError = error.toFlutterError()
        XCTAssertEqual(flutterError.code, "readingError")
    }

    func testForbiddenToFlutterError() {
        let inner = NSError(domain: "DRM", code: 1)
        let error = ReadiumError.publicationIsRestricted(inner)
        let flutterError = error.toFlutterError()
        XCTAssertEqual(flutterError.code, "forbidden")
    }
}

// MARK: - FlureadiumError Tests

final class FlureadiumErrorTests: XCTestCase {

    func testToJsonAllFields() {
        let error = FlureadiumError(
            message: "Something broke",
            code: "ERR_001",
            data: "extra data",
            details: ["key": "value"]
        )
        let json = error.toJson()
        XCTAssertEqual(json["message"] as? String, "Something broke")
        XCTAssertEqual(json["code"] as? String, "ERR_001")
        XCTAssertEqual(json["data"] as? String, "extra data")
        XCTAssertNotNil(json["stack"])
    }

    func testToJsonMinimal() {
        let error = FlureadiumError(message: "Oops")
        let json = error.toJson()
        XCTAssertEqual(json["message"] as? String, "Oops")
    }
}
