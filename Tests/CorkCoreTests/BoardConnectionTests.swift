import XCTest
@testable import CorkCore

@MainActor
final class BoardConnectionTests: XCTestCase {
    func testBoardDefaultsConnectionsWhenDecodedWithoutField() throws {
        let items = makeItems()
        let board = CorkBoard(
            name: "Connected",
            items: items,
            connections: [makeConnection(items: items)]
        )
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(board)) as? [String: Any]
        )
        payload.removeValue(forKey: "connections")

        let data = try JSONSerialization.data(withJSONObject: payload)
        let decodedBoard = try JSONDecoder().decode(CorkBoard.self, from: data)

        XCTAssertTrue(decodedBoard.connections.isEmpty)
    }

    func testConnectionsRoundTripThroughJSON() throws {
        let items = makeItems()
        let board = CorkBoard(
            name: "Connected",
            items: items,
            connections: [makeConnection(items: items, style: .string)]
        )

        let data = try JSONEncoder().encode(board)
        let decodedBoard = try JSONDecoder().decode(CorkBoard.self, from: data)

        XCTAssertEqual(decodedBoard, board)
    }

    func testBeginConnectionSelectsValidatedSource() {
        let items = makeItems()
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: items)])

        XCTAssertFalse(store.beginConnection(from: UUID()))
        XCTAssertTrue(store.beginConnection(from: items[0].id))
        XCTAssertEqual(store.connectionSourceItemID, items[0].id)
        XCTAssertEqual(store.selectedItemID, items[0].id)
    }

    func testConnectSourceCreatesConnectionAndAutosaves() {
        let items = makeItems()
        let repository = CapturingConnectionRepository()
        let store = BoardStore(
            boards: [CorkBoard(name: "Board", items: items)],
            repository: repository,
            autosaveDelay: 0
        )
        store.beginConnection(from: items[0].id)

        let didConnect = store.connectConnectionSource(to: items[1].id, style: .string)

        XCTAssertTrue(didConnect)
        XCTAssertNil(store.connectionSourceItemID)
        XCTAssertEqual(store.selectedItemID, items[1].id)
        XCTAssertEqual(store.selectedBoard.connections.count, 1)
        XCTAssertEqual(store.selectedBoard.connections[0].style, .string)
        XCTAssertTrue(store.selectedBoard.connections[0].connects(items[0].id, items[1].id))
        XCTAssertEqual(repository.savedSnapshots.count, 1)
    }

    func testConnectingSameCardsUpdatesStyleWithoutAddingDuplicate() {
        let items = makeItems()
        let connection = makeConnection(items: items, style: .string)
        let store = BoardStore(boards: [CorkBoard(
            name: "Board",
            items: items,
            connections: [connection]
        )])
        store.beginConnection(from: items[1].id)

        let didConnect = store.connectConnectionSource(to: items[0].id, style: .line)

        XCTAssertTrue(didConnect)
        XCTAssertEqual(store.selectedBoard.connections.count, 1)
        XCTAssertEqual(store.selectedBoard.connections[0].id, connection.id)
        XCTAssertEqual(store.selectedBoard.connections[0].style, .line)
    }

    func testConnectionRejectsSameOrUnknownTarget() {
        let items = makeItems()
        let store = BoardStore(boards: [CorkBoard(name: "Board", items: items)])

        store.beginConnection(from: items[0].id)
        XCTAssertFalse(store.connectConnectionSource(to: items[0].id, style: .line))
        XCTAssertEqual(store.connectionSourceItemID, items[0].id)
        XCTAssertFalse(store.connectConnectionSource(to: UUID(), style: .line))
        XCTAssertTrue(store.selectedBoard.connections.isEmpty)
    }

    func testRemoveConnectionsOnlyRemovesConnectionsForRequestedCard() {
        let items = makeItems(count: 3)
        let firstConnection = BoardConnection(
            sourceItemID: items[0].id,
            targetItemID: items[1].id,
            style: .string
        )
        let secondConnection = BoardConnection(
            sourceItemID: items[1].id,
            targetItemID: items[2].id,
            style: .line
        )
        let board = CorkBoard(
            name: "Board",
            items: items,
            connections: [firstConnection, secondConnection]
        )
        let store = BoardStore(boards: [board])

        XCTAssertTrue(store.removeConnections(for: items[0].id))
        XCTAssertEqual(store.selectedBoard.connections, [secondConnection])
        XCTAssertFalse(store.removeConnections(for: items[0].id))
    }

    func testDeletingCardRemovesItsConnections() {
        let items = makeItems(count: 3)
        let board = CorkBoard(
            name: "Board",
            items: items,
            connections: [
                BoardConnection(
                    sourceItemID: items[0].id,
                    targetItemID: items[1].id,
                    style: .string
                ),
                BoardConnection(
                    sourceItemID: items[1].id,
                    targetItemID: items[2].id,
                    style: .line
                )
            ]
        )
        let store = BoardStore(boards: [board])

        store.deleteItem(items[0].id)

        XCTAssertEqual(store.selectedBoard.connections.count, 1)
        XCTAssertTrue(store.selectedBoard.connections[0].connects(items[1].id, items[2].id))
    }

    func testDuplicatingBoardRemapsConnectionsToDuplicatedCards() throws {
        let items = makeItems()
        let sourceBoard = CorkBoard(
            name: "Source",
            items: items,
            connections: [makeConnection(items: items, style: .string)]
        )
        let store = BoardStore(boards: [sourceBoard])

        let duplicate = try XCTUnwrap(store.duplicateBoard(id: sourceBoard.id))

        XCTAssertEqual(duplicate.connections.count, 1)
        XCTAssertEqual(duplicate.connections[0].style, .string)
        XCTAssertTrue(duplicate.connections[0].connects(
            duplicate.items[0].id,
            duplicate.items[1].id
        ))
        XCTAssertFalse(Set(items.map(\.id)).contains(duplicate.connections[0].sourceItemID))
        XCTAssertFalse(Set(items.map(\.id)).contains(duplicate.connections[0].targetItemID))
    }

    func testSwitchingBoardsCancelsPendingConnection() {
        let firstItems = makeItems()
        let first = CorkBoard(name: "First", items: firstItems)
        let second = CorkBoard(name: "Second")
        let store = BoardStore(boards: [first, second])
        store.beginConnection(from: firstItems[0].id)

        store.selectBoard(second.id)

        XCTAssertNil(store.connectionSourceItemID)
    }

    private func makeItems(count: Int = 2) -> [BoardItem] {
        (0..<count).map { index in
            BoardItem(
                frame: BoardRect(
                    origin: BoardPoint(x: Double(20 + (index * 260)), y: 30),
                    size: BoardSize(width: 220, height: 160)
                ),
                content: .text(TextCard(title: "Note \(index + 1)", body: "Body"))
            )
        }
    }

    private func makeConnection(
        items: [BoardItem],
        style: BoardConnectionStyle = .line
    ) -> BoardConnection {
        BoardConnection(
            sourceItemID: items[0].id,
            targetItemID: items[1].id,
            style: style
        )
    }
}

private final class CapturingConnectionRepository: BoardRepository {
    private(set) var savedSnapshots: [BoardLibrarySnapshot] = []

    func loadSnapshot() throws -> BoardLibrarySnapshot? {
        nil
    }

    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        savedSnapshots.append(snapshot)
    }
}
