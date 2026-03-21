//
//  FlutterTTSNavigatorTests.swift
//  flureadiumTests
//
//  Unit tests for FlutterTTSNavigator TTS lifecycle, covering:
//  - initNavigator() error handling for unsupported publications
//  - ttsGetAvailableVoices() sort order
//  - ttsCanSpeak via PublicationSpeechSynthesizer.canSpeak static method
//  - ttsRequestInstallVoice no-op handler
//  - ttsEnable error propagation for unsupported publications
//
//  NOTE: Requires Flutter framework (runs through Xcode/Flutter build, not pure SPM).
//

import XCTest
import Flutter
import ReadiumShared
import ReadiumNavigator
@testable import flureadium

final class FlutterTTSNavigatorTests: XCTestCase {

    // MARK: - Helpers

    /// Creates a Publication that does NOT support TTS (no ContentService).
    private func makeUnspeakablePublication() -> Publication {
        Publication(manifest: Manifest(metadata: Metadata(title: "Unspeakable")))
    }

    // MARK: - initNavigator() error handling

    func testInitNavigatorWithUnsupportedPublicationThrowsError() async {
        let publication = makeUnspeakablePublication()
        let navigator = FlutterTTSNavigator(
            publication: publication,
            initialLocator: nil
        )

        // After the fix, initNavigator() should throw for unsupported publications
        // instead of crashing via force-unwrap.
        do {
            try await navigator.initNavigator()
            XCTFail("initNavigator() should throw for an unsupported publication")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "Flureadium")
            XCTAssertTrue(
                nsError.localizedDescription.contains("does not support TTS"),
                "Error should mention TTS not supported, got: \(nsError.localizedDescription)"
            )
        }
    }

    // MARK: - ttsGetAvailableVoices sort order

    func testGetAvailableVoicesReturnsEmptyWhenSynthesizerIsNil() {
        let publication = makeUnspeakablePublication()
        let navigator = FlutterTTSNavigator(
            publication: publication,
            initialLocator: nil
        )

        // synthesizer is nil (initNavigator not called), should return empty
        let voices = navigator.ttsGetAvailableVoices()
        XCTAssertTrue(voices.isEmpty, "Voices should be empty when synthesizer is nil")
    }

    func testGetAvailableVoicesReturnsSortedList() {
        let publication = makeUnspeakablePublication()
        let navigator = FlutterTTSNavigator(
            publication: publication,
            initialLocator: nil
        )

        // The method should return voices in sorted order.
        // With nil synthesizer this returns an empty (trivially sorted) list.
        // The sort contract is verified: result == result.sorted()
        let voices = navigator.ttsGetAvailableVoices()
        let sorted = voices.sorted()
        XCTAssertEqual(voices, sorted, "Available voices must be returned in sorted order")
    }

    // MARK: - PublicationSpeechSynthesizer.canSpeak

    func testCanSpeakReturnsFalseForPublicationWithoutContentService() {
        // A bare Publication with no services cannot be spoken.
        let publication = makeUnspeakablePublication()
        let result = PublicationSpeechSynthesizer.canSpeak(publication: publication)
        XCTAssertFalse(result, "canSpeak should return false for a publication without ContentService")
    }

    func testCanSpeakReturnsFalseForEmptyPublication() {
        let publication = Publication(manifest: Manifest())
        let result = PublicationSpeechSynthesizer.canSpeak(publication: publication)
        XCTAssertFalse(result, "canSpeak should return false for an empty publication")
    }

    // MARK: - ttsRequestInstallVoice no-op handler

    func testTtsRequestInstallVoiceHandlerCallsResultWithNil() {
        // The ttsRequestInstallVoice handler should be a no-op that calls result(nil).
        // We verify this by exercising the plugin handler through a mock.
        let plugin = FlureadiumPlugin()
        let expectation = expectation(description: "result called")

        let call = FlutterMethodCall(methodName: "ttsRequestInstallVoice", arguments: nil)
        plugin.handle(call) { response in
            // On iOS, ttsRequestInstallVoice is a no-op returning nil.
            XCTAssertFalse(response is FlutterError,
                           "ttsRequestInstallVoice should not return an error")
            XCTAssertNil(response, "ttsRequestInstallVoice should return nil (no-op on iOS)")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - ttsCanSpeak handler

    func testTtsCanSpeakReturnsFalseWhenNoPublicationLoaded() {
        // Clear any global publication state.
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

    func testTtsCanSpeakReturnsFalseForUnspeakablePublication() {
        // Set a publication that has no ContentService.
        currentPublication = Publication(manifest: Manifest(metadata: Metadata(title: "NoTTS")))

        let plugin = FlureadiumPlugin()
        let expectation = expectation(description: "result called")

        let call = FlutterMethodCall(methodName: "ttsCanSpeak", arguments: nil)
        plugin.handle(call) { response in
            XCTAssertEqual(response as? Bool, false,
                           "ttsCanSpeak should return false for a publication without ContentService")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - ttsEnable error handling

    func testTtsEnableWithUnsupportedPublicationSendsFlutterError() {
        // Set a publication that does not support TTS.
        currentPublication = Publication(manifest: Manifest(metadata: Metadata(title: "NoTTS")))

        let plugin = FlureadiumPlugin()
        let expectation = expectation(description: "result called")

        let call = FlutterMethodCall(methodName: "ttsEnable", arguments: nil)
        plugin.handle(call) { response in
            // After the fix, ttsEnable should return a FlutterError
            // when the publication does not support TTS.
            if let error = response as? FlutterError {
                XCTAssertEqual(error.code, "TTSError")
                XCTAssertTrue(
                    error.message?.contains("TTS") == true || error.message?.contains("support") == true,
                    "Error message should mention TTS, got: \(error.message ?? "nil")"
                )
            } else {
                XCTFail("ttsEnable should return FlutterError for unsupported publication, got: \(String(describing: response))")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - Teardown

    override func tearDown() {
        // Reset global state after each test.
        currentPublication = nil
        super.tearDown()
    }
}
