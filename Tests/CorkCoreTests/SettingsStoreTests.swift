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

    func testUpdateCardOpacityChangesSettings() {
        let store = SettingsStore(settings: AppSettings(cardOpacity: 1.0))

        let didUpdate = store.updateCardOpacity(0.62)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.settings.cardOpacity, 0.62)
    }

    func testUpdateCardOpacityClampsValue() {
        let store = SettingsStore(settings: AppSettings(cardOpacity: 1.0))

        store.updateCardOpacity(0.1)

        XCTAssertEqual(store.settings.cardOpacity, AppSettings.minimumCardOpacity)
    }

    func testUpdateCardOpacityRejectsUnchangedValue() {
        let store = SettingsStore(settings: AppSettings(cardOpacity: 0.8))

        let didUpdate = store.updateCardOpacity(0.8)

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

    func testUpdateBoardThemeChangesSettings() {
        let store = SettingsStore()

        let didUpdate = store.updateBoardTheme(.posterBoard)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.settings.boardTheme, .posterBoard)
    }

    func testUpdateBoardThemeRejectsUnchangedValue() {
        let store = SettingsStore(settings: AppSettings(boardTheme: .system))

        let didUpdate = store.updateBoardTheme(.system)

        XCTAssertFalse(didUpdate)
    }

    func testUpdateBoardDisplayModeChangesSettings() {
        let store = SettingsStore()

        let didUpdate = store.updateBoardDisplayMode(.compact)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.settings.boardDisplayMode, .compact)
    }

    func testUpdateBoardDisplayModeRejectsUnchangedValue() {
        let store = SettingsStore(settings: AppSettings(boardDisplayMode: .large))

        let didUpdate = store.updateBoardDisplayMode(.large)

        XCTAssertFalse(didUpdate)
    }

    func testUpdateCustomBoardColorsEnabledChangesSettings() {
        let store = SettingsStore()

        let didUpdate = store.updateCustomBoardColorsEnabled(true)

        XCTAssertTrue(didUpdate)
        XCTAssertTrue(store.settings.customBoardColorsEnabled)
    }

    func testUpdateCustomBoardColorsEnabledRejectsUnchangedValue() {
        let store = SettingsStore(settings: AppSettings(customBoardColorsEnabled: true))

        let didUpdate = store.updateCustomBoardColorsEnabled(true)

        XCTAssertFalse(didUpdate)
    }

    func testUpdateCustomBoardColorsChangesSettings() {
        let store = SettingsStore()
        let colors = BoardSurfaceColors(startHex: "#1F6FEB", endHex: "#FF7B72")

        let didUpdate = store.updateCustomBoardColors(colors)

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(store.settings.customBoardColors, colors)
    }

    func testUpdateCustomBoardColorsRejectsUnchangedValue() {
        let colors = BoardSurfaceColors(startHex: "#1F6FEB", endHex: "#FF7B72")
        let store = SettingsStore(settings: AppSettings(customBoardColors: colors))

        let didUpdate = store.updateCustomBoardColors(colors)

        XCTAssertFalse(didUpdate)
    }

    func testUpdateCustomBoardTitleBarColorPreservesSurfaceColor() {
        let store = SettingsStore(settings: AppSettings(
            customBoardColors: BoardSurfaceColors(startHex: "#1F6FEB", endHex: "#FF7B72")
        ))

        let didUpdate = store.updateCustomBoardTitleBarColor("#4ECDC4")

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(
            store.settings.customBoardColors,
            BoardSurfaceColors(startHex: "#4ECDC4", endHex: "#FF7B72")
        )
    }

    func testUpdateCustomBoardSurfaceColorPreservesTitleBarColor() {
        let store = SettingsStore(settings: AppSettings(
            customBoardColors: BoardSurfaceColors(startHex: "#1F6FEB", endHex: "#FF7B72")
        ))

        let didUpdate = store.updateCustomBoardSurfaceColor("#4ECDC4")

        XCTAssertTrue(didUpdate)
        XCTAssertEqual(
            store.settings.customBoardColors,
            BoardSurfaceColors(startHex: "#1F6FEB", endHex: "#4ECDC4")
        )
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

    func testMarkQuickStartGuideSeenChangesSettingsOnlyOnce() {
        let store = SettingsStore()

        XCTAssertTrue(store.markQuickStartGuideSeen())
        XCTAssertTrue(store.settings.hasSeenQuickStartGuide)
        XCTAssertFalse(store.markQuickStartGuideSeen())
    }

    func testMarkQuickStartGuideSeenAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            repository: repository,
            autosaveDelay: 0
        )

        store.markQuickStartGuideSeen()

        XCTAssertEqual(
            repository.savedSettings,
            [AppSettings(hasSeenQuickStartGuide: true)]
        )
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

    func testUpdateCardOpacityAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            settings: AppSettings(cardOpacity: 1.0),
            repository: repository,
            autosaveDelay: 0
        )

        store.updateCardOpacity(0.7)

        XCTAssertEqual(repository.savedSettings, [AppSettings(cardOpacity: 0.7)])
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

    func testUpdateBoardThemeAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            repository: repository,
            autosaveDelay: 0
        )

        store.updateBoardTheme(.system)

        XCTAssertEqual(repository.savedSettings, [AppSettings(boardTheme: .system)])
    }

    func testUpdateBoardDisplayModeAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            repository: repository,
            autosaveDelay: 0
        )

        store.updateBoardDisplayMode(.large)

        XCTAssertEqual(repository.savedSettings, [AppSettings(boardDisplayMode: .large)])
    }

    func testUpdateCustomBoardColorsEnabledAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            repository: repository,
            autosaveDelay: 0
        )

        store.updateCustomBoardColorsEnabled(true)

        XCTAssertEqual(repository.savedSettings, [AppSettings(customBoardColorsEnabled: true)])
    }

    func testUpdateCustomBoardColorsAutosavesWhenRepositoryIsConfigured() {
        let repository = CapturingSettingsRepository()
        let store = SettingsStore(
            repository: repository,
            autosaveDelay: 0
        )
        let colors = BoardSurfaceColors(startHex: "#1F6FEB", endHex: "#FF7B72")

        store.updateCustomBoardColors(colors)

        XCTAssertEqual(repository.savedSettings, [AppSettings(customBoardColors: colors)])
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
