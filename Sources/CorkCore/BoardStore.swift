import Combine
import Foundation

@MainActor
public final class BoardStore: ObservableObject {
    @Published public private(set) var boards: [CorkBoard]
    @Published public private(set) var selectedBoardID: CorkBoard.ID
    @Published public private(set) var lastPersistenceError: Error?

    public convenience init(snapshot: BoardLibrarySnapshot) {
        self.init(snapshot: snapshot, repository: nil)
    }

    public convenience init(
        snapshot: BoardLibrarySnapshot,
        repository: BoardRepository?,
        autosaveDelay: TimeInterval = 0.35
    ) {
        self.init(
            boards: snapshot.boards,
            selectedBoardID: snapshot.selectedBoardID,
            repository: repository,
            autosaveDelay: autosaveDelay
        )
    }

    private let repository: BoardRepository?
    private let autosaveDelay: TimeInterval
    private var autosaveTask: Task<Void, Never>?

    public init(
        boards: [CorkBoard] = CorkBoard.sampleBoards,
        selectedBoardID: CorkBoard.ID? = nil,
        repository: BoardRepository? = nil,
        autosaveDelay: TimeInterval = 0.35
    ) {
        precondition(!boards.isEmpty, "Cork needs at least one board.")
        self.boards = boards
        self.selectedBoardID = selectedBoardID.flatMap { id in
            boards.first { $0.id == id }?.id
        } ?? boards[0].id
        self.repository = repository
        self.autosaveDelay = autosaveDelay
    }

    public var selectedBoard: CorkBoard {
        boards.first { $0.id == selectedBoardID } ?? boards[0]
    }

    public var snapshot: BoardLibrarySnapshot {
        BoardLibrarySnapshot(boards: boards, selectedBoardID: selectedBoardID)
    }

    public func selectBoard(_ id: CorkBoard.ID) {
        guard selectedBoardID != id,
              boards.contains(where: { $0.id == id })
        else {
            return
        }

        selectedBoardID = id
        scheduleAutosave()
    }

    public func updateItemPosition(_ id: BoardItem.ID, to origin: BoardPoint) {
        let didUpdate = updateSelectedBoard { board in
            guard let itemIndex = board.items.firstIndex(where: { $0.id == id }) else {
                return false
            }

            board.items[itemIndex].frame.origin = BoardPoint(
                x: max(12, origin.x),
                y: max(12, origin.y)
            )
            board.updatedAt = Date()
            return true
        }

        if didUpdate {
            scheduleAutosave()
        }
    }

    public func flushPendingAutosave() {
        autosaveTask?.cancel()
        autosaveTask = nil
        saveSnapshot(snapshot)
    }

    @discardableResult
    private func updateSelectedBoard(_ update: (inout CorkBoard) -> Bool) -> Bool {
        guard let boardIndex = boards.firstIndex(where: { $0.id == selectedBoardID }) else {
            return false
        }

        return update(&boards[boardIndex])
    }

    private func scheduleAutosave() {
        guard repository != nil else {
            return
        }

        autosaveTask?.cancel()

        let snapshot = snapshot

        guard autosaveDelay > 0 else {
            saveSnapshot(snapshot)
            return
        }

        let nanoseconds = UInt64(autosaveDelay * 1_000_000_000)
        autosaveTask = Task { @MainActor [weak self, snapshot] in
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else {
                return
            }

            self?.saveSnapshot(snapshot)
        }
    }

    private func saveSnapshot(_ snapshot: BoardLibrarySnapshot) {
        do {
            try repository?.saveSnapshot(snapshot)
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }
}
