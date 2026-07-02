import CorkCore
import SwiftUI

struct BoardCardView: View {
    let item: BoardItem
    let isSelected: Bool

    var body: some View {
        cardContent
            .frame(width: item.frame.size.width, height: item.frame.size.height, alignment: .topLeading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.primary.opacity(isSelected ? 0.12 : 0.08), lineWidth: 1)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.82), lineWidth: 2)
                        .padding(1)
                }
            }
            .shadow(color: .black.opacity(isSelected ? 0.2 : 0.14), radius: isSelected ? 14 : 10, x: 0, y: 5)
            .offset(x: item.frame.origin.x, y: item.frame.origin.y)
            .zIndex(isSelected ? 2 : 1)
            .allowsHitTesting(false)
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
