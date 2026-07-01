import Combine
import Foundation

@MainActor
public final class BoardStore: ObservableObject {
    @Published public private(set) var boards: [CorkBoard]
    @Published public private(set) var selectedBoardID: CorkBoard.ID

    public init(boards: [CorkBoard] = CorkBoard.sampleBoards) {
        precondition(!boards.isEmpty, "Cork needs at least one board.")
        self.boards = boards
        self.selectedBoardID = boards[0].id
    }

    public var selectedBoard: CorkBoard {
        boards.first { $0.id == selectedBoardID } ?? boards[0]
    }

    public func selectBoard(_ id: CorkBoard.ID) {
        guard boards.contains(where: { $0.id == id }) else {
            return
        }

        selectedBoardID = id
    }

    public func updateItemPosition(_ id: BoardItem.ID, to origin: BoardPoint) {
        updateSelectedBoard { board in
            guard let itemIndex = board.items.firstIndex(where: { $0.id == id }) else {
                return
            }

            board.items[itemIndex].frame.origin = BoardPoint(
                x: max(12, origin.x),
                y: max(12, origin.y)
            )
            board.updatedAt = Date()
        }
    }

    private func updateSelectedBoard(_ update: (inout CorkBoard) -> Void) {
        guard let boardIndex = boards.firstIndex(where: { $0.id == selectedBoardID }) else {
            return
        }

        update(&boards[boardIndex])
    }
}
