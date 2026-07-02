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

    func testSelectItemChangesSelectedItem() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.selectItem(item.id)

        XCTAssertEqual(store.selectedItemID, item.id)
        XCTAssertEqual(store.selectedItem, item)
    }

    func testSelectingUnknownItemDoesNothing() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.selectItem(UUID())

        XCTAssertNil(store.selectedItemID)
    }

    func testClearSelectionClearsSelectedItem() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.selectItem(item.id)
        store.clearSelection()

        XCTAssertNil(store.selectedItemID)
        XCTAssertNil(store.selectedItem)
    }

    func testSelectingAnotherBoardClearsSelectedItem() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let first = CorkBoard(name: "First", items: [item])
        let second = CorkBoard(name: "Second")
        let store = BoardStore(boards: [first, second])

        store.selectItem(item.id)
        store.selectBoard(second.id)

        XCTAssertNil(store.selectedItemID)
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

    func testMoveSelectedItemMovesItemByDelta() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 40, y: 60),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.selectItem(item.id)
        store.moveSelectedItem(by: BoardPoint(x: 8, y: -8))

        XCTAssertEqual(store.selectedBoard.items[0].frame.origin, BoardPoint(x: 48, y: 52))
    }

    func testMoveSelectedItemClampsToCanvasBounds() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 40, y: 40),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.selectItem(item.id)
        store.moveSelectedItem(
            by: BoardPoint(x: 999, y: 999),
            constrainedTo: BoardSize(width: 300, height: 240)
        )

        XCTAssertEqual(store.selectedBoard.items[0].frame.origin, BoardPoint(x: 168, y: 108))
    }

    func testMoveSelectedItemReturnsFalseWithoutSelection() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 40, y: 40),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        let didMove = store.moveSelectedItem(by: BoardPoint(x: 8, y: 8))

        XCTAssertFalse(didMove)
        XCTAssertEqual(store.selectedBoard.items[0].frame.origin, BoardPoint(x: 40, y: 40))
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

    func testDeleteItemRemovesItemAndClearsSelection() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 40, y: 40),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.selectItem(item.id)
        let didDelete = store.deleteItem(item.id)

        XCTAssertTrue(didDelete)
        XCTAssertTrue(store.selectedBoard.items.isEmpty)
        XCTAssertNil(store.selectedItemID)
    }

    func testDeleteSelectedItemReturnsFalseWithoutSelection() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        XCTAssertFalse(store.deleteSelectedItem())
    }

    func testDeleteItemAutosavesWhenRepositoryIsConfigured() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 40, y: 40),
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

        store.deleteItem(item.id)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertTrue(repository.savedSnapshots[0].selectedBoard.items.isEmpty)
    }

    func testDuplicateItemCreatesOffsetItemWithNewIDAndSelectsIt() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 40, y: 40),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        let duplicate = store.duplicateItem(item.id)

        XCTAssertEqual(store.selectedBoard.items.count, 2)
        XCTAssertNotEqual(duplicate?.id, item.id)
        XCTAssertEqual(duplicate?.frame.origin, BoardPoint(x: 64, y: 64))
        XCTAssertEqual(duplicate?.content, item.content)
        XCTAssertEqual(store.selectedItemID, duplicate?.id)
    }

    func testDuplicateSelectedItemClampsToCanvasBounds() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 160, y: 100),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.selectItem(item.id)
        let duplicate = store.duplicateSelectedItem(
            constrainedTo: BoardSize(width: 300, height: 240)
        )

        XCTAssertEqual(duplicate?.frame.origin, BoardPoint(x: 168, y: 108))
    }

    func testDuplicateItemAutosavesWhenRepositoryIsConfigured() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 40, y: 40),
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

        let duplicate = store.duplicateItem(item.id)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoard.items.count, 2)
        XCTAssertEqual(store.selectedItemID, duplicate?.id)
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
