import Combine
import Foundation

@MainActor
public final class BoardStore: ObservableObject {
    public enum Defaults {
        public static let newCardOrigin = BoardPoint(x: 48, y: 48)
        public static let textCardSize = BoardSize(width: 260, height: 190)
        public static let checklistCardSize = BoardSize(width: 240, height: 210)
        public static let imageCardSize = BoardSize(width: 230, height: 170)
    }

    @Published public private(set) var boards: [CorkBoard]
    @Published public private(set) var selectedBoardID: CorkBoard.ID
    @Published public private(set) var selectedItemID: BoardItem.ID?
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

    public var selectedItem: BoardItem? {
        selectedBoard.items.first { $0.id == selectedItemID }
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
        selectedItemID = nil
        scheduleAutosave()
    }

    public func selectItem(_ id: BoardItem.ID) {
        guard selectedBoard.items.contains(where: { $0.id == id }) else {
            return
        }

        selectedItemID = id
    }

    public func clearSelection() {
        selectedItemID = nil
    }

    @discardableResult
    public func createTextCard(
        title: String = "Untitled Note",
        body: String = "",
        at origin: BoardPoint = Defaults.newCardOrigin,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> BoardItem {
        createItem(
            content: .text(TextCard(
                title: sanitizedTitle(title, fallback: "Untitled Note"),
                body: body
            )),
            origin: origin,
            size: Defaults.textCardSize,
            constrainedTo: canvasSize
        )
    }

    @discardableResult
    public func createChecklistCard(
        title: String = "Untitled Checklist",
        entries: [ChecklistEntry] = [],
        at origin: BoardPoint = Defaults.newCardOrigin,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> BoardItem {
        createItem(
            content: .checklist(ChecklistCard(
                title: sanitizedTitle(title, fallback: "Untitled Checklist"),
                entries: entries
            )),
            origin: origin,
            size: Defaults.checklistCardSize,
            constrainedTo: canvasSize
        )
    }

    @discardableResult
    public func createImageCard(
        title: String = "Untitled Image",
        source: ImageSource? = nil,
        at origin: BoardPoint = Defaults.newCardOrigin,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> BoardItem {
        createItem(
            content: .image(ImageCard(
                title: sanitizedTitle(title, fallback: "Untitled Image"),
                source: source
            )),
            origin: origin,
            size: Defaults.imageCardSize,
            constrainedTo: canvasSize
        )
    }

    @discardableResult
    public func updateTextCard(
        _ id: BoardItem.ID,
        title: String,
        body: String
    ) -> Bool {
        updateItemContent(id) { content in
            guard case .text(let currentCard) = content else {
                return nil
            }

            let nextCard = TextCard(
                title: sanitizedTitle(title, fallback: "Untitled Note"),
                body: body
            )

            guard currentCard != nextCard else {
                return nil
            }

            return .text(nextCard)
        }
    }

    @discardableResult
    public func updateChecklistCard(
        _ id: BoardItem.ID,
        title: String,
        entries: [ChecklistEntry]
    ) -> Bool {
        updateItemContent(id) { content in
            guard case .checklist(let currentCard) = content else {
                return nil
            }

            let nextCard = ChecklistCard(
                title: sanitizedTitle(title, fallback: "Untitled Checklist"),
                entries: entries
            )

            guard currentCard != nextCard else {
                return nil
            }

            return .checklist(nextCard)
        }
    }

    @discardableResult
    public func updateImageCard(
        _ id: BoardItem.ID,
        title: String,
        source: ImageSource?
    ) -> Bool {
        updateItemContent(id) { content in
            guard case .image(let currentCard) = content else {
                return nil
            }

            let nextCard = ImageCard(
                title: sanitizedTitle(title, fallback: "Untitled Image"),
                source: source
            )

            guard currentCard != nextCard else {
                return nil
            }

            return .image(nextCard)
        }
    }

    @discardableResult
    public func createBoard(name: String = "Untitled Board") -> CorkBoard {
        let now = Date()
        let board = CorkBoard(
            name: sanitizedTitle(name, fallback: "Untitled Board"),
            createdAt: now,
            updatedAt: now
        )

        boards.append(board)
        selectedBoardID = board.id
        selectedItemID = nil
        scheduleAutosave()

        return board
    }

    @discardableResult
    public func renameBoard(id: CorkBoard.ID, name: String) -> Bool {
        guard let boardIndex = boards.firstIndex(where: { $0.id == id }) else {
            return false
        }

        let sanitizedName = sanitizedTitle(name, fallback: "")

        guard !sanitizedName.isEmpty,
              boards[boardIndex].name != sanitizedName
        else {
            return false
        }

        boards[boardIndex].name = sanitizedName
        boards[boardIndex].updatedAt = Date()
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func deleteBoard(id: CorkBoard.ID) -> Bool {
        guard boards.count > 1,
              let boardIndex = boards.firstIndex(where: { $0.id == id })
        else {
            return false
        }

        let wasSelectedBoard = boards[boardIndex].id == selectedBoardID
        boards.remove(at: boardIndex)

        if wasSelectedBoard {
            let fallbackIndex = min(boardIndex, boards.count - 1)
            selectedBoardID = boards[fallbackIndex].id
            selectedItemID = nil
        }

        scheduleAutosave()

        return true
    }

    public func updateItemPosition(
        _ id: BoardItem.ID,
        to origin: BoardPoint,
        constrainedTo canvasSize: BoardSize? = nil
    ) {
        let didUpdate = updateSelectedBoard { board in
            guard let itemIndex = board.items.firstIndex(where: { $0.id == id }) else {
                return false
            }

            board.items[itemIndex].frame.origin = Self.clampedOrigin(
                origin,
                itemSize: board.items[itemIndex].frame.size,
                canvasSize: canvasSize
            )
            board.updatedAt = Date()
            return true
        }

        if didUpdate {
            scheduleAutosave()
        }
    }

    @discardableResult
    public func moveSelectedItem(
        by delta: BoardPoint,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> Bool {
        guard let selectedItemID,
              let item = selectedItem
        else {
            return false
        }

        let nextOrigin = BoardPoint(
            x: item.frame.origin.x + delta.x,
            y: item.frame.origin.y + delta.y
        )
        updateItemPosition(selectedItemID, to: nextOrigin, constrainedTo: canvasSize)
        return true
    }

    @discardableResult
    public func deleteSelectedItem() -> Bool {
        guard let selectedItemID else {
            return false
        }

        return deleteItem(selectedItemID)
    }

    @discardableResult
    public func deleteItem(_ id: BoardItem.ID) -> Bool {
        let didDelete = updateSelectedBoard { board in
            guard let itemIndex = board.items.firstIndex(where: { $0.id == id }) else {
                return false
            }

            board.items.remove(at: itemIndex)
            board.updatedAt = Date()
            return true
        }

        if didDelete {
            if selectedItemID == id {
                selectedItemID = nil
            }

            scheduleAutosave()
        }

        return didDelete
    }

    @discardableResult
    public func duplicateSelectedItem(constrainedTo canvasSize: BoardSize? = nil) -> BoardItem? {
        guard let selectedItemID else {
            return nil
        }

        return duplicateItem(selectedItemID, constrainedTo: canvasSize)
    }

    @discardableResult
    public func duplicateItem(
        _ id: BoardItem.ID,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> BoardItem? {
        var duplicatedItem: BoardItem?

        let didDuplicate = updateSelectedBoard { board in
            guard let itemIndex = board.items.firstIndex(where: { $0.id == id }) else {
                return false
            }

            var item = board.items[itemIndex]
            item.id = UUID()
            item.frame.origin = Self.clampedOrigin(
                BoardPoint(
                    x: item.frame.origin.x + 24,
                    y: item.frame.origin.y + 24
                ),
                itemSize: item.frame.size,
                canvasSize: canvasSize
            )
            board.items.append(item)
            board.updatedAt = Date()
            duplicatedItem = item
            return true
        }

        if didDuplicate, let duplicatedItem {
            selectedItemID = duplicatedItem.id
            scheduleAutosave()
        }

        return duplicatedItem
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

    @discardableResult
    private func createItem(
        content: BoardItemContent,
        origin: BoardPoint,
        size: BoardSize,
        constrainedTo canvasSize: BoardSize?
    ) -> BoardItem {
        let item = BoardItem(
            frame: BoardRect(
                origin: Self.clampedOrigin(origin, itemSize: size, canvasSize: canvasSize),
                size: size
            ),
            content: content
        )

        updateSelectedBoard { board in
            board.items.append(item)
            board.updatedAt = Date()
            return true
        }
        selectedItemID = item.id
        scheduleAutosave()

        return item
    }

    @discardableResult
    private func updateItemContent(
        _ id: BoardItem.ID,
        makeContent: (BoardItemContent) -> BoardItemContent?
    ) -> Bool {
        let didUpdate = updateSelectedBoard { board in
            guard let itemIndex = board.items.firstIndex(where: { $0.id == id }),
                  let nextContent = makeContent(board.items[itemIndex].content)
            else {
                return false
            }

            board.items[itemIndex].content = nextContent
            board.updatedAt = Date()
            return true
        }

        if didUpdate {
            selectedItemID = id
            scheduleAutosave()
        }

        return didUpdate
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

    private static func clampedOrigin(
        _ origin: BoardPoint,
        itemSize: BoardSize,
        canvasSize: BoardSize?
    ) -> BoardPoint {
        let minimum = 12.0
        let maximumX = canvasSize.map { max(minimum, $0.width - itemSize.width - minimum) }
        let maximumY = canvasSize.map { max(minimum, $0.height - itemSize.height - minimum) }
        let clampedX = min(maximumX ?? .greatestFiniteMagnitude, max(minimum, origin.x))
        let clampedY = min(maximumY ?? .greatestFiniteMagnitude, max(minimum, origin.y))

        return BoardPoint(x: clampedX, y: clampedY)
    }

    private func sanitizedTitle(_ value: String, fallback: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? fallback : trimmedValue
    }
}
