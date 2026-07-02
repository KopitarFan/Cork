import XCTest
@testable import CorkCore

@MainActor
final class BoardStoreCreationTests: XCTestCase {
    func testCreateTextCardAddsSelectedTextItem() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        let item = store.createTextCard(
            title: "  Draft Note  ",
            body: "Keep this visible.",
            at: BoardPoint(x: 80, y: 96)
        )

        XCTAssertEqual(store.selectedBoard.items.count, 1)
        XCTAssertEqual(store.selectedItemID, item.id)
        XCTAssertEqual(item.frame.origin, BoardPoint(x: 80, y: 96))
        XCTAssertEqual(item.frame.size, BoardStore.Defaults.textCardSize)

        guard case .text(let card) = item.content else {
            return XCTFail("Expected a text card.")
        }

        XCTAssertEqual(card.title, "Draft Note")
        XCTAssertEqual(card.body, "Keep this visible.")
    }

    func testCreateTextCardUsesFallbackTitle() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        let item = store.createTextCard(title: "   ")

        guard case .text(let card) = item.content else {
            return XCTFail("Expected a text card.")
        }

        XCTAssertEqual(card.title, "Untitled Note")
    }

    func testCreateChecklistCardAddsSelectedChecklistItem() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])
        let entries = [
            ChecklistEntry(title: "One", isComplete: true),
            ChecklistEntry(title: "Two")
        ]

        let item = store.createChecklistCard(
            title: "  Launch  ",
            entries: entries,
            at: BoardPoint(x: 90, y: 120)
        )

        XCTAssertEqual(store.selectedBoard.items.count, 1)
        XCTAssertEqual(store.selectedItemID, item.id)
        XCTAssertEqual(item.frame.origin, BoardPoint(x: 90, y: 120))
        XCTAssertEqual(item.frame.size, BoardStore.Defaults.checklistCardSize)

        guard case .checklist(let card) = item.content else {
            return XCTFail("Expected a checklist card.")
        }

        XCTAssertEqual(card.title, "Launch")
        XCTAssertEqual(card.entries, entries)
    }

    func testCreateImageCardAddsSelectedImageItem() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])
        let source = ImageSource.bundledSymbol("photo")

        let item = store.createImageCard(
            title: "  Reference  ",
            source: source,
            at: BoardPoint(x: 110, y: 140)
        )

        XCTAssertEqual(store.selectedBoard.items.count, 1)
        XCTAssertEqual(store.selectedItemID, item.id)
        XCTAssertEqual(item.frame.origin, BoardPoint(x: 110, y: 140))
        XCTAssertEqual(item.frame.size, BoardStore.Defaults.imageCardSize)

        guard case .image(let card) = item.content else {
            return XCTFail("Expected an image card.")
        }

        XCTAssertEqual(card.title, "Reference")
        XCTAssertEqual(card.source, source)
    }

    func testUpdateTextCardChangesTextContentAndSelectsItem() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Old", body: "Old body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        let didUpdate = store.updateTextCard(item.id, title: "  New  ", body: "New body")

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.selectedItemID, item.id)

        guard case .text(let card) = store.selectedBoard.items[0].content else {
            return XCTFail("Expected a text card.")
        }

        XCTAssertEqual(card.title, "New")
        XCTAssertEqual(card.body, "New body")
    }

    func testUpdateTextCardUsesFallbackTitle() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Old", body: "Body"))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        store.updateTextCard(item.id, title: "   ", body: "Body")

        guard case .text(let card) = store.selectedBoard.items[0].content else {
            return XCTFail("Expected a text card.")
        }

        XCTAssertEqual(card.title, "Untitled Note")
    }

    func testUpdateChecklistCardChangesChecklistContent() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .checklist(ChecklistCard(title: "Old", entries: []))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])
        let entries = [
            ChecklistEntry(title: "One", isComplete: true),
            ChecklistEntry(title: "Two")
        ]

        let didUpdate = store.updateChecklistCard(item.id, title: "New", entries: entries)

        XCTAssertTrue(didUpdate)

        guard case .checklist(let card) = store.selectedBoard.items[0].content else {
            return XCTFail("Expected a checklist card.")
        }

        XCTAssertEqual(card.title, "New")
        XCTAssertEqual(card.entries, entries)
    }

    func testUpdateImageCardChangesImageContent() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .image(ImageCard(title: "Old", source: .bundledSymbol("photo")))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])
        let source = ImageSource.fileReference(URL(fileURLWithPath: "/tmp/reference.png"))

        let didUpdate = store.updateImageCard(item.id, title: "New", source: source)

        XCTAssertTrue(didUpdate)

        guard case .image(let card) = store.selectedBoard.items[0].content else {
            return XCTFail("Expected an image card.")
        }

        XCTAssertEqual(card.title, "New")
        XCTAssertEqual(card.source, source)
    }

    func testUpdateCardRejectsWrongContentType() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .checklist(ChecklistCard(title: "List", entries: []))
        )
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        let didUpdate = store.updateTextCard(item.id, title: "Note", body: "Body")

        XCTAssertFalse(didUpdate)
        XCTAssertEqual(store.selectedBoard.items[0], item)
    }

    func testUpdateCardRejectsUnknownItem() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        let didUpdate = store.updateTextCard(UUID(), title: "Note", body: "Body")

        XCTAssertFalse(didUpdate)
        XCTAssertTrue(store.selectedBoard.items.isEmpty)
    }

    func testUpdateCardRejectsUnchangedContent() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Note", body: "Body"))
        )
        let repository = CapturingCreationRepository()
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        let didUpdate = store.updateTextCard(item.id, title: "Note", body: "Body")

        XCTAssertFalse(didUpdate)
        XCTAssertEqual(repository.savedSnapshots.count, 0)
    }

    func testUpdateCardAutosavesWhenRepositoryIsConfigured() {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 10, y: 10),
                size: BoardSize(width: 120, height: 120)
            ),
            content: .text(TextCard(title: "Old", body: "Body"))
        )
        let repository = CapturingCreationRepository()
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        store.updateTextCard(item.id, title: "New", body: "Body")

        XCTAssertEqual(repository.savedSnapshots.count, 1)

        guard case .text(let card) = repository.savedSnapshots[0].selectedBoard.items[0].content else {
            return XCTFail("Expected a text card.")
        }

        XCTAssertEqual(card.title, "New")
    }

    func testCreateCardClampsToCanvasBounds() {
        let board = CorkBoard(name: "Board")
        let store = BoardStore(boards: [board])

        let item = store.createTextCard(
            at: BoardPoint(x: 999, y: 999),
            constrainedTo: BoardSize(width: 320, height: 260)
        )

        XCTAssertEqual(item.frame.origin, BoardPoint(x: 48, y: 58))
    }

    func testCreateCardAutosavesWhenRepositoryIsConfigured() {
        let board = CorkBoard(name: "Board")
        let repository = CapturingCreationRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        let item = store.createTextCard(title: "Saved")

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoard.items.first?.id, item.id)
    }

    func testCreateBoardAddsAndSelectsBoard() {
        let first = CorkBoard(name: "First")
        let store = BoardStore(boards: [first])

        let board = store.createBoard(name: "  Second  ")

        XCTAssertEqual(store.boards.count, 2)
        XCTAssertEqual(store.boards[1].id, board.id)
        XCTAssertEqual(board.name, "Second")
        XCTAssertEqual(store.selectedBoardID, board.id)
        XCTAssertNil(store.selectedItemID)
    }

    func testCreateBoardUsesFallbackName() {
        let first = CorkBoard(name: "First")
        let store = BoardStore(boards: [first])

        let board = store.createBoard(name: "   ")

        XCTAssertEqual(board.name, "Untitled Board")
    }

    func testCreateBoardAutosavesWhenRepositoryIsConfigured() {
        let first = CorkBoard(name: "First")
        let repository = CapturingCreationRepository()
        let store = BoardStore(
            boards: [first],
            repository: repository,
            autosaveDelay: 0
        )

        let board = store.createBoard(name: "Second")

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoardID, board.id)
    }

    func testRenameBoardTrimsName() {
        let board = CorkBoard(name: "Old")
        let store = BoardStore(boards: [board])

        let didRename = store.renameBoard(id: board.id, name: "  New  ")

        XCTAssertTrue(didRename)
        XCTAssertEqual(store.boards[0].name, "New")
    }

    func testRenameBoardRejectsBlankName() {
        let board = CorkBoard(name: "Old")
        let store = BoardStore(boards: [board])

        let didRename = store.renameBoard(id: board.id, name: "   ")

        XCTAssertFalse(didRename)
        XCTAssertEqual(store.boards[0].name, "Old")
    }

    func testRenameBoardRejectsUnknownBoard() {
        let board = CorkBoard(name: "Old")
        let store = BoardStore(boards: [board])

        let didRename = store.renameBoard(id: UUID(), name: "New")

        XCTAssertFalse(didRename)
        XCTAssertEqual(store.boards[0].name, "Old")
    }

    func testRenameBoardAutosavesWhenRepositoryIsConfigured() {
        let board = CorkBoard(name: "Old")
        let repository = CapturingCreationRepository()
        let store = BoardStore(
            boards: [board],
            repository: repository,
            autosaveDelay: 0
        )

        store.renameBoard(id: board.id, name: "New")

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].boards[0].name, "New")
    }

    func testDeleteBoardRemovesSelectedBoardAndSelectsFallback() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let third = CorkBoard(name: "Third")
        let store = BoardStore(boards: [first, second, third], selectedBoardID: second.id)

        let didDelete = store.deleteBoard(id: second.id)

        XCTAssertTrue(didDelete)
        XCTAssertEqual(store.boards.map(\.id), [first.id, third.id])
        XCTAssertEqual(store.selectedBoardID, third.id)
        XCTAssertNil(store.selectedItemID)
    }

    func testDeleteBoardSelectsPreviousBoardWhenDeletingLastBoard() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let store = BoardStore(boards: [first, second], selectedBoardID: second.id)

        let didDelete = store.deleteBoard(id: second.id)

        XCTAssertTrue(didDelete)
        XCTAssertEqual(store.selectedBoardID, first.id)
    }

    func testDeleteUnselectedBoardKeepsSelectedBoard() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let store = BoardStore(boards: [first, second], selectedBoardID: first.id)

        let didDelete = store.deleteBoard(id: second.id)

        XCTAssertTrue(didDelete)
        XCTAssertEqual(store.selectedBoardID, first.id)
    }

    func testDeleteBoardRejectsLastBoard() {
        let board = CorkBoard(name: "Only")
        let store = BoardStore(boards: [board])

        let didDelete = store.deleteBoard(id: board.id)

        XCTAssertFalse(didDelete)
        XCTAssertEqual(store.boards, [board])
        XCTAssertEqual(store.selectedBoardID, board.id)
    }

    func testDeleteBoardRejectsUnknownBoard() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let store = BoardStore(boards: [first, second])

        let didDelete = store.deleteBoard(id: UUID())

        XCTAssertFalse(didDelete)
        XCTAssertEqual(store.boards, [first, second])
    }

    func testDeleteBoardAutosavesWhenRepositoryIsConfigured() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")
        let repository = CapturingCreationRepository()
        let store = BoardStore(
            boards: [first, second],
            repository: repository,
            autosaveDelay: 0
        )

        store.deleteBoard(id: second.id)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].boards, [first])
    }
}

private final class CapturingCreationRepository: BoardRepository {
    private(set) var savedSnapshots: [BoardLibrarySnapshot] = []

    func loadSnapshot() throws -> BoardLibrarySnapshot? {
        nil
    }

    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
