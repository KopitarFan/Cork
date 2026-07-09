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
        let board = CorkBoard(
            name: "Milestone 2",
            isPinned: true,
            sortIndex: 3,
            items: [item]
        )
        let snapshot = BoardLibrarySnapshot(boards: [board], selectedBoardID: board.id)

        let data = try JSONEncoder().encode(snapshot)
        let decodedSnapshot = try JSONDecoder().decode(BoardLibrarySnapshot.self, from: data)

        XCTAssertEqual(decodedSnapshot, snapshot)
    }

    func testCorkBoardDefaultsManagementMetadataWhenDecodedWithoutFields() throws {
        let board = CorkBoard(
            name: "Legacy",
            isPinned: true,
            sortIndex: 4
        )
        var payload = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(board)
            ) as? [String: Any]
        )
        payload.removeValue(forKey: "isPinned")
        payload.removeValue(forKey: "sortIndex")
        let data = try JSONSerialization.data(withJSONObject: payload)

        let decodedBoard = try JSONDecoder().decode(CorkBoard.self, from: data)

        XCTAssertEqual(decodedBoard.id, board.id)
        XCTAssertEqual(decodedBoard.name, "Legacy")
        XCTAssertFalse(decodedBoard.isPinned)
        XCTAssertEqual(decodedBoard.sortIndex, 0)
    }

    func testTextCardDefaultsToPlainTextWhenDecodedWithoutFormat() throws {
        let json = """
        {
            "title": "Old Note",
            "body": "Saved before formats existed."
        }
        """

        let card = try JSONDecoder().decode(TextCard.self, from: Data(json.utf8))

        XCTAssertEqual(card.title, "Old Note")
        XCTAssertEqual(card.body, "Saved before formats existed.")
        XCTAssertEqual(card.format, .plainText)
    }

    func testPaletteColorParsesAndNormalizesHexValues() {
        let colors = PaletteColor.colors(from: "#f66, 4ecdc4\nFFE66D invalid #292F36")

        XCTAssertEqual(colors.map(\.hex), [
            "#FF6666",
            "#4ECDC4",
            "#FFE66D",
            "#292F36"
        ])
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
