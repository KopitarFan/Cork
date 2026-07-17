import AppKit
import ImageIO
import SwiftUI

struct FileImageThumbnailView: View {
    let url: URL
    let securityScopedBookmark: Data?

    @StateObject private var loader = FileImageThumbnailLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderImage
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .onAppear {
            loader.load(url, securityScopedBookmark: securityScopedBookmark)
        }
        .onChange(of: url) { _, nextURL in
            loader.load(nextURL, securityScopedBookmark: securityScopedBookmark)
        }
        .onChange(of: securityScopedBookmark) { _, nextBookmark in
            loader.load(url, securityScopedBookmark: nextBookmark)
        }
        .onDisappear {
            loader.cancel()
        }
    }

    private var placeholderImage: some View {
        Image(systemName: loader.didFail ? "exclamationmark.triangle" : "photo")
            .font(.system(size: 40, weight: .medium))
            .foregroundStyle(.secondary)
    }
}

@MainActor
private final class FileImageThumbnailLoader: ObservableObject {
    @Published private(set) var image: NSImage?
    @Published private(set) var didFail = false

    private var currentCacheKey: String?
    private var isLoading = false
    private var loadToken = UUID()

    func load(_ url: URL, securityScopedBookmark: Data?) {
        let cache = FileImageThumbnailCache.shared
        let cacheKey = cache.cacheKey(
            for: url,
            securityScopedBookmark: securityScopedBookmark
        )

        if currentCacheKey == cacheKey, image != nil || isLoading {
            return
        }

        loadToken = UUID()
        let token = loadToken
        currentCacheKey = cacheKey
        didFail = false

        if let cachedImage = cache.cachedImage(forKey: cacheKey) {
            image = cachedImage
            isLoading = false
            return
        }

        image = nil
        isLoading = true

        cache.loadThumbnail(
            for: url,
            securityScopedBookmark: securityScopedBookmark,
            cacheKey: cacheKey
        ) { [weak self] thumbnail in
            Task { @MainActor [weak self] in
                guard let self, self.loadToken == token else {
                    return
                }

                isLoading = false
                image = thumbnail
                didFail = thumbnail == nil
            }
        }
    }

    func cancel() {
        loadToken = UUID()
        currentCacheKey = nil
        isLoading = false
    }
}

private final class FileImageThumbnailCache {
    static let shared = FileImageThumbnailCache()

    private let maxPixelSize = 1_200
    private let cache = NSCache<NSString, NSImage>()
    private let thumbnailQueue = DispatchQueue(
        label: "com.cork.thumbnail-generation",
        qos: .userInitiated
    )

    private init() {
        cache.countLimit = 200
        cache.totalCostLimit = 128 * 1_024 * 1_024
    }

    func cacheKey(for url: URL, securityScopedBookmark: Data?) -> String {
        SecurityScopedBookmark.withAccess(
            to: securityScopedBookmark,
            fallbackURL: url
        ) { resolvedURL in
            let values = try? resolvedURL.resourceValues(forKeys: [
                .contentModificationDateKey,
                .fileSizeKey
            ])
            let modifiedAt = values?.contentModificationDate?.timeIntervalSinceReferenceDate ?? 0
            let fileSize = values?.fileSize ?? 0

            return [
                resolvedURL.standardizedFileURL.path,
                "\(modifiedAt)",
                "\(fileSize)",
                "\(maxPixelSize)"
            ].joined(separator: "|")
        }
    }

    func cachedImage(forKey cacheKey: String) -> NSImage? {
        cache.object(forKey: cacheKey as NSString)
    }

    func loadThumbnail(
        for url: URL,
        securityScopedBookmark: Data?,
        cacheKey: String,
        completion: @escaping (NSImage?) -> Void
    ) {
        if let cachedImage = cachedImage(forKey: cacheKey) {
            completion(cachedImage)
            return
        }

        thumbnailQueue.async { [cache, maxPixelSize] in
            let image = SecurityScopedBookmark.withAccess(
                to: securityScopedBookmark,
                fallbackURL: url
            ) { resolvedURL in
                Self.makeThumbnail(for: resolvedURL, maxPixelSize: maxPixelSize)
            }

            if let image {
                cache.setObject(
                    image,
                    forKey: cacheKey as NSString,
                    cost: Self.cacheCost(for: image)
                )
            }

            completion(image)
        }
    }

    private static func makeThumbnail(for url: URL, maxPixelSize: Int) -> NSImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]

        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions as CFDictionary) else {
            return nil
        }

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }

    private static func cacheCost(for image: NSImage) -> Int {
        Int(image.size.width * image.size.height * 4)
    }
}
