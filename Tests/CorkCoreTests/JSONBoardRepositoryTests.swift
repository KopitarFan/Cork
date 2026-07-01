import XCTest
@testable import CorkCore

final class JSONBoardRepositoryTests: XCTestCase {
    private var temporaryDirectories: [URL] = []

    override func tearDownWithError() throws {
        for url in temporaryDirectories {
            try? FileManager.default.removeItem(at: url)
        }

        temporaryDirectories.removeAll()
    }

    func testLoadingMissingFileReturnsNil() throws {
        let repository = JSONBoardRepository(fileURL: makeTemporaryFileURL())

        let snapshot = try repository.loadSnapshot()

        XCTAssertNil(snapshot)
    }

    func testSaveCreatesParentDirectoryAndRoundTripsSnapshot() throws {
        let fileURL = makeTemporaryFileURL()
        let repository = JSONBoardRepository(fileURL: fileURL)
        let board = CorkBoard(name: "Persisted")
        let snapshot = BoardLibrarySnapshot(boards: [board], selectedBoardID: board.id)

        try repository.saveSnapshot(snapshot)
        let loadedSnapshot = try repository.loadSnapshot()

        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        XCTAssertEqual(loadedSnapshot, snapshot)
    }

    func testLoadingInvalidJSONThrows() throws {
        let fileURL = makeTemporaryFileURL()
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("not json".utf8).write(to: fileURL)
        let repository = JSONBoardRepository(fileURL: fileURL)

        XCTAssertThrowsError(try repository.loadSnapshot())
    }

    private func makeTemporaryFileURL() -> URL {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("CorkTests-\(UUID().uuidString)", isDirectory: true)
        temporaryDirectories.append(directoryURL)

        return directoryURL
            .appendingPathComponent("Nested", isDirectory: true)
            .appendingPathComponent("boards.json", isDirectory: false)
    }
}
