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

    func testSelectingUnknownBoardDoesNothing() {
        let board = CorkBoard(name: "Only")
        let store = BoardStore(boards: [board])

        store.selectBoard(UUID())

        XCTAssertEqual(store.selectedBoard.id, board.id)
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
}
