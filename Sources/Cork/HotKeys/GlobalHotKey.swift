import Carbon
import Foundation

struct HotKeyModifiers: OptionSet {
    let rawValue: UInt32

    static let command = HotKeyModifiers(rawValue: UInt32(cmdKey))
    static let option = HotKeyModifiers(rawValue: UInt32(optionKey))
    static let control = HotKeyModifiers(rawValue: UInt32(controlKey))
    static let shift = HotKeyModifiers(rawValue: UInt32(shiftKey))
}

enum GlobalHotKeyError: LocalizedError {
    case registrationFailed(OSStatus)
    case eventHandlerFailed(OSStatus)

    var errorDescription: String? {
        switch self {
        case .registrationFailed(let status):
            "Hot key registration failed with status \(status)."
        case .eventHandlerFailed(let status):
            "Hot key event handler installation failed with status \(status)."
        }
    }
}

final class GlobalHotKey {
    private let keyCode: UInt32
    private let modifiers: HotKeyModifiers
    private let handler: () -> Void
    private let signature = fourCharacterCode("CORK")
    private let identifier = UInt32(1)

    private var hotKeyReference: EventHotKeyRef?
    private var eventHandlerReference: EventHandlerRef?

    init(keyCode: UInt32, modifiers: HotKeyModifiers, handler: @escaping () -> Void) {
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.handler = handler
    }

    deinit {
        unregister()
    }

    func register() throws {
        let hotKeyID = EventHotKeyID(signature: signature, id: identifier)
        let registrationStatus = RegisterEventHotKey(
            keyCode,
            modifiers.rawValue,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyReference
        )

        guard registrationStatus == noErr else {
            throw GlobalHotKeyError.registrationFailed(registrationStatus)
        }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            hotKeyEventHandler,
            1,
            &eventType,
            selfPointer,
            &eventHandlerReference
        )

        guard handlerStatus == noErr else {
            unregister()
            throw GlobalHotKeyError.eventHandlerFailed(handlerStatus)
        }
    }

    private func unregister() {
        if let hotKeyReference {
            UnregisterEventHotKey(hotKeyReference)
            self.hotKeyReference = nil
        }

        if let eventHandlerReference {
            RemoveEventHandler(eventHandlerReference)
            self.eventHandlerReference = nil
        }
    }

    fileprivate func handleEvent(_ event: EventRef?) {
        var eventHotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &eventHotKeyID
        )

        guard status == noErr,
              eventHotKeyID.signature == signature,
              eventHotKeyID.id == identifier
        else {
            return
        }

        DispatchQueue.main.async { [handler] in
            handler()
        }
    }
}

private let hotKeyEventHandler: EventHandlerUPP = { _, event, userData in
    guard let userData else {
        return noErr
    }

    let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(userData).takeUnretainedValue()
    hotKey.handleEvent(event)
    return noErr
}

private func fourCharacterCode(_ value: String) -> UInt32 {
    precondition(value.utf8.count == 4)

    return value.utf8.reduce(0) { partialResult, character in
        (partialResult << 8) + UInt32(character)
    }
}
