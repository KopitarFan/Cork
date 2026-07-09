import XCTest
@testable import CorkCore

@MainActor
final class BoardStoreBoardManagementTests: XCTestCase {
    func testCreateBoardAssignsStableSortIndex() {
        let first = CorkBoard(name: "First", sortIndex: 0)
        let second = CorkBoard(name: "Second", sortIndex: 1)
        let store = BoardStore(boards: [first, second])

        let third = store.createBoard(name: "Third")

        XCTAssertEqual(third.sortIndex, 2)
        XCTAssertEqual(store.boards.map(\.sortIndex), [0, 1, 2])
    }

    func testSetBoardPinnedUpdatesPinnedStateAndAutosaves() {
        let board = CorkBoard(name: "Board")
        let repository = CapturingBoardManagementRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        let didPin = store.setBoardPinned(id: board.id, isPinned: true)

        XCTAssertTrue(didPin)
        XCTAssertEqual(store.boards[0].isPinned, true)
        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].boards[0].isPinned, true)
    }

    func testSetBoardPinnedRejectsUnknownAndUnchangedBoards() {
        let board = CorkBoard(name: "Board", isPinned: true)
        let store = BoardStore(boards: [board])

        XCTAssertFalse(store.setBoardPinned(id: UUID(), isPinned: false))
        XCTAssertFalse(store.setBoardPinned(id: board.id, isPinned: true))
        XCTAssertEqual(store.boards[0], board)
    }

    func testToggleBoardPinnedFlipsPinnedState() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        XCTAssertTrue(store.toggleBoardPinned(id: board.id))
        XCTAssertTrue(store.boards[0].isPinned)

        XCTAssertTrue(store.toggleBoardPinned(id: board.id))
        XCTAssertFalse(store.boards[0].isPinned)
    }

    func testMoveBoardReordersBoardsAndNormalizesSortIndices() {
        let first = CorkBoard(name: "First", sortIndex: 0)
        let second = CorkBoard(name: "Second", sortIndex: 1)
        let third = CorkBoard(name: "Third", sortIndex: 2)
        let store = BoardStore(boards: [first, second, third], selectedBoardID: first.id)

        let didMove = store.moveBoard(id: first.id, toIndex: 2)

        XCTAssertTrue(didMove)
        XCTAssertEqual(store.boards.map(\.id), [second.id, third.id, first.id])
        XCTAssertEqual(store.boards.map(\.sortIndex), [0, 1, 2])
        XCTAssertEqual(store.selectedBoardID, first.id)
    }

    func testMoveBoardRejectsUnknownOutOfRangeAndSameIndexMoves() {
        let first = CorkBoard(name: "First", sortIndex: 0)
        let second = CorkBoard(name: "Second", sortIndex: 1)
        let store = BoardStore(boards: [first, second])

        XCTAssertFalse(store.moveBoard(id: UUID(), toIndex: 0))
        XCTAssertFalse(store.moveBoard(id: first.id, toIndex: -1))
        XCTAssertFalse(store.moveBoard(id: first.id, toIndex: 2))
        XCTAssertFalse(store.moveBoard(id: first.id, toIndex: 0))
        XCTAssertEqual(store.boards, [first, second])
    }

    func testMoveBoardAutosavesWhenRepositoryIsConfigured() {
        let first = CorkBoard(name: "First", sortIndex: 0)
        let second = CorkBoard(name: "Second", sortIndex: 1)
        let repository = CapturingBoardManagementRepository()
        let store = BoardStore(
            boards: [first, second],
            repository: repository,
            autosaveDelay: 0
        )

        store.moveBoard(id: second.id, toIndex: 0)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].boards.map(\.id), [second.id, first.id])
        XCTAssertEqual(repository.savedSnapshots[0].boards.map(\.sortIndex), [0, 1])
    }

    func testDuplicateBoardCopiesItemsWithNewIDsAndSelectsCopy() throws {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 20, y: 30),
                size: BoardSize(width: 240, height: 180)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let first = CorkBoard(
            name: "First",
            isPinned: true,
            sortIndex: 0,
            items: [item]
        )
        let second = CorkBoard(name: "Second", sortIndex: 1)
        let store = BoardStore(boards: [first, second], selectedBoardID: first.id)
        store.selectItem(item.id)

        let duplicate = try XCTUnwrap(store.duplicateBoard(id: first.id))

        XCTAssertEqual(store.boards.map(\.id), [first.id, duplicate.id, second.id])
        XCTAssertEqual(store.boards.map(\.sortIndex), [0, 1, 2])
        XCTAssertEqual(duplicate.name, "First Copy")
        XCTAssertFalse(duplicate.isPinned)
        XCTAssertEqual(duplicate.items.count, 1)
        XCTAssertNotEqual(duplicate.items[0].id, item.id)
        XCTAssertEqual(duplicate.items[0].frame, item.frame)
        XCTAssertEqual(duplicate.items[0].content, item.content)
        XCTAssertEqual(store.selectedBoardID, duplicate.id)
        XCTAssertNil(store.selectedItemID)
    }

    func testDuplicateBoardRejectsUnknownBoard() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        XCTAssertNil(store.duplicateBoard(id: UUID()))
        XCTAssertEqual(store.boards, [board])
    }

    func testDuplicateBoardAutosavesWhenRepositoryIsConfigured() throws {
        let board = CorkBoard(name: "Board")
        let repository = CapturingBoardManagementRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        let duplicate = try XCTUnwrap(store.duplicateBoard(id: board.id))

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].boards.map(\.id), [board.id, duplicate.id])
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoardID, duplicate.id)
    }

    func testDeleteBoardNormalizesSortIndices() {
        let first = CorkBoard(name: "First", sortIndex: 0)
        let second = CorkBoard(name: "Second", sortIndex: 1)
        let third = CorkBoard(name: "Third", sortIndex: 2)
        let store = BoardStore(boards: [first, second, third])

        store.deleteBoard(id: second.id)

        XCTAssertEqual(store.boards.map(\.id), [first.id, third.id])
        XCTAssertEqual(store.boards.map(\.sortIndex), [0, 1])
    }
}

private final class CapturingBoardManagementRepository: BoardRepository {
    private(set) var savedSnapshots: [BoardLibrarySnapshot] = []

    func loadSnapshot() throws -> BoardLibrarySnapshot? {
        nil
    }

    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
