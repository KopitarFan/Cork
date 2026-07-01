import XCTest
@testable import CorkCore

@MainActor
final class BoardStoreTests: XCTestCase {
    func testSelectBoardChangesSelectedBoard() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let store = BoardStore(boards: [first, second])

        store.selectBoard(second.id)

        XCTAssertEqual(store.selectedBoard.id, second.id)
    }

    func testInitializesFromSnapshot() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let snapshot = BoardLibrarySnapshot(boards: [first, second], selectedBoardID: second.id)

        let store = BoardStore(snapshot: snapshot)

        XCTAssertEqual(store.boards, [first, second])
        XCTAssertEqual(store.selectedBoardID, second.id)
        XCTAssertEqual(store.selectedBoard.id, second.id)
    }

    func testSelectingUnknownBoardDoesNothing() {
        let board = CorkBoard(name: "Only")
        let store = BoardStore(boards: [board])

        store.selectBoard(UUID())

        XCTAssertEqual(store.selectedBoard.id, board.id)
    }

    func testSelectingBoardAutosavesWhenRepositoryIsConfigured() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let repository = CapturingBoardRepository()
        let store = BoardStore(
            boards: [first, second],
            repository: repository,
            autosaveDelay: 0
        )

        store.selectBoard(second.id)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoardID, second.id)
    }

    func testUpdateItemPositionMovesItemOnSelectedBoard() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.updateItemPosition(item.id, to: BoardPoint(x: 42, y: 84))

        XCTAssertEqual(store.selectedBoard.items[0].frame.origin, BoardPoint(x: 42, y: 84))
    }

    func testUpdatingItemPositionAutosavesWhenRepositoryIsConfigured() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let repository = CapturingBoardRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        store.updateItemPosition(item.id, to: BoardPoint(x: 42, y: 84))

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(
            repository.savedSnapshots[0].selectedBoard.items[0].frame.origin,
            BoardPoint(x: 42, y: 84)
        )
    }

    func testUpdateItemPositionClampsToCanvasInset() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 40, y: 40),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.updateItemPosition(item.id, to: BoardPoint(x: -100, y: -10))

        XCTAssertEqual(store.selectedBoard.items[0].frame.origin, BoardPoint(x: 12, y: 12))
    }

    func testAutosaveDebouncesRapidPositionUpdates() async throws {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let repository = CapturingBoardRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0.05
        )

        store.updateItemPosition(item.id, to: BoardPoint(x: 20, y: 20))
        store.updateItemPosition(item.id, to: BoardPoint(x: 30, y: 30))
        store.updateItemPosition(item.id, to: BoardPoint(x: 40, y: 40))

        XCTAssertEqual(repository.savedSnapshots.count, 0)

        try await Task.sleep(nanoseconds: 120_000_000)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(
            repository.savedSnapshots[0].selectedBoard.items[0].frame.origin,
            BoardPoint(x: 40, y: 40)
        )
    }

    func testFlushPendingAutosaveSavesImmediately() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let repository = CapturingBoardRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 10
        )

        store.updateItemPosition(item.id, to: BoardPoint(x: 60, y: 60))
        store.flushPendingAutosave()

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(
            repository.savedSnapshots[0].selectedBoard.items[0].frame.origin,
            BoardPoint(x: 60, y: 60)
        )
    }

    func testExportsSnapshot() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let store = BoardStore(boards: [first, second])

        store.selectBoard(second.id)

        XCTAssertEqual(
            store.snapshot,
            BoardLibrarySnapshot(boards: [first, second], selectedBoardID: second.id)
        )
    }
}

private final class CapturingBoardRepository: BoardRepository {
    private(set) var savedSnapshots: [BoardLibrarySnapshot] = []

    func loadSnapshot() throws -> BoardLibrarySnapshot? {
        nil
    }

    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
