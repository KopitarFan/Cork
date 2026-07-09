import Combine
import Foundation

@MainActor
public final class SettingsStore: ObservableObject {
    @Published public private(set) var settings: AppSettings
    @Published public private(set) var lastPersistenceError: Error?

    private let repository: SettingsRepository?
    private let autosaveDelay: TimeInterval
    private var autosaveTask: Task<Void, Never>?

    public init(
        settings: AppSettings = .default,
        repository: SettingsRepository? = nil,
        autosaveDelay: TimeInterval = 0.25
    ) {
        self.settings = settings
        self.repository = repository
        self.autosaveDelay = autosaveDelay
    }

    @discardableResult
    public func updateBoardOpacity(_ value: Double) -> Bool {
        let boardOpacity = AppSettings.clampedBoardOpacity(value)

        guard settings.boardOpacity != boardOpacity else {
            return false
        }

        settings.boardOpacity = boardOpacity
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func updateLaunchAtLoginEnabled(_ isEnabled: Bool) -> Bool {
        guard settings.launchAtLoginEnabled != isEnabled else {
            return false
        }

        settings.launchAtLoginEnabled = isEnabled
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func updateBoardSlideEdge(_ edge: BoardSlideEdge) -> Bool {
        guard settings.boardSlideEdge != edge else {
            return false
        }

        settings.boardSlideEdge = edge
        scheduleAutosave()

        return true
    }

    public func flushPendingAutosave() {
        autosaveTask?.cancel()
        autosaveTask = nil
        saveSettings(settings)
    }

    private func scheduleAutosave() {
        guard repository != nil else {
            return
        }

        autosaveTask?.cancel()

        let settings = settings

        guard autosaveDelay > 0 else {
            saveSettings(settings)
            return
        }

        let nanoseconds = UInt64(autosaveDelay * 1_000_000_000)
        autosaveTask = Task { @MainActor [weak self, settings] in
            try? await Task.sleep(nanoseconds: nanoseconds)

            guard !Task.isCancelled else {
                return
            }

            self?.saveSettings(settings)
        }
    }

    private func saveSettings(_ settings: AppSettings) {
        do {
            try repository?.saveSettings(settings)
            lastPersistenceError = nil
        } catch {
            lastPersistenceError = error
        }
    }
}
