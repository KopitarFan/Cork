import AppKit
import Foundation
import WebKit

@main
@MainActor
struct CaptureWebsite {
    private static var delegate: CaptureDelegate?

    static func main() {
        guard CommandLine.arguments.count == 5,
              let width = Double(CommandLine.arguments[3]),
              let height = Double(CommandLine.arguments[4])
        else {
            FileHandle.standardError.write(
                Data("Usage: CaptureWebsite <page-path> <output-path> <width> <height>\n".utf8)
            )
            exit(2)
        }

        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let delegate = CaptureDelegate(
            pagePath: CommandLine.arguments[1],
            outputPath: CommandLine.arguments[2],
            viewport: CGSize(width: width, height: height)
        )
        self.delegate = delegate
        app.delegate = delegate
        app.run()
    }
}

@MainActor
private final class CaptureDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    private let pagePath: String
    private let fragment: String?
    private let galleryTabIndex: Int?
    private let outputPath: String
    private let viewport: CGSize
    private var window: NSWindow?
    private var webView: WKWebView?

    init(pagePath: String, outputPath: String, viewport: CGSize) {
        let components = pagePath.split(separator: "#", maxSplits: 1).map(String.init)
        let fragmentComponents = components.count == 2
            ? components[1].split(separator: ":", maxSplits: 1).map(String.init)
            : []
        self.pagePath = components[0]
        self.fragment = fragmentComponents.first
        self.galleryTabIndex = fragmentComponents.count == 2 ? Int(fragmentComponents[1]) : nil
        self.outputPath = outputPath
        self.viewport = viewport
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        let webView = WKWebView(frame: CGRect(origin: .zero, size: viewport))
        webView.navigationDelegate = self

        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: viewport),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.contentView = webView
        window.setFrameOrigin(NSPoint(x: -10_000, y: -10_000))
        window.orderFrontRegardless()

        self.window = window
        self.webView = webView

        let fileURL = URL(fileURLWithPath: pagePath)

        var siteRoot = fileURL.deletingLastPathComponent()
        while siteRoot.lastPathComponent != "Website",
              siteRoot.pathComponents.count > 1 {
            siteRoot.deleteLastPathComponent()
        }
        webView.loadFileURL(fileURL, allowingReadAccessTo: siteRoot)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let script: String
        if let fragment {
            let galleryAction = galleryTabIndex.map {
                "var tab = document.querySelectorAll('[data-gallery-tab]')[\($0)]; if (tab) { tab.click(); }"
            } ?? ""
            script = "var target = document.getElementById('\(fragment)'); if (target) { window.scrollTo(0, target.offsetTop - 88); } \(galleryAction)"
        } else {
            script = "window.scrollTo(0, 0);"
        }

        webView.evaluateJavaScript(script) { [weak self] _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self?.capture(webView)
            }
        }
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: any Error
    ) {
        fail(error.localizedDescription)
    }

    private func capture(_ webView: WKWebView) {
        let configuration = WKSnapshotConfiguration()
        configuration.rect = CGRect(origin: .zero, size: viewport)

        webView.takeSnapshot(with: configuration) { [weak self] image, error in
            guard let self else { return }

            do {
                if let error { throw error }
                guard let image,
                      let tiff = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiff),
                      let png = bitmap.representation(using: .png, properties: [:])
                else {
                    throw CaptureError.couldNotEncode
                }

                try png.write(to: URL(fileURLWithPath: outputPath), options: .atomic)
                NSApp.terminate(nil)
            } catch {
                fail(error.localizedDescription)
            }
        }
    }

    private func fail(_ message: String) {
        FileHandle.standardError.write(Data("Website capture failed: \(message)\n".utf8))
        NSApp.terminate(nil)
    }
}

private enum CaptureError: Error {
    case couldNotEncode
}
