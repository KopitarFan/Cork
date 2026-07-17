import CorkCore
import AppKit
import SwiftUI

struct BoardCardView: View {
    let item: BoardItem
    let isSelected: Bool
    let isHovered: Bool
    let isConnectionSource: Bool
    @Environment(\.colorScheme) private var ambientColorScheme

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
            .overlay {
                if isConnectionSource {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            Color(red: 0.72, green: 0.08, blue: 0.10),
                            style: StrokeStyle(lineWidth: 2, dash: [6, 4])
                        )
                        .padding(2)
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
            .environment(\.cardFontDesign, fontDesign)
            .environment(\.colorScheme, resolvedColorScheme)
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
                                .font(fontDesign.font(.callout))
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
                    .font(fontDesign.font(.callout))
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(card.url.absoluteString)
                    .font(fontDesign.font(.caption))
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
                FileImageThumbnailView(
                    url: url,
                    securityScopedBookmark: card.securityScopedBookmark
                )
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

    private var cardBackground: AnyShapeStyle {
        if let customBackgroundHex = item.appearance.backgroundHex {
            return AnyShapeStyle(Color(cardHex: customBackgroundHex).opacity(0.96))
        }

        switch item.content {
        case .text:
            return AnyShapeStyle(Color(nsColor: .textBackgroundColor).opacity(0.95))
        case .checklist:
            return AnyShapeStyle(Color(nsColor: .selectedContentBackgroundColor).opacity(0.14))
        case .image:
            return AnyShapeStyle(Color(nsColor: .underPageBackgroundColor).opacity(0.92))
        case .url:
            return AnyShapeStyle(Color(nsColor: .controlBackgroundColor).opacity(0.94))
        case .file:
            return AnyShapeStyle(Color(nsColor: .windowBackgroundColor).opacity(0.94))
        case .palette:
            return AnyShapeStyle(Color(nsColor: .textBackgroundColor).opacity(0.95))
        }
    }

    private var fontDesign: CardFontDesign {
        item.appearance.fontDesign
    }

    private var resolvedColorScheme: ColorScheme {
        item.appearance.backgroundHex?.preferredCardColorScheme ?? ambientColorScheme
    }
}

private struct CardFontDesignEnvironmentKey: EnvironmentKey {
    static let defaultValue = CardFontDesign.rounded
}

private extension EnvironmentValues {
    var cardFontDesign: CardFontDesign {
        get { self[CardFontDesignEnvironmentKey.self] }
        set { self[CardFontDesignEnvironmentKey.self] = newValue }
    }
}

private extension CardFontDesign {
    var swiftUIFontDesign: Font.Design {
        switch self {
        case .system:
            return .default
        case .rounded:
            return .rounded
        case .serif:
            return .serif
        case .monospaced:
            return .monospaced
        }
    }

    func font(_ style: Font.TextStyle) -> Font {
        .system(style, design: swiftUIFontDesign)
    }

    func font(size: CGFloat, weight: Font.Weight) -> Font {
        .system(size: size, weight: weight, design: swiftUIFontDesign)
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
    @Environment(\.cardFontDesign) private var cardFontDesign

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
                        .font(cardFontDesign.font(.caption))
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                }
            }

            Text(displayName)
                .font(cardFontDesign.font(.callout))
                .fontWeight(.medium)
                .foregroundStyle(fileExists ? .primary : .secondary)
                .lineLimit(1)

            Text(resolvedURL.path)
                .font(cardFontDesign.font(.caption))
                .foregroundStyle(.secondary)
                .lineLimit(fileExists ? 3 : 2)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .topLeading)
        }
    }

    private var displayName: String {
        resolvedURL.lastPathComponent.isEmpty ? resolvedURL.path : resolvedURL.lastPathComponent
    }

    private var resolvedURL: URL {
        SecurityScopedBookmark.resolve(
            card.securityScopedBookmark,
            fallbackURL: card.url
        )
    }

    private var fileExists: Bool {
        guard card.url.isFileURL else {
            return true
        }

        return SecurityScopedBookmark.withAccess(
            to: card.securityScopedBookmark,
            fallbackURL: card.url
        ) { url in
            FileManager.default.fileExists(atPath: url.path)
        }
    }
}

private struct TextCardBody: View {
    let card: TextCard
    @Environment(\.cardFontDesign) private var cardFontDesign

    @ViewBuilder
    var body: some View {
        switch card.format {
        case .plainText:
            Text(card.body)
                .font(cardFontDesign.font(.body))
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
    @Environment(\.cardFontDesign) private var cardFontDesign

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
                        .font(cardFontDesign.font(.caption))
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
    @Environment(\.cardFontDesign) private var cardFontDesign

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
                .font(cardFontDesign.font(.body))
                .foregroundStyle(.primary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("•")
                    .font(cardFontDesign.font(.callout))
                    .foregroundStyle(.secondary)

                inlineText(text)
                    .font(cardFontDesign.font(.body))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .orderedList(let marker, let text):
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(marker)
                    .font(cardFontDesign.font(.caption))
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 16, alignment: .trailing)

                inlineText(text)
                    .font(cardFontDesign.font(.body))
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
            return cardFontDesign.font(.title3)
        case 2:
            return cardFontDesign.font(.headline)
        default:
            return cardFontDesign.font(.subheadline)
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
    @Environment(\.cardFontDesign) private var cardFontDesign

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(cardFontDesign.font(size: 12, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22, height: 22)
                .background {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.accentColor.opacity(0.14))
                }

            Text(title)
                .font(cardFontDesign.font(.subheadline))
                .fontWeight(.semibold)
                .lineLimit(1)
        }
    }
}

private extension Color {
    init(cardHex hex: String) {
        let hexValue = String(hex.dropFirst())
        guard let rgbValue = UInt64(hexValue, radix: 16) else {
            self = Color(nsColor: .textBackgroundColor)
            return
        }

        self.init(
            red: Double((rgbValue >> 16) & 0xFF) / 255,
            green: Double((rgbValue >> 8) & 0xFF) / 255,
            blue: Double(rgbValue & 0xFF) / 255
        )
    }
}

private extension String {
    var preferredCardColorScheme: ColorScheme? {
        let hexValue = String(dropFirst())
        guard let rgbValue = UInt64(hexValue, radix: 16) else {
            return nil
        }

        let red = Double((rgbValue >> 16) & 0xFF) / 255
        let green = Double((rgbValue >> 8) & 0xFF) / 255
        let blue = Double(rgbValue & 0xFF) / 255
        let luminance = (red * 0.299) + (green * 0.587) + (blue * 0.114)

        return luminance > 0.55 ? .light : .dark
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
