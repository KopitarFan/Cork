import Foundation

public enum BoardSlideEdge: String, Codable, CaseIterable, Equatable, Sendable {
    case top
    case bottom
    case left
    case right
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
    public static let defaultLaunchAtLoginEnabled = false
    public static let defaultBoardSlideEdge = BoardSlideEdge.top
    public static let defaultHotKeyConfiguration = HotKeyConfiguration.default
    public static let `default` = AppSettings()

    public var boardOpacity: Double
    public var launchAtLoginEnabled: Bool
    public var boardSlideEdge: BoardSlideEdge
    public var hotKeyConfiguration: HotKeyConfiguration

    public init(
        boardOpacity: Double = Self.defaultBoardOpacity,
        launchAtLoginEnabled: Bool = Self.defaultLaunchAtLoginEnabled,
        boardSlideEdge: BoardSlideEdge = Self.defaultBoardSlideEdge,
        hotKeyConfiguration: HotKeyConfiguration = Self.defaultHotKeyConfiguration
    ) {
        self.boardOpacity = Self.clampedBoardOpacity(boardOpacity)
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.boardSlideEdge = boardSlideEdge
        self.hotKeyConfiguration = hotKeyConfiguration.normalizedOrDefault
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let boardOpacity = try container.decodeIfPresent(Double.self, forKey: .boardOpacity)
            ?? Self.defaultBoardOpacity
        let launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled)
            ?? Self.defaultLaunchAtLoginEnabled
        let boardSlideEdge = try container.decodeIfPresent(BoardSlideEdge.self, forKey: .boardSlideEdge)
            ?? Self.defaultBoardSlideEdge
        let hotKeyConfiguration = try container.decodeIfPresent(
            HotKeyConfiguration.self,
            forKey: .hotKeyConfiguration
        ) ?? Self.defaultHotKeyConfiguration

        self.init(
            boardOpacity: boardOpacity,
            launchAtLoginEnabled: launchAtLoginEnabled,
            boardSlideEdge: boardSlideEdge,
            hotKeyConfiguration: hotKeyConfiguration
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(boardOpacity, forKey: .boardOpacity)
        try container.encode(launchAtLoginEnabled, forKey: .launchAtLoginEnabled)
        try container.encode(boardSlideEdge, forKey: .boardSlideEdge)
        try container.encode(hotKeyConfiguration, forKey: .hotKeyConfiguration)
    }

    public static func clampedBoardOpacity(_ value: Double) -> Double {
        min(maximumBoardOpacity, max(minimumBoardOpacity, value))
    }

    private enum CodingKeys: String, CodingKey {
        case boardOpacity
        case launchAtLoginEnabled
        case boardSlideEdge
        case hotKeyConfiguration
    }
}
