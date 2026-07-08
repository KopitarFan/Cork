import AppKit
import CorkCore
import UniformTypeIdentifiers

enum CorkDialogs {
    static func promptForBoardName(
        title: String,
        message: String,
        defaultName: String
    ) -> String? {
        let field = NSTextField(string: defaultName)
        field.placeholderString = "Board name"
        field.frame = NSRect(x: 0, y: 0, width: 320, height: 24)

        let alert = makeAlert(title: title, message: message)
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = field

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        return trimmed(field.stringValue).isEmpty ? nil : field.stringValue
    }

    static func confirmBoardDeletion(boardName: String) -> Bool {
        let alert = makeAlert(
            title: "Delete Board",
            message: "Delete \"\(boardName)\"?"
        )
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Cancel")
        alert.addButton(withTitle: "Delete")
        alert.buttons.last?.hasDestructiveAction = true

        return alert.runModal() == .alertSecondButtonReturn
    }

    static func promptForTextCard(title: String, card: TextCard) -> TextCard? {
        let titleField = NSTextField(string: card.title)
        titleField.placeholderString = "Title"

        let bodyView = makeTextView(text: card.body)
        let bodyScrollView = makeScrollView(containing: bodyView, height: 164)
        let markdownCheckbox = NSButton(checkboxWithTitle: "Markdown", target: nil, action: nil)
        markdownCheckbox.state = card.format == .markdown ? .on : .off

        let form = makeFormView(rows: [
            makeLabeledRow(label: "Title", view: titleField),
            makeLabeledRow(label: "Body", view: bodyScrollView),
            makeLabeledRow(label: "Format", view: markdownCheckbox)
        ])

        let alert = makeAlert(title: title, message: "")
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = form

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        let format: TextCardFormat = markdownCheckbox.state == .on ? .markdown : .plainText
        return TextCard(title: titleField.stringValue, body: bodyView.string, format: format)
    }

    static func promptForChecklistCard(title: String, card: ChecklistCard) -> ChecklistCard? {
        let titleField = NSTextField(string: card.title)
        titleField.placeholderString = "Title"

        let entriesView = makeTextView(text: checklistText(from: card.entries))
        let entriesScrollView = makeScrollView(containing: entriesView, height: 170)
        let form = makeFormView(rows: [
            makeLabeledRow(label: "Title", view: titleField),
            makeLabeledRow(label: "Items", view: entriesScrollView)
        ])

        let alert = makeAlert(title: title, message: "")
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = form

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        return ChecklistCard(
            title: titleField.stringValue,
            entries: checklistEntries(from: entriesView.string)
        )
    }

    static func promptForImageTitle(title: String, card: ImageCard) -> ImageCard? {
        let titleField = NSTextField(string: card.title)
        titleField.placeholderString = "Title"
        titleField.frame = NSRect(x: 0, y: 0, width: 320, height: 24)

        let alert = makeAlert(title: title, message: "")
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = titleField

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        return ImageCard(title: titleField.stringValue, source: card.source)
    }

    static func promptForURLCard(title: String, card: URLCard) -> URLCard? {
        let titleField = NSTextField(string: card.title)
        titleField.placeholderString = "Title"

        let urlField = NSTextField(string: card.url.absoluteString)
        urlField.placeholderString = "https://example.com"

        let form = makeFormView(rows: [
            makeLabeledRow(label: "Title", view: titleField),
            makeLabeledRow(label: "URL", view: urlField)
        ])

        let alert = makeAlert(title: title, message: "")
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = form

        guard alert.runModal() == .alertFirstButtonReturn,
              let url = webURL(from: urlField.stringValue)
        else {
            return nil
        }

        return URLCard(title: titleField.stringValue, url: url)
    }

    static func promptForColorPaletteCard(title: String, card: ColorPaletteCard) -> ColorPaletteCard? {
        let titleField = NSTextField(string: card.title)
        titleField.placeholderString = "Title"

        let colorsView = makeTextView(text: paletteText(from: card.colors))
        let colorsScrollView = makeScrollView(containing: colorsView, height: 118)
        let form = makeFormView(rows: [
            makeLabeledRow(label: "Title", view: titleField),
            makeLabeledRow(label: "Colors", view: colorsScrollView)
        ])

        let alert = makeAlert(title: title, message: "Enter hex colors separated by commas, spaces, or new lines.")
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = form

        guard alert.runModal() == .alertFirstButtonReturn else {
            return nil
        }

        let colors = PaletteColor.colors(from: colorsView.string)
        return ColorPaletteCard(title: titleField.stringValue, colors: colors)
    }

    static func chooseImageFile() -> URL? {
        activateAppForDialog()

        let panel = NSOpenPanel()
        panel.title = "Add Image"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]

        guard panel.runModal() == .OK else {
            return nil
        }

        return panel.url
    }

    static func defaultImageTitle(for url: URL) -> String {
        let name = url.deletingPathExtension().lastPathComponent
        return trimmed(name).isEmpty ? "Untitled Image" : name
    }

    private static func makeAlert(title: String, message: String) -> NSAlert {
        activateAppForDialog()

        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        return alert
    }

    private static func activateAppForDialog() {
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func makeTextView(text: String) -> NSTextView {
        let textView = NSTextView()
        textView.string = text
        textView.font = .preferredFont(forTextStyle: .body)
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: 360,
            height: CGFloat.greatestFiniteMagnitude
        )
        return textView
    }

    private static func makeScrollView(containing textView: NSTextView, height: CGFloat) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        scrollView.documentView = textView
        textView.frame = NSRect(x: 0, y: 0, width: 360, height: height)

        NSLayoutConstraint.activate([
            scrollView.widthAnchor.constraint(equalToConstant: 360),
            scrollView.heightAnchor.constraint(equalToConstant: height)
        ])

        return scrollView
    }

    private static func makeFormView(rows: [NSView]) -> NSView {
        let stackView = NSStackView(views: rows)
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 10
        stackView.distribution = .fill
        stackView.setFrameSize(NSSize(width: 400, height: stackView.fittingSize.height))

        return stackView
    }

    private static func makeLabeledRow(label: String, view: NSView) -> NSView {
        view.translatesAutoresizingMaskIntoConstraints = false

        let labelView = NSTextField(labelWithString: label)
        labelView.font = .preferredFont(forTextStyle: .caption1)
        labelView.textColor = .secondaryLabelColor

        let stackView = NSStackView(views: [labelView, view])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4

        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 360)
        ])

        return stackView
    }

    private static func checklistText(from entries: [ChecklistEntry]) -> String {
        entries.map { entry in
            entry.isComplete ? "[x] \(entry.title)" : entry.title
        }
        .joined(separator: "\n")
    }

    private static func paletteText(from colors: [PaletteColor]) -> String {
        colors.map(\.hex).joined(separator: "\n")
    }

    private static func checklistEntries(from text: String) -> [ChecklistEntry] {
        text.components(separatedBy: .newlines).compactMap { line in
            let trimmedLine = trimmed(line)

            guard !trimmedLine.isEmpty else {
                return nil
            }

            if let title = titleByRemoving(prefix: "[x]", from: trimmedLine) {
                return ChecklistEntry(title: title, isComplete: true)
            }

            if let title = titleByRemoving(prefix: "- [x]", from: trimmedLine) {
                return ChecklistEntry(title: title, isComplete: true)
            }

            if let title = titleByRemoving(prefix: "[ ]", from: trimmedLine) {
                return ChecklistEntry(title: title)
            }

            if let title = titleByRemoving(prefix: "- [ ]", from: trimmedLine) {
                return ChecklistEntry(title: title)
            }

            return ChecklistEntry(title: trimmedLine)
        }
    }

    private static func titleByRemoving(prefix: String, from value: String) -> String? {
        guard value.lowercased().hasPrefix(prefix.lowercased()) else {
            return nil
        }

        let title = trimmed(String(value.dropFirst(prefix.count)))
        return title.isEmpty ? nil : title
    }

    private static func webURL(from value: String) -> URL? {
        let trimmedValue = trimmed(value)

        guard let url = URL(string: trimmedValue),
              !url.isFileURL,
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https"
        else {
            return nil
        }

        return url
    }

    private static func trimmed(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
