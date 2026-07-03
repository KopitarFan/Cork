import CorkCore
import AppKit
import SwiftUI

struct BoardView: View {
    @ObservedObject var boardStore: BoardStore
    @State private var canvasSize = BoardSize(width: 900, height: 520)

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .opacity(0.45)

            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    BoardCanvasBackground()
                        .zIndex(0)

                    ForEach(boardStore.selectedBoard.items) { item in
                        BoardCardView(
                            item: item,
                            isSelected: item.id == boardStore.selectedItemID
                        )
                    }

                    BoardMouseInputView(
                        items: boardStore.selectedBoard.items,
                        selectedItemID: boardStore.selectedItemID,
                        boardSize: boardSize(from: proxy.size),
                        onSelect: { itemID in
                            boardStore.selectItem(itemID)
                        },
                        onClearSelection: {
                            boardStore.clearSelection()
                        },
                        onEdit: { itemID in
                            editItem(itemID)
                        },
                        onMove: { itemID, origin in
                            boardStore.updateItemPosition(
                                itemID,
                                to: origin,
                                constrainedTo: boardSize(from: proxy.size)
                            )
                        },
                        onDuplicate: { itemID in
                            boardStore.duplicateItem(
                                itemID,
                                constrainedTo: boardSize(from: proxy.size)
                            )
                        },
                        onDelete: { itemID in
                            boardStore.deleteItem(itemID)
                        },
                        onImport: { intents, origin in
                            boardStore.importItems(
                                intents,
                                at: origin,
                                constrainedTo: boardSize(from: proxy.size)
                            )
                        }
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .zIndex(3)

                    BoardKeyboardView { event in
                        handleKeyDown(event, boardSize: boardSize(from: proxy.size))
                    }
                    .frame(width: 0, height: 0)
                    .zIndex(4)
                }
                .clipped()
                .onAppear {
                    canvasSize = boardSize(from: proxy.size)
                }
                .onChange(of: proxy.size) { _, size in
                    canvasSize = boardSize(from: size)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.24), radius: 22, x: 0, y: 18)
        .padding(1)
    }

    private func createTextCard() {
        let draft = TextCard(title: "Untitled Note", body: "")

        guard let card = CorkDialogs.promptForTextCard(
            title: "New Text Note",
            card: draft
        ) else {
            return
        }

        boardStore.createTextCard(
            title: card.title,
            body: card.body,
            at: originForNewCard(size: BoardStore.Defaults.textCardSize),
            constrainedTo: canvasSize
        )
    }

    private func createChecklistCard() {
        let draft = ChecklistCard(title: "Untitled Checklist", entries: [])

        guard let card = CorkDialogs.promptForChecklistCard(
            title: "New Checklist",
            card: draft
        ) else {
            return
        }

        boardStore.createChecklistCard(
            title: card.title,
            entries: card.entries,
            at: originForNewCard(size: BoardStore.Defaults.checklistCardSize),
            constrainedTo: canvasSize
        )
    }

    private func createImageCard() {
        guard let imageURL = CorkDialogs.chooseImageFile() else {
            return
        }

        boardStore.createImageCard(
            title: CorkDialogs.defaultImageTitle(for: imageURL),
            source: .fileReference(imageURL),
            at: originForNewCard(size: BoardStore.Defaults.imageCardSize),
            constrainedTo: canvasSize
        )
    }

    private func editSelectedItem() {
        guard let selectedItem = boardStore.selectedItem else {
            return
        }

        editItem(selectedItem.id)
    }

    private func editItem(_ itemID: BoardItem.ID) {
        guard let item = boardStore.selectedBoard.items.first(where: { $0.id == itemID }) else {
            return
        }

        switch item.content {
        case .text(let card):
            guard let editedCard = CorkDialogs.promptForTextCard(
                title: "Edit Text Note",
                card: card
            ) else {
                return
            }

            boardStore.updateTextCard(
                item.id,
                title: editedCard.title,
                body: editedCard.body
            )

        case .checklist(let card):
            guard let editedCard = CorkDialogs.promptForChecklistCard(
                title: "Edit Checklist",
                card: card
            ) else {
                return
            }

            boardStore.updateChecklistCard(
                item.id,
                title: editedCard.title,
                entries: editedCard.entries
            )

        case .image(let card):
            guard let editedCard = CorkDialogs.promptForImageTitle(
                title: "Edit Image Card",
                card: card
            ) else {
                return
            }

            boardStore.updateImageCard(
                item.id,
                title: editedCard.title,
                source: editedCard.source
            )
        }
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
    }

    private func handleKeyDown(_ event: NSEvent, boardSize: BoardSize) -> Bool {
        if event.modifierFlags.contains(.command),
           event.charactersIgnoringModifiers?.lowercased() == "d" {
            return boardStore.duplicateSelectedItem(constrainedTo: boardSize) != nil
        }

        switch Int(event.keyCode) {
        case 51, 117:
            return boardStore.deleteSelectedItem()
        case 123:
            return moveSelectedItem(x: -keyboardMoveAmount(for: event), y: 0, boardSize: boardSize)
        case 124:
            return moveSelectedItem(x: keyboardMoveAmount(for: event), y: 0, boardSize: boardSize)
        case 125:
            return moveSelectedItem(x: 0, y: keyboardMoveAmount(for: event), boardSize: boardSize)
        case 126:
            return moveSelectedItem(x: 0, y: -keyboardMoveAmount(for: event), boardSize: boardSize)
        default:
            return false
        }
    }

    private func moveSelectedItem(x: Double, y: Double, boardSize: BoardSize) -> Bool {
        boardStore.moveSelectedItem(
            by: BoardPoint(x: x, y: y),
            constrainedTo: boardSize
        )
    }

    private func keyboardMoveAmount(for event: NSEvent) -> Double {
        event.modifierFlags.contains(.shift) ? 24 : 8
    }

    private func boardSize(from size: CGSize) -> BoardSize {
        BoardSize(width: size.width, height: size.height)
    }

    private func originForNewCard(size: BoardSize) -> BoardPoint {
        let offset = Double(boardStore.selectedBoard.items.count % 5) * 24

        return BoardPoint(
            x: max(12, ((canvasSize.width - size.width) / 2) + offset),
            y: max(12, ((canvasSize.height - size.height) / 2) + offset)
        )
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(boardStore.selectedBoard.name)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.semibold)

            Spacer()

            Text("\(boardStore.selectedBoard.items.count)")
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())

            cardCreationMenu

            Button {
                editSelectedItem()
            } label: {
                Image(systemName: "pencil")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .disabled(boardStore.selectedItem == nil)
            .help("Edit Selected Card")

            boardActionsMenu
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var cardCreationMenu: some View {
        Menu {
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
        } label: {
            Image(systemName: "plus")
                .frame(width: 24, height: 24)
        }
        .menuStyle(.borderlessButton)
        .help("Add Card")
    }

    private var boardActionsMenu: some View {
        Menu {
            Button {
                createBoard()
            } label: {
                Label("New Board", systemImage: "plus.rectangle.on.rectangle")
            }

            Button {
                renameSelectedBoard()
            } label: {
                Label("Rename Board", systemImage: "pencil")
            }

            Divider()

            Button {
                deleteSelectedBoard()
            } label: {
                Label("Delete Board", systemImage: "trash")
            }
            .disabled(boardStore.boards.count <= 1)
        } label: {
            Image(systemName: "ellipsis.circle")
                .frame(width: 24, height: 24)
        }
        .menuStyle(.borderlessButton)
        .help("Board Actions")
    }
}

private struct BoardCanvasBackground: View {
    var body: some View {
        Canvas { context, size in
            let spacing = CGFloat(28)
            let color = Color.primary.opacity(0.055)

            for x in stride(from: CGFloat(0), through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(color), lineWidth: 0.5)
            }

            for y in stride(from: CGFloat(0), through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(color), lineWidth: 0.5)
            }
        }
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor).opacity(0.74),
                    Color(nsColor: .controlBackgroundColor).opacity(0.58)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
