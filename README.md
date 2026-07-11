# Cork

Cork is a macOS desktop utility for ambient work context: the handful of notes, images, links, files, and reminders someone wants visible while working without switching applications.

It behaves like a virtual corkboard that lives just off-screen. Press the global shortcut or use the menu bar item and the board slides in from the configured screen edge. Press the shortcut again and it disappears.

Cork is not trying to replace Obsidian, Freeform, Notion, Milanote, or a full note-taking system. It is closer to the physical corkboard beside a writer's desk: quick to glance at, easy to change, and quiet the rest of the time.

## Product Principles

- Instant to open and close.
- No loading screens.
- No complex navigation.
- Optimized for glancing, not long-form editing.
- Native macOS look and feel.
- Keyboard-first.
- Drag-and-drop wherever it naturally belongs.
- Beautiful, calm animations.

Opening Cork should feel like pulling back a curtain, not launching an app.

## Current Status

The project currently has the first runnable foundation, persistence layer, card interaction layer, real card creation flow, drag-and-drop imports, resizing/layout polish, the core Milestone 7 card types, board-management polish, and the first preferences surface:

- Menu bar app.
- Configurable global keyboard shortcut, defaulting to `Command` + `Option` + `B`.
- Configurable slide-in board edge.
- Multiple named sample boards.
- Text, checklist, image, URL, file, and color palette cards.
- Plain-text and Markdown text note formats.
- Card creation from the board header and menu bar.
- Lightweight editing for text notes, Markdown notes, checklist items, image card titles, URL cards, and color palettes.
- Local image card creation through the native file picker.
- Draggable card positions.
- Selected-card state with keyboard movement.
- Duplicate, delete, and edit actions for cards.
- Context menus for card actions, including double-click edit.
- Board creation, rename, deletion, duplicate, pin/unpin, ordering, and menu-bar board switching.
- Pinned boards appear first in the `Boards` menu.
- Preferences window opened from the menu bar.
- Board opacity preference with live preview.
- Slide edge preference for top, bottom, left, and right.
- Keyboard shortcut preference with a lightweight native recorder and reset action.
- Launch-at-login preference plumbing through `SMAppService`; the control is disabled in SwiftPM debug runs until Cork is packaged as a `.app`.
- Drag-and-drop image imports from Finder.
- Drag-and-drop plain text imports.
- Drag-and-drop URL imports as dedicated URL cards.
- Drag-and-drop file imports as dedicated file cards.
- Resizable cards with a selected-card bottom-right handle.
- Minimum and maximum card sizes.
- Edge-aware movement and resizing bounds.
- Hover and selected states for direct manipulation.
- Downsampled cached thumbnails for large local image cards.
- URL-card context menu actions, including opening links in the default browser.
- File-card context menu actions, including opening files and revealing them in Finder.
- JSON-backed persistence in Application Support.
- Autosave for board selection, board changes, card creation, card editing, card movement, card resizing, and card actions.
- Autosave for app preferences, including board opacity, slide edge, launch-at-login intent, and keyboard shortcut.
- A separate `CorkCore` target for board and card models.
- Unit tests for board selection, board management, card movement, card resizing, card creation, URL/file/palette card creation/editing/imports, Markdown text cards, board lifecycle commands, import resolution, app settings, snapshot encoding, JSON persistence, and autosave.

Not implemented yet:

- Copied asset storage for imported files and remote images.
- Rich URL previews and favicons.
- Packaged `.app` release workflow.

## Run

From the project directory:

```sh
cd /Users/miguel/Projects/Cork
swift run Cork
```

Use `Command` + `Option` + `B` to show or hide the board by default. You can change the shortcut in Preferences or use the Cork menu bar item.

## Test

```sh
swift test
```

If the project has just been moved between directories and Swift reports stale `ModuleCache` or `SwiftShims` errors, clean the package once:

```sh
swift package clean
swift test
```

## Project Layout

```text
Sources/
  Cork/
    App/        Menu bar app lifecycle and coordination
    Board/      Slide-in panel and board UI
    HotKeys/    Global keyboard shortcut support
  CorkCore/     Board, card, and layout domain model
Tests/
  CorkCoreTests/
docs/
  architecture.md
  manual-testing.md
  milestones.md
```

## Technical Direction

Cork targets modern macOS and prefers native Apple APIs:

- Swift and SwiftUI for app structure and views.
- AppKit where macOS windowing behavior requires it.
- `MenuBarExtra` for the menu bar utility surface.
- Carbon hot keys for the first global shortcut.
- Small JSON-backed persistence adapters for local board state and app settings.

The codebase is intentionally split so product logic can be tested without AppKit and SwiftUI. `CorkCore` owns the board model and import intent resolution. The app target owns presentation, window behavior, hot keys, and AppKit drag-and-drop adapters.

## Next Development Slice

The next slice continues Milestone 9: preferences and system behavior.

- Verify launch at login in a packaged `.app` build.
- Continue system-behavior polish around multi-monitor and active-application rules.
- Keep rich URL previews, favicons, copied asset storage, and sandbox bookmarks as later follow-ups.

See [docs/milestones.md](docs/milestones.md) for the broader build path.
