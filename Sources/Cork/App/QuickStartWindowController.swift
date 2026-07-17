import AppKit
import CorkCore
import SwiftUI

@MainActor
final class QuickStartWindowController {
    private let settingsStore: SettingsStore
    private let onShowBoard: () -> Void
    private let onShowPreferences: () -> Void

    private lazy var window: NSWindow = {
        let hostingController = NSHostingController(
            rootView: QuickStartView(
                settingsStore: settingsStore,
                onShowBoard: { [weak self] in
                    self?.dismissAndShowBoard()
                },
                onShowPreferences: { [weak self] in
                    self?.dismissAndShowPreferences()
                }
            )
        )
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 440),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "Welcome to Cork"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        window.center()
        return window
    }()

    init(
        settingsStore: SettingsStore,
        onShowBoard: @escaping () -> Void,
        onShowPreferences: @escaping () -> Void
    ) {
        self.settingsStore = settingsStore
        self.onShowBoard = onShowBoard
        self.onShowPreferences = onShowPreferences
    }

    func show() {
        if !window.isVisible {
            window.center()
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    private func dismissAndShowBoard() {
        window.orderOut(nil)
        onShowBoard()
    }

    private func dismissAndShowPreferences() {
        window.orderOut(nil)
        onShowPreferences()
    }
}

private struct QuickStartView: View {
    @ObservedObject var settingsStore: SettingsStore
    let onShowBoard: () -> Void
    let onShowPreferences: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(red: 0.68, green: 0.43, blue: 0.22))

                    Image(systemName: "rectangle.stack.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
                .frame(width: 60, height: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to Cork")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Keep the context you need close without leaving your work.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 18) {
                QuickStartRow(
                    systemImage: "keyboard",
                    title: "Call up your board",
                    detail: "Press \(shortcutName) to show Cork. Press it again when Cork is frontmost to hide it."
                )

                QuickStartRow(
                    systemImage: "square.and.arrow.down",
                    title: "Bring in your context",
                    detail: "Drag images, files, links, and text onto the board, or use Add to create a card."
                )

                QuickStartRow(
                    systemImage: "rectangle.3.group",
                    title: "Arrange it your way",
                    detail: "Switch boards from the title bar, hover cards to see their names, and use String to connect ideas."
                )
            }

            Divider()

            HStack {
                Text("Reopen this guide anytime from Settings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("Preferences...") {
                    onShowPreferences()
                }

                Button("Show Cork") {
                    onShowBoard()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(26)
        .frame(width: 560, height: 440)
    }

    private var shortcutName: String {
        HotKeyPresentation.displayName(for: settingsStore.settings.hotKeyConfiguration)
    }
}

private struct QuickStartRow: View {
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color(red: 0.68, green: 0.16, blue: 0.14))
                .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
