import Combine
import CorkCore
import Foundation
import ServiceManagement

@MainActor
final class LaunchAtLoginController: ObservableObject {
    @Published private(set) var isSupported: Bool
    @Published private(set) var isEnabled: Bool
    @Published private(set) var requiresApproval: Bool
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
        self.isEnabled = false
        self.requiresApproval = false

        refresh()
    }

    func refresh() {
        isSupported = service.isSupported

        guard isSupported else {
            isEnabled = false
            requiresApproval = false
            statusMessage = "Available in packaged app builds."
            return
        }

        apply(service.status)
    }

    func setEnabled(_ shouldEnable: Bool) {
        guard isSupported else {
            isEnabled = false
            requiresApproval = false
            statusMessage = "Available in packaged app builds."
            return
        }

        do {
            try service.setEnabled(shouldEnable)
            apply(service.status)
        } catch {
            apply(service.status, errorMessage: error.localizedDescription)
        }
    }

    func openSystemSettings() {
        service.openSystemSettings()
    }

    private func apply(
        _ status: LaunchAtLoginServiceStatus,
        errorMessage: String? = nil
    ) {
        switch status {
        case .disabled:
            isEnabled = false
            requiresApproval = false
            statusMessage = errorMessage
        case .enabled:
            isEnabled = true
            requiresApproval = false
            statusMessage = nil
        case .requiresApproval:
            isEnabled = false
            requiresApproval = true
            statusMessage = "Allow Cork under Login Items in System Settings to finish enabling this option."
        case .unavailable:
            isEnabled = false
            requiresApproval = false
            statusMessage = errorMessage ?? "Cork could not read its Login Items status."
        }

        settingsStore.updateLaunchAtLoginEnabled(isEnabled)
    }
}

enum LaunchAtLoginServiceStatus {
    case disabled
    case enabled
    case requiresApproval
    case unavailable
}

@MainActor
protocol LaunchAtLoginServicing {
    var isSupported: Bool { get }
    var status: LaunchAtLoginServiceStatus { get }

    func setEnabled(_ shouldEnable: Bool) throws
    func openSystemSettings()
}

@MainActor
private struct SystemLaunchAtLoginService: LaunchAtLoginServicing {
    var isSupported: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    var status: LaunchAtLoginServiceStatus {
        switch SMAppService.mainApp.status {
        case .notRegistered:
            return .disabled
        case .enabled:
            return .enabled
        case .requiresApproval:
            return .requiresApproval
        case .notFound:
            return .unavailable
        @unknown default:
            return .unavailable
        }
    }

    func setEnabled(_ shouldEnable: Bool) throws {
        let status = SMAppService.mainApp.status

        if shouldEnable {
            if status == .notRegistered {
                try SMAppService.mainApp.register()
            }
        } else if status == .enabled || status == .requiresApproval {
            try SMAppService.mainApp.unregister()
        }
    }

    func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
