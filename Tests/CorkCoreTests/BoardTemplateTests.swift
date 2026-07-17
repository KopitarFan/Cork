import XCTest
@testable import CorkCore

@MainActor
final class BoardTemplateTests: XCTestCase {
    func testTemplateCatalogIncludesExpectedWorkflows() {
        XCTAssertEqual(BoardTemplate.allCases, [
            .agile,
            .kanban,
            .visionBoard,
            .scheduling,
            .randomArrangement,
            .projectHub,
            .writingRoom,
            .swotAnalysis
        ])
    }

    func testTemplatesHaveUniquePresentationMetadata() {
        let templates = BoardTemplate.allCases

        XCTAssertEqual(Set(templates.map(\.title)).count, templates.count)
        XCTAssertEqual(Set(templates.map(\.summary)).count, templates.count)
        XCTAssertTrue(templates.allSatisfy { !$0.systemImageName.isEmpty })
    }

    func testEveryTemplateProducesUsableCards() {
        for template in BoardTemplate.allCases {
            let items = template.makeItems()

            XCTAssertFalse(items.isEmpty, "\(template.title) should contain starter cards")
            XCTAssertEqual(Set(items.map(\.id)).count, items.count)
            XCTAssertTrue(items.allSatisfy { !$0.content.displayTitle.isEmpty })
            XCTAssertTrue(items.allSatisfy { $0.frame.origin.x >= 0 && $0.frame.origin.y >= 0 })
            XCTAssertTrue(items.allSatisfy { $0.frame.size.width > 0 && $0.frame.size.height > 0 })
            XCTAssertTrue(items.contains { $0.appearance.backgroundHex != nil })
        }
    }

    func testMakingTemplateItemsCreatesFreshIDs() {
        let firstItems = BoardTemplate.kanban.makeItems()
        let secondItems = BoardTemplate.kanban.makeItems()

        XCTAssertTrue(Set(firstItems.map(\.id)).isDisjoint(with: Set(secondItems.map(\.id))))
    }

    func testCreateBoardFromTemplateAddsStarterCardsAndSelectsBoard() {
        let first = CorkBoard(name: "First")
        let store = BoardStore(boards: [first])

        let board = store.createBoard(name: "Sprint 12", template: .agile)

        XCTAssertEqual(board.name, "Sprint 12")
        XCTAssertEqual(board.items.count, BoardTemplate.agile.makeItems().count)
        XCTAssertEqual(store.selectedBoardID, board.id)
        XCTAssertEqual(store.selectedBoard.items.map(\.content.displayTitle), [
            "Sprint Goal",
            "Backlog",
            "In Progress",
            "Review",
            "Done"
        ])
        XCTAssertNil(store.selectedItemID)
    }

    func testCreateBlankBoardStillCreatesNoCards() {
        let store = BoardStore(boards: [CorkBoard(name: "First")])

        let board = store.createBoard(name: "Blank")

        XCTAssertTrue(board.items.isEmpty)
    }

    func testCreateBoardFromTemplateAutosaves() {
        let repository = CapturingTemplateRepository()
        let store = BoardStore(
            boards: [CorkBoard(name: "First")],
            repository: repository,
            autosaveDelay: 0
        )

        let board = store.createBoard(name: "Vision", template: .visionBoard)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoardID, board.id)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoard.items.count, board.items.count)
    }
}

private final class CapturingTemplateRepository: BoardRepository {
    private(set) var savedSnapshots: [BoardLibrarySnapshot] = []

    func loadSnapshot() throws -> BoardLibrarySnapshot? {
        nil
    }

    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
