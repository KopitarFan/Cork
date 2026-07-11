import AppKit
import CorkCore
import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    static let shared = AppCoordinator()

    let boardStore: BoardStore
    let settingsStore: SettingsStore

    @Published private(set) var isBoardVisible = false

    private lazy var launchAtLoginController = LaunchAtLoginController(
        settingsStore: settingsStore
    )
    private lazy var hotKeyController = HotKeyController(
        settingsStore: settingsStore
    ) { [weak self] in
        self?.toggleBoard()
    }
    private lazy var boardPanelController = BoardPanelController(
        boardStore: boardStore,
        settingsStore: settingsStore
    )
    private lazy var preferencesWindowController = PreferencesWindowController(
        settingsStore: settingsStore,
        launchAtLoginController: launchAtLoginController,
        hotKeyController: hotKeyController
    )
    private var didStart = false

    private init() {
        boardStore = Self.makeBoardStore()
        settingsStore = Self.makeSettingsStore()
    }

    func start() {
        guard !didStart else {
            return
        }

        didStart = true
        NSApp.setActivationPolicy(.accessory)
        hotKeyController.start()
        launchAtLoginController.refresh()
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

    func showPreferences() {
        preferencesWindowController.show()
    }

    func flushPendingAutosave() {
        boardStore.flushPendingAutosave()
        settingsStore.flushPendingAutosave()
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

    private static func makeSettingsStore() -> SettingsStore {
        do {
            let repository = try JSONSettingsRepository.applicationSupportRepository()
            let settings: AppSettings

            do {
                settings = try repository.loadSettings() ?? .default
            } catch {
                NSLog("Cork could not load saved settings: \(error.localizedDescription)")
                settings = .default
            }

            return SettingsStore(settings: settings, repository: repository)
        } catch {
            NSLog("Cork could not create settings repository: \(error.localizedDescription)")
            return SettingsStore()
        }
    }

}
