import Foundation

public struct JSONBoardRepository: BoardRepository {
    public let fileURL: URL

    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    public static func applicationSupportRepository(
        appName: String = "Cork",
        fileName: String = "boards.json",
        fileManager: FileManager = .default
    ) throws -> JSONBoardRepository {
        let applicationSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = applicationSupportURL.appendingPathComponent(appName, isDirectory: true)
        let fileURL = directoryURL.appendingPathComponent(fileName, isDirectory: false)

        return JSONBoardRepository(fileURL: fileURL, fileManager: fileManager)
    }

    public func loadSnapshot() throws -> BoardLibrarySnapshot? {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(BoardLibrarySnapshot.self, from: data)
    }

    public func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: [.atomic])
    }
}
