import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

@main
struct ComposeScreenshots {
    static func main() throws {
        let arguments = CommandLine.arguments

        guard arguments.count >= 2 else {
            throw ComposerError.usage
        }

        switch arguments[1] {
        case "crop":
            guard arguments.count == 8 else { throw ComposerError.usage }
            try crop(
                input: arguments[2],
                output: arguments[3],
                rect: CGRect(
                    x: Double(arguments[4])!,
                    y: Double(arguments[5])!,
                    width: Double(arguments[6])!,
                    height: Double(arguments[7])!
                )
            )
        case "compose":
            guard arguments.count == 11 else { throw ComposerError.usage }
            try compose(
                output: arguments[2],
                screenshot: arguments[3],
                icon: arguments[4],
                eyebrow: arguments[5],
                headline: arguments[6],
                subtitle: arguments[7],
                backgroundHex: arguments[8],
                foregroundHex: arguments[9],
                accentHex: arguments[10]
            )
        case "compose-preferences":
            guard arguments.count == 12 else { throw ComposerError.usage }
            try composePreferences(
                output: arguments[2],
                boardScreenshot: arguments[3],
                preferencesScreenshot: arguments[4],
                icon: arguments[5],
                eyebrow: arguments[6],
                headline: arguments[7],
                subtitle: arguments[8],
                backgroundHex: arguments[9],
                foregroundHex: arguments[10],
                accentHex: arguments[11]
            )
        case "contact-sheet":
            guard arguments.count == 9 else { throw ComposerError.usage }
            try contactSheet(output: arguments[2], screenshots: Array(arguments[3...7]), icon: arguments[8])
        case "preview-poster":
            guard arguments.count == 4 else { throw ComposerError.usage }
            try previewPoster(input: arguments[2], output: arguments[3])
        default:
            throw ComposerError.usage
        }
    }

    private static func crop(input: String, output: String, rect: CGRect) throws {
        let inputURL = URL(fileURLWithPath: input)
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil),
              let cropped = image.cropping(to: rect)
        else {
            throw ComposerError.couldNotRead(input)
        }

        try write(cropped, to: output)
    }

    private static func compose(
        output: String,
        screenshot: String,
        icon: String,
        eyebrow: String,
        headline: String,
        subtitle: String,
        backgroundHex: String,
        foregroundHex: String,
        accentHex: String
    ) throws {
        let canvas = try makeCanvas(backgroundHex: backgroundHex) {
            drawHeader(
                eyebrow: eyebrow,
                headline: headline,
                subtitle: subtitle,
                foregroundHex: foregroundHex,
                accentHex: accentHex,
                iconPath: icon
            )

            try drawWindow(
                imagePath: screenshot,
                rect: CGRect(x: 100, y: 105, width: 2360, height: 1037),
                cornerRadius: 28
            )
        }

        try write(canvas, to: output)
    }

    private static func composePreferences(
        output: String,
        boardScreenshot: String,
        preferencesScreenshot: String,
        icon: String,
        eyebrow: String,
        headline: String,
        subtitle: String,
        backgroundHex: String,
        foregroundHex: String,
        accentHex: String
    ) throws {
        let canvas = try makeCanvas(backgroundHex: backgroundHex) {
            drawHeader(
                eyebrow: eyebrow,
                headline: headline,
                subtitle: subtitle,
                foregroundHex: foregroundHex,
                accentHex: accentHex,
                iconPath: icon
            )

            try drawWindow(
                imagePath: boardScreenshot,
                rect: CGRect(x: 80, y: 125, width: 2080, height: 914),
                cornerRadius: 26,
                opacity: 0.86
            )

            try drawWindow(
                imagePath: preferencesScreenshot,
                rect: CGRect(x: 1660, y: 70, width: 780, height: 1037),
                cornerRadius: 24
            )
        }

        try write(canvas, to: output)
    }

    private static func contactSheet(output: String, screenshots: [String], icon: String) throws {
        let size = NSSize(width: 1920, height: 2400)
        let canvas = NSImage(size: size)
        canvas.lockFocus()

        NSColor(hex: "#F2F5F1").setFill()
        NSBezierPath(rect: NSRect(origin: .zero, size: size)).fill()

        let iconImage = try loadImage(icon)
        iconImage.draw(in: CGRect(x: 80, y: 2240, width: 96, height: 96))

        drawText(
            "Cork 1.0 App Store Screenshots",
            rect: CGRect(x: 205, y: 2262, width: 1500, height: 70),
            font: .systemFont(ofSize: 44, weight: .bold),
            color: NSColor(hex: "#173C33")
        )

        let positions = [
            CGRect(x: 70, y: 1595, width: 860, height: 537),
            CGRect(x: 990, y: 1595, width: 860, height: 537),
            CGRect(x: 70, y: 988, width: 860, height: 537),
            CGRect(x: 990, y: 988, width: 860, height: 537),
            CGRect(x: 530, y: 381, width: 860, height: 537)
        ]

        for (path, rect) in zip(screenshots, positions) {
            try drawWindow(imagePath: path, rect: rect, cornerRadius: 14, shadowBlur: 16)
        }

        canvas.unlockFocus()
        try write(canvas, to: output)
    }

    private static func previewPoster(input: String, output: String) throws {
        let source = try loadImage(input)
        let canvas = NSImage(size: NSSize(width: 1920, height: 1080))
        canvas.lockFocus()

        NSGraphicsContext.current?.imageInterpolation = .high
        let sourceRect = CGRect(x: 0, y: 80, width: 2560, height: 1440)
        source.draw(
            in: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            from: sourceRect,
            operation: .copy,
            fraction: 1
        )

        canvas.unlockFocus()
        try write(canvas, to: output)
    }

    private static func makeCanvas(
        backgroundHex: String,
        drawing: () throws -> Void
    ) throws -> NSImage {
        let canvas = NSImage(size: NSSize(width: 2560, height: 1600))
        canvas.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        NSColor(hex: backgroundHex).setFill()
        NSBezierPath(rect: CGRect(x: 0, y: 0, width: 2560, height: 1600)).fill()

        do {
            try drawing()
        } catch {
            canvas.unlockFocus()
            throw error
        }

        canvas.unlockFocus()
        return canvas
    }

    private static func drawHeader(
        eyebrow: String,
        headline: String,
        subtitle: String,
        foregroundHex: String,
        accentHex: String,
        iconPath: String
    ) {
        let foreground = NSColor(hex: foregroundHex)
        let accent = NSColor(hex: accentHex)

        accent.setFill()
        NSBezierPath(roundedRect: CGRect(x: 100, y: 1483, width: 58, height: 8), xRadius: 4, yRadius: 4).fill()

        drawText(
            eyebrow.uppercased(),
            rect: CGRect(x: 180, y: 1460, width: 1500, height: 52),
            font: .systemFont(ofSize: 25, weight: .semibold),
            color: foreground.withAlphaComponent(0.72)
        )

        let headlineFontSize: CGFloat = headline.count > 39 ? 68 : 78
        drawText(
            headline,
            rect: CGRect(x: 100, y: 1322, width: 2100, height: 125),
            font: .systemFont(ofSize: headlineFontSize, weight: .bold),
            color: foreground
        )

        drawText(
            subtitle,
            rect: CGRect(x: 104, y: 1240, width: 2050, height: 66),
            font: .systemFont(ofSize: 34, weight: .regular),
            color: foreground.withAlphaComponent(0.76)
        )

        if let icon = NSImage(contentsOfFile: iconPath) {
            icon.draw(in: CGRect(x: 2310, y: 1402, width: 140, height: 140))
        }
    }

    private static func drawWindow(
        imagePath: String,
        rect: CGRect,
        cornerRadius: CGFloat,
        opacity: CGFloat = 1,
        shadowBlur: CGFloat = 34
    ) throws {
        let image = try loadImage(imagePath)
        let framePath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.28)
        shadow.shadowBlurRadius = shadowBlur
        shadow.shadowOffset = NSSize(width: 0, height: -12)

        NSGraphicsContext.saveGraphicsState()
        shadow.set()
        NSColor.white.setFill()
        framePath.fill()
        NSGraphicsContext.restoreGraphicsState()

        NSGraphicsContext.saveGraphicsState()
        framePath.addClip()
        image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: opacity)
        NSGraphicsContext.restoreGraphicsState()

        NSColor.white.withAlphaComponent(0.28).setStroke()
        framePath.lineWidth = 2
        framePath.stroke()
    }

    private static func drawText(
        _ text: String,
        rect: CGRect,
        font: NSFont,
        color: NSColor
    ) {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping

        NSString(string: text).draw(
            with: rect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: style
            ]
        )
    }

    private static func loadImage(_ path: String) throws -> NSImage {
        guard let image = NSImage(contentsOfFile: path) else {
            throw ComposerError.couldNotRead(path)
        }

        return image
    }

    private static func write(_ image: NSImage, to path: String) throws {
        var rect = CGRect(origin: .zero, size: image.size)
        guard let cgImage = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else {
            throw ComposerError.couldNotEncode(path)
        }

        try write(cgImage, to: path)
    }

    private static func write(_ image: CGImage, to path: String) throws {
        guard let context = CGContext(
            data: nil,
            width: image.width,
            height: image.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            throw ComposerError.couldNotEncode(path)
        }

        context.setFillColor(CGColor(gray: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        guard let opaqueImage = context.makeImage() else {
            throw ComposerError.couldNotEncode(path)
        }

        let url = URL(fileURLWithPath: path)
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            throw ComposerError.couldNotEncode(path)
        }

        CGImageDestinationAddImage(destination, opaqueImage, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ComposerError.couldNotEncode(path)
        }
    }
}

private extension NSColor {
    convenience init(hex: String) {
        let value = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let number = UInt64(value, radix: 16) ?? 0
        self.init(
            red: CGFloat((number >> 16) & 0xFF) / 255,
            green: CGFloat((number >> 8) & 0xFF) / 255,
            blue: CGFloat(number & 0xFF) / 255,
            alpha: 1
        )
    }
}

private enum ComposerError: LocalizedError {
    case usage
    case couldNotRead(String)
    case couldNotEncode(String)

    var errorDescription: String? {
        switch self {
        case .usage:
            "Invalid screenshot composer arguments."
        case .couldNotRead(let path):
            "Could not read image: \(path)"
        case .couldNotEncode(let path):
            "Could not encode image: \(path)"
        }
    }
}
