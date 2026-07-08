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
            Button {
                createBoard()
            } label: {
                Label("New Board", systemImage: "plus.rectangle.on.rectangle")
            }

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

        Divider()

        ForEach(boardStore.boards) { board in
            Button {
                boardStore.selectBoard(board.id)
                coordinator.showBoard()
            } label: {
                if board.id == boardStore.selectedBoardID {
                    Label(board.name, systemImage: "checkmark")
                } else {
                    Text(board.name)
                }
            }
        }

        Divider()

        Button("Quit Cork") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q")
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
