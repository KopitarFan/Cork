import AppKit
import CorkCore
import SwiftUI

@MainActor
final class PreferencesWindowController {
    private let window: NSWindow

    init(
        settingsStore: SettingsStore,
        launchAtLoginController: LaunchAtLoginController
    ) {
        let hostingController = NSHostingController(
            rootView: PreferencesView(
                settingsStore: settingsStore,
                launchAtLoginController: launchAtLoginController
            )
        )
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 340),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = hostingController
        window.title = "Cork Preferences"
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.collectionBehavior = [.fullScreenAuxiliary, .moveToActiveSpace]
        window.center()
    }

    func show() {
        if !window.isVisible {
            window.center()
        }

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }
}

private struct PreferencesView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var launchAtLoginController: LaunchAtLoginController

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Preferences")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Board Opacity", systemImage: "circle.lefthalf.filled")

                    Spacer()

                    Text(opacityPercentage)
                        .font(.system(.body, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }

                Slider(
                    value: Binding(
                        get: {
                            settingsStore.settings.boardOpacity
                        },
                        set: { value in
                            settingsStore.updateBoardOpacity(value)
                        }
                    ),
                    in: AppSettings.minimumBoardOpacity...AppSettings.maximumBoardOpacity
                )
            }

            HStack {
                Spacer()

                Button("Reset") {
                    settingsStore.updateBoardOpacity(AppSettings.defaultBoardOpacity)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Label("Slide Edge", systemImage: "rectangle.arrowtriangle.2.inward")

                Picker(
                    "Slide Edge",
                    selection: Binding(
                        get: {
                            settingsStore.settings.boardSlideEdge
                        },
                        set: { edge in
                            settingsStore.updateBoardSlideEdge(edge)
                        }
                    )
                ) {
                    ForEach(BoardSlideEdge.allCases, id: \.self) { edge in
                        Text(title(for: edge))
                            .tag(edge)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle(
                    isOn: Binding(
                        get: {
                            launchAtLoginController.isEnabled
                        },
                        set: { isEnabled in
                            launchAtLoginController.setEnabled(isEnabled)
                        }
                    )
                ) {
                    Label("Launch at Login", systemImage: "power")
                }
                .toggleStyle(.switch)
                .disabled(!launchAtLoginController.isSupported)

                if let statusMessage = launchAtLoginController.statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(22)
        .frame(minWidth: 440, minHeight: 340)
    }

    private var opacityPercentage: String {
        let percentage = Int((settingsStore.settings.boardOpacity * 100).rounded())
        return "\(percentage)%"
    }

    private func title(for edge: BoardSlideEdge) -> String {
        switch edge {
        case .top:
            return "Top"
        case .bottom:
            return "Bottom"
        case .left:
            return "Left"
        case .right:
            return "Right"
        }
    }
}
