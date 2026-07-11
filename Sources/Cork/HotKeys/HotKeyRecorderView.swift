import AppKit
import CorkCore
import SwiftUI

struct HotKeyRecorderView: NSViewRepresentable {
    let configuration: HotKeyConfiguration
    let onRecord: (HotKeyConfiguration) -> Void
    let onReject: (String) -> Void

    func makeNSView(context: Context) -> HotKeyRecorderButton {
        let button = HotKeyRecorderButton()
        button.bezelStyle = .rounded
        button.setButtonType(.momentaryPushIn)
        button.toolTip = "Record keyboard shortcut"
        button.onRecord = onRecord
        button.onReject = onReject
        button.configuration = configuration

        return button
    }

    func updateNSView(_ nsView: HotKeyRecorderButton, context: Context) {
        nsView.onRecord = onRecord
        nsView.onReject = onReject
        nsView.configuration = configuration
    }
}

final class HotKeyRecorderButton: NSButton {
    var configuration: HotKeyConfiguration = .default {
        didSet {
            if !isRecording {
                title = HotKeyPresentation.displayName(for: configuration)
            }
        }
    }

    var onRecord: ((HotKeyConfiguration) -> Void)?
    var onReject: ((String) -> Void)?

    private var isRecording = false {
        didSet {
            title = isRecording ? "Recording..." : HotKeyPresentation.displayName(for: configuration)
        }
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 {
            isRecording = false
            return
        }

        let configuration = HotKeyPresentation.configuration(from: event)

        guard configuration.isValid else {
            NSSound.beep()
            onReject?("Choose a shortcut with at least one modifier.")
            return
        }

        isRecording = false
        self.configuration = configuration
        onRecord?(configuration)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }
}
