import AppKit
import CorkCore

struct BoardDropResolver {
    static let supportedPasteboardTypes: [NSPasteboard.PasteboardType] = [
        .fileURL,
        .URL,
        .string
    ]

    private let importResolver = BoardImportResolver()

    func importIntents(from pasteboard: NSPasteboard) -> [BoardImportIntent] {
        importResolver.intents(from: importSources(from: pasteboard))
    }

    func securityScopedBookmarks(for intents: [BoardImportIntent]) -> [URL: Data] {
        var bookmarks: [URL: Data] = [:]

        for intent in intents {
            let fileURL: URL?

            switch intent {
            case .imageFile(let url, _), .fileReference(let url, _):
                fileURL = url
            case .plainText, .webURL:
                fileURL = nil
            }

            guard let fileURL,
                  bookmarks[fileURL] == nil,
                  let bookmark = SecurityScopedBookmark.create(for: fileURL)
            else {
                continue
            }

            bookmarks[fileURL] = bookmark
        }

        return bookmarks
    }

    private func importSources(from pasteboard: NSPasteboard) -> [BoardImportSource] {
        fileURLs(from: pasteboard).map(BoardImportSource.fileURL) +
            webURLs(from: pasteboard).map(BoardImportSource.webURL) +
            plainTexts(from: pasteboard).map(BoardImportSource.plainText)
    }

    private func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        let objects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) ?? []

        return objects.compactMap { object in
            if let url = object as? URL {
                return url
            }

            if let url = object as? NSURL {
                return url as URL
            }

            return nil
        }
    }

    private func webURLs(from pasteboard: NSPasteboard) -> [URL] {
        let objects = pasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: false]
        ) ?? []

        return objects.compactMap { object in
            if let url = object as? URL {
                return url
            }

            if let url = object as? NSURL {
                return url as URL
            }

            return nil
        }
        .filter { !$0.isFileURL }
    }

    private func plainTexts(from pasteboard: NSPasteboard) -> [String] {
        let values = [
            pasteboard.string(forType: .URL),
            pasteboard.string(forType: .string)
        ]

        return values.compactMap { value in
            let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmedValue?.isEmpty == false ? trimmedValue : nil
        }
    }
}
