import XCTest
@testable import CorkCore

final class BoardImportResolverTests: XCTestCase {
    func testImageFileSourceCreatesImageIntent() {
        let resolver = BoardImportResolver()
        let url = URL(fileURLWithPath: "/tmp/mood board.png")

        let intents = resolver.intents(from: [.fileURL(url)])

        XCTAssertEqual(intents, [
            .imageFile(url: url, title: "mood board")
        ])
    }

    func testNonImageFileSourceCreatesFileReferenceIntent() {
        let resolver = BoardImportResolver()
        let url = URL(fileURLWithPath: "/tmp/brief.pdf")

        let intents = resolver.intents(from: [.fileURL(url)])

        XCTAssertEqual(intents, [
            .fileReference(url: url, title: "brief")
        ])
    }

    func testWebURLSourceCreatesWebURLIntent() {
        let resolver = BoardImportResolver()
        let url = URL(string: "https://example.com/reference")!

        let intents = resolver.intents(from: [.webURL(url)])

        XCTAssertEqual(intents, [
            .webURL(url: url, title: "example.com")
        ])
    }

    func testPlainTextSourceCreatesPlainTextIntent() {
        let resolver = BoardImportResolver()

        let intents = resolver.intents(from: [
            .plainText("  Keep this nearby.\nSecond line.  ")
        ])

        XCTAssertEqual(intents, [
            .plainText(title: "Keep this nearby.", body: "Keep this nearby.\nSecond line.")
        ])
    }

    func testPlainTextURLCreatesWebURLIntent() {
        let resolver = BoardImportResolver()
        let url = URL(string: "https://example.com/reference")!

        let intents = resolver.intents(from: [
            .plainText("  https://example.com/reference  ")
        ])

        XCTAssertEqual(intents, [
            .webURL(url: url, title: "example.com")
        ])
    }

    func testFileSourcesWinOverURLAndTextSources() {
        let resolver = BoardImportResolver()
        let fileURL = URL(fileURLWithPath: "/tmp/reference.txt")
        let webURL = URL(string: "https://example.com/reference")!

        let intents = resolver.intents(from: [
            .plainText("Some text"),
            .webURL(webURL),
            .fileURL(fileURL)
        ])

        XCTAssertEqual(intents, [
            .fileReference(url: fileURL, title: "reference")
        ])
    }

    func testMultipleFileSourcesCreateMultipleFileIntents() {
        let resolver = BoardImportResolver()
        let imageURL = URL(fileURLWithPath: "/tmp/reference.jpg")
        let documentURL = URL(fileURLWithPath: "/tmp/notes.md")

        let intents = resolver.intents(from: [
            .fileURL(imageURL),
            .fileURL(documentURL)
        ])

        XCTAssertEqual(intents, [
            .imageFile(url: imageURL, title: "reference"),
            .fileReference(url: documentURL, title: "notes")
        ])
    }

    func testUnsupportedURLAndBlankTextCreateNoIntent() {
        let resolver = BoardImportResolver()
        let url = URL(string: "ftp://example.com/reference")!

        let intents = resolver.intents(from: [
            .webURL(url),
            .plainText("   ")
        ])

        XCTAssertTrue(intents.isEmpty)
    }
}
