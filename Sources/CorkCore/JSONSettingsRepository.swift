import Foundation

public struct JSONSettingsRepository: SettingsRepository {
    public let fileURL: URL

    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public static func applicationSupportRepository(
        appName: String = "Cork",
        fileName: String = "settings.json",
        fileManager: FileManager = .default
    ) throws -> JSONSettingsRepository {
        let applicationSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = applicationSupportURL.appendingPathComponent(appName, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)

        return JSONSettingsRepository(fileURL: fileURL, fileManager: fileManager)
    }

    public func loadSettings() throws -> AppSettings? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(AppSettings.self, from: data)
    }

    public func saveSettings(_ settings: AppSettings) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(settings)
        try data.write(to: fileURL, options: [.atomic])
    }
}
