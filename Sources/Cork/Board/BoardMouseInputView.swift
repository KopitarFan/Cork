import AppKit
import CorkCore
import SwiftUI

struct BoardMouseInputView: NSViewRepresentable {
    let items: [BoardItem]
    let selectedItemID: BoardItem.ID?
    let boardSize: BoardSize
    let onSelect: (BoardItem.ID) -> Void
    let onClearSelection: () -> Void
    let onEdit: (BoardItem.ID) -> Void
    let onMove: (BoardItem.ID, BoardPoint) -> Void
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
        nsView.onEdit = onEdit
        nsView.onMove = onMove
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
    var onEdit: ((BoardItem.ID) -> Void)?
    var onMove: ((BoardItem.ID, BoardPoint) -> Void)?
    var onDuplicate: ((BoardItem.ID) -> Void)?
    var onDelete: ((BoardItem.ID) -> Void)?
    var onImport: (([BoardImportIntent], BoardPoint) -> Void)?

    private let dropResolver = BoardDropResolver()
    private var draggedItemID: BoardItem.ID?
    private var dragStartLocation: BoardPoint?
    private var dragStartOrigin: BoardPoint?
    private var contextItemID: BoardItem.ID?

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

    override func mouseDown(with event: NSEvent) {
        let location = boardPoint(for: event)

        guard let item = item(at: location) else {
            onClearSelection?()
            return
        }

        onSelect?(item.id)

        if event.clickCount == 2 {
            onEdit?(item.id)
            return
        }

        draggedItemID = item.id
        dragStartLocation = location
        dragStartOrigin = item.frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard let draggedItemID,
              let dragStartLocation,
              let dragStartOrigin
        else {
            return
        }

        let location = boardPoint(for: event)
        let nextOrigin = BoardPoint(
            x: dragStartOrigin.x + location.x - dragStartLocation.x,
            y: dragStartOrigin.y + location.y - dragStartLocation.y
        )

        onMove?(draggedItemID, nextOrigin)
    }

    override func mouseUp(with event: NSEvent) {
        draggedItemID = nil
        dragStartLocation = nil
        dragStartOrigin = nil
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

    private func boardPoint(for draggingInfo: NSDraggingInfo) -> BoardPoint {
        let location = convert(draggingInfo.draggingLocation, from: nil)
        return BoardPoint(x: location.x, y: location.y)
    }

    private func dropOperation(for draggingInfo: NSDraggingInfo) -> NSDragOperation {
        dropResolver.importIntents(from: draggingInfo.draggingPasteboard).isEmpty ? [] : .copy
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

private extension BoardRect {
    func contains(_ point: BoardPoint) -> Bool {
        point.x >= origin.x &&
        point.x <= origin.x + size.width &&
        point.y >= origin.y &&
        point.y <= origin.y + size.height
    }
}

private extension BoardPoint {
    var nsPoint: NSPoint {
        NSPoint(x: x, y: y)
    }
}
