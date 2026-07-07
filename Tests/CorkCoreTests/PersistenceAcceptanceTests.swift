import XCTest
@testable import CorkCore

@MainActor
final class PersistenceAcceptanceTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryDirectories {
            try? FileManager.default.removeItem(at: url)
        }

        temporaryDirectories.removeAll()
    }

    func testMissingSaveHydratesStoreFromSampleSnapshot() throws {
        let repository = JSONBoardRepository(fileURL: makeTemporaryFileURL())
        let snapshot = try repository.loadSnapshot() ?? .sample

        let store = BoardStore(
            snapshot: snapshot,
            repository: repository,
            autosaveDelay: 0
        )

        XCTAssertEqual(store.boards, CorkBoard.sampleBoards)
        XCTAssertEqual(store.selectedBoardID, CorkBoard.sampleBoards[0].id)
    }

    func testSelectedBoardPersistsThroughRepositoryAndFreshStore() throws {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let repository = JSONBoardRepository(fileURL: makeTemporaryFileURL())
        let store = BoardStore(
            boards: [first, second],
            repository: repository,
            autosaveDelay: 0
        )

        store.selectBoard(second.id)

        let loadedSnapshot = try XCTUnwrap(repository.loadSnapshot())
        let restoredStore = BoardStore(
            snapshot: loadedSnapshot,
            repository: repository,
            autosaveDelay: 0
        )

        XCTAssertEqual(restoredStore.selectedBoardID, second.id)
        XCTAssertEqual(restoredStore.selectedBoard, second)
    }

    func testMovedCardPositionPersistsThroughRepositoryAndFreshStore() throws {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let repository = JSONBoardRepository(fileURL: makeTemporaryFileURL())
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        store.updateItemPosition(item.id, to: BoardPoint(x: 188, y: 244))

        let loadedSnapshot = try XCTUnwrap(repository.loadSnapshot())
        let restoredStore = BoardStore(
            snapshot: loadedSnapshot,
            repository: repository,
            autosaveDelay: 0
        )

        XCTAssertEqual(
            restoredStore.selectedBoard.items[0].frame.origin,
            BoardPoint(x: 188, y: 244)
        )
    }

    func testResizedCardFramePersistsThroughRepositoryAndFreshStore() throws {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let repository = JSONBoardRepository(fileURL: makeTemporaryFileURL())
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        store.resizeItem(item.id, to: BoardSize(width: 280, height: 220))

        let loadedSnapshot = try XCTUnwrap(repository.loadSnapshot())
        let restoredStore = BoardStore(
            snapshot: loadedSnapshot,
            repository: repository,
            autosaveDelay: 0
        )

        XCTAssertEqual(
            restoredStore.selectedBoard.items[0].frame.size,
            BoardSize(width: 280, height: 220)
        )
    }

    func testURLCardPersistsThroughRepositoryAndFreshStore() throws {
        let board = CorkBoard(name: "Board")
        let repository = JSONBoardRepository(fileURL: makeTemporaryFileURL())
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )
        let url = URL(string: "https://example.com/reference")!

        let item = store.createURLCard(
            title: "Reference",
            url: url,
            at: BoardPoint(x: 72, y: 96)
        )

        let loadedSnapshot = try XCTUnwrap(repository.loadSnapshot())
        let restoredStore = BoardStore(
            snapshot: loadedSnapshot,
            repository: repository,
            autosaveDelay: 0
        )

        XCTAssertEqual(restoredStore.selectedItemID, nil)
        XCTAssertEqual(restoredStore.selectedBoard.items[0].id, item.id)
        XCTAssertEqual(restoredStore.selectedBoard.items[0].frame.origin, BoardPoint(x: 72, y: 96))
        XCTAssertEqual(restoredStore.selectedBoard.items[0].frame.size, BoardStore.Defaults.urlCardSize)

        guard case .url(let card) = restoredStore.selectedBoard.items[0].content else {
            return XCTFail("Expected a URL card.")
        }

        XCTAssertEqual(card.title, "Reference")
        XCTAssertEqual(card.url, url)
    }

    func testRepositoryRoundTripPreservesFullBoardLibrary() throws {
        let first = CorkBoard(
            name: "Writing",
            items: [
                BoardItem(
                    frame: BoardRect(
                        origin: BoardPoint(x: 24, y: 36),
                        size: BoardSize(width: 220, height: 160)
                    ),
                    content: .text(TextCard(title: "Thread", body: "Keep this visible."))
                )
            ]
        )
        let second = CorkBoard(
            name: "Release",
            items: [
                BoardItem(
                    frame: BoardRect(
                        origin: BoardPoint(x: 90, y: 120),
                        size: BoardSize(width: 260, height: 210)
                    ),
                    content: .checklist(ChecklistCard(
                        title: "Before Ship",
                        entries: [
                            ChecklistEntry(title: "Run tests", isComplete: true),
                            ChecklistEntry(title: "Manual QA")
                        ]
                    ))
                ),
                BoardItem(
                    frame: BoardRect(
                        origin: BoardPoint(x: 390, y: 80),
                        size: BoardSize(width: 220, height: 180)
                    ),
                    content: .image(ImageCard(
                        title: "Reference",
                        source: .bundledSymbol("photo")
                    ))
                ),
                BoardItem(
                    frame: BoardRect(
                        origin: BoardPoint(x: 650, y: 124),
                        size: BoardSize(width: 280, height: 150)
                    ),
                    content: .url(URLCard(
                        title: "Release Notes",
                        url: URL(string: "https://example.com/release-notes")!
                    ))
                )
            ]
        )
        let snapshot = BoardLibrarySnapshot(boards: [first, second], selectedBoardID: second.id)
        let repository = JSONBoardRepository(fileURL: makeTemporaryFileURL())

        try repository.saveSnapshot(snapshot)

        XCTAssertEqual(try repository.loadSnapshot(), snapshot)
    }

    private func makeTemporaryFileURL() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorkAcceptanceTests-\(UUID().uuidString)", isDirectory: true)
        temporaryDirectories.append(directoryURL)

        return directoryURL
            .appendingPathComponent("State", isDirectory: true)
            .appendingPathComponent("boards.json", isDirectory: false)
    }
}
