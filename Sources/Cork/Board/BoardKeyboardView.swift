import AppKit
import SwiftUI

struct BoardKeyboardView: NSViewRepresentable {
    var onKeyDown: (NSEvent) -> Bool

    func makeNSView(context: Context) -> KeyboardMonitorView {
        let view = KeyboardMonitorView()
        view.onKeyDown = onKeyDown
        return view
    }

    func updateNSView(_ nsView: KeyboardMonitorView, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
}

final class KeyboardMonitorView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    private var keyDownMonitor: Any?

    deinit {
        if let keyDownMonitor {
            NSEvent.removeMonitor(keyDownMonitor)
        }
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        if window == nil {
            removeKeyDownMonitor()
        } else {
            installKeyDownMonitor()
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        nil
    }

    private func installKeyDownMonitor() {
        guard keyDownMonitor == nil else {
            return
        }

        keyDownMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self,
                  window?.isKeyWindow == true,
                  onKeyDown?(event) == true
            else {
                return event
            }

            return nil
        }
    }

    private func removeKeyDownMonitor() {
        guard let keyDownMonitor else {
            return
        }

        NSEvent.removeMonitor(keyDownMonitor)
        self.keyDownMonitor = nil
    }
}
