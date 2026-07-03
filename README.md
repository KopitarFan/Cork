# Cork

Cork is a macOS desktop utility for ambient work context: the handful of notes, images, links, files, and reminders someone wants visible while working without switching applications.

It behaves like a virtual corkboard that lives just off-screen. Press the global shortcut or use the menu bar item and the board slides down from the top edge. Press the shortcut again and it disappears.

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

The project currently has the first runnable foundation, persistence layer, card interaction layer, real card creation flow, and drag-and-drop imports:

- Menu bar app.
- Global keyboard shortcut: `Command` + `Option` + `B`.
- Top-edge slide-in board panel.
- Multiple named sample boards.
- Text, checklist, and image cards.
- Card creation from the board header and menu bar.
- Lightweight editing for text notes, checklist items, and image card titles.
- Local image card creation through the native file picker.
- Draggable card positions.
- Selected-card state with keyboard movement.
- Duplicate, delete, and edit actions for cards.
- Context menus for card actions, including double-click edit.
- Board creation, rename, deletion, and menu-bar board switching.
- Drag-and-drop image imports from Finder.
- Drag-and-drop plain text imports.
- Drag-and-drop URL imports as lightweight text placeholder cards.
- Drag-and-drop file imports as lightweight text placeholder cards.
- JSON-backed persistence in Application Support.
- Autosave for board selection, board changes, card creation, card editing, card movement, and card actions.
- A separate `CorkCore` target for board and card models.
- Unit tests for board selection, card movement, card creation, card editing, board lifecycle commands, import resolution, snapshot encoding, JSON persistence, and autosave.

Not implemented yet:

- Dedicated URL and file card renderers.
- Copied asset storage for imported files and remote images.
- Card resizing.
- Packaged `.app` release workflow.

## Run

From the project directory:

```sh
cd /Users/miguel/Projects/Cork
swift run Cork
```

Use `Command` + `Option` + `B` to show or hide the board. You can also use the Cork menu bar item.

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
- A small JSON-backed persistence adapter for local board state.

The codebase is intentionally split so product logic can be tested without AppKit and SwiftUI. `CorkCore` owns the board model and import intent resolution. The app target owns presentation, window behavior, hot keys, and AppKit drag-and-drop adapters.

## Next Development Slice

The next slice is Milestone 6: resizing and layout polish:

- Add card resizing.
- Add minimum and maximum card sizes.
- Add edge-aware movement bounds.
- Improve hover and selected states.
- Tune drag and resize feel.

See [docs/milestones.md](docs/milestones.md) for the broader build path.
