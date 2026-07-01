import AppKit
import Carbon.HIToolbox
import CorkCore
import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()

    let boardStore = BoardStore()

    @Published private(set) var isBoardVisible = false

    private lazy var boardPanelController = BoardPanelController(boardStore: boardStore)
    private var globalHotKey: GlobalHotKey?
    private var didStart = false

    private init() {}

    func start() {
        guard !didStart else {
            return
        }

        didStart = true
        NSApp.setActivationPolicy(.accessory)
        registerDefaultHotKey()
    }

    func toggleBoard() {
        if isBoardVisible {
            hideBoard()
        } else {
            showBoard()
        }
    }

    func showBoard() {
        boardPanelController.show()
        isBoardVisible = true
    }

    func hideBoard() {
        boardPanelController.hide()
        isBoardVisible = false
    }

    private func registerDefaultHotKey() {
        let hotKey = GlobalHotKey(
            keyCode: UInt32(kVK_ANSI_B),
            modifiers: [.command, .option]
        ) { [weak self] in
            self?.toggleBoard()
        }

        do {
            try hotKey.register()
            globalHotKey = hotKey
        } catch {
            NSLog("Cork could not register the default hot key: \(error.localizedDescription)")
        }
    }
}
