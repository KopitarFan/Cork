import Foundation

public struct CorkBoard: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isPinned: Bool
    public var sortIndex: Int
    public var items: [BoardItem]
    public var connections: [BoardConnection]

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isPinned: Bool = false,
        sortIndex: Int = 0,
        items: [BoardItem] = [],
        connections: [BoardConnection] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.sortIndex = sortIndex
        self.items = items
        self.connections = connections
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        sortIndex = try container.decodeIfPresent(Int.self, forKey: .sortIndex) ?? 0
        items = try container.decode([BoardItem].self, forKey: .items)
        connections = try container.decodeIfPresent([BoardConnection].self, forKey: .connections) ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(sortIndex, forKey: .sortIndex)
        try container.encode(items, forKey: .items)
        try container.encode(connections, forKey: .connections)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case updatedAt
        case isPinned
        case sortIndex
        case items
        case connections
    }
}

public enum BoardConnectionStyle: String, Codable, CaseIterable, Equatable, Sendable {
    case line
    case string
}

public struct BoardConnection: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var sourceItemID: BoardItem.ID
    public var targetItemID: BoardItem.ID
    public var style: BoardConnectionStyle

    public init(
        id: UUID = UUID(),
        sourceItemID: BoardItem.ID,
        targetItemID: BoardItem.ID,
        style: BoardConnectionStyle
    ) {
        self.id = id
        self.sourceItemID = sourceItemID
        self.targetItemID = targetItemID
        self.style = style
    }

    public func connects(_ firstItemID: BoardItem.ID, _ secondItemID: BoardItem.ID) -> Bool {
        (sourceItemID == firstItemID && targetItemID == secondItemID) ||
            (sourceItemID == secondItemID && targetItemID == firstItemID)
    }

    public func includes(_ itemID: BoardItem.ID) -> Bool {
        sourceItemID == itemID || targetItemID == itemID
    }
}

public enum CardFontDesign: String, Codable, CaseIterable, Equatable, Sendable {
    case system
    case rounded
    case serif
    case monospaced
}

public struct CardAppearance: Codable, Equatable, Sendable {
    public static let `default` = CardAppearance()

    public var backgroundHex: String?
    public var fontDesign: CardFontDesign

    public init(
        backgroundHex: String? = nil,
        fontDesign: CardFontDesign = .rounded
    ) {
        self.backgroundHex = backgroundHex.flatMap(AppColorHex.normalized)
        self.fontDesign = fontDesign
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.init(
            backgroundHex: try container.decodeIfPresent(String.self, forKey: .backgroundHex),
            fontDesign: try container.decodeIfPresent(CardFontDesign.self, forKey: .fontDesign) ?? .rounded
        )
    }

    private enum CodingKeys: String, CodingKey {
        case backgroundHex
        case fontDesign
    }
}

public struct BoardItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var frame: BoardRect
    public var content: BoardItemContent
    public var appearance: CardAppearance

    public init(
        id: UUID = UUID(),
        frame: BoardRect,
        content: BoardItemContent,
        appearance: CardAppearance = .default
    ) {
        self.id = id
        self.frame = frame
        self.content = content
        self.appearance = appearance
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(UUID.self, forKey: .id)
        frame = try container.decode(BoardRect.self, forKey: .frame)
        content = try container.decode(BoardItemContent.self, forKey: .content)
        appearance = try container.decodeIfPresent(CardAppearance.self, forKey: .appearance) ?? .default
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(frame, forKey: .frame)
        try container.encode(content, forKey: .content)
        try container.encode(appearance, forKey: .appearance)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case frame
        case content
        case appearance
    }
}

public enum BoardItemContent: Codable, Equatable, Sendable {
    case text(TextCard)
    case checklist(ChecklistCard)
    case image(ImageCard)
    case url(URLCard)
    case file(FileCard)
    case palette(ColorPaletteCard)

    public var displayTitle: String {
        switch self {
        case .text(let card):
            card.title
        case .checklist(let card):
            card.title
        case .image(let card):
            card.title
        case .url(let card):
            card.title
        case .file(let card):
            card.title
        case .palette(let card):
            card.title
        }
    }
}

public enum TextCardFormat: String, Codable, Equatable, Sendable {
    case plainText
    case markdown
}

public struct TextCard: Codable, Equatable, Sendable {
    public var title: String
    public var body: String
    public var format: TextCardFormat

    public init(
        title: String,
        body: String,
        format: TextCardFormat = .plainText
    ) {
        self.title = title
        self.body = body
        self.format = format
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        title = try container.decode(String.self, forKey: .title)
        body = try container.decode(String.self, forKey: .body)
        format = try container.decodeIfPresent(TextCardFormat.self, forKey: .format) ?? .plainText
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encode(format, forKey: .format)
    }

    private enum CodingKeys: String, CodingKey {
        case title
        case body
        case format
    }
}

public struct ChecklistCard: Codable, Equatable, Sendable {
    public var title: String
    public var entries: [ChecklistEntry]

    public init(title: String, entries: [ChecklistEntry]) {
        self.title = title
        self.entries = entries
    }
}

public struct ChecklistEntry: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var isComplete: Bool

    public init(id: UUID = UUID(), title: String, isComplete: Bool = false) {
        self.id = id
        self.title = title
        self.isComplete = isComplete
    }
}

public struct ImageCard: Codable, Equatable, Sendable {
    public var title: String
    public var source: ImageSource?
    public var securityScopedBookmark: Data?

    public init(
        title: String,
        source: ImageSource? = nil,
        securityScopedBookmark: Data? = nil
    ) {
        self.title = title
        self.source = source
        self.securityScopedBookmark = securityScopedBookmark
    }
}

public enum ImageSource: Codable, Equatable, Sendable {
    case bundledSymbol(String)
    case fileReference(URL)
}

public struct URLCard: Codable, Equatable, Sendable {
    public var title: String
    public var url: URL

    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
}

public struct FileCard: Codable, Equatable, Sendable {
    public var title: String
    public var url: URL
    public var securityScopedBookmark: Data?

    public init(
        title: String,
        url: URL,
        securityScopedBookmark: Data? = nil
    ) {
        self.title = title
        self.url = url
        self.securityScopedBookmark = securityScopedBookmark
    }
}

public struct ColorPaletteCard: Codable, Equatable, Sendable {
    public static let defaultColors = [
        PaletteColor(hex: "#FF6B6B"),
        PaletteColor(hex: "#4ECDC4"),
        PaletteColor(hex: "#FFE66D"),
        PaletteColor(hex: "#292F36")
    ]

    public var title: String
    public var colors: [PaletteColor]

    public init(title: String, colors: [PaletteColor]) {
        self.title = title
        self.colors = colors
    }
}

public struct PaletteColor: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var hex: String
    public var id: String { hex }

    public init(hex: String) {
        self.hex = Self.normalizedHex(hex) ?? "#000000"
    }

    public init?(validating hex: String) {
        guard let normalizedHex = Self.normalizedHex(hex) else {
            return nil
        }

        self.hex = normalizedHex
    }

    public static func colors(from text: String) -> [PaletteColor] {
        text.split { character in
            character == "," ||
                character == ";" ||
                character == "\n" ||
                character == "\t" ||
                character == " "
        }
        .compactMap { PaletteColor(validating: String($0)) }
    }

    private static func normalizedHex(_ value: String) -> String? {
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

public struct BoardRect: Codable, Equatable, Sendable {
    public var origin: BoardPoint
    public var size: BoardSize

    public init(origin: BoardPoint, size: BoardSize) {
        self.origin = origin
        self.size = size
    }
}

public struct BoardPoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct BoardSize: Codable, Equatable, Sendable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }
}

public extension CorkBoard {
    static let sampleBoards: [CorkBoard] = {
        let now = Date(timeIntervalSinceReferenceDate: 802_000_000)

        return [
            CorkBoard(
                id: UUID(uuidString: "9DA2E0FB-8EA1-41E7-B116-F33EC1C5980D")!,
                name: "Writing Desk",
                createdAt: now,
                updatedAt: now,
                items: [
                    BoardItem(
                        id: UUID(uuidString: "DAF4B3ED-6E11-4BA5-A24F-DF355B7F3B45")!,
                        frame: BoardRect(
                            origin: BoardPoint(x: 40, y: 44),
                            size: BoardSize(width: 260, height: 190)
                        ),
                        content: .text(TextCard(
                            title: "Chapter Thread",
                            body: "Keep the old letter visible while revising the scene."
                        ))
                    ),
                    BoardItem(
                        id: UUID(uuidString: "52D5D8C5-9971-4140-AD16-D4567D0DD069")!,
                        frame: BoardRect(
                            origin: BoardPoint(x: 340, y: 82),
                            size: BoardSize(width: 240, height: 210)
                        ),
                        content: .checklist(ChecklistCard(
                            title: "Before Export",
                            entries: [
                                ChecklistEntry(title: "Read ending aloud", isComplete: true),
                                ChecklistEntry(title: "Check continuity"),
                                ChecklistEntry(title: "Send draft")
                            ]
                        ))
                    ),
                    BoardItem(
                        id: UUID(uuidString: "7FDB7B6B-D1F7-47EA-8828-B02A7768D5ED")!,
                        frame: BoardRect(
                            origin: BoardPoint(x: 626, y: 52),
                            size: BoardSize(width: 230, height: 170)
                        ),
                        content: .image(ImageCard(
                            title: "Mood Reference",
                            source: .bundledSymbol("photo.on.rectangle.angled")
                        ))
                    )
                ]
            ),
            CorkBoard(
                id: UUID(uuidString: "2D3D5D22-A0AE-402D-8868-CCAB18B1DA92")!,
                name: "Build Notes",
                createdAt: now,
                updatedAt: now,
                items: [
                    BoardItem(
                        id: UUID(uuidString: "3C1895E4-E638-46D4-90C5-48B2CB7F4718")!,
                        frame: BoardRect(
                            origin: BoardPoint(x: 52, y: 54),
                            size: BoardSize(width: 280, height: 186)
                        ),
                        content: .text(TextCard(
                            title: "Cork MVP",
                            body: "Instant board, native feel, draggable glance cards."
                        ))
                    )
                ]
            )
        ]
    }()
}
