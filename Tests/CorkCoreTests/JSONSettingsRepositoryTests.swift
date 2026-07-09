import XCTest
@testable import CorkCore

final class JSONSettingsRepositoryTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryDirectories {
            try? FileManager.default.removeItem(at: url)
        }

        temporaryDirectories.removeAll()
    }

    func testLoadingMissingFileReturnsNil() throws {
        let repository = JSONSettingsRepository(fileURL: makeTemporaryFileURL())

        let settings = try repository.loadSettings()

        XCTAssertNil(settings)
    }

    func testSaveCreatesParentDirectoryAndRoundTripsSettings() throws {
        let fileURL = makeTemporaryFileURL()
        let repository = JSONSettingsRepository(fileURL: fileURL)
        let settings = AppSettings(
            boardOpacity: 0.72,
            launchAtLoginEnabled: true,
            boardSlideEdge: .right
        )

        try repository.saveSettings(settings)
        let loadedSettings = try repository.loadSettings()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(loadedSettings, settings)
    }

    func testLoadingInvalidJSONThrows() throws {
        let fileURL = makeTemporaryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(to: fileURL)
        let repository = JSONSettingsRepository(fileURL: fileURL)

        XCTAssertThrowsError(try repository.loadSettings())
    }

    private func makeTemporaryFileURL() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorkSettingsTests-\(UUID().uuidString)", isDirectory: true)
        temporaryDirectories.append(directoryURL)

        return directoryURL
            .appendingPathComponent("Nested", isDirectory: true)
            .appendingPathComponent("settings.json", isDirectory: false)
    }
}
