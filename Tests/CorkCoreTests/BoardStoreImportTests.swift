import XCTest
@testable import CorkCore

@MainActor
final class BoardStoreImportTests: XCTestCase {
    func testImportImageFileCreatesImageCardAtDropLocation() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])
        let url = URL(fileURLWithPath: "/tmp/reference.png")

        let items = store.importItems(
            [.imageFile(url: url, title: "Reference")],
            at: BoardPoint(x: 140, y: 180)
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(store.selectedBoard.items, items)
        XCTAssertEqual(store.selectedItemID, items[0].id)
        XCTAssertEqual(items[0].frame.origin, BoardPoint(x: 140, y: 180))
        XCTAssertEqual(items[0].frame.size, BoardStore.Defaults.imageCardSize)

        guard case .image(let card) = items[0].content else {
            return XCTFail("Expected an image card.")
        }

        XCTAssertEqual(card.title, "Reference")
        XCTAssertEqual(card.source, .fileReference(url))
    }

    func testImportMultipleImageFilesStaggersCardsFromDropLocation() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])
        let firstURL = URL(fileURLWithPath: "/tmp/one.png")
        let secondURL = URL(fileURLWithPath: "/tmp/two.jpg")

        let items = store.importItems(
            [
                .imageFile(url: firstURL, title: "One"),
                .imageFile(url: secondURL, title: "Two")
            ],
            at: BoardPoint(x: 72, y: 96)
        )

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].frame.origin, BoardPoint(x: 72, y: 96))
        XCTAssertEqual(items[1].frame.origin, BoardPoint(x: 96, y: 120))
        XCTAssertEqual(store.selectedBoard.items.map(\.id), items.map(\.id))
        XCTAssertEqual(store.selectedItemID, items[1].id)
    }

    func testImportPlainTextCreatesTextCard() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        let items = store.importItems(
            [.plainText(title: "Snippet", body: "Keep this nearby.")],
            at: BoardPoint(x: 72, y: 96)
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].frame.origin, BoardPoint(x: 72, y: 96))

        guard case .text(let card) = items[0].content else {
            return XCTFail("Expected a text card.")
        }

        XCTAssertEqual(card.title, "Snippet")
        XCTAssertEqual(card.body, "Keep this nearby.")
        XCTAssertEqual(card.format, .plainText)
    }

    func testImportWebURLCreatesURLCard() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])
        let url = URL(string: "https://example.com/reference")!

        let items = store.importItems(
            [.webURL(url: url, title: "example.com")],
            at: BoardPoint(x: 72, y: 96)
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].frame.origin, BoardPoint(x: 72, y: 96))
        XCTAssertEqual(items[0].frame.size, BoardStore.Defaults.urlCardSize)

        guard case .url(let card) = items[0].content else {
            return XCTFail("Expected a URL card.")
        }

        XCTAssertEqual(card.title, "example.com")
        XCTAssertEqual(card.url, url)
    }

    func testImportWebURLClampsToCanvasBounds() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])
        let url = URL(string: "https://example.com/reference")!

        let items = store.importItems(
            [.webURL(url: url, title: "example.com")],
            at: BoardPoint(x: 999, y: 999),
            constrainedTo: BoardSize(width: 320, height: 260)
        )

        XCTAssertEqual(items[0].frame.origin, BoardPoint(x: 28, y: 98))
    }

    func testImportWebURLAutosavesWhenRepositoryIsConfigured() {
        let board = CorkBoard(name: "Board")
        let repository = CapturingImportRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )
        let url = URL(string: "https://example.com/reference")!

        let items = store.importItems(
            [.webURL(url: url, title: "example.com")],
            at: BoardPoint(x: 72, y: 96)
        )

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoard.items.first?.id, items[0].id)

        guard case .url(let card) = repository.savedSnapshots[0].selectedBoard.items[0].content else {
            return XCTFail("Expected a URL card.")
        }

        XCTAssertEqual(card.title, "example.com")
        XCTAssertEqual(card.url, url)
    }

    func testImportFileReferenceCreatesFileCard() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])
        let url = URL(fileURLWithPath: "/tmp/reference.pdf")

        let items = store.importItems(
            [.fileReference(url: url, title: "reference")],
            at: BoardPoint(x: 72, y: 96)
        )

        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items[0].frame.origin, BoardPoint(x: 72, y: 96))
        XCTAssertEqual(items[0].frame.size, BoardStore.Defaults.fileCardSize)

        guard case .file(let card) = items[0].content else {
            return XCTFail("Expected a file card.")
        }

        XCTAssertEqual(card.title, "reference")
        XCTAssertEqual(card.url, url)
    }

    func testImportImageFileClampsToCanvasBounds() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        let items = store.importItems(
            [.imageFile(url: URL(fileURLWithPath: "/tmp/reference.png"), title: "Reference")],
            at: BoardPoint(x: 999, y: 999),
            constrainedTo: BoardSize(width: 300, height: 240)
        )

        XCTAssertEqual(items[0].frame.origin, BoardPoint(x: 58, y: 58))
    }

    func testImportEmptyIntentListDoesNothing() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        let items = store.importItems([], at: BoardPoint(x: 72, y: 96))

        XCTAssertTrue(items.isEmpty)
        XCTAssertTrue(store.selectedBoard.items.isEmpty)
        XCTAssertNil(store.selectedItemID)
    }

    func testImportImageFileAutosavesWhenRepositoryIsConfigured() {
        let board = CorkBoard(name: "Board")
        let repository = CapturingImportRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        let items = store.importItems(
            [.imageFile(url: URL(fileURLWithPath: "/tmp/reference.png"), title: "Reference")],
            at: BoardPoint(x: 72, y: 96)
        )

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoard.items.first?.id, items[0].id)
    }

    func testImportFileReferenceAutosavesWhenRepositoryIsConfigured() {
        let board = CorkBoard(name: "Board")
        let repository = CapturingImportRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )
        let url = URL(fileURLWithPath: "/tmp/reference.pdf")

        let items = store.importItems(
            [.fileReference(url: url, title: "reference")],
            at: BoardPoint(x: 72, y: 96)
        )

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoard.items.first?.id, items[0].id)

        guard case .file(let card) = repository.savedSnapshots[0].selectedBoard.items[0].content else {
            return XCTFail("Expected a file card.")
        }

        XCTAssertEqual(card.title, "reference")
        XCTAssertEqual(card.url, url)
    }
}

private final class CapturingImportRepository: BoardRepository {
    private(set) var savedSnapshots: [BoardLibrarySnapshot] = []

    func loadSnapshot() throws -> BoardLibrarySnapshot? {
        nil
    }

    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
