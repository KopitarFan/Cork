import Combine
import Foundation

@MainActor
public final class BoardStore: ObservableObject {
    public enum Defaults {
        public static let newCardOrigin = BoardPoint(x: 48, y: 48)
        public static let textCardSize = BoardSize(width: 260, height: 190)
        public static let checklistCardSize = BoardSize(width: 240, height: 210)
        public static let imageCardSize = BoardSize(width: 230, height: 170)
        public static let urlCardSize = BoardSize(width: 280, height: 150)
        public static let fileCardSize = BoardSize(width: 280, height: 150)
        public static let paletteCardSize = BoardSize(width: 260, height: 176)
        public static let minimumCardSize = BoardSize(width: 160, height: 120)
        public static let maximumCardSize = BoardSize(width: 640, height: 520)
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
        format: TextCardFormat = .plainText,
        at origin: BoardPoint = Defaults.newCardOrigin,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> BoardItem {
        createItem(
            content: .text(TextCard(
                title: sanitizedTitle(title, fallback: "Untitled Note"),
                body: body,
                format: format
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
    public func createURLCard(
        title: String = "",
        url: URL,
        at origin: BoardPoint = Defaults.newCardOrigin,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> BoardItem {
        createItem(
            content: .url(URLCard(
                title: sanitizedURLTitle(title, url: url),
                url: url
            )),
            origin: origin,
            size: Defaults.urlCardSize,
            constrainedTo: canvasSize
        )
    }

    @discardableResult
    public func createFileCard(
        title: String = "",
        url: URL,
        at origin: BoardPoint = Defaults.newCardOrigin,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> BoardItem {
        createItem(
            content: .file(FileCard(
                title: sanitizedFileTitle(title, url: url),
                url: url
            )),
            origin: origin,
            size: Defaults.fileCardSize,
            constrainedTo: canvasSize
        )
    }

    @discardableResult
    public func createColorPaletteCard(
        title: String = "Untitled Palette",
        colors: [PaletteColor] = [],
        at origin: BoardPoint = Defaults.newCardOrigin,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> BoardItem {
        createItem(
            content: .palette(ColorPaletteCard(
                title: sanitizedTitle(title, fallback: "Untitled Palette"),
                colors: sanitizedPaletteColors(colors)
            )),
            origin: origin,
            size: Defaults.paletteCardSize,
            constrainedTo: canvasSize
        )
    }

    @discardableResult
    public func updateTextCard(
        _ id: BoardItem.ID,
        title: String,
        body: String,
        format: TextCardFormat? = nil
    ) -> Bool {
        updateItemContent(id) { content in
            guard case .text(let currentCard) = content else {
                return nil
            }

            let nextCard = TextCard(
                title: sanitizedTitle(title, fallback: "Untitled Note"),
                body: body,
                format: format ?? currentCard.format
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
    public func updateURLCard(
        _ id: BoardItem.ID,
        title: String,
        url: URL
    ) -> Bool {
        updateItemContent(id) { content in
            guard case .url(let currentCard) = content else {
                return nil
            }

            let nextCard = URLCard(
                title: sanitizedURLTitle(title, url: url),
                url: url
            )

            guard currentCard != nextCard else {
                return nil
            }

            return .url(nextCard)
        }
    }

    @discardableResult
    public func updateColorPaletteCard(
        _ id: BoardItem.ID,
        title: String,
        colors: [PaletteColor]
    ) -> Bool {
        updateItemContent(id) { content in
            guard case .palette(let currentCard) = content else {
                return nil
            }

            let nextCard = ColorPaletteCard(
                title: sanitizedTitle(title, fallback: "Untitled Palette"),
                colors: sanitizedPaletteColors(colors)
            )

            guard currentCard != nextCard else {
                return nil
            }

            return .palette(nextCard)
        }
    }

    @discardableResult
    public func createBoard(name: String = "Untitled Board") -> CorkBoard {
        let now = Date()
        let board = CorkBoard(
            name: sanitizedTitle(name, fallback: "Untitled Board"),
            createdAt: now,
            updatedAt: now,
            sortIndex: nextBoardSortIndex()
        )

        boards.append(board)
        normalizeBoardSortIndices()
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
    public func setBoardPinned(id: CorkBoard.ID, isPinned: Bool) -> Bool {
        guard let boardIndex = boards.firstIndex(where: { $0.id == id }),
              boards[boardIndex].isPinned != isPinned
        else {
            return false
        }

        boards[boardIndex].isPinned = isPinned
        boards[boardIndex].updatedAt = Date()
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func toggleBoardPinned(id: CorkBoard.ID) -> Bool {
        guard let board = boards.first(where: { $0.id == id }) else {
            return false
        }

        return setBoardPinned(id: id, isPinned: !board.isPinned)
    }

    @discardableResult
    public func moveBoard(id: CorkBoard.ID, toIndex: Int) -> Bool {
        guard boards.indices.contains(toIndex),
              let currentIndex = boards.firstIndex(where: { $0.id == id }),
              currentIndex != toIndex
        else {
            return false
        }

        let board = boards.remove(at: currentIndex)
        boards.insert(board, at: min(toIndex, boards.count))
        normalizeBoardSortIndices()
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func duplicateBoard(id: CorkBoard.ID) -> CorkBoard? {
        guard let boardIndex = boards.firstIndex(where: { $0.id == id }) else {
            return nil
        }

        let now = Date()
        let sourceBoard = boards[boardIndex]
        let duplicatedItems = sourceBoard.items.map { item in
            var item = item
            item.id = UUID()
            return item
        }
        let duplicatedBoard = CorkBoard(
            name: "\(sourceBoard.name) Copy",
            createdAt: now,
            updatedAt: now,
            isPinned: false,
            sortIndex: boardIndex + 1,
            items: duplicatedItems
        )

        boards.insert(duplicatedBoard, at: boardIndex + 1)
        normalizeBoardSortIndices()
        selectedBoardID = duplicatedBoard.id
        selectedItemID = nil
        scheduleAutosave()

        return boards.first { $0.id == duplicatedBoard.id }
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
        normalizeBoardSortIndices()

        if wasSelectedBoard {
            let fallbackIndex = min(boardIndex, boards.count - 1)
            selectedBoardID = boards[fallbackIndex].id
            selectedItemID = nil
        }

        scheduleAutosave()

        return true
    }

    @discardableResult
    public func importItems(
        _ intents: [BoardImportIntent],
        at origin: BoardPoint,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> [BoardItem] {
        var createdItems: [BoardItem] = []
        var nextOrigin = origin

        for intent in intents {
            let item: BoardItem

            switch intent {
            case .imageFile(let url, let title):
                item = createImageCard(
                    title: title,
                    source: .fileReference(url),
                    at: nextOrigin,
                    constrainedTo: canvasSize
                )
            case .plainText(let title, let body):
                item = createTextCard(
                    title: title,
                    body: body,
                    at: nextOrigin,
                    constrainedTo: canvasSize
                )
            case .webURL(let url, let title):
                item = createURLCard(
                    title: title,
                    url: url,
                    at: nextOrigin,
                    constrainedTo: canvasSize
                )
            case .fileReference(let url, let title):
                item = createFileCard(
                    title: title,
                    url: url,
                    at: nextOrigin,
                    constrainedTo: canvasSize
                )
            }

            createdItems.append(item)
            nextOrigin = BoardPoint(
                x: item.frame.origin.x + 24,
                y: item.frame.origin.y + 24
            )
        }

        return createdItems
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
    public func resizeItem(
        _ id: BoardItem.ID,
        to size: BoardSize,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> Bool {
        let didUpdate = updateSelectedBoard { board in
            guard let itemIndex = board.items.firstIndex(where: { $0.id == id }) else {
                return false
            }

            let currentFrame = board.items[itemIndex].frame
            let nextSize = Self.clampedSize(
                size,
                origin: currentFrame.origin,
                canvasSize: canvasSize
            )
            let nextFrame = BoardRect(
                origin: Self.clampedOrigin(
                    currentFrame.origin,
                    itemSize: nextSize,
                    canvasSize: canvasSize
                ),
                size: nextSize
            )

            guard currentFrame != nextFrame else {
                return false
            }

            board.items[itemIndex].frame = nextFrame
            board.updatedAt = Date()
            return true
        }

        if didUpdate {
            scheduleAutosave()
        }

        return didUpdate
    }

    @discardableResult
    public func resizeSelectedItem(
        to size: BoardSize,
        constrainedTo canvasSize: BoardSize? = nil
    ) -> Bool {
        guard let selectedItemID else {
            return false
        }

        return resizeItem(selectedItemID, to: size, constrainedTo: canvasSize)
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

    private static func clampedSize(
        _ size: BoardSize,
        origin: BoardPoint,
        canvasSize: BoardSize?
    ) -> BoardSize {
        let width = min(
            Defaults.maximumCardSize.width,
            max(Defaults.minimumCardSize.width, size.width)
        )
        let height = min(
            Defaults.maximumCardSize.height,
            max(Defaults.minimumCardSize.height, size.height)
        )

        guard let canvasSize else {
            return BoardSize(width: width, height: height)
        }

        let maximumWidth = max(
            Defaults.minimumCardSize.width,
            canvasSize.width - origin.x - canvasInset
        )
        let maximumHeight = max(
            Defaults.minimumCardSize.height,
            canvasSize.height - origin.y - canvasInset
        )

        return BoardSize(
            width: min(width, maximumWidth),
            height: min(height, maximumHeight)
        )
    }

    private static func clampedOrigin(
        _ origin: BoardPoint,
        itemSize: BoardSize,
        canvasSize: BoardSize?
    ) -> BoardPoint {
        let maximumX = canvasSize.map { max(canvasInset, $0.width - itemSize.width - canvasInset) }
        let maximumY = canvasSize.map { max(canvasInset, $0.height - itemSize.height - canvasInset) }
        let clampedX = min(maximumX ?? .greatestFiniteMagnitude, max(canvasInset, origin.x))
        let clampedY = min(maximumY ?? .greatestFiniteMagnitude, max(canvasInset, origin.y))

        return BoardPoint(x: clampedX, y: clampedY)
    }

    private static let canvasInset = 12.0

    private func sanitizedTitle(_ value: String, fallback: String) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? fallback : trimmedValue
    }

    private func sanitizedURLTitle(_ value: String, url: URL) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedValue.isEmpty {
            return trimmedValue
        }

        if let host = url.host(), !host.isEmpty {
            return host
        }

        return "Link"
    }

    private func sanitizedFileTitle(_ value: String, url: URL) -> String {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmedValue.isEmpty {
            return trimmedValue
        }

        let filename = url.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return filename.isEmpty ? "File" : filename
    }

    private func sanitizedPaletteColors(_ colors: [PaletteColor]) -> [PaletteColor] {
        colors.isEmpty ? Self.defaultPaletteColors : colors
    }

    private func nextBoardSortIndex() -> Int {
        max((boards.map(\.sortIndex).max() ?? -1) + 1, boards.count)
    }

    private func normalizeBoardSortIndices() {
        for index in boards.indices {
            boards[index].sortIndex = index
        }
    }

    private static let defaultPaletteColors = ColorPaletteCard.defaultColors
}
