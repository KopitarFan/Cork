import AppKit
import CorkCore
import SwiftUI

struct BoardMouseInputView: NSViewRepresentable {
    let items: [BoardItem]
    let selectedItemID: BoardItem.ID?
    let boardSize: BoardSize
    let onSelect: (BoardItem.ID) -> Void
    let onClearSelection: () -> Void
    let onHoverChange: (BoardItem.ID?) -> Void
    let onEdit: (BoardItem.ID) -> Void
    let onMove: (BoardItem.ID, BoardPoint) -> Void
    let onResize: (BoardItem.ID, BoardSize) -> Void
    let onOpenURL: (BoardItem.ID) -> Void
    let onDuplicate: (BoardItem.ID) -> Void
    let onDelete: (BoardItem.ID) -> Void
    let onImport: ([BoardImportIntent], BoardPoint) -> Void

    func makeNSView(context: Context) -> BoardMouseCatcherView {
        let view = BoardMouseCatcherView()
        updateNSView(view, context: context)
        return view
    }

    func updateNSView(_ nsView: BoardMouseCatcherView, context: Context) {
        nsView.items = items
        nsView.selectedItemID = selectedItemID
        nsView.boardSize = boardSize
        nsView.onSelect = onSelect
        nsView.onClearSelection = onClearSelection
        nsView.onHoverChange = onHoverChange
        nsView.onEdit = onEdit
        nsView.onMove = onMove
        nsView.onResize = onResize
        nsView.onOpenURL = onOpenURL
        nsView.onDuplicate = onDuplicate
        nsView.onDelete = onDelete
        nsView.onImport = onImport
    }
}

final class BoardMouseCatcherView: NSView {
    var items: [BoardItem] = []
    var selectedItemID: BoardItem.ID?
    var boardSize = BoardSize(width: 0, height: 0)
    var onSelect: ((BoardItem.ID) -> Void)?
    var onClearSelection: (() -> Void)?
    var onHoverChange: ((BoardItem.ID?) -> Void)?
    var onEdit: ((BoardItem.ID) -> Void)?
    var onMove: ((BoardItem.ID, BoardPoint) -> Void)?
    var onResize: ((BoardItem.ID, BoardSize) -> Void)?
    var onOpenURL: ((BoardItem.ID) -> Void)?
    var onDuplicate: ((BoardItem.ID) -> Void)?
    var onDelete: ((BoardItem.ID) -> Void)?
    var onImport: (([BoardImportIntent], BoardPoint) -> Void)?

    private let dropResolver = BoardDropResolver()
    private var activeInteraction: ActiveInteraction?
    private var hoveredItemID: BoardItem.ID?
    private var contextItemID: BoardItem.ID?
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes(BoardDropResolver.supportedPasteboardTypes)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        registerForDraggedTypes(BoardDropResolver.supportedPasteboardTypes)
    }

    override var isFlipped: Bool {
        true
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
    }

    override func updateTrackingAreas() {
        if let trackingArea {
            removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .inVisibleRect, .mouseMoved, .mouseEnteredAndExited],
            owner: self
        )
        addTrackingArea(trackingArea)
        self.trackingArea = trackingArea

        super.updateTrackingAreas()
    }

    override func mouseDown(with event: NSEvent) {
        let location = boardPoint(for: event)

        if let item = resizeItem(at: location) {
            onSelect?(item.id)
            activeInteraction = .resize(
                id: item.id,
                startLocation: location,
                startSize: item.frame.size
            )
            updateCursor(at: location)
            return
        }

        guard let item = item(at: location) else {
            onClearSelection?()
            setHoveredItemID(nil)
            return
        }

        onSelect?(item.id)

        if event.clickCount == 2 {
            onEdit?(item.id)
            return
        }

        activeInteraction = .move(
            id: item.id,
            startLocation: location,
            startOrigin: item.frame.origin
        )
        updateCursor(at: location)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let activeInteraction else {
            return
        }

        let location = boardPoint(for: event)

        switch activeInteraction {
        case .move(let id, let startLocation, let startOrigin):
            let nextOrigin = BoardPoint(
                x: startOrigin.x + location.x - startLocation.x,
                y: startOrigin.y + location.y - startLocation.y
            )
            onMove?(id, nextOrigin)
        case .resize(let id, let startLocation, let startSize):
            let nextSize = BoardSize(
                width: startSize.width + location.x - startLocation.x,
                height: startSize.height + location.y - startLocation.y
            )
            onResize?(id, nextSize)
        }

        updateCursor(at: location)
    }

    override func mouseUp(with event: NSEvent) {
        let location = boardPoint(for: event)
        activeInteraction = nil
        updateHover(at: location)
        updateCursor(at: location)
    }

    override func mouseMoved(with event: NSEvent) {
        let location = boardPoint(for: event)
        updateHover(at: location)
        updateCursor(at: location)
    }

    override func mouseExited(with event: NSEvent) {
        setHoveredItemID(nil)
        NSCursor.arrow.set()
    }

    override func rightMouseDown(with event: NSEvent) {
        let location = boardPoint(for: event)

        guard let item = item(at: location) else {
            onClearSelection?()
            return
        }

        onSelect?(item.id)
        contextItemID = item.id

        let menu = NSMenu()

        if case .url = item.content {
            let openItem = NSMenuItem(
                title: "Open Link",
                action: #selector(openContextItem),
                keyEquivalent: ""
            )
            openItem.target = self
            menu.addItem(openItem)
            menu.addItem(.separator())
        }

        let editItem = NSMenuItem(
            title: "Edit",
            action: #selector(editContextItem),
            keyEquivalent: ""
        )
        editItem.target = self
        menu.addItem(editItem)

        menu.addItem(.separator())

        let duplicateItem = NSMenuItem(
            title: "Duplicate",
            action: #selector(duplicateContextItem),
            keyEquivalent: ""
        )
        duplicateItem.target = self
        menu.addItem(duplicateItem)

        let deleteItem = NSMenuItem(
            title: "Delete",
            action: #selector(deleteContextItem),
            keyEquivalent: ""
        )
        deleteItem.target = self
        menu.addItem(deleteItem)

        menu.popUp(positioning: nil, at: location.nsPoint, in: self)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        dropOperation(for: sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        dropOperation(for: sender)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let intents = dropResolver.importIntents(from: sender.draggingPasteboard)

        guard !intents.isEmpty else {
            return false
        }

        onImport?(intents, boardPoint(for: sender))
        return true
    }

    @objc private func editContextItem() {
        guard let contextItemID else {
            return
        }

        onEdit?(contextItemID)
        self.contextItemID = nil
    }

    @objc private func openContextItem() {
        guard let contextItemID else {
            return
        }

        onOpenURL?(contextItemID)
        self.contextItemID = nil
    }

    @objc private func duplicateContextItem() {
        guard let contextItemID else {
            return
        }

        onDuplicate?(contextItemID)
        self.contextItemID = nil
    }

    @objc private func deleteContextItem() {
        guard let contextItemID else {
            return
        }

        onDelete?(contextItemID)
        self.contextItemID = nil
    }

    private func boardPoint(for event: NSEvent) -> BoardPoint {
        let location = convert(event.locationInWindow, from: nil)
        return BoardPoint(x: location.x, y: location.y)
    }

    private func updateHover(at point: BoardPoint) {
        setHoveredItemID(item(at: point)?.id)
    }

    private func setHoveredItemID(_ itemID: BoardItem.ID?) {
        guard hoveredItemID != itemID else {
            return
        }

        hoveredItemID = itemID
        onHoverChange?(itemID)
    }

    private func updateCursor(at point: BoardPoint) {
        if case .resize = activeInteraction {
            NSCursor.resizeLeftRight.set()
            return
        }

        if case .move = activeInteraction {
            NSCursor.closedHand.set()
            return
        }

        if resizeItem(at: point) != nil {
            NSCursor.resizeLeftRight.set()
        } else if item(at: point) != nil {
            NSCursor.openHand.set()
        } else {
            NSCursor.arrow.set()
        }
    }

    private func boardPoint(for draggingInfo: NSDraggingInfo) -> BoardPoint {
        let location = convert(draggingInfo.draggingLocation, from: nil)
        return BoardPoint(x: location.x, y: location.y)
    }

    private func dropOperation(for draggingInfo: NSDraggingInfo) -> NSDragOperation {
        dropResolver.importIntents(from: draggingInfo.draggingPasteboard).isEmpty ? [] : .copy
    }

    private func resizeItem(at point: BoardPoint) -> BoardItem? {
        guard let selectedItemID else {
            return nil
        }

        return items.first { item in
            item.id == selectedItemID && item.frame.containsResizeHandle(point)
        }
    }

    private func item(at point: BoardPoint) -> BoardItem? {
        let selectedItem = selectedItemID.flatMap { selectedID in
            items.first { item in
                item.id == selectedID && item.frame.contains(point)
            }
        }

        if let selectedItem {
            return selectedItem
        }

        return items.reversed().first { item in
            item.frame.contains(point)
        }
    }
}

private enum ActiveInteraction {
    case move(
        id: BoardItem.ID,
        startLocation: BoardPoint,
        startOrigin: BoardPoint
    )
    case resize(
        id: BoardItem.ID,
        startLocation: BoardPoint,
        startSize: BoardSize
    )
}

private extension BoardRect {
    func contains(_ point: BoardPoint) -> Bool {
        point.x >= origin.x &&
        point.x <= origin.x + size.width &&
        point.y >= origin.y &&
        point.y <= origin.y + size.height
    }

    func containsResizeHandle(_ point: BoardPoint) -> Bool {
        let handleSize = 24.0
        return point.x >= origin.x + size.width - handleSize &&
            point.x <= origin.x + size.width &&
            point.y >= origin.y + size.height - handleSize &&
            point.y <= origin.y + size.height
    }
}

private extension BoardPoint {
    var nsPoint: NSPoint {
        NSPoint(x: x, y: y)
    }
}
