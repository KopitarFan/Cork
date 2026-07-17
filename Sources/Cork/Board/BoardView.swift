import CorkCore
import AppKit
import SwiftUI

struct BoardView: View {
    @ObservedObject var boardStore: BoardStore
    @ObservedObject var settingsStore: SettingsStore
    let onShowPreferences: () -> Void
    let onShowQuickStart: () -> Void

    @State private var canvasSize = BoardSize(width: 900, height: 520)
    @State private var hoveredItemID: BoardItem.ID?
    @State private var connectionToolStyle: BoardConnectionStyle?
    @State private var connectionPreview: BoardConnectionPreview?

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()
                .opacity(0.45)

            GeometryReader { proxy in
                ZStack(alignment: .topLeading) {
                    BoardCanvasBackground(
                        theme: settingsStore.settings.boardTheme,
                        customColors: activeCustomBoardColors,
                        opacity: settingsStore.settings.boardOpacity
                    )
                        .zIndex(0)

                    BoardConnectionsView(
                        items: boardStore.selectedBoard.items,
                        connections: boardStore.selectedBoard.connections,
                        preview: connectionPreview
                    )
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .opacity(settingsStore.settings.cardOpacity)
                    .zIndex(0.5)

                    ForEach(boardStore.selectedBoard.items) { item in
                        BoardCardView(
                            item: item,
                            isSelected: item.id == boardStore.selectedItemID,
                            isHovered: item.id == hoveredItemID,
                            isConnectionSource: item.id == boardStore.connectionSourceItemID
                        )
                        .opacity(settingsStore.settings.cardOpacity)
                        .zIndex(1)
                    }

                    if let hoveredItem {
                        BoardCardNameTooltip(title: displayName(for: hoveredItem))
                            .position(cardNameTooltipPosition(for: hoveredItem, in: proxy.size))
                            .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            .zIndex(2)
                    }

                    BoardMouseInputView(
                        items: boardStore.selectedBoard.items,
                        selectedItemID: boardStore.selectedItemID,
                        boardSize: boardSize(from: proxy.size),
                        connectionToolStyle: connectionToolStyle,
                        onSelect: { itemID in
                            boardStore.selectItem(itemID)
                        },
                        onClearSelection: {
                            boardStore.clearSelection()
                        },
                        onHoverChange: { itemID in
                            hoveredItemID = itemID
                        },
                        onEdit: { itemID in
                            editItem(itemID)
                        },
                        onImageDoubleClick: { itemID in
                            handleImageDoubleClick(itemID)
                        },
                        onEditAppearance: { itemID in
                            editItemAppearance(itemID)
                        },
                        onReplaceImage: { itemID in
                            replaceImage(itemID)
                        },
                        onMove: { itemID, origin in
                            boardStore.updateItemPosition(
                                itemID,
                                to: origin,
                                constrainedTo: boardSize(from: proxy.size)
                            )
                        },
                        onResize: { itemID, size in
                            boardStore.resizeItem(
                                itemID,
                                to: size,
                                constrainedTo: boardSize(from: proxy.size)
                            )
                        },
                        onOpenURL: { itemID in
                            openURLCard(itemID)
                        },
                        onOpenFile: { itemID in
                            openFileCard(itemID)
                        },
                        onRevealFile: { itemID in
                            revealFileCard(itemID)
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
                        onImport: { intents, securityScopedBookmarks, origin in
                            boardStore.importItems(
                                intents,
                                at: origin,
                                constrainedTo: boardSize(from: proxy.size),
                                securityScopedBookmarks: securityScopedBookmarks
                            )
                        },
                        onConnectionDragStart: { itemID, point in
                            startConnectionDrag(from: itemID, at: point)
                        },
                        onConnectionDragChange: { point in
                            connectionPreview?.targetPoint = point
                        },
                        onConnectionDragEnd: { targetItemID in
                            finishConnectionDrag(at: targetItemID)
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
                .animation(.easeOut(duration: 0.12), value: hoveredItemID)
                .clipped()
                .onAppear {
                    canvasSize = boardSize(from: proxy.size)
                }
                .onChange(of: proxy.size) { _, size in
                    canvasSize = boardSize(from: size)
                }
                .onChange(of: boardStore.selectedBoardID) {
                    connectionPreview = nil
                }
            }
        }
        .background {
            BoardChromeBackground(
                theme: settingsStore.settings.boardTheme,
                customColors: activeCustomBoardColors,
                opacity: settingsStore.settings.boardOpacity
            )
        }
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
            format: card.format,
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
            securityScopedBookmark: SecurityScopedBookmark.create(for: imageURL),
            at: originForNewCard(size: BoardStore.Defaults.imageCardSize),
            constrainedTo: canvasSize
        )
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

        boardStore.createColorPaletteCard(
            title: card.title,
            colors: card.colors,
            at: originForNewCard(size: BoardStore.Defaults.paletteCardSize),
            constrainedTo: canvasSize
        )
    }

    private func editSelectedItem() {
        guard let selectedItem = boardStore.selectedItem else {
            return
        }

        guard selectedItem.isEditable else {
            return
        }

        editItem(selectedItem.id)
    }

    private func editSelectedItemAppearance() {
        guard let selectedItemID = boardStore.selectedItemID else {
            return
        }

        editItemAppearance(selectedItemID)
    }

    private func editItemAppearance(_ itemID: BoardItem.ID) {
        guard let item = boardStore.selectedBoard.items.first(where: { $0.id == itemID }),
              let appearance = CorkDialogs.promptForCardAppearance(
                title: "Card Appearance",
                appearance: item.appearance
              )
        else {
            return
        }

        boardStore.updateItemAppearance(item.id, appearance: appearance)
    }

    private func replaceSelectedImage() {
        guard let selectedItemID = boardStore.selectedItemID else {
            return
        }

        replaceImage(selectedItemID)
    }

    private func replaceImage(_ itemID: BoardItem.ID) {
        guard let item = boardStore.selectedBoard.items.first(where: { $0.id == itemID }),
              case .image(let card) = item.content,
              let imageURL = CorkDialogs.chooseImageFile()
        else {
            return
        }

        boardStore.updateImageCard(
            item.id,
            title: card.title,
            source: .fileReference(imageURL),
            securityScopedBookmark: SecurityScopedBookmark.create(for: imageURL)
        )
    }

    private func handleImageDoubleClick(_ itemID: BoardItem.ID) {
        guard let item = boardStore.selectedBoard.items.first(where: { $0.id == itemID }),
              case .image(let card) = item.content,
              let action = CorkDialogs.promptForImageCardDoubleClickAction(cardTitle: card.title)
        else {
            return
        }

        switch action {
        case .rename:
            editItem(itemID)
        case .replaceImage:
            replaceImage(itemID)
        }
    }

    private func beginConnectionFromSelectedItem() {
        guard let selectedItemID = boardStore.selectedItemID else {
            return
        }

        boardStore.beginConnection(from: selectedItemID)
    }

    private func connectToSelectedItem(style: BoardConnectionStyle) {
        guard let selectedItemID = boardStore.selectedItemID else {
            return
        }

        boardStore.connectConnectionSource(to: selectedItemID, style: style)
    }

    private func removeSelectedItemConnections() {
        guard let selectedItemID = boardStore.selectedItemID else {
            return
        }

        boardStore.removeConnections(for: selectedItemID)
    }

    private func toggleStringTool() {
        if connectionToolStyle == .string {
            cancelConnectionWorkflow()
        } else {
            boardStore.cancelConnection()
            connectionPreview = nil
            connectionToolStyle = .string
        }
    }

    private func startConnectionDrag(from itemID: BoardItem.ID, at point: BoardPoint) {
        guard let connectionToolStyle,
              boardStore.beginConnection(from: itemID)
        else {
            return
        }

        connectionPreview = BoardConnectionPreview(
            id: UUID(),
            sourceItemID: itemID,
            style: connectionToolStyle,
            targetPoint: point
        )
    }

    private func finishConnectionDrag(at targetItemID: BoardItem.ID?) {
        guard let connectionPreview else {
            boardStore.cancelConnection()
            return
        }

        if let targetItemID {
            boardStore.connectConnectionSource(
                to: targetItemID,
                style: connectionPreview.style
            )
        } else {
            boardStore.cancelConnection()
        }

        self.connectionPreview = nil
    }

    private func cancelConnectionWorkflow() {
        connectionPreview = nil
        connectionToolStyle = nil
        boardStore.cancelConnection()
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
                body: editedCard.body,
                format: editedCard.format
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

        case .url(let card):
            guard let editedCard = CorkDialogs.promptForURLCard(
                title: "Edit Link",
                card: card
            ) else {
                return
            }

            boardStore.updateURLCard(
                item.id,
                title: editedCard.title,
                url: editedCard.url
            )

        case .file:
            return

        case .palette(let card):
            guard let editedCard = CorkDialogs.promptForColorPaletteCard(
                title: "Edit Color Palette",
                card: card
            ) else {
                return
            }

            boardStore.updateColorPaletteCard(
                item.id,
                title: editedCard.title,
                colors: editedCard.colors
            )
        }
    }

    private func openURLCard(_ itemID: BoardItem.ID) {
        guard let item = boardStore.selectedBoard.items.first(where: { $0.id == itemID }),
              case .url(let card) = item.content
        else {
            return
        }

        NSWorkspace.shared.open(card.url)
    }

    private func openFileCard(_ itemID: BoardItem.ID) {
        guard let item = boardStore.selectedBoard.items.first(where: { $0.id == itemID }),
              case .file(let card) = item.content
        else {
            return
        }

        _ = SecurityScopedBookmark.withAccess(
            to: card.securityScopedBookmark,
            fallbackURL: card.url
        ) { url in
            NSWorkspace.shared.open(url)
        }
    }

    private func revealFileCard(_ itemID: BoardItem.ID) {
        guard let item = boardStore.selectedBoard.items.first(where: { $0.id == itemID }),
              case .file(let card) = item.content
        else {
            return
        }

        SecurityScopedBookmark.withAccess(
            to: card.securityScopedBookmark,
            fallbackURL: card.url
        ) { url in
            NSWorkspace.shared.activateFileViewerSelecting([url])
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

    private func createBoard(from template: BoardTemplate) {
        guard let name = CorkDialogs.promptForBoardName(
            title: "New \(template.title) Board",
            message: template.summary,
            defaultName: template.title
        ) else {
            return
        }

        boardStore.createBoard(name: name, template: template)
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

    private func toggleSelectedBoardPinned() {
        boardStore.toggleBoardPinned(id: boardStore.selectedBoardID)
    }

    private func duplicateSelectedBoard() {
        boardStore.duplicateBoard(id: boardStore.selectedBoardID)
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

    private func deleteSelectedBoard() {
        guard boardStore.boards.count > 1,
              CorkDialogs.confirmBoardDeletion(boardName: boardStore.selectedBoard.name)
        else {
            return
        }

        boardStore.deleteBoard(id: boardStore.selectedBoardID)
    }

    private func handleKeyDown(_ event: NSEvent, boardSize: BoardSize) -> Bool {
        if event.keyCode == 53,
           connectionToolStyle != nil || boardStore.connectionSourceItemID != nil {
            cancelConnectionWorkflow()
            return true
        }

        if event.keyCode == 48,
           event.modifierFlags.contains(.control) {
            return event.modifierFlags.contains(.shift)
                ? boardStore.selectPreviousBoard()
                : boardStore.selectNextBoard()
        }

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

    private var selectedBoardIndex: Int? {
        boardStore.boards.firstIndex { $0.id == boardStore.selectedBoardID }
    }

    private var cardCountText: String {
        let count = boardStore.selectedBoard.items.count
        return count == 1 ? "1 card" : "\(count) cards"
    }

    private var hoveredItem: BoardItem? {
        guard let hoveredItemID else {
            return nil
        }

        return boardStore.selectedBoard.items.first { $0.id == hoveredItemID }
    }

    private func displayName(for item: BoardItem) -> String {
        let title = item.content.displayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? "Untitled Card" : title
    }

    private func cardNameTooltipPosition(for item: BoardItem, in size: CGSize) -> CGPoint {
        let horizontalInset = min(112, max(36, size.width / 2))
        let cardCenterX = CGFloat(item.frame.origin.x + (item.frame.size.width / 2))
        let x = min(max(cardCenterX, horizontalInset), size.width - horizontalInset)
        let aboveY = CGFloat(item.frame.origin.y) - 18
        let belowY = CGFloat(item.frame.origin.y + item.frame.size.height) + 18
        let y = aboveY >= 16 ? aboveY : min(size.height - 16, belowY)

        return CGPoint(x: x, y: y)
    }

    private var activeCustomBoardColors: BoardSurfaceColors? {
        settingsStore.settings.customBoardColorsEnabled ? settingsStore.settings.customBoardColors : nil
    }

    private var header: some View {
        HStack(spacing: 12) {
            boardSwitcherMenu

            Spacer(minLength: 12)

            boardStatus

            HStack(spacing: 6) {
                cardCreationMenu

                stringToolButton

                selectedCardActionsMenu

                boardActionsMenu

                settingsMenu
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private var boardSwitcherMenu: some View {
        Menu {
            boardSwitcherItems
        } label: {
            HStack(spacing: 8) {
                Image(systemName: boardStore.selectedBoard.isPinned ? "pin.fill" : "rectangle.stack")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)

                Text(boardStore.selectedBoard.name)
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: 260, alignment: .leading)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .help("Switch Board")
    }

    @ViewBuilder
    private var boardSwitcherItems: some View {
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

            Button {
                createColorPaletteCard()
            } label: {
                Label("Color Palette", systemImage: "swatchpalette")
            }
        } label: {
            HeaderControlLabel(title: "Add", systemImage: "plus")
        }
        .menuStyle(.borderlessButton)
        .help("Add Card")
    }

    private var selectedCardActionsMenu: some View {
        Menu {
            Button {
                editSelectedItem()
            } label: {
                Label("Edit Selected Card", systemImage: "pencil")
            }
            .disabled(boardStore.selectedItem?.isEditable != true)

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
        } label: {
            HeaderControlLabel(title: "Card", systemImage: "rectangle.on.rectangle.angled")
        }
        .menuStyle(.borderlessButton)
        .help("Selected Card Actions")
    }

    private var stringToolButton: some View {
        Button {
            toggleStringTool()
        } label: {
            HeaderControlLabel(
                title: "String",
                systemImage: "scribble.variable",
                isActive: connectionToolStyle == .string
            )
        }
        .buttonStyle(.borderless)
        .help(connectionToolStyle == .string ? "Stop Drawing Strings" : "Draw String Connections")
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
                cancelConnectionWorkflow()
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

    private var boardActionsMenu: some View {
        Menu {
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
                boardStore.selectNextBoard()
            } label: {
                Label("Next Board", systemImage: "chevron.right")
            }
            .keyboardShortcut(.tab, modifiers: [.control])
            .disabled(boardStore.boards.count <= 1)

            Button {
                boardStore.selectPreviousBoard()
            } label: {
                Label("Previous Board", systemImage: "chevron.left")
            }
            .keyboardShortcut(.tab, modifiers: [.control, .shift])
            .disabled(boardStore.boards.count <= 1)

            Divider()

            Button {
                renameSelectedBoard()
            } label: {
                Label("Rename Board", systemImage: "pencil")
            }

            Button {
                toggleSelectedBoardPinned()
            } label: {
                Label(
                    boardStore.selectedBoard.isPinned ? "Unpin Board" : "Pin Board",
                    systemImage: boardStore.selectedBoard.isPinned ? "pin.slash" : "pin"
                )
            }

            Button {
                duplicateSelectedBoard()
            } label: {
                Label("Duplicate Board", systemImage: "rectangle.on.rectangle")
            }

            Button {
                moveSelectedBoardUp()
            } label: {
                Label("Move Board Up", systemImage: "arrow.up")
            }
            .disabled(selectedBoardIndex == nil || selectedBoardIndex == 0)

            Button {
                moveSelectedBoardDown()
            } label: {
                Label("Move Board Down", systemImage: "arrow.down")
            }
            .disabled(selectedBoardIndex == nil || selectedBoardIndex == boardStore.boards.count - 1)

            Divider()

            Button {
                deleteSelectedBoard()
            } label: {
                Label("Delete Board", systemImage: "trash")
            }
            .disabled(boardStore.boards.count <= 1)
        } label: {
            HeaderControlLabel(title: "Board", systemImage: "rectangle.stack")
        }
        .menuStyle(.borderlessButton)
        .help("Board Actions")
    }

    private var settingsMenu: some View {
        Menu {
            Button {
                onShowPreferences()
            } label: {
                Label("Preferences...", systemImage: "gearshape")
            }

            Button {
                onShowQuickStart()
            } label: {
                Label("Quick Start Guide...", systemImage: "questionmark.circle")
            }
        } label: {
            HeaderControlLabel(title: "Settings", systemImage: "gearshape")
        }
        .menuStyle(.borderlessButton)
        .help("Settings")
    }

    private func duplicateSelectedItem() {
        boardStore.duplicateSelectedItem(constrainedTo: canvasSize)
    }

    private func deleteSelectedItem() {
        boardStore.deleteSelectedItem()
    }

    @ViewBuilder
    private var boardStatus: some View {
        if let connectionSourceItem = boardStore.connectionSourceItem {
            HStack(spacing: 6) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.72, green: 0.08, blue: 0.10))

                Text("From \(connectionSourceItem.content.displayTitle)")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .frame(maxWidth: 150)

                Button {
                    cancelConnectionWorkflow()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.borderless)
                .help("Cancel Connection")
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.thinMaterial, in: Capsule())
        } else {
            Text(cardCountText)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .monospacedDigit()
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
        }
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

    private var selectedItemIsImage: Bool {
        guard let selectedItem = boardStore.selectedItem,
              case .image = selectedItem.content
        else {
            return false
        }

        return true
    }
}

private struct HeaderControlLabel: View {
    let title: String
    let systemImage: String
    var isActive = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))

            Text(title)
                .font(.system(.callout, design: .rounded))
                .fontWeight(.medium)
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? Color.white : Color.primary)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(.thinMaterial)

                if isActive {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(red: 0.66, green: 0.05, blue: 0.07))
                }
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct BoardCardNameTooltip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .truncationMode(.middle)
            .foregroundStyle(.primary)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .frame(maxWidth: 220)
            .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(.white.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.18), radius: 5, x: 0, y: 2)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct BoardChromeBackground: View {
    let theme: BoardTheme
    let customColors: BoardSurfaceColors?
    let opacity: Double

    var body: some View {
        Group {
            if let customColors {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(customColors.startColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.regularMaterial)
                            .opacity(0.22)
                    }
            } else {
                switch theme {
                case .corkboard:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.55, green: 0.38, blue: 0.22))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(.regularMaterial)
                                .opacity(0.28)
                        }
                case .posterBoard:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color(red: 0.94, green: 0.95, blue: 0.93).opacity(0.42))
                        }
                case .system:
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.regularMaterial)
                }
            }
        }
        .opacity(opacity)
    }
}

private struct BoardCanvasBackground: View {
    let theme: BoardTheme
    let customColors: BoardSurfaceColors?
    let opacity: Double

    var body: some View {
        ZStack {
            baseBackground
            themeTexture
        }
        .opacity(opacity)
    }

    @ViewBuilder
    private var baseBackground: some View {
        if let customColors {
            customColors.endColor
        } else {
            switch theme {
            case .corkboard:
                LinearGradient(
                    colors: [
                        Color(red: 0.68, green: 0.48, blue: 0.29),
                        Color(red: 0.52, green: 0.35, blue: 0.21)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .posterBoard:
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.97, blue: 0.95),
                        Color(red: 0.88, green: 0.91, blue: 0.88)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .system:
                LinearGradient(
                    colors: [
                        Color(nsColor: .windowBackgroundColor).opacity(0.74),
                        Color(nsColor: .controlBackgroundColor).opacity(0.58)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    @ViewBuilder
    private var themeTexture: some View {
        switch theme {
        case .corkboard:
            CorkTexture()
        case .posterBoard:
            PosterBoardTexture()
        case .system:
            SystemGridTexture()
        }
    }
}

private struct CorkTexture: View {
    var body: some View {
        Canvas { context, size in
            let fiberColor = Color.black.opacity(0.08)
            let highlightColor = Color.white.opacity(0.06)
            let dotColor = Color.black.opacity(0.1)

            for y in stride(from: CGFloat(10), through: size.height, by: 18) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y + CGFloat(Int(y) % 7) - 3))
                context.stroke(path, with: .color(fiberColor), lineWidth: 0.45)
            }

            for x in stride(from: CGFloat(12), through: size.width, by: 34) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + CGFloat(Int(x) % 9) - 4, y: size.height))
                context.stroke(path, with: .color(highlightColor), lineWidth: 0.35)
            }

            for y in stride(from: CGFloat(14), through: size.height, by: 26) {
                for x in stride(from: CGFloat(16), through: size.width, by: 31) {
                    let seed = (Int(x) * 17 + Int(y) * 23) % 11
                    let radius = CGFloat(0.7 + Double(seed % 4) * 0.2)
                    let rect = CGRect(
                        x: x + CGFloat(seed - 5),
                        y: y + CGFloat((seed * 2) - 8),
                        width: radius,
                        height: radius
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(dotColor))
                }
            }
        }
        .blendMode(.multiply)
    }
}

private struct PosterBoardTexture: View {
    var body: some View {
        Canvas { context, size in
            let gridColor = Color(red: 0.35, green: 0.48, blue: 0.58).opacity(0.08)
            let majorGridColor = Color(red: 0.35, green: 0.48, blue: 0.58).opacity(0.12)
            let spacing = CGFloat(32)

            for x in stride(from: CGFloat(0), through: size.width, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(path, with: .color(Int(x / spacing).isMultiple(of: 4) ? majorGridColor : gridColor), lineWidth: 0.6)
            }

            for y in stride(from: CGFloat(0), through: size.height, by: spacing) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(path, with: .color(Int(y / spacing).isMultiple(of: 4) ? majorGridColor : gridColor), lineWidth: 0.6)
            }
        }
    }
}

private struct SystemGridTexture: View {
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
    }
}

private extension BoardSurfaceColors {
    var startColor: Color {
        Color(boardHex: startHex)
    }

    var endColor: Color {
        Color(boardHex: endHex)
    }
}

private extension Color {
    init(boardHex hex: String) {
        let hexValue = String(hex.dropFirst())
        guard let rgbValue = UInt64(hexValue, radix: 16) else {
            self = .black
            return
        }

        self.init(
            red: Double((rgbValue >> 16) & 0xFF) / 255,
            green: Double((rgbValue >> 8) & 0xFF) / 255,
            blue: Double(rgbValue & 0xFF) / 255
        )
    }
}

private extension BoardItem {
    var isEditable: Bool {
        if case .file = content {
            return false
        }

        return true
    }
}
