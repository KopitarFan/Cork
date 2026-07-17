import AppKit
import Combine
import CorkCore
import SwiftUI

@MainActor
final class BoardPanelController {
    private let panel: BoardPanel
    private let hostingController: NSHostingController<BoardView>
    private let settingsStore: SettingsStore

    private var visibleFrame: NSRect = .zero
    private var hiddenFrame: NSRect = .zero
    private var cancellables: Set<AnyCancellable> = []

    init(
        boardStore: BoardStore,
        settingsStore: SettingsStore,
        onShowPreferences: @escaping () -> Void,
        onShowQuickStart: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.hostingController = NSHostingController(
            rootView: BoardView(
                boardStore: boardStore,
                settingsStore: settingsStore,
                onShowPreferences: onShowPreferences,
                onShowQuickStart: onShowQuickStart
            )
        )
        self.panel = BoardPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        configurePanel()
        observeLayoutSettings()
    }

    func show() {
        recalculateFrames()

        if !panel.isVisible {
            panel.setFrame(hiddenFrame, display: false)
            panel.orderFrontRegardless()
        }

        bringToFront()
        animatePanel(to: visibleFrame)
    }

    func bringToFront() {
        panel.orderFrontRegardless()
        panel.makeKey()
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

    var isFrontmost: Bool {
        panel.isVisible && panel.isKeyWindow
    }

    private func configurePanel() {
        panel.contentViewController = hostingController
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.level = .normal
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.animationBehavior = .none
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false
    }

    private func recalculateFrames() {
        let screen = screenUnderMouse() ?? NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1100, height: 760)
        let metrics = settingsStore.settings.boardDisplayMode.panelMetrics
        let sideMargin = max(metrics.minimumSideMargin, min(metrics.maximumSideMargin, screenFrame.width * 0.025))
        let edgeMargin = CGFloat(12)
        let availableWidth = max(320, screenFrame.width - (sideMargin * 2))
        let proposedWidth = screenFrame.width * metrics.widthFraction
        let widthLimit = metrics.maximumWidth.map { min($0, availableWidth) } ?? availableWidth
        let width = min(availableWidth, min(proposedWidth, widthLimit))
        let availableHeight = max(280, screenFrame.height - (edgeMargin * 2))
        let proposedHeight = min(screenFrame.height * metrics.heightFraction, metrics.maximumHeight)
        let height = min(availableHeight, max(metrics.minimumHeight, proposedHeight))
        let x = screenFrame.midX - (width / 2)
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

    private func observeLayoutSettings() {
        settingsStore.$settings
            .map { settings in
                BoardPanelLayoutSettings(
                    slideEdge: settings.boardSlideEdge,
                    displayMode: settings.boardDisplayMode
                )
            }
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.updateVisibleLayoutIfNeeded()
            }
            .store(in: &cancellables)
    }

    private func updateVisibleLayoutIfNeeded() {
        guard panel.isVisible else {
            return
        }

        recalculateFrames()
        animatePanel(to: visibleFrame)
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

private struct BoardPanelLayoutSettings: Equatable {
    let slideEdge: BoardSlideEdge
    let displayMode: BoardDisplayMode
}

private struct BoardPanelMetrics {
    let widthFraction: CGFloat
    let maximumWidth: CGFloat?
    let heightFraction: CGFloat
    let maximumHeight: CGFloat
    let minimumHeight: CGFloat
    let minimumSideMargin: CGFloat
    let maximumSideMargin: CGFloat
}

private extension BoardDisplayMode {
    var panelMetrics: BoardPanelMetrics {
        switch self {
        case .compact:
            BoardPanelMetrics(
                widthFraction: 0.78,
                maximumWidth: 860,
                heightFraction: 0.42,
                maximumHeight: 420,
                minimumHeight: 320,
                minimumSideMargin: 24,
                maximumSideMargin: 44
            )
        case .standard:
            BoardPanelMetrics(
                widthFraction: 1.0,
                maximumWidth: nil,
                heightFraction: 0.72,
                maximumHeight: 720,
                minimumHeight: 420,
                minimumSideMargin: 18,
                maximumSideMargin: 36
            )
        case .large:
            BoardPanelMetrics(
                widthFraction: 1.0,
                maximumWidth: nil,
                heightFraction: 0.86,
                maximumHeight: 860,
                minimumHeight: 500,
                minimumSideMargin: 12,
                maximumSideMargin: 28
            )
        }
    }
}
