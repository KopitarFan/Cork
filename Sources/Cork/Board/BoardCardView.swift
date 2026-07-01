import CorkCore
import SwiftUI

struct BoardCardView: View {
    let item: BoardItem
    let boardSize: CGSize
    let onMove: (BoardPoint) -> Void

    @State private var dragStart: BoardPoint?

    var body: some View {
        cardContent
            .frame(width: item.frame.size.width, height: item.frame.size.height, alignment: .topLeading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.primary.opacity(0.08), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.14), radius: 10, x: 0, y: 5)
            .position(
                x: item.frame.origin.x + item.frame.size.width / 2,
                y: item.frame.origin.y + item.frame.size.height / 2
            )
            .gesture(dragGesture)
    }

    @ViewBuilder
    private var cardContent: some View {
        switch item.content {
        case .text(let card):
            VStack(alignment: .leading, spacing: 10) {
                CardTitle(title: card.title, systemImage: "note.text")

                Text(card.body)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)

        case .checklist(let card):
            VStack(alignment: .leading, spacing: 10) {
                CardTitle(title: card.title, systemImage: "checklist")

                VStack(alignment: .leading, spacing: 7) {
                    ForEach(card.entries) { entry in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Image(systemName: entry.isComplete ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(entry.isComplete ? .green : .secondary)
                                .frame(width: 14)

                            Text(entry.title)
                                .font(.system(.callout, design: .rounded))
                                .foregroundStyle(entry.isComplete ? .secondary : .primary)
                                .strikethrough(entry.isComplete)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .padding(14)

        case .image(let card):
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(.thinMaterial)

                    Image(systemName: symbolName(for: card))
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.secondary)
                }

                Text(card.title)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
        }
    }

    private var cardBackground: some ShapeStyle {
        switch item.content {
        case .text:
            AnyShapeStyle(Color(nsColor: .textBackgroundColor).opacity(0.95))
        case .checklist:
            AnyShapeStyle(Color(nsColor: .selectedContentBackgroundColor).opacity(0.14))
        case .image:
            AnyShapeStyle(Color(nsColor: .underPageBackgroundColor).opacity(0.92))
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragStart == nil {
                    dragStart = item.frame.origin
                }

                guard let dragStart else {
                    return
                }

                let maxX = max(12, Double(boardSize.width) - item.frame.size.width - 12)
                let maxY = max(12, Double(boardSize.height) - item.frame.size.height - 12)
                let nextOrigin = BoardPoint(
                    x: min(maxX, max(12, dragStart.x + value.translation.width)),
                    y: min(maxY, max(12, dragStart.y + value.translation.height))
                )

                onMove(nextOrigin)
            }
            .onEnded { _ in
                dragStart = nil
            }
    }

    private func symbolName(for card: ImageCard) -> String {
        guard case .bundledSymbol(let symbolName) = card.source else {
            return "photo"
        }

        return symbolName
    }
}

private struct CardTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .lineLimit(1)
        }
    }
}
