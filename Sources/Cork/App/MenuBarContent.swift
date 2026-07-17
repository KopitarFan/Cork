import AppKit
import CorkCore
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var boardStore: BoardStore
    @ObservedObject private var settingsStore: SettingsStore

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        self.boardStore = coordinator.boardStore
        self.settingsStore = coordinator.settingsStore
    }

    var body: some View {
        toggleBoardButton

        Divider()

        Menu("New Card") {
            Button {
                createTextCard()
            } label: {
                Label("Text Note", systemImage: "note.text.badge.plus")
            }

            Button {
                createChecklistCard()
            } label: {
                Label("Checklist", systemImage: "checklist")
            }

            Button {
                createImageCard()
            } label: {
                Label("Image", systemImage: "photo.badge.plus")
            }

            Button {
                createColorPaletteCard()
            } label: {
                Label("Color Palette", systemImage: "swatchpalette")
            }
        }

        Menu("Selected Card") {
            selectedCardActions
        }

        Menu("Boards") {
            boardSwitcher

            Divider()

            Button {
                createBoard()
            } label: {
                Label("New Board", systemImage: "plus.rectangle.on.rectangle")
            }

            Menu("New Board From Template") {
                ForEach(BoardTemplate.allCases) { template in
                    Button {
                        createBoard(from: template)
                    } label: {
                        Label(template.title, systemImage: template.systemImageName)
                    }
                }
            }

            Divider()

            Button {
                selectNextBoard()
            } label: {
                Label("Next Board", systemImage: "chevron.right")
            }
            .keyboardShortcut(.tab, modifiers: [.control])
            .disabled(boardStore.boards.count <= 1)

            Button {
                selectPreviousBoard()
            } label: {
                Label("Previous Board", systemImage: "chevron.left")
            }
            .keyboardShortcut(.tab, modifiers: [.control, .shift])
            .disabled(boardStore.boards.count <= 1)

            Divider()

            currentBoardActions
        }

        Divider()

        Button {
            coordinator.showQuickStartGuide()
        } label: {
            Label("Quick Start Guide...", systemImage: "questionmark.circle")
        }

        Button {
            coordinator.showPreferences()
        } label: {
            Label("Preferences...", systemImage: "gearshape")
        }
        .keyboardShortcut(",", modifiers: [.command])

        Divider()

        Button("Quit Cork") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private var toggleBoardButton: some View {
        if let shortcut = HotKeyPresentation.menuShortcut(for: settingsStore.settings.hotKeyConfiguration) {
            rawToggleBoardButton
                .keyboardShortcut(shortcut.key, modifiers: shortcut.modifiers)
        } else {
            rawToggleBoardButton
        }
    }

    private var rawToggleBoardButton: some View {
        Button(coordinator.boardToggleTitle) {
            coordinator.toggleBoard()
        }
    }

    @ViewBuilder
    private var selectedCardActions: some View {
        Button {
            editSelectedItem()
        } label: {
            Label("Edit Selected Card", systemImage: "pencil")
        }
        .disabled(!selectedItemIsEditable)

        Button {
            editSelectedItemAppearance()
        } label: {
            Label("Card Appearance...", systemImage: "paintpalette")
        }
        .disabled(boardStore.selectedItemID == nil)

        Button {
            replaceSelectedImage()
        } label: {
            Label("Replace Image...", systemImage: "photo.on.rectangle.angled")
        }
        .disabled(!selectedItemIsImage)

        Divider()

        selectedCardConnectionActions

        Divider()

        Button {
            duplicateSelectedItem()
        } label: {
            Label("Duplicate Selected Card", systemImage: "plus.square.on.square")
        }
        .disabled(boardStore.selectedItemID == nil)

        Button {
            deleteSelectedItem()
        } label: {
            Label("Delete Selected Card", systemImage: "trash")
        }
        .disabled(boardStore.selectedItemID == nil)
    }

    @ViewBuilder
    private var selectedCardConnectionActions: some View {
        if boardStore.connectionSourceItemID == nil {
            Button {
                beginConnectionFromSelectedItem()
            } label: {
                Label("Start Connection Here", systemImage: "point.topleft.down.to.point.bottomright.curvepath")
            }
            .disabled(boardStore.selectedItemID == nil)
        } else {
            if canConnectToSelectedItem {
                Button {
                    connectToSelectedItem(style: .string)
                } label: {
                    Label("Connect with String", systemImage: "scribble.variable")
                }

                Button {
                    connectToSelectedItem(style: .line)
                } label: {
                    Label("Connect with Line", systemImage: "line.diagonal")
                }
            }

            Button {
                boardStore.cancelConnection()
            } label: {
                Label("Cancel Connection", systemImage: "xmark")
            }
        }

        Button {
            removeSelectedItemConnections()
        } label: {
            Label("Remove Card Connections", systemImage: "link.badge.minus")
        }
        .disabled(!selectedItemHasConnections)
    }

    @ViewBuilder
    private var currentBoardActions: some View {
        Button {
            toggleSelectedBoardPinned()
        } label: {
            Label(
                boardStore.selectedBoard.isPinned ? "Unpin Current Board" : "Pin Current Board",
                systemImage: boardStore.selectedBoard.isPinned ? "pin.slash" : "pin"
            )
        }

        Button {
            duplicateSelectedBoard()
        } label: {
            Label("Duplicate Current Board", systemImage: "rectangle.on.rectangle")
        }

        Button {
            moveSelectedBoardUp()
        } label: {
            Label("Move Current Board Up", systemImage: "arrow.up")
        }
        .disabled(selectedBoardIndex == nil || selectedBoardIndex == 0)

        Button {
            moveSelectedBoardDown()
        } label: {
            Label("Move Current Board Down", systemImage: "arrow.down")
        }
        .disabled(selectedBoardIndex == nil || selectedBoardIndex == boardStore.boards.count - 1)

        Divider()

        Button {
            renameSelectedBoard()
        } label: {
            Label("Rename Current Board", systemImage: "pencil")
        }

        Button {
            deleteSelectedBoard()
        } label: {
            Label("Delete Current Board", systemImage: "trash")
        }
        .disabled(boardStore.boards.count <= 1)
    }

    @ViewBuilder
    private var boardSwitcher: some View {
        ForEach(pinnedBoards) { board in
            boardSelectionButton(for: board)
        }

        if !pinnedBoards.isEmpty && !unpinnedBoards.isEmpty {
            Divider()
        }

        ForEach(unpinnedBoards) { board in
            boardSelectionButton(for: board)
        }
    }

    private func boardSelectionButton(for board: CorkBoard) -> some View {
        Button {
            boardStore.selectBoard(board.id)
            coordinator.showBoard()
        } label: {
            if board.id == boardStore.selectedBoardID {
                Label(board.name, systemImage: "checkmark")
            } else if board.isPinned {
                Label(board.name, systemImage: "pin.fill")
            } else {
                Text(board.name)
            }
        }
    }

    private var pinnedBoards: [CorkBoard] {
        boardStore.boards.filter(\.isPinned)
    }

    private var unpinnedBoards: [CorkBoard] {
        boardStore.boards.filter { !$0.isPinned }
    }

    private var selectedBoardIndex: Int? {
        boardStore.boards.firstIndex { $0.id == boardStore.selectedBoardID }
    }

    private var selectedItemIsEditable: Bool {
        guard let selectedItem = boardStore.selectedItem else {
            return false
        }

        if case .file = selectedItem.content {
            return false
        }

        return true
    }

    private var selectedItemIsImage: Bool {
        guard let selectedItem = boardStore.selectedItem,
              case .image = selectedItem.content
        else {
            return false
        }

        return true
    }

    private var canConnectToSelectedItem: Bool {
        guard let sourceItemID = boardStore.connectionSourceItemID,
              let selectedItemID = boardStore.selectedItemID
        else {
            return false
        }

        return sourceItemID != selectedItemID
    }

    private var selectedItemHasConnections: Bool {
        guard let selectedItemID = boardStore.selectedItemID else {
            return false
        }

        return boardStore.selectedBoard.connections.contains { $0.includes(selectedItemID) }
    }

    private func toggleSelectedBoardPinned() {
        boardStore.toggleBoardPinned(id: boardStore.selectedBoardID)
    }

    private func selectNextBoard() {
        if boardStore.selectNextBoard() {
            coordinator.showBoard()
        }
    }

    private func selectPreviousBoard() {
        if boardStore.selectPreviousBoard() {
            coordinator.showBoard()
        }
    }

    private func duplicateSelectedBoard() {
        boardStore.duplicateBoard(id: boardStore.selectedBoardID)
        coordinator.showBoard()
    }

    private func moveSelectedBoardUp() {
        guard let selectedBoardIndex,
              selectedBoardIndex > 0
        else {
            return
        }

        boardStore.moveBoard(id: boardStore.selectedBoardID, toIndex: selectedBoardIndex - 1)
    }

    private func moveSelectedBoardDown() {
        guard let selectedBoardIndex,
              selectedBoardIndex < boardStore.boards.count - 1
        else {
            return
        }

        boardStore.moveBoard(id: boardStore.selectedBoardID, toIndex: selectedBoardIndex + 1)
    }

    private func createTextCard() {
        let draft = TextCard(title: "Untitled Note", body: "")

        guard let card = CorkDialogs.promptForTextCard(
            title: "New Text Note",
            card: draft
        ) else {
            return
        }

        boardStore.createTextCard(title: card.title, body: card.body, format: card.format)
        coordinator.showBoard()
    }

    private func createChecklistCard() {
        let draft = ChecklistCard(title: "Untitled Checklist", entries: [])

        guard let card = CorkDialogs.promptForChecklistCard(
            title: "New Checklist",
            card: draft
        ) else {
            return
        }

        boardStore.createChecklistCard(title: card.title, entries: card.entries)
        coordinator.showBoard()
    }

    private func createImageCard() {
        guard let imageURL = CorkDialogs.chooseImageFile() else {
            return
        }

        boardStore.createImageCard(
            title: CorkDialogs.defaultImageTitle(for: imageURL),
            source: .fileReference(imageURL),
            securityScopedBookmark: SecurityScopedBookmark.create(for: imageURL)
        )
        coordinator.showBoard()
    }

    private func createColorPaletteCard() {
        let draft = ColorPaletteCard(
            title: "Untitled Palette",
            colors: ColorPaletteCard.defaultColors
        )

        guard let card = CorkDialogs.promptForColorPaletteCard(
            title: "New Color Palette",
            card: draft
        ) else {
            return
        }

        boardStore.createColorPaletteCard(title: card.title, colors: card.colors)
        coordinator.showBoard()
    }

    private func editSelectedItem() {
        guard let selectedItem = boardStore.selectedItem,
              selectedItemIsEditable
        else {
            return
        }

        if editItem(selectedItem) {
            coordinator.showBoard()
        }
    }

    private func editSelectedItemAppearance() {
        guard let selectedItem = boardStore.selectedItem,
              let appearance = CorkDialogs.promptForCardAppearance(
                title: "Card Appearance",
                appearance: selectedItem.appearance
              )
        else {
            return
        }

        if boardStore.updateItemAppearance(selectedItem.id, appearance: appearance) {
            coordinator.showBoard()
        }
    }

    private func replaceSelectedImage() {
        guard let selectedItem = boardStore.selectedItem,
              case .image(let card) = selectedItem.content,
              let imageURL = CorkDialogs.chooseImageFile()
        else {
            return
        }

        if boardStore.updateImageCard(
            selectedItem.id,
            title: card.title,
            source: .fileReference(imageURL),
            securityScopedBookmark: SecurityScopedBookmark.create(for: imageURL)
        ) {
            coordinator.showBoard()
        }
    }

    private func beginConnectionFromSelectedItem() {
        guard let selectedItemID = boardStore.selectedItemID else {
            return
        }

        if boardStore.beginConnection(from: selectedItemID) {
            coordinator.showBoard()
        }
    }

    private func connectToSelectedItem(style: BoardConnectionStyle) {
        guard let selectedItemID = boardStore.selectedItemID else {
            return
        }

        if boardStore.connectConnectionSource(to: selectedItemID, style: style) {
            coordinator.showBoard()
        }
    }

    private func removeSelectedItemConnections() {
        guard let selectedItemID = boardStore.selectedItemID else {
            return
        }

        if boardStore.removeConnections(for: selectedItemID) {
            coordinator.showBoard()
        }
    }

    private func editItem(_ item: BoardItem) -> Bool {
        switch item.content {
        case .text(let card):
            guard let editedCard = CorkDialogs.promptForTextCard(
                title: "Edit Text Note",
                card: card
            ) else {
                return false
            }

            return boardStore.updateTextCard(
                item.id,
                title: editedCard.title,
                body: editedCard.body,
                format: editedCard.format
            )

        case .checklist(let card):
            guard let editedCard = CorkDialogs.promptForChecklistCard(
                title: "Edit Checklist",
                card: card
            ) else {
                return false
            }

            return boardStore.updateChecklistCard(
                item.id,
                title: editedCard.title,
                entries: editedCard.entries
            )

        case .image(let card):
            guard let editedCard = CorkDialogs.promptForImageTitle(
                title: "Edit Image Card",
                card: card
            ) else {
                return false
            }

            return boardStore.updateImageCard(
                item.id,
                title: editedCard.title,
                source: editedCard.source
            )

        case .url(let card):
            guard let editedCard = CorkDialogs.promptForURLCard(
                title: "Edit Link",
                card: card
            ) else {
                return false
            }

            return boardStore.updateURLCard(
                item.id,
                title: editedCard.title,
                url: editedCard.url
            )

        case .file:
            return false

        case .palette(let card):
            guard let editedCard = CorkDialogs.promptForColorPaletteCard(
                title: "Edit Color Palette",
                card: card
            ) else {
                return false
            }

            return boardStore.updateColorPaletteCard(
                item.id,
                title: editedCard.title,
                colors: editedCard.colors
            )
        }
    }

    private func duplicateSelectedItem() {
        boardStore.duplicateSelectedItem()
        coordinator.showBoard()
    }

    private func deleteSelectedItem() {
        boardStore.deleteSelectedItem()
        coordinator.showBoard()
    }

    private func createBoard() {
        guard let name = CorkDialogs.promptForBoardName(
            title: "New Board",
            message: "",
            defaultName: "Untitled Board"
        ) else {
            return
        }

        boardStore.createBoard(name: name)
        coordinator.showBoard()
    }

    private func createBoard(from template: BoardTemplate) {
        guard let name = CorkDialogs.promptForBoardName(
            title: "New \(template.title) Board",
            message: template.summary,
            defaultName: template.title
        ) else {
            return
        }

        boardStore.createBoard(name: name, template: template)
        coordinator.showBoard()
    }

    private func renameSelectedBoard() {
        guard let name = CorkDialogs.promptForBoardName(
            title: "Rename Board",
            message: "",
            defaultName: boardStore.selectedBoard.name
        ) else {
            return
        }

        boardStore.renameBoard(id: boardStore.selectedBoardID, name: name)
    }

    private func deleteSelectedBoard() {
        guard boardStore.boards.count > 1,
              CorkDialogs.confirmBoardDeletion(boardName: boardStore.selectedBoard.name)
        else {
            return
        }

        boardStore.deleteBoard(id: boardStore.selectedBoardID)
        coordinator.showBoard()
    }
}
