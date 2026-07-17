import Foundation

public enum BoardSlideEdge: String, Codable, CaseIterable, Equatable, Sendable {
    case top
    case bottom
    case left
    case right
}

public enum BoardTheme: String, Codable, CaseIterable, Equatable, Sendable {
    case corkboard
    case posterBoard
    case system
}

public enum BoardDisplayMode: String, Codable, CaseIterable, Equatable, Sendable {
    case compact
    case standard
    case large
}

public struct BoardSurfaceColors: Codable, Equatable, Sendable {
    public static let defaultStartHex = "#AD7A4A"
    public static let defaultEndHex = "#855936"
    public static let `default` = BoardSurfaceColors()

    public var startHex: String
    public var endHex: String

    public init(
        startHex: String = Self.defaultStartHex,
        endHex: String = Self.defaultEndHex
    ) {
        self.startHex = AppColorHex.normalized(startHex) ?? Self.defaultStartHex
        self.endHex = AppColorHex.normalized(endHex) ?? Self.defaultEndHex
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let startHex = try container.decodeIfPresent(String.self, forKey: .startHex)
            ?? Self.defaultStartHex
        let endHex = try container.decodeIfPresent(String.self, forKey: .endHex)
            ?? Self.defaultEndHex

        self.init(startHex: startHex, endHex: endHex)
    }

    public func withStartHex(_ startHex: String) -> BoardSurfaceColors {
        BoardSurfaceColors(startHex: startHex, endHex: endHex)
    }

    public func withEndHex(_ endHex: String) -> BoardSurfaceColors {
        BoardSurfaceColors(startHex: startHex, endHex: endHex)
    }

    private enum CodingKeys: String, CodingKey {
        case startHex
        case endHex
    }
}

public enum AppColorHex {
    public static func normalized(_ value: String) -> String? {
        let trimmedValue = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let expandedValue: String

        switch trimmedValue.count {
        case 3:
            expandedValue = trimmedValue.map { "\($0)\($0)" }.joined()
        case 6:
            expandedValue = trimmedValue
        default:
            return nil
        }

        let hexCharacters = CharacterSet(charactersIn: "0123456789ABCDEFabcdef")
        guard expandedValue.unicodeScalars.allSatisfy({ hexCharacters.contains($0) }) else {
            return nil
        }

        return "#\(expandedValue.uppercased())"
    }
}

public enum HotKeyModifier: String, Codable, CaseIterable, Equatable, Sendable {
    case command
    case option
    case control
    case shift
}

public struct HotKeyConfiguration: Codable, Equatable, Sendable {
    public static let defaultKeyCode: UInt16 = 11
    public static let defaultModifiers: [HotKeyModifier] = [.command, .option]
    public static let `default` = HotKeyConfiguration(
        keyCode: defaultKeyCode,
        modifiers: defaultModifiers
    )

    public var keyCode: UInt16
    public var modifiers: [HotKeyModifier]

    public init(
        keyCode: UInt16 = Self.defaultKeyCode,
        modifiers: [HotKeyModifier] = Self.defaultModifiers
    ) {
        self.keyCode = keyCode
        self.modifiers = Self.normalizedModifiers(modifiers)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let keyCode = try container.decode(UInt16.self, forKey: .keyCode)
        let modifiers = try container.decode([HotKeyModifier].self, forKey: .modifiers)

        self.init(keyCode: keyCode, modifiers: modifiers)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifiers, forKey: .modifiers)
    }

    public var isValid: Bool {
        !modifiers.isEmpty
    }

    public var normalizedOrDefault: HotKeyConfiguration {
        isValid ? self : .default
    }

    private static func normalizedModifiers(_ modifiers: [HotKeyModifier]) -> [HotKeyModifier] {
        let uniqueModifiers = Set(modifiers)

        return HotKeyModifier.allCases.filter { uniqueModifiers.contains($0) }
    }

    private enum CodingKeys: String, CodingKey {
        case keyCode
        case modifiers
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultBoardOpacity = 1.0
    public static let minimumBoardOpacity = 0.55
    public static let maximumBoardOpacity = 1.0
    public static let defaultCardOpacity = 1.0
    public static let minimumCardOpacity = 0.35
    public static let maximumCardOpacity = 1.0
    public static let defaultLaunchAtLoginEnabled = false
    public static let defaultBoardSlideEdge = BoardSlideEdge.top
    public static let defaultHotKeyConfiguration = HotKeyConfiguration.default
    public static let defaultBoardTheme = BoardTheme.corkboard
    public static let defaultBoardDisplayMode = BoardDisplayMode.standard
    public static let defaultCustomBoardColorsEnabled = false
    public static let defaultCustomBoardColors = BoardSurfaceColors.default
    public static let defaultHasSeenQuickStartGuide = false
    public static let `default` = AppSettings()

    public var boardOpacity: Double
    public var cardOpacity: Double
    public var launchAtLoginEnabled: Bool
    public var boardSlideEdge: BoardSlideEdge
    public var hotKeyConfiguration: HotKeyConfiguration
    public var boardTheme: BoardTheme
    public var boardDisplayMode: BoardDisplayMode
    public var customBoardColorsEnabled: Bool
    public var customBoardColors: BoardSurfaceColors
    public var hasSeenQuickStartGuide: Bool

    public init(
        boardOpacity: Double = Self.defaultBoardOpacity,
        cardOpacity: Double = Self.defaultCardOpacity,
        launchAtLoginEnabled: Bool = Self.defaultLaunchAtLoginEnabled,
        boardSlideEdge: BoardSlideEdge = Self.defaultBoardSlideEdge,
        hotKeyConfiguration: HotKeyConfiguration = Self.defaultHotKeyConfiguration,
        boardTheme: BoardTheme = Self.defaultBoardTheme,
        boardDisplayMode: BoardDisplayMode = Self.defaultBoardDisplayMode,
        customBoardColorsEnabled: Bool = Self.defaultCustomBoardColorsEnabled,
        customBoardColors: BoardSurfaceColors = Self.defaultCustomBoardColors,
        hasSeenQuickStartGuide: Bool = Self.defaultHasSeenQuickStartGuide
    ) {
        self.boardOpacity = Self.clampedBoardOpacity(boardOpacity)
        self.cardOpacity = Self.clampedCardOpacity(cardOpacity)
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.boardSlideEdge = boardSlideEdge
        self.hotKeyConfiguration = hotKeyConfiguration.normalizedOrDefault
        self.boardTheme = boardTheme
        self.boardDisplayMode = boardDisplayMode
        self.customBoardColorsEnabled = customBoardColorsEnabled
        self.customBoardColors = customBoardColors
        self.hasSeenQuickStartGuide = hasSeenQuickStartGuide
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let boardOpacity = try container.decodeIfPresent(Double.self, forKey: .boardOpacity)
            ?? Self.defaultBoardOpacity
        let cardOpacity = try container.decodeIfPresent(Double.self, forKey: .cardOpacity)
            ?? Self.defaultCardOpacity
        let launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled)
            ?? Self.defaultLaunchAtLoginEnabled
        let boardSlideEdge = try container.decodeIfPresent(BoardSlideEdge.self, forKey: .boardSlideEdge)
            ?? Self.defaultBoardSlideEdge
        let hotKeyConfiguration = try container.decodeIfPresent(
            HotKeyConfiguration.self,
            forKey: .hotKeyConfiguration
        ) ?? Self.defaultHotKeyConfiguration
        let boardTheme = try container.decodeIfPresent(BoardTheme.self, forKey: .boardTheme)
            ?? Self.defaultBoardTheme
        let boardDisplayMode = try container.decodeIfPresent(BoardDisplayMode.self, forKey: .boardDisplayMode)
            ?? Self.defaultBoardDisplayMode
        let customBoardColorsEnabled = try container.decodeIfPresent(
            Bool.self,
            forKey: .customBoardColorsEnabled
        ) ?? Self.defaultCustomBoardColorsEnabled
        let customBoardColors = try container.decodeIfPresent(
            BoardSurfaceColors.self,
            forKey: .customBoardColors
        ) ?? Self.defaultCustomBoardColors
        let hasSeenQuickStartGuide = try container.decodeIfPresent(
            Bool.self,
            forKey: .hasSeenQuickStartGuide
        ) ?? Self.defaultHasSeenQuickStartGuide
        self.init(
            boardOpacity: boardOpacity,
            cardOpacity: cardOpacity,
            launchAtLoginEnabled: launchAtLoginEnabled,
            boardSlideEdge: boardSlideEdge,
            hotKeyConfiguration: hotKeyConfiguration,
            boardTheme: boardTheme,
            boardDisplayMode: boardDisplayMode,
            customBoardColorsEnabled: customBoardColorsEnabled,
            customBoardColors: customBoardColors,
            hasSeenQuickStartGuide: hasSeenQuickStartGuide
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(boardOpacity, forKey: .boardOpacity)
        try container.encode(cardOpacity, forKey: .cardOpacity)
        try container.encode(launchAtLoginEnabled, forKey: .launchAtLoginEnabled)
        try container.encode(boardSlideEdge, forKey: .boardSlideEdge)
        try container.encode(hotKeyConfiguration, forKey: .hotKeyConfiguration)
        try container.encode(boardTheme, forKey: .boardTheme)
        try container.encode(boardDisplayMode, forKey: .boardDisplayMode)
        try container.encode(customBoardColorsEnabled, forKey: .customBoardColorsEnabled)
        try container.encode(customBoardColors, forKey: .customBoardColors)
        try container.encode(hasSeenQuickStartGuide, forKey: .hasSeenQuickStartGuide)
    }

    public static func clampedBoardOpacity(_ value: Double) -> Double {
        min(maximumBoardOpacity, max(minimumBoardOpacity, value))
    }

    public static func clampedCardOpacity(_ value: Double) -> Double {
        min(maximumCardOpacity, max(minimumCardOpacity, value))
    }

    private enum CodingKeys: String, CodingKey {
        case boardOpacity
        case cardOpacity
        case launchAtLoginEnabled
        case boardSlideEdge
        case hotKeyConfiguration
        case boardTheme
        case boardDisplayMode
        case customBoardColorsEnabled
        case customBoardColors
        case hasSeenQuickStartGuide
    }
}
