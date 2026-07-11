import XCTest
@testable import CorkCore

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testUpdateBoardOpacityChangesSettings() {
        let store = SettingsStore(settings: AppSettings(boardOpacity: 1.0))

        let didUpdate = store.updateBoardOpacity(0.78)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.settings.boardOpacity, 0.78)
    }

    func testUpdateBoardOpacityClampsValue() {
        let store = SettingsStore(settings: AppSettings(boardOpacity: 1.0))

        store.updateBoardOpacity(0.1)

        XCTAssertEqual(store.settings.boardOpacity, AppSettings.minimumBoardOpacity)
    }

    func testUpdateBoardOpacityRejectsUnchangedValue() {
        let store = SettingsStore(settings: AppSettings(boardOpacity: 0.8))

        let didUpdate = store.updateBoardOpacity(0.8)

        XCTAssertFalse(didUpdate)
    }

    func testUpdateLaunchAtLoginChangesSettings() {
        let store = SettingsStore()

        let didUpdate = store.updateLaunchAtLoginEnabled(true)

        XCTAssertTrue(didUpdate)
        XCTAssertTrue(store.settings.launchAtLoginEnabled)
    }

    func testUpdateLaunchAtLoginRejectsUnchangedValue() {
        let store = SettingsStore(settings: AppSettings(launchAtLoginEnabled: true))

        let didUpdate = store.updateLaunchAtLoginEnabled(true)

        XCTAssertFalse(didUpdate)
    }

    func testUpdateBoardSlideEdgeChangesSettings() {
        let store = SettingsStore()

        let didUpdate = store.updateBoardSlideEdge(.right)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.settings.boardSlideEdge, .right)
    }

    func testUpdateBoardSlideEdgeRejectsUnchangedValue() {
        let store = SettingsStore(settings: AppSettings(boardSlideEdge: .bottom))

        let didUpdate = store.updateBoardSlideEdge(.bottom)

        XCTAssertFalse(didUpdate)
    }

    func testUpdateHotKeyConfigurationChangesSettings() {
        let store = SettingsStore()
        let configuration = HotKeyConfiguration(keyCode: 8, modifiers: [.command, .shift])

        let didUpdate = store.updateHotKeyConfiguration(configuration)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.settings.hotKeyConfiguration, configuration)
    }

    func testUpdateHotKeyConfigurationRejectsUnchangedValue() {
        let configuration = HotKeyConfiguration(keyCode: 8, modifiers: [.command, .shift])
        let store = SettingsStore(settings: AppSettings(hotKeyConfiguration: configuration))

        let didUpdate = store.updateHotKeyConfiguration(configuration)

        XCTAssertFalse(didUpdate)
    }

    func testUpdateHotKeyConfigurationRejectsInvalidValue() {
        let store = SettingsStore()
        let configuration = HotKeyConfiguration(keyCode: 8, modifiers: [])

        let didUpdate = store.updateHotKeyConfiguration(configuration)

        XCTAssertFalse(didUpdate)
        XCTAssertEqual(store.settings.hotKeyConfiguration, AppSettings.defaultHotKeyConfiguration)
    }

    func testUpdateBoardOpacityAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            settings: AppSettings(boardOpacity: 1.0),
            repository: repository,
            autosaveDelay: 0
        )

        store.updateBoardOpacity(0.7)

        XCTAssertEqual(repository.savedSettings, [AppSettings(boardOpacity: 0.7)])
    }

    func testUpdateLaunchAtLoginAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            repository: repository,
            autosaveDelay: 0
        )

        store.updateLaunchAtLoginEnabled(true)

        XCTAssertEqual(repository.savedSettings, [AppSettings(launchAtLoginEnabled: true)])
    }

    func testUpdateBoardSlideEdgeAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            repository: repository,
            autosaveDelay: 0
        )

        store.updateBoardSlideEdge(.left)

        XCTAssertEqual(repository.savedSettings, [AppSettings(boardSlideEdge: .left)])
    }

    func testUpdateHotKeyConfigurationAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            repository: repository,
            autosaveDelay: 0
        )
        let configuration = HotKeyConfiguration(keyCode: 8, modifiers: [.command, .shift])

        store.updateHotKeyConfiguration(configuration)

        XCTAssertEqual(repository.savedSettings, [AppSettings(hotKeyConfiguration: configuration)])
    }

    func testFlushPendingAutosaveSavesImmediately() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            settings: AppSettings(boardOpacity: 1.0),
            repository: repository,
            autosaveDelay: 10
        )

        store.updateBoardOpacity(0.7)
        store.flushPendingAutosave()

        XCTAssertEqual(repository.savedSettings, [AppSettings(boardOpacity: 0.7)])
    }
}

private final class CapturingSettingsRepository: SettingsRepository {
    private(set) var savedSettings: [AppSettings] = []

    func loadSettings() throws -> AppSettings? {
        nil
    }

    func saveSettings(_ settings: AppSettings) throws {
        savedSettings.append(settings)
    }
}
