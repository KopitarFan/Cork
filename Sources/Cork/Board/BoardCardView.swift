import CorkCore
import AppKit
import SwiftUI

struct BoardCardView: View {
    let item: BoardItem
    let isSelected: Bool
    let isHovered: Bool

    var body: some View {
        cardContent
            .frame(width: item.frame.size.width, height: item.frame.size.height, alignment: .topLeading)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(.primary.opacity(isSelected || isHovered ? 0.14 : 0.08), lineWidth: 1)
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.82), lineWidth: 2)
                        .padding(1)
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    ResizeHandle()
                        .padding(5)
                }
            }
            .shadow(
                color: .black.opacity(isSelected ? 0.2 : (isHovered ? 0.17 : 0.14)),
                radius: isSelected ? 14 : (isHovered ? 12 : 10),
                x: 0,
                y: isSelected || isHovered ? 6 : 5
            )
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
                    .lineLimit(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipped()

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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipped()

        case .image(let card):
            VStack(spacing: 10) {
                imagePreview(for: card)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(card.title)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
        }
    }

    @ViewBuilder
    private func imagePreview(for card: ImageCard) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(.thinMaterial)

            switch card.source {
            case .fileReference(let url):
                FileImageThumbnailView(url: url)
            case .bundledSymbol(let symbolName):
                Image(systemName: symbolName)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(.secondary)
            case nil:
                placeholderImage
            }
        }
    }

    private var placeholderImage: some View {
        Image(systemName: "photo")
            .font(.system(size: 40, weight: .medium))
            .foregroundStyle(.secondary)
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
}

private struct ResizeHandle: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(.regularMaterial)

            Canvas { context, size in
                let color = Color.secondary.opacity(0.72)

                for offset in [CGFloat(4), CGFloat(8), CGFloat(12)] {
                    var path = Path()
                    path.move(to: CGPoint(x: size.width - offset, y: size.height))
                    path.addLine(to: CGPoint(x: size.width, y: size.height - offset))
                    context.stroke(path, with: .color(color), lineWidth: 1.2)
                }
            }
            .padding(3)
        }
        .frame(width: 18, height: 18)
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(.primary.opacity(0.12), lineWidth: 1)
        }
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
