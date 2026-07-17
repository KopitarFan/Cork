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
    public func updateCardOpacity(_ value: Double) -> Bool {
        let cardOpacity = AppSettings.clampedCardOpacity(value)

        guard settings.cardOpacity != cardOpacity else {
            return false
        }

        settings.cardOpacity = cardOpacity
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

    @discardableResult
    public func updateBoardTheme(_ theme: BoardTheme) -> Bool {
        guard settings.boardTheme != theme else {
            return false
        }

        settings.boardTheme = theme
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func updateBoardDisplayMode(_ displayMode: BoardDisplayMode) -> Bool {
        guard settings.boardDisplayMode != displayMode else {
            return false
        }

        settings.boardDisplayMode = displayMode
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func updateCustomBoardColorsEnabled(_ isEnabled: Bool) -> Bool {
        guard settings.customBoardColorsEnabled != isEnabled else {
            return false
        }

        settings.customBoardColorsEnabled = isEnabled
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func updateCustomBoardColors(_ colors: BoardSurfaceColors) -> Bool {
        guard settings.customBoardColors != colors else {
            return false
        }

        settings.customBoardColors = colors
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func updateCustomBoardTitleBarColor(_ hex: String) -> Bool {
        updateCustomBoardColors(settings.customBoardColors.withStartHex(hex))
    }

    @discardableResult
    public func updateCustomBoardSurfaceColor(_ hex: String) -> Bool {
        updateCustomBoardColors(settings.customBoardColors.withEndHex(hex))
    }

    @discardableResult
    public func updateHotKeyConfiguration(_ configuration: HotKeyConfiguration) -> Bool {
        guard configuration.isValid else {
            return false
        }

        let configuration = configuration.normalizedOrDefault

        guard settings.hotKeyConfiguration != configuration else {
            return false
        }

        settings.hotKeyConfiguration = configuration
        scheduleAutosave()

        return true
    }

    @discardableResult
    public func markQuickStartGuideSeen() -> Bool {
        guard !settings.hasSeenQuickStartGuide else {
            return false
        }

        settings.hasSeenQuickStartGuide = true
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
