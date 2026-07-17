import Foundation

public enum BoardTemplate: String, CaseIterable, Identifiable, Sendable {
    case agile
    case kanban
    case visionBoard
    case scheduling
    case randomArrangement
    case projectHub
    case writingRoom
    case swotAnalysis

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .agile:
            return "Agile Sprint"
        case .kanban:
            return "Kanban"
        case .visionBoard:
            return "Vision Board"
        case .scheduling:
            return "Weekly Schedule"
        case .randomArrangement:
            return "Random Arrangement"
        case .projectHub:
            return "Project Hub"
        case .writingRoom:
            return "Writing Room"
        case .swotAnalysis:
            return "SWOT Analysis"
        }
    }

    public var summary: String {
        switch self {
        case .agile:
            return "A sprint goal with backlog, active work, review, and done columns."
        case .kanban:
            return "A simple four-column flow for tracking work."
        case .visionBoard:
            return "Image placeholders, an intention, and a supporting color palette."
        case .scheduling:
            return "A weekday plan with one checklist for each day."
        case .randomArrangement:
            return "A loose mix of notes, images, tasks, and colors for freeform thinking."
        case .projectHub:
            return "Goals, status, actions, decisions, and working notes in one view."
        case .writingRoom:
            return "Premise, characters, scene beats, references, and visual tone."
        case .swotAnalysis:
            return "A four-quadrant strengths, weaknesses, opportunities, and threats board."
        }
    }

    public var systemImageName: String {
        switch self {
        case .agile:
            return "figure.run"
        case .kanban:
            return "rectangle.split.3x1"
        case .visionBoard:
            return "sparkles.rectangle.stack"
        case .scheduling:
            return "calendar"
        case .randomArrangement:
            return "square.3.layers.3d.down.right"
        case .projectHub:
            return "scope"
        case .writingRoom:
            return "pencil.and.outline"
        case .swotAnalysis:
            return "square.grid.2x2"
        }
    }

    public func makeItems() -> [BoardItem] {
        switch self {
        case .agile:
            return agileItems
        case .kanban:
            return kanbanItems
        case .visionBoard:
            return visionBoardItems
        case .scheduling:
            return schedulingItems
        case .randomArrangement:
            return randomArrangementItems
        case .projectHub:
            return projectHubItems
        case .writingRoom:
            return writingRoomItems
        case .swotAnalysis:
            return swotAnalysisItems
        }
    }

    private var agileItems: [BoardItem] {
        [
            Self.text(
                title: "Sprint Goal",
                body: "What meaningful outcome should this sprint deliver?",
                x: 20,
                y: 18,
                width: 780,
                height: 92,
                backgroundHex: "#FFF1B8",
                fontDesign: .serif
            ),
            Self.checklist(
                title: "Backlog",
                entries: ["Choose the next highest-value task", "Clarify acceptance criteria"],
                x: 20,
                y: 128,
                width: 185,
                height: 200,
                backgroundHex: "#E9F0F8"
            ),
            Self.checklist(
                title: "In Progress",
                entries: ["Move active work here"],
                x: 220,
                y: 128,
                width: 185,
                height: 200,
                backgroundHex: "#DCEEFF"
            ),
            Self.checklist(
                title: "Review",
                entries: ["Validate completed work"],
                x: 420,
                y: 128,
                width: 185,
                height: 200,
                backgroundHex: "#F1E5F7"
            ),
            Self.checklist(
                title: "Done",
                entries: ["Celebrate shipped work"],
                x: 620,
                y: 128,
                width: 185,
                height: 200,
                backgroundHex: "#DDF5E5"
            )
        ]
    }

    private var kanbanItems: [BoardItem] {
        [
            Self.checklist(
                title: "Ideas",
                entries: ["Capture incoming work", "Add useful context"],
                x: 20,
                y: 24,
                width: 185,
                height: 286,
                backgroundHex: "#EEF1F5"
            ),
            Self.checklist(
                title: "Ready",
                entries: ["Prioritized and ready to begin"],
                x: 220,
                y: 24,
                width: 185,
                height: 286,
                backgroundHex: "#FFF1B8"
            ),
            Self.checklist(
                title: "Doing",
                entries: ["Keep active work limited"],
                x: 420,
                y: 24,
                width: 185,
                height: 286,
                backgroundHex: "#DCEEFF"
            ),
            Self.checklist(
                title: "Done",
                entries: ["Completed work lands here"],
                x: 620,
                y: 24,
                width: 185,
                height: 286,
                backgroundHex: "#DDF5E5"
            )
        ]
    }

    private var visionBoardItems: [BoardItem] {
        [
            Self.image(title: "Reference 1", x: 20, y: 20, width: 220, height: 140),
            Self.text(
                title: "Intention",
                body: "Describe the feeling, direction, or future you want this board to hold.",
                x: 260,
                y: 20,
                width: 300,
                height: 140,
                backgroundHex: "#FFF1B8",
                fontDesign: .serif
            ),
            Self.image(title: "Reference 2", x: 580, y: 20, width: 220, height: 140),
            Self.image(title: "Reference 3", x: 20, y: 180, width: 220, height: 140),
            Self.palette(
                title: "Visual Language",
                colors: ["#F6BD60", "#F7EDE2", "#84A59D", "#F28482"],
                x: 260,
                y: 180,
                width: 300,
                height: 140,
                backgroundHex: "#F7EDE2"
            ),
            Self.image(title: "Reference 4", x: 580, y: 180, width: 220, height: 140)
        ]
    }

    private var schedulingItems: [BoardItem] {
        let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        let colors = ["#FDE2E4", "#FAD2E1", "#E2ECE9", "#BEE1E6", "#FFF1B8"]

        return zip(days.indices, days).map { index, day in
            Self.checklist(
                title: day,
                entries: ["Top priority", "Appointment or focus block", "Small follow-up"],
                x: 20 + (Double(index) * 158),
                y: 24,
                width: 144,
                height: 286,
                backgroundHex: colors[index],
                fontDesign: .system
            )
        }
    }

    private var randomArrangementItems: [BoardItem] {
        [
            Self.text(
                title: "Loose Thought",
                body: "Start anywhere. Rearrange as the idea takes shape.",
                x: 44,
                y: 32,
                width: 250,
                height: 160,
                backgroundHex: "#FFF1B8",
                fontDesign: .serif
            ),
            Self.image(title: "Drop an Image", x: 326, y: 18, width: 210, height: 148),
            Self.checklist(
                title: "Things to Try",
                entries: ["Follow the interesting thread", "Remove what does not belong"],
                x: 570,
                y: 52,
                width: 220,
                height: 190,
                backgroundHex: "#DCEEFF",
                fontDesign: .rounded
            ),
            Self.palette(
                title: "Unexpected Colors",
                colors: ["#FF6B6B", "#4ECDC4", "#FFE66D", "#292F36"],
                x: 66,
                y: 220,
                width: 270,
                height: 136,
                backgroundHex: "#F7EDE2"
            ),
            Self.text(
                title: "Question",
                body: "What would make this more surprising?",
                x: 368,
                y: 194,
                width: 228,
                height: 132,
                backgroundHex: "#F1E5F7",
                fontDesign: .monospaced
            ),
            Self.image(title: "Another Reference", x: 624, y: 256, width: 176, height: 128)
        ]
    }

    private var projectHubItems: [BoardItem] {
        [
            Self.text(
                title: "Project Goal",
                body: "Define the outcome, audience, and reason this project matters.",
                x: 20,
                y: 20,
                width: 380,
                height: 130,
                backgroundHex: "#FFF1B8",
                fontDesign: .serif
            ),
            Self.text(
                title: "Status",
                body: "Current state, latest progress, and the most important constraint.",
                x: 420,
                y: 20,
                width: 380,
                height: 130,
                backgroundHex: "#DCEEFF"
            ),
            Self.checklist(
                title: "Next Actions",
                entries: ["Choose the next concrete step", "Name the owner", "Set a review point"],
                x: 20,
                y: 170,
                width: 250,
                height: 166,
                backgroundHex: "#DDF5E5"
            ),
            Self.text(
                title: "Decisions",
                body: "Record decisions and the reasoning you will want later.",
                x: 290,
                y: 170,
                width: 250,
                height: 166,
                backgroundHex: "#F1E5F7"
            ),
            Self.text(
                title: "Working Notes",
                body: "Keep links, snippets, questions, and loose context here.",
                x: 560,
                y: 170,
                width: 240,
                height: 166,
                fontDesign: .monospaced
            )
        ]
    }

    private var writingRoomItems: [BoardItem] {
        [
            Self.text(
                title: "Premise",
                body: "A one-paragraph promise of the story.",
                x: 20,
                y: 20,
                width: 300,
                height: 130,
                backgroundHex: "#FFF1B8",
                fontDesign: .serif
            ),
            Self.text(
                title: "Character Want",
                body: "What do they want, and what do they actually need?",
                x: 340,
                y: 20,
                width: 220,
                height: 130,
                backgroundHex: "#FDE2E4",
                fontDesign: .serif
            ),
            Self.image(title: "Mood Reference", x: 580, y: 20, width: 220, height: 130),
            Self.checklist(
                title: "Scene Beats",
                entries: ["Opening image", "Turn or reveal", "Closing change"],
                x: 20,
                y: 170,
                width: 300,
                height: 170,
                backgroundHex: "#E2ECE9",
                fontDesign: .serif
            ),
            Self.text(
                title: "Lines to Keep",
                body: "Paste fragments, dialogue, and images of language here.",
                x: 340,
                y: 170,
                width: 220,
                height: 170,
                backgroundHex: "#F7EDE2",
                fontDesign: .serif
            ),
            Self.palette(
                title: "Tone",
                colors: ["#2F4858", "#33658A", "#86BBD8", "#F6AE2D"],
                x: 580,
                y: 170,
                width: 220,
                height: 170,
                backgroundHex: "#EEF1F5",
                fontDesign: .serif
            )
        ]
    }

    private var swotAnalysisItems: [BoardItem] {
        [
            Self.text(
                title: "Strengths",
                body: "Internal advantages, assets, and capabilities.",
                x: 20,
                y: 20,
                width: 380,
                height: 140,
                backgroundHex: "#DDF5E5"
            ),
            Self.text(
                title: "Weaknesses",
                body: "Internal limitations, gaps, and friction.",
                x: 420,
                y: 20,
                width: 380,
                height: 140,
                backgroundHex: "#FDE2E4"
            ),
            Self.text(
                title: "Opportunities",
                body: "External openings, trends, and possibilities.",
                x: 20,
                y: 180,
                width: 380,
                height: 140,
                backgroundHex: "#DCEEFF"
            ),
            Self.text(
                title: "Threats",
                body: "External risks, constraints, and uncertainties.",
                x: 420,
                y: 180,
                width: 380,
                height: 140,
                backgroundHex: "#FFF1B8"
            )
        ]
    }

    private static func text(
        title: String,
        body: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        backgroundHex: String? = nil,
        fontDesign: CardFontDesign = .rounded
    ) -> BoardItem {
        item(
            content: .text(TextCard(title: title, body: body)),
            x: x,
            y: y,
            width: width,
            height: height,
            backgroundHex: backgroundHex,
            fontDesign: fontDesign
        )
    }

    private static func checklist(
        title: String,
        entries: [String],
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        backgroundHex: String? = nil,
        fontDesign: CardFontDesign = .rounded
    ) -> BoardItem {
        item(
            content: .checklist(ChecklistCard(
                title: title,
                entries: entries.map { ChecklistEntry(title: $0) }
            )),
            x: x,
            y: y,
            width: width,
            height: height,
            backgroundHex: backgroundHex,
            fontDesign: fontDesign
        )
    }

    private static func image(
        title: String,
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) -> BoardItem {
        item(
            content: .image(ImageCard(title: title)),
            x: x,
            y: y,
            width: width,
            height: height,
            fontDesign: .rounded
        )
    }

    private static func palette(
        title: String,
        colors: [String],
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        backgroundHex: String? = nil,
        fontDesign: CardFontDesign = .rounded
    ) -> BoardItem {
        item(
            content: .palette(ColorPaletteCard(
                title: title,
                colors: colors.map { PaletteColor(hex: $0) }
            )),
            x: x,
            y: y,
            width: width,
            height: height,
            backgroundHex: backgroundHex,
            fontDesign: fontDesign
        )
    }

    private static func item(
        content: BoardItemContent,
        x: Double,
        y: Double,
        width: Double,
        height: Double,
        backgroundHex: String? = nil,
        fontDesign: CardFontDesign
    ) -> BoardItem {
        BoardItem(
            frame: BoardRect(
                origin: BoardPoint(x: x, y: y),
                size: BoardSize(width: width, height: height)
            ),
            content: content,
            appearance: CardAppearance(
                backgroundHex: backgroundHex,
                fontDesign: fontDesign
            )
        )
    }
}
