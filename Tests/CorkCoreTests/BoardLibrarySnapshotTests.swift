import XCTest
@testable import CorkCore

final class BoardLibrarySnapshotTests: XCTestCase {
    func testSnapshotDefaultsToFirstBoardWhenSelectionIsMissing() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")

        let snapshot = BoardLibrarySnapshot(boards: [first, second])

        XCTAssertEqual(snapshot.selectedBoardID, first.id)
        XCTAssertEqual(snapshot.selectedBoard, first)
    }

    func testSnapshotPreservesValidSelectedBoard() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")

        let snapshot = BoardLibrarySnapshot(boards: [first, second], selectedBoardID: second.id)

        XCTAssertEqual(snapshot.selectedBoardID, second.id)
        XCTAssertEqual(snapshot.selectedBoard, second)
    }

    func testSnapshotFallsBackToFirstBoardWhenSelectionIsUnknown() {
        let first = CorkBoard(name: "First")
        let second = CorkBoard(name: "Second")

        let snapshot = BoardLibrarySnapshot(boards: [first, second], selectedBoardID: UUID())

        XCTAssertEqual(snapshot.selectedBoardID, first.id)
        XCTAssertEqual(snapshot.selectedBoard, first)
    }

    func testSnapshotUsesCurrentSchemaVersionByDefault() {
        let board = CorkBoard(name: "Board")

        let snapshot = BoardLibrarySnapshot(boards: [board])

        XCTAssertEqual(snapshot.schemaVersion, BoardLibrarySnapshot.currentSchemaVersion)
    }

    func testSnapshotRoundTripsThroughJSON() throws {
        let item = BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: 42, y: 84),
                size: BoardSize(width: 240, height: 180)
            ),
            content: .checklist(ChecklistCard(
                title: "Ship",
                entries: [
                    ChecklistEntry(title: "Persist boards", isComplete: true),
                    ChecklistEntry(title: "Restore selection")
                ]
            ))
        )
        let board = CorkBoard(name: "Milestone 2", items: [item])
        let snapshot = BoardLibrarySnapshot(boards: [board], selectedBoardID: board.id)

        let data = try JSONEncoder().encode(snapshot)
        let decodedSnapshot = try JSONDecoder().decode(BoardLibrarySnapshot.self, from: data)

        XCTAssertEqual(decodedSnapshot, snapshot)
    }

    func testDecodingEmptyBoardListFails() throws {
        let json = """
        {
            "schemaVersion": 1,
            "boards": [],
            "selectedBoardID": "00000000-0000-0000-0000-000000000000"
        }
        """

        XCTAssertThrowsError(
            try JSONDecoder().decode(BoardLibrarySnapshot.self, from: Data(json.utf8))
        )
    }

    func testDecodingUnsupportedSchemaVersionFails() throws {
        let board = CorkBoard(name: "Board")
        let snapshot = BoardLibrarySnapshot(
            schemaVersion: BoardLibrarySnapshot.currentSchemaVersion,
            boards: [board],
            selectedBoardID: board.id
        )
        var payload = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(snapshot)
        ) as? [String: Any]
        payload?["schemaVersion"] = BoardLibrarySnapshot.currentSchemaVersion + 1

        let data = try JSONSerialization.data(withJSONObject: payload ?? [:])

        XCTAssertThrowsError(
            try JSONDecoder().decode(BoardLibrarySnapshot.self, from: data)
        )
    }
}
