import Foundation
import UniformTypeIdentifiers

public enum BoardImportSource: Equatable, Sendable {
    case fileURL(URL)
    case webURL(URL)
    case plainText(String)
}

public struct BoardImportResolver: Sendable {
    public init() {}

    public func intents(from sources: [BoardImportSource]) -> [BoardImportIntent] {
        let fileIntents = sources.compactMap { source -> BoardImportIntent? in
            guard case .fileURL(let url) = source else {
                return nil
            }

            if Self.isImageFileURL(url) {
                return .imageFile(
                    url: url,
                    title: Self.defaultTitle(for: url, fallback: "Untitled Image")
                )
            }

            return .fileReference(
                url: url,
                title: Self.defaultTitle(for: url, fallback: "File")
            )
        }

        if !fileIntents.isEmpty {
            return fileIntents
        }

        if let webURL = sources.compactMap(Self.webURL(from:)).first {
            return [
                .webURL(
                    url: webURL,
                    title: Self.defaultTitle(for: webURL)
                )
            ]
        }

        if let text = sources.compactMap(Self.plainText(from:)).first {
            return [
                .plainText(
                    title: Self.defaultTitle(for: text),
                    body: text
                )
            ]
        }

        return []
    }

    private static func webURL(from source: BoardImportSource) -> URL? {
        switch source {
        case .webURL(let url):
            isWebURL(url) ? url : nil
        case .plainText(let value):
            URL(string: value.trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { isWebURL($0) ? $0 : nil }
        case .fileURL:
            nil
        }
    }

    private static func plainText(from source: BoardImportSource) -> String? {
        guard case .plainText(let value) = source else {
            return nil
        }

        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedValue.isEmpty ? nil : trimmedValue
    }

    private static func isImageFileURL(_ url: URL) -> Bool {
        guard url.isFileURL,
              let contentType = UTType(filenameExtension: url.pathExtension)
        else {
            return false
        }

        return contentType.conforms(to: .image)
    }

    private static func isWebURL(_ url: URL) -> Bool {
        guard !url.isFileURL,
              let scheme = url.scheme?.lowercased()
        else {
            return false
        }

        return scheme == "http" || scheme == "https"
    }

    private static func defaultTitle(for url: URL, fallback: String = "Link") -> String {
        if !url.isFileURL,
           let host = url.host(),
           !host.isEmpty {
            return host
        }

        let name = url.deletingPathExtension().lastPathComponent
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? fallback : name
    }

    private static func defaultTitle(for text: String) -> String {
        let firstLine = text.components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !firstLine.isEmpty else {
            return "Text Snippet"
        }

        return String(firstLine.prefix(48))
    }
}
