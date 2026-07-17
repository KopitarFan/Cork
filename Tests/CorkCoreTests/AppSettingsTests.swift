import XCTest
@testable import CorkCore

final class AppSettingsTests: XCTestCase {
    func testSettingsUseDefaultBoardOpacity() {
        let settings = AppSettings()

        XCTAssertEqual(settings.boardOpacity, AppSettings.defaultBoardOpacity)
    }

    func testSettingsUseDefaultCardOpacity() {
        let settings = AppSettings()

        XCTAssertEqual(settings.cardOpacity, AppSettings.defaultCardOpacity)
    }

    func testSettingsUseDefaultLaunchAtLoginValue() {
        let settings = AppSettings()

        XCTAssertEqual(settings.launchAtLoginEnabled, AppSettings.defaultLaunchAtLoginEnabled)
    }

    func testSettingsUseDefaultBoardSlideEdge() {
        let settings = AppSettings()

        XCTAssertEqual(settings.boardSlideEdge, AppSettings.defaultBoardSlideEdge)
    }

    func testSettingsUseDefaultHotKeyConfiguration() {
        let settings = AppSettings()

        XCTAssertEqual(settings.hotKeyConfiguration, AppSettings.defaultHotKeyConfiguration)
    }

    func testSettingsUseDefaultBoardTheme() {
        let settings = AppSettings()

        XCTAssertEqual(settings.boardTheme, AppSettings.defaultBoardTheme)
    }

    func testSettingsUseDefaultBoardDisplayMode() {
        let settings = AppSettings()

        XCTAssertEqual(settings.boardDisplayMode, AppSettings.defaultBoardDisplayMode)
    }

    func testSettingsUseDefaultCustomBoardColors() {
        let settings = AppSettings()

        XCTAssertEqual(settings.customBoardColorsEnabled, AppSettings.defaultCustomBoardColorsEnabled)
        XCTAssertEqual(settings.customBoardColors, AppSettings.defaultCustomBoardColors)
    }

    func testSettingsUseDefaultQuickStartGuideState() {
        let settings = AppSettings()

        XCTAssertEqual(
            settings.hasSeenQuickStartGuide,
            AppSettings.defaultHasSeenQuickStartGuide
        )
    }

    func testBoardSurfaceColorsNormalizeHexValues() {
        let colors = BoardSurfaceColors(startHex: "f66", endHex: "#4ecdc4")

        XCTAssertEqual(colors.startHex, "#FF6666")
        XCTAssertEqual(colors.endHex, "#4ECDC4")
    }

    func testBoardSurfaceColorsFallBackFromInvalidHexValues() {
        let colors = BoardSurfaceColors(startHex: "not-a-color", endHex: "#12345")

        XCTAssertEqual(colors.startHex, BoardSurfaceColors.defaultStartHex)
        XCTAssertEqual(colors.endHex, BoardSurfaceColors.defaultEndHex)
    }

    func testSettingsClampBoardOpacity() {
        XCTAssertEqual(
            AppSettings(boardOpacity: AppSettings.minimumBoardOpacity - 0.2).boardOpacity,
            AppSettings.minimumBoardOpacity
        )
        XCTAssertEqual(
            AppSettings(boardOpacity: AppSettings.maximumBoardOpacity + 0.2).boardOpacity,
            AppSettings.maximumBoardOpacity
        )
    }

    func testSettingsClampCardOpacity() {
        XCTAssertEqual(
            AppSettings(cardOpacity: AppSettings.minimumCardOpacity - 0.2).cardOpacity,
            AppSettings.minimumCardOpacity
        )
        XCTAssertEqual(
            AppSettings(cardOpacity: AppSettings.maximumCardOpacity + 0.2).cardOpacity,
            AppSettings.maximumCardOpacity
        )
    }

    func testSettingsDefaultBoardOpacityWhenDecodedWithoutField() throws {
        let json = "{}"

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.boardOpacity, AppSettings.defaultBoardOpacity)
        XCTAssertEqual(settings.cardOpacity, AppSettings.defaultCardOpacity)
        XCTAssertEqual(settings.launchAtLoginEnabled, AppSettings.defaultLaunchAtLoginEnabled)
        XCTAssertEqual(settings.boardSlideEdge, AppSettings.defaultBoardSlideEdge)
        XCTAssertEqual(settings.hotKeyConfiguration, AppSettings.defaultHotKeyConfiguration)
        XCTAssertEqual(settings.boardTheme, AppSettings.defaultBoardTheme)
        XCTAssertEqual(settings.boardDisplayMode, AppSettings.defaultBoardDisplayMode)
        XCTAssertEqual(settings.customBoardColorsEnabled, AppSettings.defaultCustomBoardColorsEnabled)
        XCTAssertEqual(settings.customBoardColors, AppSettings.defaultCustomBoardColors)
        XCTAssertEqual(settings.hasSeenQuickStartGuide, AppSettings.defaultHasSeenQuickStartGuide)
    }

    func testSettingsPreservesDecodedLaunchAtLoginValue() throws {
        let json = """
        {
            "launchAtLoginEnabled": true
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertTrue(settings.launchAtLoginEnabled)
    }

    func testSettingsPreservesDecodedBoardSlideEdge() throws {
        let json = """
        {
            "boardSlideEdge": "left"
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.boardSlideEdge, .left)
    }

    func testSettingsPreservesDecodedHotKeyConfiguration() throws {
        let json = """
        {
            "hotKeyConfiguration": {
                "keyCode": 2,
                "modifiers": ["shift", "command"]
            }
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(
            settings.hotKeyConfiguration,
            HotKeyConfiguration(keyCode: 2, modifiers: [.command, .shift])
        )
    }

    func testSettingsDefaultHotKeyConfigurationWhenDecodedShortcutIsInvalid() throws {
        let json = """
        {
            "hotKeyConfiguration": {
                "keyCode": 2,
                "modifiers": []
            }
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.hotKeyConfiguration, AppSettings.defaultHotKeyConfiguration)
    }

    func testSettingsPreservesDecodedBoardTheme() throws {
        let json = """
        {
            "boardTheme": "posterBoard"
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.boardTheme, .posterBoard)
    }

    func testSettingsPreservesDecodedBoardDisplayMode() throws {
        let json = """
        {
            "boardDisplayMode": "compact"
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.boardDisplayMode, .compact)
    }

    func testSettingsPreservesDecodedCustomBoardColorsEnabled() throws {
        let json = """
        {
            "customBoardColorsEnabled": true
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertTrue(settings.customBoardColorsEnabled)
    }

    func testSettingsPreservesDecodedCustomBoardColors() throws {
        let json = """
        {
            "customBoardColors": {
                "startHex": "#1f6feb",
                "endHex": "ff7b72"
            }
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(
            settings.customBoardColors,
            BoardSurfaceColors(startHex: "#1F6FEB", endHex: "#FF7B72")
        )
    }

    func testSettingsPreservesDecodedQuickStartGuideState() throws {
        let json = """
        {
            "hasSeenQuickStartGuide": true
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertTrue(settings.hasSeenQuickStartGuide)
    }

    func testSettingsClampDecodedBoardOpacity() throws {
        let json = """
        {
            "boardOpacity": 0.1
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.boardOpacity, AppSettings.minimumBoardOpacity)
    }

    func testSettingsClampDecodedCardOpacity() throws {
        let json = """
        {
            "cardOpacity": 0.1
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.cardOpacity, AppSettings.minimumCardOpacity)
    }
}
