import Foundation

public struct CorkBoard: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date
    public var items: [BoardItem]

    public init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        items: [BoardItem] = []
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.items = items
    }
}

public struct BoardItem: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var frame: BoardRect
    public var content: BoardItemContent

    public init(id: UUID = UUID(), frame: BoardRect, content: BoardItemContent) {
        self.id = id
        self.frame = frame
        self.content = content
    }
}

public enum BoardItemContent: Codable, Equatable, Sendable {
    case text(TextCard)
    case checklist(ChecklistCard)
    case image(ImageCard)

    public var displayTitle: String {
        switch self {
        case .text(let card):
            card.title
        case .checklist(let card):
            card.title
        case .image(let card):
            card.title
        }
    }
}

public struct TextCard: Codable, Equatable, Sendable {
    public var title: String
    public var body: String

    public init(title: String, body: String) {
        self.title = title
        self.body = body
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

    public init(title: String, source: ImageSource? = nil) {
        self.title = title
        self.source = source
    }
}

public enum ImageSource: Codable, Equatable, Sendable {
    case bundledSymbol(String)
    case fileReference(URL)
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
