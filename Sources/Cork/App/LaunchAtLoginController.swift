import Combine
import CorkCore
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isSupported: Bool
    @Published private(set) var isEnabled: Bool
    @Published private(set) var statusMessage: String?

    private let settingsStore: SettingsStore
    private let service: LaunchAtLoginServicing

    convenience init(settingsStore: SettingsStore) {
        self.init(
            settingsStore: settingsStore,
            service: SystemLaunchAtLoginService()
        )
    }

    init(
        settingsStore: SettingsStore,
        service: LaunchAtLoginServicing
    ) {
        self.settingsStore = settingsStore
        self.service = service
        self.isSupported = service.isSupported
        self.isEnabled = settingsStore.settings.launchAtLoginEnabled

        refresh()
    }

    func refresh() {
        isSupported = service.isSupported

        guard isSupported else {
            isEnabled = false
            statusMessage = "Available in packaged app builds."
            return
        }

        let systemState = service.isEnabled
        isEnabled = systemState
        statusMessage = nil
        settingsStore.updateLaunchAtLoginEnabled(systemState)
    }

    func setEnabled(_ shouldEnable: Bool) {
        guard isSupported else {
            isEnabled = false
            statusMessage = "Available in packaged app builds."
            return
        }

        do {
            try service.setEnabled(shouldEnable)
            isEnabled = service.isEnabled
            statusMessage = nil
            settingsStore.updateLaunchAtLoginEnabled(isEnabled)
        } catch {
            isEnabled = service.isEnabled
            statusMessage = error.localizedDescription
            settingsStore.updateLaunchAtLoginEnabled(isEnabled)
        }
    }
}

@MainActor
protocol LaunchAtLoginServicing {
    var isSupported: Bool { get }
    var isEnabled: Bool { get }

    func setEnabled(_ shouldEnable: Bool) throws
}

@MainActor
private struct SystemLaunchAtLoginService: LaunchAtLoginServicing {
    var isSupported: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ shouldEnable: Bool) throws {
        if shouldEnable {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
    }
}
