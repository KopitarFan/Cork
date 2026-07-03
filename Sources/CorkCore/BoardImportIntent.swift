import Foundation

public enum BoardImportIntent: Equatable, Sendable {
    case imageFile(url: URL, title: String)
    case plainText(title: String, body: String)
    case webURL(url: URL, title: String)
    case fileReference(url: URL, title: String)
}
