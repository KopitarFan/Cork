import Foundation

public struct BoardLibrarySnapshot: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var boards: [CorkBoard]
    public var selectedBoardID: CorkBoard.ID

    public init(
        schemaVersion: Int = BoardLibrarySnapshot.currentSchemaVersion,
        boards: [CorkBoard],
        selectedBoardID: CorkBoard.ID? = nil
    ) {
        precondition(!boards.isEmpty, "Board library snapshots need at least one board.")

        self.schemaVersion = schemaVersion
        self.boards = boards

        if let selectedBoardID,
           boards.contains(where: { $0.id == selectedBoardID }) {
            self.selectedBoardID = selectedBoardID
        } else {
            self.selectedBoardID = boards[0].id
        }
    }

    public var selectedBoard: CorkBoard {
        boards.first { $0.id == selectedBoardID } ?? boards[0]
    }
}

public extension BoardLibrarySnapshot {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let schemaVersion = try container.decode(Int.self, forKey: .schemaVersion)
        let boards = try container.decode([CorkBoard].self, forKey: .boards)
        let selectedBoardID = try container.decode(CorkBoard.ID.self, forKey: .selectedBoardID)

        guard schemaVersion == Self.currentSchemaVersion else {
            throw DecodingError.dataCorruptedError(
                forKey: .schemaVersion,
                in: container,
                debugDescription: "Unsupported board library schema version \(schemaVersion)."
            )
        }

        guard !boards.isEmpty else {
            throw DecodingError.dataCorruptedError(
                forKey: .boards,
                in: container,
                debugDescription: "A board library must contain at least one board."
            )
        }

        self.init(
            schemaVersion: schemaVersion,
            boards: boards,
            selectedBoardID: selectedBoardID
        )
    }
}

public extension BoardLibrarySnapshot {
    static var sample: BoardLibrarySnapshot {
        BoardLibrarySnapshot(boards: CorkBoard.sampleBoards)
    }
}
