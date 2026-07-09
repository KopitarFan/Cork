public protocol SettingsRepository {
    func loadSettings() throws -> AppSettings?
    func saveSettings(_ settings: AppSettings) throws
}
