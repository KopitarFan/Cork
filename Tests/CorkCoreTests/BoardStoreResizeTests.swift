import XCTest
@testable import CorkCore

@MainActor
final class BoardStoreResizeTests: XCTestCase {
    func testResizeItemUpdatesSizeOnSelectedBoard() {
        let item = makeItem(size: BoardSize(width: 200, height: 160))
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        let didResize = store.resizeItem(item.id, to: BoardSize(width: 300, height: 260))

        XCTAssertTrue(didResize)
        XCTAssertEqual(store.selectedBoard.items[0].frame.origin, item.frame.origin)
        XCTAssertEqual(store.selectedBoard.items[0].frame.size, BoardSize(width: 300, height: 260))
    }

    func testResizeItemClampsToMinimumSize() {
        let item = makeItem(size: BoardSize(width: 220, height: 180))
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        store.resizeItem(item.id, to: BoardSize(width: 60, height: 40))

        XCTAssertEqual(store.selectedBoard.items[0].frame.size, BoardStore.Defaults.minimumCardSize)
    }

    func testResizeItemClampsToMaximumSize() {
        let item = makeItem(size: BoardSize(width: 220, height: 180))
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        store.resizeItem(item.id, to: BoardSize(width: 900, height: 800))

        XCTAssertEqual(store.selectedBoard.items[0].frame.size, BoardStore.Defaults.maximumCardSize)
    }

    func testResizeItemClampsToCanvasBounds() {
        let item = makeItem(
            origin: BoardPoint(x: 40, y: 40),
            size: BoardSize(width: 120, height: 120)
        )
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        store.resizeItem(
            item.id,
            to: BoardSize(width: 500, height: 500),
            constrainedTo: BoardSize(width: 320, height: 260)
        )

        XCTAssertEqual(store.selectedBoard.items[0].frame.origin, BoardPoint(x: 40, y: 40))
        XCTAssertEqual(store.selectedBoard.items[0].frame.size, BoardSize(width: 268, height: 208))
    }

    func testResizeItemRepositionsWhenMinimumSizeWouldOverflowCanvas() {
        let item = makeItem(
            origin: BoardPoint(x: 250, y: 200),
            size: BoardSize(width: 120, height: 120)
        )
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        store.resizeItem(
            item.id,
            to: BoardSize(width: 80, height: 80),
            constrainedTo: BoardSize(width: 320, height: 260)
        )

        XCTAssertEqual(store.selectedBoard.items[0].frame.origin, BoardPoint(x: 148, y: 128))
        XCTAssertEqual(store.selectedBoard.items[0].frame.size, BoardStore.Defaults.minimumCardSize)
    }

    func testResizeSelectedItemResizesSelection() {
        let item = makeItem(size: BoardSize(width: 220, height: 180))
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        store.selectItem(item.id)
        let didResize = store.resizeSelectedItem(to: BoardSize(width: 300, height: 240))

        XCTAssertTrue(didResize)
        XCTAssertEqual(store.selectedItemID, item.id)
        XCTAssertEqual(store.selectedBoard.items[0].frame.size, BoardSize(width: 300, height: 240))
    }

    func testResizeSelectedItemReturnsFalseWithoutSelection() {
        let item = makeItem(size: BoardSize(width: 220, height: 180))
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        let didResize = store.resizeSelectedItem(to: BoardSize(width: 300, height: 240))

        XCTAssertFalse(didResize)
        XCTAssertEqual(store.selectedBoard.items[0], item)
    }

    func testResizeItemRejectsUnknownItem() {
        let item = makeItem(size: BoardSize(width: 220, height: 180))
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        let didResize = store.resizeItem(UUID(), to: BoardSize(width: 300, height: 240))

        XCTAssertFalse(didResize)
        XCTAssertEqual(store.selectedBoard.items[0], item)
    }

    func testResizeItemRejectsUnchangedFrame() {
        let item = makeItem(size: BoardStore.Defaults.minimumCardSize)
        let repository = CapturingResizeRepository()
        let store = BoardStore(
            boards: [CorkBoard(name: "Board", items: [item])],
            repository: repository,
            autosaveDelay: 0
        )

        let didResize = store.resizeItem(item.id, to: BoardSize(width: 80, height: 80))

        XCTAssertFalse(didResize)
        XCTAssertEqual(repository.savedSnapshots.count, 0)
    }

    func testResizeItemAutosavesWhenRepositoryIsConfigured() {
        let item = makeItem(size: BoardSize(width: 220, height: 180))
        let repository = CapturingResizeRepository()
        let store = BoardStore(
            boards: [CorkBoard(name: "Board", items: [item])],
            repository: repository,
            autosaveDelay: 0
        )

        store.resizeItem(item.id, to: BoardSize(width: 300, height: 240))

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(
            repository.savedSnapshots[0].selectedBoard.items[0].frame.size,
            BoardSize(width: 300, height: 240)
        )
    }

    func testAutosaveDebouncesRapidResizeUpdates() async throws {
        let item = makeItem(size: BoardSize(width: 220, height: 180))
        let repository = CapturingResizeRepository()
        let store = BoardStore(
            boards: [CorkBoard(name: "Board", items: [item])],
            repository: repository,
            autosaveDelay: 0.05
        )

        store.resizeItem(item.id, to: BoardSize(width: 260, height: 200))
        store.resizeItem(item.id, to: BoardSize(width: 300, height: 240))
        store.resizeItem(item.id, to: BoardSize(width: 340, height: 280))

        XCTAssertEqual(repository.savedSnapshots.count, 0)

        try await Task.sleep(nanoseconds: 120_000_000)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(
            repository.savedSnapshots[0].selectedBoard.items[0].frame.size,
            BoardSize(width: 340, height: 280)
        )
    }

    private func makeItem(
        origin: BoardPoint = BoardPoint(x: 40, y: 40),
        size: BoardSize
    ) -> BoardItem {
        BoardItem(
            frame: BoardRect(origin: origin, size: size),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
    }
}

private final class CapturingResizeRepository: BoardRepository {
    private(set) var savedSnapshots: [BoardLibrarySnapshot] = []

    func loadSnapshot() throws -> BoardLibrarySnapshot? {
        nil
    }

    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
