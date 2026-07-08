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

                TextCardBody(card: card)
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
            VStack(alignment: .leading, spacing: 10) {
                imagePreview(for: card)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

                CardTitle(title: card.title, systemImage: "photo")
            }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()

        case .url(let card):
            VStack(alignment: .leading, spacing: 10) {
                CardTitle(title: card.title, systemImage: "link")

                Text(card.url.host() ?? card.url.absoluteString)
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(card.url.absoluteString)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .clipped()

        case .file(let card):
            FileCardContent(card: card)
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .clipped()

        case .palette(let card):
            ColorPaletteCardContent(card: card)
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
        case .url:
            AnyShapeStyle(Color(nsColor: .controlBackgroundColor).opacity(0.94))
        case .file:
            AnyShapeStyle(Color(nsColor: .windowBackgroundColor).opacity(0.94))
        case .palette:
            AnyShapeStyle(Color(nsColor: .textBackgroundColor).opacity(0.95))
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

private struct FileCardContent: View {
    let card: FileCard

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            CardTitle(
                title: card.title,
                systemImage: fileExists ? "doc" : "doc.badge.exclamationmark"
            )

            if !fileExists {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.orange)

                    Text("Missing file")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            Text(displayName)
                .font(.system(.callout, design: .rounded))
                .fontWeight(.medium)
                .foregroundStyle(fileExists ? .primary : .secondary)
                .lineLimit(1)

            Text(card.url.path)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(fileExists ? 3 : 2)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var displayName: String {
        card.url.lastPathComponent.isEmpty ? card.url.path : card.url.lastPathComponent
    }

    private var fileExists: Bool {
        guard card.url.isFileURL else {
            return true
        }

        return FileManager.default.fileExists(atPath: card.url.path)
    }
}

private struct TextCardBody: View {
    let card: TextCard

    @ViewBuilder
    var body: some View {
        switch card.format {
        case .plainText:
            Text(card.body)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        case .markdown:
            MarkdownCardBody(blocks: MarkdownCardBlock.blocks(from: card.body))
        }
    }
}

private struct ColorPaletteCardContent: View {
    let card: ColorPaletteCard

    private var visibleColors: ArraySlice<PaletteColor> {
        card.colors.prefix(8)
    }

    private var remainingColorCount: Int {
        max(0, card.colors.count - visibleColors.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            CardTitle(title: card.title, systemImage: "swatchpalette")

            HStack(spacing: 6) {
                ForEach(Array(visibleColors.enumerated()), id: \.offset) { _, paletteColor in
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(paletteColor.swiftUIColor)
                        .frame(width: 28, height: 38)
                        .overlay {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(.primary.opacity(0.16), lineWidth: 1)
                        }
                }

                if remainingColorCount > 0 {
                    Text("+\(remainingColorCount)")
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 38)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }

            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 72), spacing: 6)
                ],
                alignment: .leading,
                spacing: 6
            ) {
                ForEach(Array(visibleColors.enumerated()), id: \.offset) { _, paletteColor in
                    Text(paletteColor.hex)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                }
            }
        }
    }
}

private struct MarkdownCardBody: View {
    let blocks: [MarkdownCardBlock]

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(blocks) { block in
                blockView(block)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipped()
    }

    @ViewBuilder
    private func blockView(_ block: MarkdownCardBlock) -> some View {
        switch block.kind {
        case .heading(let level, let text):
            inlineText(text)
                .font(headingFont(for: level))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .paragraph(let text):
            inlineText(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.secondary)

                inlineText(text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .orderedList(let marker, let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(marker)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 16, alignment: .trailing)

                inlineText(text)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .spacer:
            Color.clear
                .frame(height: 3)
        }
    }

    private func inlineText(_ value: String) -> Text {
        if let attributedString = try? AttributedString(
            markdown: value,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attributedString)
        }

        return Text(value)
    }

    private func headingFont(for level: Int) -> Font {
        switch level {
        case 1:
            return .system(.title3, design: .rounded)
        case 2:
            return .system(.headline, design: .rounded)
        default:
            return .system(.subheadline, design: .rounded)
        }
    }
}

private struct MarkdownCardBlock: Identifiable {
    enum Kind {
        case heading(level: Int, text: String)
        case paragraph(String)
        case bullet(String)
        case orderedList(marker: String, text: String)
        case spacer
    }

    let id: Int
    let kind: Kind

    static func blocks(from text: String) -> [MarkdownCardBlock] {
        let lines = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")
        var blocks: [MarkdownCardBlock] = []
        var previousWasSpacer = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            guard !trimmedLine.isEmpty else {
                if !previousWasSpacer {
                    blocks.append(MarkdownCardBlock(id: blocks.count, kind: .spacer))
                }

                previousWasSpacer = true
                continue
            }

            previousWasSpacer = false

            if let heading = heading(from: trimmedLine) {
                blocks.append(MarkdownCardBlock(
                    id: blocks.count,
                    kind: .heading(level: heading.level, text: heading.text)
                ))
            } else if let bullet = bullet(from: trimmedLine) {
                blocks.append(MarkdownCardBlock(id: blocks.count, kind: .bullet(bullet)))
            } else if let orderedListItem = orderedListItem(from: trimmedLine) {
                blocks.append(MarkdownCardBlock(
                    id: blocks.count,
                    kind: .orderedList(marker: orderedListItem.marker, text: orderedListItem.text)
                ))
            } else {
                blocks.append(MarkdownCardBlock(id: blocks.count, kind: .paragraph(trimmedLine)))
            }
        }

        while blocks.first?.isSpacer == true {
            blocks.removeFirst()
        }

        while blocks.last?.isSpacer == true {
            blocks.removeLast()
        }

        return blocks.isEmpty ? [MarkdownCardBlock(id: 0, kind: .paragraph(""))] : blocks
    }

    private var isSpacer: Bool {
        if case .spacer = kind {
            return true
        }

        return false
    }

    private static func heading(from line: String) -> (level: Int, text: String)? {
        let level = line.prefix { $0 == "#" }.count

        guard (1...6).contains(level),
              line.dropFirst(level).first == " "
        else {
            return nil
        }

        let text = line
            .dropFirst(level)
            .trimmingCharacters(in: .whitespaces)

        return text.isEmpty ? nil : (level, text)
    }

    private static func bullet(from line: String) -> String? {
        for prefix in ["- ", "* ", "+ "] where line.hasPrefix(prefix) {
            let text = line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
            return text.isEmpty ? nil : text
        }

        return nil
    }

    private static func orderedListItem(from line: String) -> (marker: String, text: String)? {
        let digits = line.prefix { $0.isNumber }

        guard !digits.isEmpty else {
            return nil
        }

        let markerIndex = line.index(line.startIndex, offsetBy: digits.count)

        guard markerIndex < line.endIndex,
              [".", ")"].contains(String(line[markerIndex]))
        else {
            return nil
        }

        let textStart = line.index(after: markerIndex)

        guard textStart < line.endIndex,
              line[textStart] == " "
        else {
            return nil
        }

        let marker = "\(digits)\(line[markerIndex])"
        let text = line.dropFirst(marker.count).trimmingCharacters(in: .whitespaces)

        return text.isEmpty ? nil : (marker, text)
    }
}

private struct CardTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22, height: 22)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                }

            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.semibold)
                .lineLimit(1)
        }
    }
}

private extension PaletteColor {
    var swiftUIColor: Color {
        let hexValue = String(hex.dropFirst())
        guard let rgbValue = UInt64(hexValue, radix: 16) else {
            return .black
        }

        return Color(
            red: Double((rgbValue >> 16) & 0xFF) / 255,
            green: Double((rgbValue >> 8) & 0xFF) / 255,
            blue: Double(rgbValue & 0xFF) / 255
        )
    }
}
