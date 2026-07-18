import Foundation

@main
struct GenerateDemoData {
    static func main() throws {
        guard CommandLine.arguments.count == 3 else {
            throw DemoDataError.usage
        }

        let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
        let imageURL = URL(fileURLWithPath: CommandLine.arguments[2])
        let boards = makeBoards(imageURL: imageURL)

        try JSONBoardRepository(
            fileURL: outputDirectory.appendingPathComponent("boards.json")
        ).saveSnapshot(BoardLibrarySnapshot(boards: boards, selectedBoardID: boards[0].id))

        try JSONSettingsRepository(
            fileURL: outputDirectory.appendingPathComponent("settings.json")
        ).saveSettings(AppSettings(
            boardTheme: .corkboard,
            boardDisplayMode: .standard,
            hasSeenQuickStartGuide: true
        ))
    }

    private static func makeBoards(imageURL: URL) -> [CorkBoard] {
        let now = Date(timeIntervalSinceReferenceDate: 806_000_000)

        return [
            launchBoard(now: now, imageURL: imageURL),
            writingBoard(now: now, imageURL: imageURL),
            weeklyBoard(now: now),
            ideaBoard(now: now, imageURL: imageURL)
        ]
    }

    private static func launchBoard(now: Date, imageURL: URL) -> CorkBoard {
        let hero = uuid("10000000-0000-0000-0000-000000000001")
        let note = uuid("10000000-0000-0000-0000-000000000002")
        let checklist = uuid("10000000-0000-0000-0000-000000000003")
        let link = uuid("10000000-0000-0000-0000-000000000004")
        let palette = uuid("10000000-0000-0000-0000-000000000005")
        let file = uuid("10000000-0000-0000-0000-000000000006")

        return CorkBoard(
            id: uuid("10000000-0000-0000-0000-000000000000"),
            name: "Launch Plan",
            createdAt: now,
            updatedAt: now,
            isPinned: true,
            sortIndex: 0,
            items: [
                item(hero, 34, 28, 250, 360, .image(ImageCard(title: "Cork 1.0", source: .fileReference(imageURL)))),
                item(note, 315, 28, 280, 220, .text(TextCard(
                    title: "Launch Story",
                    body: "# Context, one shortcut away\n\nA calm place for the notes and references that matter right now.",
                    format: .markdown
                )), color: "#FFF0B8", font: .serif),
                item(checklist, 625, 28, 270, 250, .checklist(ChecklistCard(
                    title: "Release Day",
                    entries: [
                        ChecklistEntry(title: "Final signed build", isComplete: true),
                        ChecklistEntry(title: "App Store copy", isComplete: true),
                        ChecklistEntry(title: "Capture screenshots"),
                        ChecklistEntry(title: "Submit for review")
                    ]
                )), color: "#DDF3E4"),
                item(palette, 925, 28, 250, 155, .palette(ColorPaletteCard(
                    title: "Launch Colors",
                    colors: ["#1E4D40", "#E56B5D", "#F2C14E", "#F7F4ED"].map(PaletteColor.init)
                )), color: "#F7F4ED"),
                item(link, 315, 280, 280, 145, .url(URLCard(
                    title: "App Store Connect",
                    url: URL(string: "https://appstoreconnect.apple.com")!
                )), color: "#DDEBFA"),
                item(file, 625, 312, 270, 130, .file(FileCard(
                    title: "Cork Release Build",
                    url: URL(fileURLWithPath: "/Applications/Cork.app")
                )), color: "#EEE8F7"),
                item(uuid("10000000-0000-0000-0000-000000000007"), 925, 220, 250, 205, .text(TextCard(
                    title: "Keep It Close",
                    body: "Open with Command-Option-B.\n\nGlance, act, and get back to work."
                )), color: "#FFD9D2")
            ],
            connections: [
                connection("10000000-0000-0000-0000-000000000101", hero, note, .string),
                connection("10000000-0000-0000-0000-000000000102", note, checklist, .string),
                connection("10000000-0000-0000-0000-000000000103", checklist, palette, .line),
                connection("10000000-0000-0000-0000-000000000104", note, link, .line)
            ]
        )
    }

    private static func writingBoard(now: Date, imageURL: URL) -> CorkBoard {
        let image = uuid("20000000-0000-0000-0000-000000000001")
        let character = uuid("20000000-0000-0000-0000-000000000002")
        let beats = uuid("20000000-0000-0000-0000-000000000003")
        let palette = uuid("20000000-0000-0000-0000-000000000004")
        let line = uuid("20000000-0000-0000-0000-000000000005")

        return CorkBoard(
            id: uuid("20000000-0000-0000-0000-000000000000"),
            name: "Writing Room",
            createdAt: now,
            updatedAt: now,
            sortIndex: 1,
            items: [
                item(image, 42, 36, 310, 370, .image(ImageCard(title: "Visual North Star", source: .fileReference(imageURL)))),
                item(character, 390, 36, 320, 235, .text(TextCard(
                    title: "Character Note",
                    body: "## What she wants\nTo leave without becoming the person everyone expects.\n\n**What she needs:** a reason to stay.",
                    format: .markdown
                )), color: "#FFF2B5", font: .serif),
                item(beats, 750, 36, 310, 270, .checklist(ChecklistCard(
                    title: "Scene Beats",
                    entries: [
                        ChecklistEntry(title: "The unopened letter", isComplete: true),
                        ChecklistEntry(title: "A knock at the door"),
                        ChecklistEntry(title: "The choice"),
                        ChecklistEntry(title: "Last image")
                    ]
                )), color: "#E3F0E7", font: .serif),
                item(palette, 390, 300, 320, 165, .palette(ColorPaletteCard(
                    title: "Evening Palette",
                    colors: ["#25324A", "#7D8CA3", "#D6B483", "#F2E9DC"].map(PaletteColor.init)
                )), color: "#F5EEE4"),
                item(line, 750, 340, 385, 115, .text(TextCard(
                    title: "Opening Line",
                    body: "The letter had been waiting longer than either of them."
                )), color: "#F7D9DA", font: .serif)
            ],
            connections: [
                connection("20000000-0000-0000-0000-000000000101", image, character, .line),
                connection("20000000-0000-0000-0000-000000000102", character, beats, .string),
                connection("20000000-0000-0000-0000-000000000103", character, line, .string)
            ]
        )
    }

    private static func weeklyBoard(now: Date) -> CorkBoard {
        let monday = uuid("30000000-0000-0000-0000-000000000001")
        let tuesday = uuid("30000000-0000-0000-0000-000000000002")
        let wednesday = uuid("30000000-0000-0000-0000-000000000003")
        let focus = uuid("30000000-0000-0000-0000-000000000004")

        return CorkBoard(
            id: uuid("30000000-0000-0000-0000-000000000000"),
            name: "Weekly Focus",
            createdAt: now,
            updatedAt: now,
            sortIndex: 2,
            items: [
                item(monday, 42, 40, 260, 335, checklist("Monday", ["Plan the week", "Review draft", "Team check-in"], complete: 1), color: "#FFF0B8"),
                item(tuesday, 330, 40, 260, 335, checklist("Tuesday", ["Deep work block", "Design review", "Update notes"], complete: 1), color: "#DDEBFA"),
                item(wednesday, 618, 40, 260, 335, checklist("Wednesday", ["Ship the build", "Capture feedback", "Write follow-up"], complete: 0), color: "#DDF3E4"),
                item(focus, 915, 40, 260, 200, .text(TextCard(
                    title: "This Week",
                    body: "Make the next step obvious.\n\nKeep meetings light.\nProtect the morning."
                )), color: "#FFD9D2"),
                item(uuid("30000000-0000-0000-0000-000000000005"), 915, 265, 260, 165, .palette(ColorPaletteCard(
                    title: "Energy",
                    colors: ["#E56B5D", "#F2C14E", "#4E8D7C", "#355070"].map(PaletteColor.init)
                )), color: "#F7F4ED")
            ],
            connections: []
        )
    }

    private static func ideaBoard(now: Date, imageURL: URL) -> CorkBoard {
        let center = uuid("40000000-0000-0000-0000-000000000001")
        let insight = uuid("40000000-0000-0000-0000-000000000002")
        let evidence = uuid("40000000-0000-0000-0000-000000000003")
        let question = uuid("40000000-0000-0000-0000-000000000004")
        let next = uuid("40000000-0000-0000-0000-000000000005")

        return CorkBoard(
            id: uuid("40000000-0000-0000-0000-000000000000"),
            name: "Idea Map",
            createdAt: now,
            updatedAt: now,
            sortIndex: 3,
            items: [
                item(center, 455, 155, 290, 245, .image(ImageCard(title: "The Big Idea", source: .fileReference(imageURL)))),
                item(insight, 55, 42, 290, 180, .text(TextCard(title: "Insight", body: "Context works best when it stays visible without demanding attention.")), color: "#FFF0B8"),
                item(evidence, 55, 285, 290, 150, .url(URLCard(title: "Research Notes", url: URL(string: "https://developer.apple.com/design/human-interface-guidelines/")!)), color: "#DDEBFA"),
                item(question, 850, 42, 300, 180, .text(TextCard(title: "Question", body: "What belongs beside the work, rather than inside another app?")), color: "#FFD9D2"),
                item(next, 850, 285, 300, 150, checklist("Next Experiments", ["Watch real workflows", "Reduce friction", "Polish the motion"], complete: 1), color: "#DDF3E4")
            ],
            connections: [
                connection("40000000-0000-0000-0000-000000000101", center, insight, .string),
                connection("40000000-0000-0000-0000-000000000102", center, evidence, .string),
                connection("40000000-0000-0000-0000-000000000103", center, question, .string),
                connection("40000000-0000-0000-0000-000000000104", center, next, .string)
            ]
        )
    }

    private static func item(
        _ id: UUID,
        _ x: Double,
        _ y: Double,
        _ width: Double,
        _ height: Double,
        _ content: BoardItemContent,
        color: String? = nil,
        font: CardFontDesign = .rounded
    ) -> BoardItem {
        BoardItem(
            id: id,
            frame: BoardRect(origin: BoardPoint(x: x, y: y), size: BoardSize(width: width, height: height)),
            content: content,
            appearance: CardAppearance(backgroundHex: color, fontDesign: font)
        )
    }

    private static func checklist(
        _ title: String,
        _ entries: [String],
        complete count: Int
    ) -> BoardItemContent {
        .checklist(ChecklistCard(
            title: title,
            entries: entries.enumerated().map { index, title in
                ChecklistEntry(title: title, isComplete: index < count)
            }
        ))
    }

    private static func connection(
        _ id: String,
        _ source: UUID,
        _ target: UUID,
        _ style: BoardConnectionStyle
    ) -> BoardConnection {
        BoardConnection(id: uuid(id), sourceItemID: source, targetItemID: target, style: style)
    }

    private static func uuid(_ value: String) -> UUID {
        UUID(uuidString: value)!
    }
}

private enum DemoDataError: LocalizedError {
    case usage

    var errorDescription: String? {
        "Usage: GenerateDemoData <output-directory> <image-path>"
    }
}
