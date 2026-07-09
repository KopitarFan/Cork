import Foundation

public enum BoardSlideEdge: String, Codable, CaseIterable, Equatable, Sendable {
    case top
    case bottom
    case left
    case right
}

public struct AppSettings: Codable, Equatable, Sendable {
    public static let defaultBoardOpacity = 1.0
    public static let minimumBoardOpacity = 0.55
    public static let maximumBoardOpacity = 1.0
    public static let defaultLaunchAtLoginEnabled = false
    public static let defaultBoardSlideEdge = BoardSlideEdge.top
    public static let `default` = AppSettings()

    public var boardOpacity: Double
    public var launchAtLoginEnabled: Bool
    public var boardSlideEdge: BoardSlideEdge

    public init(
        boardOpacity: Double = Self.defaultBoardOpacity,
        launchAtLoginEnabled: Bool = Self.defaultLaunchAtLoginEnabled,
        boardSlideEdge: BoardSlideEdge = Self.defaultBoardSlideEdge
    ) {
        self.boardOpacity = Self.clampedBoardOpacity(boardOpacity)
        self.launchAtLoginEnabled = launchAtLoginEnabled
        self.boardSlideEdge = boardSlideEdge
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let boardOpacity = try container.decodeIfPresent(Double.self, forKey: .boardOpacity)
            ?? Self.defaultBoardOpacity
        let launchAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .launchAtLoginEnabled)
            ?? Self.defaultLaunchAtLoginEnabled
        let boardSlideEdge = try container.decodeIfPresent(BoardSlideEdge.self, forKey: .boardSlideEdge)
            ?? Self.defaultBoardSlideEdge

        self.init(
            boardOpacity: boardOpacity,
            launchAtLoginEnabled: launchAtLoginEnabled,
            boardSlideEdge: boardSlideEdge
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(boardOpacity, forKey: .boardOpacity)
        try container.encode(launchAtLoginEnabled, forKey: .launchAtLoginEnabled)
        try container.encode(boardSlideEdge, forKey: .boardSlideEdge)
    }

    public static func clampedBoardOpacity(_ value: Double) -> Double {
        min(maximumBoardOpacity, max(minimumBoardOpacity, value))
    }

    private enum CodingKeys: String, CodingKey {
        case boardOpacity
        case launchAtLoginEnabled
        case boardSlideEdge
    }
}
