import AppKit
import Carbon.HIToolbox
import CorkCore
import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()

    let boardStore: BoardStore

    @Published private(set) var isBoardVisible = false

    private lazy var boardPanelController = BoardPanelController(boardStore: boardStore)
    private var globalHotKey: GlobalHotKey?
    private var didStart = false

    private init() {
        boardStore = Self.makeBoardStore()
    }

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

    func flushPendingAutosave() {
        boardStore.flushPendingAutosave()
    }

    private static func makeBoardStore() -> BoardStore {
        do {
            let repository = try JSONBoardRepository.applicationSupportRepository()
            let snapshot: BoardLibrarySnapshot

            do {
                snapshot = try repository.loadSnapshot() ?? .sample
            } catch {
                NSLog("Cork could not load saved board state: \(error.localizedDescription)")
                snapshot = .sample
            }

            return BoardStore(snapshot: snapshot, repository: repository)
        } catch {
            NSLog("Cork could not create board repository: \(error.localizedDescription)")
            return BoardStore()
        }
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
