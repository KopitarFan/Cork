import AppKit
import CorkCore
import SwiftUI

struct MenuBarContent: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var boardStore: BoardStore

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        self.boardStore = coordinator.boardStore
    }

    var body: some View {
        Button(coordinator.isBoardVisible ? "Hide Cork" : "Show Cork") {
            coordinator.toggleBoard()
        }
        .keyboardShortcut("b", modifiers: [.command, .option])

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

        Menu("Boards") {
            boardSwitcher

            Divider()

            Button {
                createBoard()
            } label: {
                Label("New Board", systemImage: "plus.rectangle.on.rectangle")
            }

            Divider()

            currentBoardActions
        }

        Divider()

        Button("Quit Cork") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
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

    private func toggleSelectedBoardPinned() {
        boardStore.toggleBoardPinned(id: boardStore.selectedBoardID)
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
            source: .fileReference(imageURL)
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
