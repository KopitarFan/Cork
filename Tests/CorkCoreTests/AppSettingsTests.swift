import XCTest
@testable import CorkCore

final class AppSettingsTests: XCTestCase {
    func testSettingsUseDefaultBoardOpacity() {
        let settings = AppSettings()

        XCTAssertEqual(settings.boardOpacity, AppSettings.defaultBoardOpacity)
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

    func testSettingsDefaultBoardOpacityWhenDecodedWithoutField() throws {
        let json = "{}"

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.boardOpacity, AppSettings.defaultBoardOpacity)
        XCTAssertEqual(settings.launchAtLoginEnabled, AppSettings.defaultLaunchAtLoginEnabled)
        XCTAssertEqual(settings.boardSlideEdge, AppSettings.defaultBoardSlideEdge)
        XCTAssertEqual(settings.hotKeyConfiguration, AppSettings.defaultHotKeyConfiguration)
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

    func testSettingsClampDecodedBoardOpacity() throws {
        let json = """
        {
            "boardOpacity": 0.1
        }
        """

        let settings = try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))

        XCTAssertEqual(settings.boardOpacity, AppSettings.minimumBoardOpacity)
    }
}
