import AppKit
import CorkCore
import SwiftUI

@MainActor
final class PreferencesWindowController {
    private let window: NSWindow
    private let launchAtLoginController: LaunchAtLoginController

    init(
        settingsStore: SettingsStore,
        launchAtLoginController: LaunchAtLoginController,
        hotKeyController: HotKeyController
    ) {
        self.launchAtLoginController = launchAtLoginController
        let hostingController = NSHostingController(
            rootView: PreferencesView(
                settingsStore: settingsStore,
                launchAtLoginController: launchAtLoginController,
                hotKeyController: hotKeyController
            )
        )
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 660),
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
        launchAtLoginController.refresh()

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
    @ObservedObject var hotKeyController: HotKeyController

    @State private var hotKeyInputMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Preferences")
                    .font(.title2)
                    .fontWeight(.semibold)

                launchAtLoginSection

                Divider()

                hotKeySection

                Divider()

                opacitySection

                Divider()

                themeSection

                Divider()

                displayModeSection

                Divider()

                slideEdgeSection
            }
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(minWidth: 520, minHeight: 660)
    }

    private var opacitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Board Surface Opacity", systemImage: "circle.lefthalf.filled")

                Spacer()

                Text(boardOpacityPercentage)
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

            HStack {
                Label("Card Opacity", systemImage: "rectangle.on.rectangle")

                Spacer()

                Text(cardOpacityPercentage)
                    .font(.system(.body, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }

            Slider(
                value: Binding(
                    get: {
                        settingsStore.settings.cardOpacity
                    },
                    set: { value in
                        settingsStore.updateCardOpacity(value)
                    }
                ),
                in: AppSettings.minimumCardOpacity...AppSettings.maximumCardOpacity
            )

            HStack {
                Spacer()

                Button("Reset Both") {
                    settingsStore.updateBoardOpacity(AppSettings.defaultBoardOpacity)
                    settingsStore.updateCardOpacity(AppSettings.defaultCardOpacity)
                }
            }
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Board Theme", systemImage: "paintpalette")

            Picker(
                "Board Theme",
                selection: Binding(
                    get: {
                        settingsStore.settings.boardTheme
                    },
                    set: { theme in
                        settingsStore.updateBoardTheme(theme)
                    }
                )
            ) {
                ForEach(BoardTheme.allCases, id: \.self) { theme in
                    Text(title(for: theme))
                        .tag(theme)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Toggle(
                isOn: Binding(
                    get: {
                        settingsStore.settings.customBoardColorsEnabled
                    },
                    set: { isEnabled in
                        settingsStore.updateCustomBoardColorsEnabled(isEnabled)
                    }
                )
            ) {
                Label("Custom Board Colors", systemImage: "eyedropper")
            }
            .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 8) {
                BoardColorPreferenceRow(
                    title: "Title Bar Color",
                    systemImage: "rectangle.topthird.inset.filled",
                    hex: settingsStore.settings.customBoardColors.startHex,
                    color: NSColor(boardHex: settingsStore.settings.customBoardColors.startHex),
                    onChange: { color in
                        settingsStore.updateCustomBoardTitleBarColor(color.boardHexString)
                    }
                )

                BoardColorPreferenceRow(
                    title: "Board Surface Color",
                    systemImage: "rectangle.fill",
                    hex: settingsStore.settings.customBoardColors.endHex,
                    color: NSColor(boardHex: settingsStore.settings.customBoardColors.endHex),
                    onChange: { color in
                        settingsStore.updateCustomBoardSurfaceColor(color.boardHexString)
                    }
                )

                HStack {
                    Button("Swap Colors") {
                        let colors = settingsStore.settings.customBoardColors
                        settingsStore.updateCustomBoardColors(
                            BoardSurfaceColors(
                                startHex: colors.endHex,
                                endHex: colors.startHex
                            )
                        )
                    }

                    Button("Reset Colors") {
                        settingsStore.updateCustomBoardColors(AppSettings.defaultCustomBoardColors)
                    }

                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding(.leading, 20)
            .disabled(!settingsStore.settings.customBoardColorsEnabled)
        }
    }

    private var displayModeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Board Size", systemImage: "rectangle.resize")

            Picker(
                "Board Size",
                selection: Binding(
                    get: {
                        settingsStore.settings.boardDisplayMode
                    },
                    set: { displayMode in
                        settingsStore.updateBoardDisplayMode(displayMode)
                    }
                )
            ) {
                ForEach(BoardDisplayMode.allCases, id: \.self) { displayMode in
                    Text(title(for: displayMode))
                        .tag(displayMode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var slideEdgeSection: some View {
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
    }

    private var hotKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Keyboard Shortcut", systemImage: "keyboard")

            HStack {
                HotKeyRecorderView(
                    configuration: settingsStore.settings.hotKeyConfiguration,
                    onRecord: { configuration in
                        hotKeyInputMessage = nil
                        settingsStore.updateHotKeyConfiguration(configuration)
                    },
                    onReject: { message in
                        hotKeyInputMessage = message
                    }
                )
                .frame(width: 122, height: 28)

                Spacer()

                Button("Reset") {
                    hotKeyInputMessage = nil
                    settingsStore.updateHotKeyConfiguration(.default)
                }
            }

            if let hotKeyStatusMessage {
                Text(hotKeyStatusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var launchAtLoginSection: some View {
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

            if launchAtLoginController.requiresApproval {
                Button("Open Login Items Settings") {
                    launchAtLoginController.openSystemSettings()
                }
            }
        }
    }

    private var boardOpacityPercentage: String {
        let percentage = Int((settingsStore.settings.boardOpacity * 100).rounded())
        return "\(percentage)%"
    }

    private var cardOpacityPercentage: String {
        let percentage = Int((settingsStore.settings.cardOpacity * 100).rounded())
        return "\(percentage)%"
    }

    private var hotKeyStatusMessage: String? {
        hotKeyInputMessage ?? hotKeyController.statusMessage
    }

    private func title(for theme: BoardTheme) -> String {
        switch theme {
        case .corkboard:
            return "Cork"
        case .posterBoard:
            return "Poster"
        case .system:
            return "System"
        }
    }

    private func title(for displayMode: BoardDisplayMode) -> String {
        switch displayMode {
        case .compact:
            return "Compact"
        case .standard:
            return "Standard"
        case .large:
            return "Large"
        }
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

private struct BoardColorPreferenceRow: View {
    let title: String
    let systemImage: String
    let hex: String
    let color: NSColor
    let onChange: (NSColor) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Label(title, systemImage: systemImage)
                .frame(width: 130, alignment: .leading)

            Text(hex)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .leading)

            BoardColorWell(color: color, onChange: onChange)
                .frame(width: 46, height: 24)

            Spacer()
        }
    }
}

private struct BoardColorWell: NSViewRepresentable {
    let color: NSColor
    let onChange: (NSColor) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeNSView(context: Context) -> NSColorWell {
        let colorWell = NSColorWell(frame: NSRect(x: 0, y: 0, width: 46, height: 24))
        colorWell.color = color
        colorWell.isBordered = true
        colorWell.target = context.coordinator
        colorWell.action = #selector(Coordinator.colorDidChange(_:))

        return colorWell
    }

    func updateNSView(_ colorWell: NSColorWell, context: Context) {
        context.coordinator.onChange = onChange

        guard !colorWell.color.matchesBoardColor(color) else {
            return
        }

        colorWell.color = color
    }

    final class Coordinator: NSObject {
        var onChange: (NSColor) -> Void

        init(onChange: @escaping (NSColor) -> Void) {
            self.onChange = onChange
        }

        @objc func colorDidChange(_ sender: NSColorWell) {
            NSColorPanel.shared.showsAlpha = false
            onChange(sender.color)
        }
    }
}

private extension NSColor {
    convenience init(boardHex hex: String) {
        let hexValue = String(hex.dropFirst())
        guard let rgbValue = UInt64(hexValue, radix: 16) else {
            self.init(srgbRed: 0, green: 0, blue: 0, alpha: 1)
            return
        }

        self.init(
            srgbRed: CGFloat((rgbValue >> 16) & 0xFF) / 255,
            green: CGFloat((rgbValue >> 8) & 0xFF) / 255,
            blue: CGFloat(rgbValue & 0xFF) / 255,
            alpha: 1
        )
    }

    var boardHexString: String {
        let color = usingColorSpace(.sRGB) ?? .black
        let red = Self.colorByte(color.redComponent)
        let green = Self.colorByte(color.greenComponent)
        let blue = Self.colorByte(color.blueComponent)

        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    func matchesBoardColor(_ color: NSColor) -> Bool {
        boardHexString == color.boardHexString
    }

    private static func colorByte(_ component: CGFloat) -> Int {
        min(255, max(0, Int((component * 255).rounded())))
    }
}
