import XCTest
@testable import CorkCore

@MainActor
final class BoardItemAppearanceTests: XCTestCase {
    func testBoardItemUsesDefaultAppearance() {
        let item = makeItem()

        XCTAssertEqual(item.appearance, .default)
        XCTAssertNil(item.appearance.backgroundHex)
        XCTAssertEqual(item.appearance.fontDesign, .rounded)
    }

    func testCardAppearanceNormalizesBackgroundColor() {
        XCTAssertEqual(
            CardAppearance(backgroundHex: "4ecdc4", fontDesign: .serif),
            CardAppearance(backgroundHex: "#4ECDC4", fontDesign: .serif)
        )
        XCTAssertNil(CardAppearance(backgroundHex: "not-a-color").backgroundHex)
    }

    func testBoardItemAppearanceRoundTripsThroughJSON() throws {
        let item = makeItem(appearance: CardAppearance(
            backgroundHex: "#4ECDC4",
            fontDesign: .monospaced
        ))

        let data = try JSONEncoder().encode(item)
        let decodedItem = try JSONDecoder().decode(BoardItem.self, from: data)

        XCTAssertEqual(decodedItem, item)
    }

    func testBoardItemDefaultsAppearanceWhenDecodedWithoutField() throws {
        let item = makeItem(appearance: CardAppearance(
            backgroundHex: "#4ECDC4",
            fontDesign: .serif
        ))
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(item)) as? [String: Any]
        )
        payload.removeValue(forKey: "appearance")

        let data = try JSONSerialization.data(withJSONObject: payload)
        let decodedItem = try JSONDecoder().decode(BoardItem.self, from: data)

        XCTAssertEqual(decodedItem.appearance, .default)
    }

    func testUpdateItemAppearanceChangesOnlyRequestedItemAndSelectsIt() {
        let first = makeItem(title: "First")
        let second = makeItem(title: "Second")
        let board = CorkBoard(name: "Board", items: [first, second])
        let store = BoardStore(boards: [board])
        let appearance = CardAppearance(backgroundHex: "#FDE2E4", fontDesign: .serif)

        let didUpdate = store.updateItemAppearance(first.id, appearance: appearance)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.selectedBoard.items[0].appearance, appearance)
        XCTAssertEqual(store.selectedBoard.items[1], second)
        XCTAssertEqual(store.selectedItemID, first.id)
    }

    func testUpdateItemAppearanceRejectsUnknownAndUnchangedItems() {
        let appearance = CardAppearance(backgroundHex: "#FDE2E4", fontDesign: .serif)
        let item = makeItem(appearance: appearance)
        let board = CorkBoard(name: "Board", items: [item])
        let store = BoardStore(boards: [board])

        XCTAssertFalse(store.updateItemAppearance(UUID(), appearance: appearance))
        XCTAssertFalse(store.updateItemAppearance(item.id, appearance: appearance))
        XCTAssertEqual(store.selectedBoard.items[0], item)
    }

    func testUpdateItemAppearanceAutosaves() {
        let item = makeItem()
        let repository = CapturingAppearanceRepository()
        let store = BoardStore(
            boards: [CorkBoard(name: "Board", items: [item])],
            repository: repository,
            autosaveDelay: 0
        )
        let appearance = CardAppearance(backgroundHex: "#2F4858", fontDesign: .monospaced)

        store.updateItemAppearance(item.id, appearance: appearance)

        XCTAssertEqual(repository.savedSnapshots.count, 1)
        XCTAssertEqual(repository.savedSnapshots[0].selectedBoard.items[0].appearance, appearance)
    }

    func testDuplicateItemPreservesAppearance() throws {
        let appearance = CardAppearance(backgroundHex: "#FFF1B8", fontDesign: .serif)
        let item = makeItem(appearance: appearance)
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: [item])])

        let duplicate = try XCTUnwrap(store.duplicateItem(item.id))

        XCTAssertNotEqual(duplicate.id, item.id)
        XCTAssertEqual(duplicate.appearance, appearance)
    }

    private func makeItem(
        title: String = "Note",
        appearance: CardAppearance = .default
    ) -> BoardItem {
        BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 20, y: 30),
                size: BoardSize(width: 240, height: 180)
            ),
            content: .text(TextCard(title: title, body: "Body")),
            appearance: appearance
        )
    }
}

private final class CapturingAppearanceRepository: BoardRepository {
    private(set) var savedSnapshots: [BoardLibrarySnapshot] = []

    func loadSnapshot() throws -> BoardLibrarySnapshot? {
        nil
    }

    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
