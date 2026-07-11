import Combine
import CorkCore
import Foundation

@MainActor
final class HotKeyController: ObservableObject {
    @Published private(set) var statusMessage: String?
    @Published private(set) var registeredConfiguration: HotKeyConfiguration?

    private let settingsStore: SettingsStore
    private let handler: () -> Void
    private var globalHotKey: GlobalHotKey?
    private var cancellables: Set<AnyCancellable> = []
    private var didStart = false

    init(settingsStore: SettingsStore, handler: @escaping () -> Void) {
        self.settingsStore = settingsStore
        self.handler = handler
    }

    func start() {
        guard !didStart else {
            return
        }

        didStart = true

        settingsStore.$settings
            .map(\.hotKeyConfiguration)
            .removeDuplicates()
            .sink { [weak self] configuration in
                self?.register(configuration)
            }
            .store(in: &cancellables)
    }

    private func register(_ configuration: HotKeyConfiguration) {
        guard configuration.isValid else {
            globalHotKey = nil
            registeredConfiguration = nil
            statusMessage = "Choose a shortcut with at least one modifier."
            return
        }

        let hotKey = GlobalHotKey(
            keyCode: UInt32(configuration.keyCode),
            modifiers: carbonModifiers(for: configuration)
        ) { [weak self] in
            self?.handler()
        }

        globalHotKey = nil

        do {
            try hotKey.register()
            globalHotKey = hotKey
            registeredConfiguration = configuration
            statusMessage = nil
        } catch {
            registeredConfiguration = nil
            statusMessage = error.localizedDescription
            NSLog("Cork could not register hot key \(HotKeyPresentation.displayName(for: configuration)): \(error.localizedDescription)")
        }
    }

    private func carbonModifiers(for configuration: HotKeyConfiguration) -> HotKeyModifiers {
        configuration.modifiers.reduce(HotKeyModifiers()) { result, modifier in
            var result = result

            switch modifier {
            case .command:
                result.insert(.command)
            case .option:
                result.insert(.option)
            case .control:
                result.insert(.control)
            case .shift:
                result.insert(.shift)
            }

            return result
        }
    }
}
