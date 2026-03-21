import XCTest
import ReadiumShared
import ReadiumNavigator
import MediaPlayer
@testable import flureadium

final class NowPlayingInfoUpdaterTests: XCTestCase {

    // MARK: - Helpers

    private func makePublication(
        title: String = "Test Book",
        authors: [String] = ["Author One"],
        chapters: [(href: String, title: String?)] = [
            ("ch1.xhtml", "First Chapter"),
            ("ch2.xhtml", "Second Chapter"),
            ("ch3.xhtml", nil),
        ]
    ) -> Publication {
        let readingOrder = chapters.map { ch in
            Link(href: ch.href, mediaType: .xhtml, title: ch.title)
        }
        let contributors = authors.map { Contributor(name: $0) }
        return Publication(manifest: Manifest(
            metadata: Metadata(
                title: title,
                authors: contributors
            ),
            readingOrder: readingOrder
        ))
    }

    override func tearDown() {
        NowPlayingInfo.shared.clear()
        super.tearDown()
    }

    // MARK: - setupNowPlayingInfo

    func testSetupNowPlayingInfoSetsTitle() {
        let pub = makePublication(title: "My Book")
        let updater = NowPlayingInfoUpdater(withPublication: pub)
        updater.setupNowPlayingInfo()
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "My Book")
    }

    func testSetupNowPlayingInfoSetsArtist() {
        let pub = makePublication(authors: ["Alice", "Bob"])
        let updater = NowPlayingInfoUpdater(withPublication: pub)
        updater.setupNowPlayingInfo()
        XCTAssertEqual(NowPlayingInfo.shared.media?.artist, "Alice, Bob")
    }

    func testSetupNowPlayingInfoSetsChapterCount() {
        let pub = makePublication(chapters: [("a", "A"), ("b", "B")])
        let updater = NowPlayingInfoUpdater(withPublication: pub)
        updater.setupNowPlayingInfo()
        XCTAssertEqual(NowPlayingInfo.shared.media?.chapterCount, 2)
    }

    // MARK: - updateChapterNo: standard

    func testStandardInfoTypeUsesBookTitleAndAuthors() {
        let pub = makePublication(title: "Book", authors: ["Alice", "Bob"])
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .standard)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "Book")
        XCTAssertEqual(NowPlayingInfo.shared.media?.artist, "Alice, Bob")
    }

    // MARK: - updateChapterNo: standardWCh

    func testStandardWChAppendsChapterToTitle() {
        let pub = makePublication(title: "Book", chapters: [("a", "Ch 1"), ("b", "Ch 2")])
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .standardWCh)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "Book - Ch 1")
    }

    func testStandardWChFallsBackToGeneratedChapterTitle() {
        let pub = makePublication(title: "Book", chapters: [("a", nil)])
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .standardWCh)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)
        let title = NowPlayingInfo.shared.media?.title ?? ""
        XCTAssertTrue(title.hasPrefix("Book - "), "Title should start with 'Book - ' followed by fallback chapter name")
    }

    // MARK: - updateChapterNo: chapterTitle

    func testChapterTitleSetsChapterAsTitle() {
        let pub = makePublication(title: "Book", authors: ["Alice"])
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .chapterTitle)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "First Chapter")
        XCTAssertEqual(NowPlayingInfo.shared.media?.artist, "Book")
    }

    // MARK: - updateChapterNo: chapterTitleAuthor

    func testChapterTitleAuthorSetsChapterAsTitleWithBookAndAuthors() {
        let pub = makePublication(title: "Book", authors: ["Alice"])
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .chapterTitleAuthor)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "First Chapter")
        XCTAssertEqual(NowPlayingInfo.shared.media?.artist, "Book - Alice")
    }

    // MARK: - updateChapterNo: titleChapter

    func testTitleChapterSetsChapterAsArtist() {
        let pub = makePublication(title: "Book")
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .titleChapter)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "Book")
        XCTAssertEqual(NowPlayingInfo.shared.media?.artist, "First Chapter")
    }

    // MARK: - updateChapterNo: dedup

    func testUpdateChapterNoSkipsDuplicate() {
        let pub = makePublication()
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .chapterTitle)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)

        // Manually modify the title to detect whether the second call is a no-op
        NowPlayingInfo.shared.media?.title = "modified"
        updater.updateChapterNo(0)
        // Title should remain "modified" because the duplicate was skipped
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "modified")
    }

    func testUpdateChapterNoUpdatesOnDifferentChapter() {
        let pub = makePublication()
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .chapterTitle)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "First Chapter")

        updater.updateChapterNo(1)
        XCTAssertEqual(NowPlayingInfo.shared.media?.title, "Second Chapter")
    }

    func testUpdateChapterNoSetsChapterNumber() {
        let pub = makePublication()
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .standard)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(2)
        XCTAssertEqual(NowPlayingInfo.shared.media?.chapterNumber, 2)
    }

    func testUpdateChapterNoNilResetsChapterNumber() {
        let pub = makePublication()
        let updater = NowPlayingInfoUpdater(withPublication: pub, infoType: .standard)
        updater.setupNowPlayingInfo()
        updater.updateChapterNo(0)
        XCTAssertEqual(NowPlayingInfo.shared.media?.chapterNumber, 0)
        updater.updateChapterNo(nil)
        XCTAssertNil(NowPlayingInfo.shared.media?.chapterNumber)
    }

    // MARK: - clearNowPlaying

    func testClearNowPlaying() {
        let pub = makePublication()
        let updater = NowPlayingInfoUpdater(withPublication: pub)
        updater.setupNowPlayingInfo()
        XCTAssertNotNil(NowPlayingInfo.shared.media)
        updater.clearNowPlaying()
        XCTAssertNil(NowPlayingInfo.shared.media)
    }
}
