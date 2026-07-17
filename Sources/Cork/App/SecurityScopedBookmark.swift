import Foundation

enum SecurityScopedBookmark {
    static func create(for url: URL) -> Data? {
        guard url.isFileURL else {
            return nil
        }

        let didStartAccess = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            return try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            NSLog("Cork could not preserve access to %@: %@", url.path, error.localizedDescription)
            return nil
        }
    }

    static func resolve(_ bookmarkData: Data?, fallbackURL: URL) -> URL {
        guard let bookmarkData else {
            return fallbackURL
        }

        do {
            var isStale = false
            return try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope, .withoutUI],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            NSLog("Cork could not restore access to %@: %@", fallbackURL.path, error.localizedDescription)
            return fallbackURL
        }
    }

    static func withAccess<Result>(
        to bookmarkData: Data?,
        fallbackURL: URL,
        perform operation: (URL) throws -> Result
    ) rethrows -> Result {
        let resolvedURL = resolve(bookmarkData, fallbackURL: fallbackURL)
        let didStartAccess = resolvedURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccess {
                resolvedURL.stopAccessingSecurityScopedResource()
            }
        }

        return try operation(resolvedURL)
    }
}
