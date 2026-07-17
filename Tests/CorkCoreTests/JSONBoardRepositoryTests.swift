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

    func testRoundTripPreservesSecurityScopedBookmarks() throws {
        let fileURL = makeTemporaryFileURL()
        let repository = JSONBoardRepository(fileURL: fileURL)
        let imageURL = URL(fileURLWithPath: "/tmp/image.png")
        let documentURL = URL(fileURLWithPath: "/tmp/document.pdf")
        let imageBookmark = Data([0x01, 0x02, 0x03])
        let documentBookmark = Data([0x04, 0x05, 0x06])
        let board = CorkBoard(
            name: "Persisted",
            items: [
                BoardItem(
                    frame: BoardRect(
                        origin: BoardPoint(x: 10, y: 10),
                        size: BoardSize(width: 200, height: 180)
                    ),
                    content: .image(ImageCard(
                        title: "Image",
                        source: .fileReference(imageURL),
                        securityScopedBookmark: imageBookmark
                    ))
                ),
                BoardItem(
                    frame: BoardRect(
                        origin: BoardPoint(x: 230, y: 10),
                        size: BoardSize(width: 220, height: 160)
                    ),
                    content: .file(FileCard(
                        title: "Document",
                        url: documentURL,
                        securityScopedBookmark: documentBookmark
                    ))
                )
            ]
        )
        let snapshot = BoardLibrarySnapshot(boards: [board], selectedBoardID: board.id)

        try repository.saveSnapshot(snapshot)
        let loadedSnapshot = try XCTUnwrap(repository.loadSnapshot())

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
