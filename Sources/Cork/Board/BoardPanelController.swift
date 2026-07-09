import AppKit
import CorkCore
import SwiftUI

@MainActor
final class BoardPanelController {
    private let panel: BoardPanel
    private let hostingController: NSHostingController<BoardView>
    private let settingsStore: SettingsStore

    private var visibleFrame: NSRect = .zero
    private var hiddenFrame: NSRect = .zero

    init(boardStore: BoardStore, settingsStore: SettingsStore) {
        self.settingsStore = settingsStore
        self.hostingController = NSHostingController(
            rootView: BoardView(boardStore: boardStore, settingsStore: settingsStore)
        )
        self.panel = BoardPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configurePanel()
    }

    func show() {
        recalculateFrames()

        if !panel.isVisible {
            panel.setFrame(hiddenFrame, display: false)
            panel.orderFrontRegardless()
        }

        panel.makeKey()
        animatePanel(to: visibleFrame)
    }

    func hide() {
        guard panel.isVisible else {
            return
        }

        recalculateFrames()
        animatePanel(to: hiddenFrame) { [weak panel] in
            panel?.orderOut(nil)
        }
    }

    private func configurePanel() {
        panel.contentViewController = hostingController
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.animationBehavior = .none
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
    }

    private func recalculateFrames() {
        let screen = screenUnderMouse() ?? NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1100, height: 760)
        let sideMargin = max(18, min(36, screenFrame.width * 0.025))
        let edgeMargin = CGFloat(12)
        let width = screenFrame.width - (sideMargin * 2)
        let height = min(screenFrame.height * 0.72, 720)
        let x = screenFrame.minX + sideMargin
        let topY = screenFrame.maxY - height - edgeMargin
        let centeredY = screenFrame.midY - (height / 2)
        let bottomY = screenFrame.minY + edgeMargin

        switch settingsStore.settings.boardSlideEdge {
        case .top:
            visibleFrame = NSRect(x: x, y: topY, width: width, height: height)
            hiddenFrame = NSRect(x: x, y: screenFrame.maxY + 8, width: width, height: height)
        case .bottom:
            visibleFrame = NSRect(x: x, y: bottomY, width: width, height: height)
            hiddenFrame = NSRect(x: x, y: screenFrame.minY - height - 8, width: width, height: height)
        case .left:
            visibleFrame = NSRect(x: x, y: centeredY, width: width, height: height)
            hiddenFrame = NSRect(x: screenFrame.minX - width - 8, y: centeredY, width: width, height: height)
        case .right:
            visibleFrame = NSRect(x: x, y: centeredY, width: width, height: height)
            hiddenFrame = NSRect(x: screenFrame.maxX + 8, y: centeredY, width: width, height: height)
        }
    }

    private func screenUnderMouse() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first { screen in
            screen.frame.contains(mouseLocation)
        }
    }

    private func animatePanel(to frame: NSRect, completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.28
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(frame, display: true)
        } completionHandler: {
            completion?()
        }
    }
}

final class BoardPanel: NSPanel {
    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }
}
