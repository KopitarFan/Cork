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

The project currently has the first runnable foundation and persistence layer:

- Menu bar app.
- Global keyboard shortcut: `Command` + `Option` + `B`.
- Top-edge slide-in board panel.
- Multiple named sample boards.
- Sample text, checklist, and image cards.
- Draggable card positions.
- JSON-backed persistence in Application Support.
- Autosave for board selection and card movement.
- A separate `CorkCore` target for board and card models.
- Unit tests for board selection, card movement, snapshot encoding, JSON persistence, and autosave.

Not implemented yet:

- Creating and editing real cards.
- Drag-and-drop imports.
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
- SwiftData or a small persistence adapter for local board state.

The codebase is intentionally split so product logic can be tested without AppKit and SwiftUI. `CorkCore` owns the board model. The app target owns presentation, window behavior, hot keys, and eventually drag-and-drop import adapters.

## Next Development Slice

The next slice is Milestone 3: selection and card actions:

- Add selected-card state.
- Add keyboard movement for selected cards.
- Add delete and duplicate actions.
- Add a minimal contextual card menu.
- Add a native, quiet selected-card treatment.

See [docs/milestones.md](docs/milestones.md) for the broader build path.
