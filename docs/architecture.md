# Cork Architecture

Cork should feel like a native macOS utility that happens to contain a board, not a document app with a hidden window. The architecture is designed around fast presentation, small focused features, and a domain model that can grow without coupling every decision to SwiftUI or AppKit.

## Goals

- Keep launch and toggle behavior instant.
- Keep windowing concerns isolated from board content.
- Keep board data testable without UI frameworks.
- Prefer native macOS APIs over third-party dependencies.
- Add features through small adapters and card views instead of broad rewrites.
- Make persistence boring, local, and migration-friendly.

## Non-Goals

- Cork is not a long-form writing environment.
- Cork is not a file manager.
- Cork is not a collaborative whiteboard.
- Cork is not a replacement for full note-taking systems.

Those apps can keep being excellent at deep work. Cork should stay excellent at ambient context.

## Runtime Shape

```mermaid
flowchart LR
    User["User input"] --> Shell["App shell"]
    Shell --> Windowing["Board windowing"]
    Shell --> Settings["Settings store"]
    Shell --> Commands["Board commands"]
    Windowing --> BoardUI["SwiftUI board UI"]
    BoardUI --> Commands
    Commands --> Store["Board store"]
    Store --> Domain["CorkCore domain model"]
    Store --> Persistence["Board persistence adapter"]
    Settings --> SettingsPersistence["Settings persistence adapter"]
    Drop["Drag and drop adapter"] --> ImportResolver["Import resolver"]
    ImportResolver --> Commands
```

The important boundary is that `CorkCore` does not know about AppKit, SwiftUI, global hot keys, or storage frameworks. It models boards, cards, positions, and user-level operations.

## Layers

### App Shell

The shell owns lifecycle and high-level commands.

Current files:

- `Sources/Cork/App/CorkApp.swift`
- `Sources/Cork/App/AppCoordinator.swift`
- `Sources/Cork/App/CorkDialogs.swift`
- `Sources/Cork/App/LaunchAtLoginController.swift`
- `Sources/Cork/App/MenuBarContent.swift`
- `Sources/Cork/App/PreferencesWindowController.swift`

Responsibilities:

- Set Cork's accessory app behavior.
- Create the menu bar surface.
- Register global shortcuts.
- Route user commands to the board store and panel controller.
- Present native prompts for lightweight card and board editing.
- Present the Preferences window.
- Bridge system settings such as launch at login.
- Keep app-level state such as whether the board is visible.

The shell should remain thin. It should not directly encode board data, perform imports, or know persistence details.

### Hot Keys

Current file:

- `Sources/Cork/HotKeys/GlobalHotKey.swift`

The first implementation uses Carbon event hot keys because they are still the practical native route for app-level global keyboard shortcuts on macOS.

Near-term considerations:

- Detect registration failure and expose it in a small diagnostics path.
- Move key binding configuration behind a `HotKeyConfiguration` value.
- Later, add a settings UI for changing the shortcut.

### Windowing

Current file:

- `Sources/Cork/Board/BoardPanelController.swift`

The board is an `NSPanel` hosted by AppKit, with SwiftUI content inside an `NSHostingController`.

Responsibilities:

- Choose the target screen.
- Calculate hidden and visible frames.
- Animate from the configured slide edge.
- Keep the panel lightweight and non-document-like.
- Support board opacity through the SwiftUI board surface.
- Eventually support deeper multi-monitor behavior and active-application rules.

The panel controller should not know how board items are stored or rendered. It only hosts the board surface.

### Board UI

Current files:

- `Sources/Cork/Board/BoardKeyboardView.swift`
- `Sources/Cork/Board/BoardMouseInputView.swift`
- `Sources/Cork/Board/BoardView.swift`
- `Sources/Cork/Board/BoardCardView.swift`
- `Sources/Cork/Board/FileImageThumbnailView.swift`

The board UI is SwiftUI. It should prioritize direct manipulation and glanceability.

Guidelines:

- Keep the canvas flat and immediately usable.
- Avoid navigation stacks, inspectors, and persistent sidebars in the default board.
- Prefer contextual controls that appear when selecting or hovering over a card.
- Keep card dimensions stable while dragging or editing.
- Make keyboard actions first-class.
- Keep card and board editing lightweight, using native dialogs instead of persistent inspectors.
- Route create, edit, duplicate, delete, move, and board lifecycle actions through `BoardStore`.
- Route resizing through `BoardStore` so pointer, keyboard, and future command surfaces share one layout policy.
- Render file-backed images from cached downsampled thumbnails instead of decoding original files from SwiftUI body evaluation.

### Domain Model

Current files:

- `Sources/CorkCore/AppSettings.swift`
- `Sources/CorkCore/BoardImportIntent.swift`
- `Sources/CorkCore/BoardImportResolver.swift`
- `Sources/CorkCore/BoardModels.swift`
- `Sources/CorkCore/BoardStore.swift`
- `Sources/CorkCore/SettingsStore.swift`

`CorkCore` owns board state and user-level operations.

Current model:

- `CorkBoard`
- `BoardItem`
- `BoardItemContent`
- `BoardImportIntent`
- `BoardImportResolver`
- `TextCard`
- `ChecklistCard`
- `ImageCard`
- `URLCard`
- `BoardRect`
- `BoardPoint`
- `BoardSize`

The domain model should stay platform-light. It can use `Foundation` value types like `UUID`, `Date`, and `URL`, but should avoid `NSView`, `NSImage`, `SwiftUI.Image`, and persistence framework annotations unless there is a strong reason.

### Persistence

Persistence is implemented behind a small repository protocol so Cork can keep a simple runtime model.

Current shape:

```swift
public protocol BoardRepository {
    func loadSnapshot() throws -> BoardLibrarySnapshot?
    func saveSnapshot(_ snapshot: BoardLibrarySnapshot) throws
}

public protocol SettingsRepository {
    func loadSettings() throws -> AppSettings?
    func saveSettings(_ settings: AppSettings) throws
}
```

The first board implementation is `JSONBoardRepository`, which stores a `BoardLibrarySnapshot` at:

```text
~/Library/Application Support/Cork/boards.json
```

The first settings implementation is `JSONSettingsRepository`, which stores `AppSettings` at:

```text
~/Library/Application Support/Cork/settings.json
```

Current persistence behavior:

- Save all boards.
- Save the selected board ID.
- Save card frames and card content.
- Save board names, pinned state, board ordering, and board lifecycle changes.
- Save created and edited text, Markdown, checklist, image, URL, file, and palette cards.
- Save resized card frames.
- Save local image cards as file references.
- Save dropped image cards as local file references.
- Save dropped text cards as text cards.
- Save dropped web URLs as URL cards.
- Save dropped non-image files as file cards.
- Restore state automatically on launch.
- Fall back to sample boards if no saved state exists.
- Debounce autosaves while cards are dragged.
- Flush pending autosaves when Cork quits.

Current settings behavior:

- Save board opacity.
- Save the selected slide edge.
- Save the user's launch-at-login preference.
- Restore settings automatically on launch.
- Fall back to strong defaults if no saved settings exist.
- Debounce settings autosaves.
- Flush pending settings autosaves when Cork quits.

Storage notes:

- JSON is the right first storage layer because the domain model is already `Codable`, easy to test, and easy to inspect during early development.
- SwiftData can still replace the repository internals later if Cork needs richer querying or migrations.
- Imported image/file assets should be stored in Application Support.
- Security-scoped bookmarks will be needed for external file references when Cork links rather than copies.

The important design point is that persistence remains isolated. Cork should be able to evolve storage without changing board rendering or windowing code.

## Data Model

```mermaid
classDiagram
    class CorkBoard {
        UUID id
        String name
        Date createdAt
        Date updatedAt
        Bool isPinned
        Int sortIndex
        BoardItem[] items
    }

    class BoardItem {
        UUID id
        BoardRect frame
        BoardItemContent content
    }

    class BoardItemContent {
        text
        checklist
        image
        url
        file
        palette
    }

    class BoardRect {
        BoardPoint origin
        BoardSize size
    }

    CorkBoard "1" --> "*" BoardItem
    BoardItem --> BoardRect
    BoardItem --> BoardItemContent
```

The current app implements text, checklist, image, URL, file, and palette cards. Text cards can render either plain text or Markdown through `TextCardFormat`, so Markdown notes share the same domain payload and editing path as ordinary notes. Image cards can use bundled SF Symbols for samples or local file references for user-created images. URL cards store a title and web URL, render lightweight native link cards, and open links through `NSWorkspace` in the app layer. File cards store a title and referenced local URL, render native document-style cards, and use `NSWorkspace` for open and reveal actions. Palette cards store normalized hex colors and render compact swatches for glanceable design context.

## Commands

Views should use explicit board commands rather than mutating arbitrary state. This keeps menus, hot keys, drag-and-drop, Apple Shortcuts, and future automation hooks pointed at the same behavior.

Examples:

- `selectBoard(id:)`
- `createBoard(name:)`
- `renameBoard(id:name:)`
- `setBoardPinned(id:isPinned:)`
- `toggleBoardPinned(id:)`
- `moveBoard(id:toIndex:)`
- `duplicateBoard(id:)`
- `deleteBoard(id:)`
- `createTextCard(title:body:format:at:)`
- `createChecklistCard(title:entries:at:)`
- `createImageCard(title:source:at:)`
- `createURLCard(title:url:at:)`
- `createFileCard(title:url:at:)`
- `createColorPaletteCard(title:colors:at:)`
- `updateTextCard(_:title:body:format:)`
- `updateChecklistCard(_:title:entries:)`
- `updateImageCard(_:title:source:)`
- `updateURLCard(_:title:url:)`
- `updateColorPaletteCard(_:title:colors:)`
- `updateItemPosition(_:to:)`
- `resizeItem(_:to:)`
- `resizeSelectedItem(to:)`
- `moveSelectedItem(by:)`
- `duplicateItem(_:)`
- `deleteItem(_:)`
- `importItems(_:at:constrainedTo:)`

The command layer currently lives in `BoardStore`. If it grows too large, the next extraction should be a small command facade around the store rather than direct view mutation.

Board management is intentionally still lightweight:

- Pinned boards are regular boards with `isPinned` metadata, not a separate collection.
- Board ordering is stored with `sortIndex` and normalized after create, move, duplicate, and delete operations.
- Duplicating a board copies its cards with new item IDs, selects the copy, and leaves the copy unpinned.
- The menu bar `Boards` menu lists boards first, with pinned boards above unpinned boards, then shows current-board actions.

## Drag and Drop

Drag-and-drop is implemented as an import pipeline:

```mermaid
flowchart LR
    Pasteboard["NSPasteboard values"] --> Adapter["AppKit drop adapter"]
    Adapter --> Source["BoardImportSource"]
    Source --> Resolver["BoardImportResolver"]
    Resolver --> Intent["BoardImportIntent"]
    Intent --> Commands["Board command"]
    Commands --> Store["Board store"]
```

Current drop types:

- Image files from Finder.
- File URLs from Finder.
- Web URLs from browsers.
- Plain text snippets.

Current behavior:

- Image file drops create image cards backed by file references.
- Image file cards render downsampled cached thumbnails for interactive performance.
- Plain text drops create text cards.
- Web URL drops create URL cards.
- Non-image file drops create dedicated file cards.
- Drops land at the board-coordinate drop location and stagger when multiple files are imported.

Copy-versus-reference behavior should remain explicit:

- Local files currently start as references.
- The thumbnail cache is an in-memory render cache, not durable copied asset storage.
- File cards currently reference the original local file path.
- Copied-file support belongs in an asset storage adapter under Application Support.
- Images dropped from the web should eventually be copied into Cork's app support storage.
- URL cards are intentionally lightweight for now; rich previews and favicons should be optional and cached.

## Error Handling

Cork should avoid interruptive alerts for normal utility behavior.

Use:

- Quiet fallbacks for missing saved state.
- Small non-blocking indicators for failed imports.
- Menu diagnostics for hot-key registration problems.
- Logged errors for unexpected persistence failures during development.

As the app matures, user-visible recovery should be added for cases where data might not save.

## Testing Strategy

Keep tests concentrated around behavior that should not regress:

- Board selection.
- Board pinning, ordering, duplication, and lifecycle commands.
- Card movement and resizing bounds.
- Card creation commands.
- Card editing commands.
- URL import and URL card command behavior.
- Board creation, rename, and deletion commands.
- Persistence round trips.
- Import intent resolution.
- Large-image interaction behavior through manual QA.

UI animation and AppKit panel behavior can remain manually verified early, then gain focused tests once packaging and UI structure settle.

## Extension Points

- New card types add a domain payload, a card renderer, and command support.
- New import sources add resolver code that produces card creation intents.
- Search indexes domain content and file metadata, not rendered views.
- Apple Shortcuts calls the same command layer used by menu items and hot keys.
- Multiple monitor support belongs in windowing, not board state.
