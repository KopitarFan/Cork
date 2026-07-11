import AppKit
import CorkCore
import SwiftUI

struct MenuKeyboardShortcut {
    let key: KeyEquivalent
    let modifiers: EventModifiers
}

enum HotKeyPresentation {
    static func displayName(for configuration: HotKeyConfiguration) -> String {
        let modifiers = configuration.modifiers
            .map(symbol(for:))
            .joined()
        let keyName = keyName(for: configuration.keyCode)

        return "\(modifiers)\(keyName)"
    }

    static func menuShortcut(for configuration: HotKeyConfiguration) -> MenuKeyboardShortcut? {
        guard let keyEquivalent = keyEquivalent(for: configuration.keyCode) else {
            return nil
        }

        return MenuKeyboardShortcut(
            key: keyEquivalent,
            modifiers: eventModifiers(for: configuration.modifiers)
        )
    }

    static func configuration(from event: NSEvent) -> HotKeyConfiguration {
        HotKeyConfiguration(
            keyCode: event.keyCode,
            modifiers: hotKeyModifiers(from: event.modifierFlags)
        )
    }

    private static func symbol(for modifier: HotKeyModifier) -> String {
        switch modifier {
        case .command:
            return "⌘"
        case .option:
            return "⌥"
        case .control:
            return "⌃"
        case .shift:
            return "⇧"
        }
    }

    private static func eventModifiers(for modifiers: [HotKeyModifier]) -> EventModifiers {
        modifiers.reduce(EventModifiers()) { result, modifier in
            var result = result

            switch modifier {
            case .command:
                result.insert(.command)
            case .option:
                result.insert(.option)
            case .control:
                result.insert(.control)
            case .shift:
                result.insert(.shift)
            }

            return result
        }
    }

    private static func hotKeyModifiers(from flags: NSEvent.ModifierFlags) -> [HotKeyModifier] {
        var modifiers: [HotKeyModifier] = []

        if flags.contains(.command) {
            modifiers.append(.command)
        }

        if flags.contains(.option) {
            modifiers.append(.option)
        }

        if flags.contains(.control) {
            modifiers.append(.control)
        }

        if flags.contains(.shift) {
            modifiers.append(.shift)
        }

        return modifiers
    }

    private static func keyName(for keyCode: UInt16) -> String {
        keyNames[keyCode] ?? "Key \(keyCode)"
    }

    private static func keyEquivalent(for keyCode: UInt16) -> KeyEquivalent? {
        guard let character = keyEquivalents[keyCode] else {
            return nil
        }

        return KeyEquivalent(Character(character))
    }

    private static let keyNames: [UInt16: String] = [
        0: "A",
        1: "S",
        2: "D",
        3: "F",
        4: "H",
        5: "G",
        6: "Z",
        7: "X",
        8: "C",
        9: "V",
        11: "B",
        12: "Q",
        13: "W",
        14: "E",
        15: "R",
        16: "Y",
        17: "T",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        22: "6",
        23: "5",
        24: "=",
        25: "9",
        26: "7",
        27: "-",
        28: "8",
        29: "0",
        31: "O",
        32: "U",
        34: "I",
        35: "P",
        37: "L",
        38: "J",
        40: "K",
        41: ";",
        43: ",",
        44: "/",
        45: "N",
        46: "M",
        47: ".",
        49: "Space",
        50: "`",
        122: "F1",
        120: "F2",
        99: "F3",
        118: "F4",
        96: "F5",
        97: "F6",
        98: "F7",
        100: "F8",
        101: "F9",
        109: "F10",
        103: "F11",
        111: "F12"
    ]

    private static let keyEquivalents: [UInt16: String] = [
        0: "a",
        1: "s",
        2: "d",
        3: "f",
        4: "h",
        5: "g",
        6: "z",
        7: "x",
        8: "c",
        9: "v",
        11: "b",
        12: "q",
        13: "w",
        14: "e",
        15: "r",
        16: "y",
        17: "t",
        18: "1",
        19: "2",
        20: "3",
        21: "4",
        22: "6",
        23: "5",
        24: "=",
        25: "9",
        26: "7",
        27: "-",
        28: "8",
        29: "0",
        31: "o",
        32: "u",
        34: "i",
        35: "p",
        37: "l",
        38: "j",
        40: "k",
        41: ";",
        43: ",",
        44: "/",
        45: "n",
        46: "m",
        47: ".",
        49: " "
    ]
}
