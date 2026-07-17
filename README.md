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

The project currently has the first runnable foundation, persistence layer, card interaction layer, real card creation flow, drag-and-drop imports, resizing/layout polish, the core Milestone 7 card types, board-management polish, board UI polish, and the first preferences surface:

- Menu bar app.
- Configurable global keyboard shortcut, defaulting to `Command` + `Option` + `B`.
- Configurable slide-in board edge.
- Multiple named sample boards.
- Text, checklist, image, URL, file, and color palette cards.
- Plain-text and Markdown text note formats.
- Card creation from the board header and menu bar.
- Lightweight editing for text notes, Markdown notes, checklist items, image card titles, URL cards, and color palettes.
- Local image card creation through the native file picker.
- Image replacement that preserves the card's title, layout, appearance, and connections.
- Draggable card positions.
- Hover labels that reveal each card's full name without opening it.
- Selected-card state with keyboard movement.
- Duplicate, delete, and edit actions for cards.
- Selected-card action menu in both the menu bar and board title bar.
- Context menus for card actions, including double-click edit and an image-card chooser for renaming or replacing the image.
- Per-card background color and font choices, available from card context menus and both Selected Card menus.
- Persisted card-to-card connections with straight-line and red-string styles, plus a selected title-bar String tool for drawing directly between cards.
- Board creation, rename, deletion, duplicate, pin/unpin, ordering, and menu-bar board switching.
- Built-in Agile Sprint, Kanban, Vision Board, Weekly Schedule, Random Arrangement, Project Hub, Writing Room, and SWOT Analysis board templates.
- On-board title-bar switcher for changing boards without leaving the board surface.
- Quick next/previous board switching with `Control` + `Tab` and `Control` + `Shift` + `Tab` while Cork is active.
- Mirrored Add Card, Selected Card, Boards, and Settings controls in the menu bar and board title bar.
- Pinned boards appear first in the `Boards` menu.
- Preferences window opened from the menu bar or the board title bar.
- A one-time Quick Start guide for fresh installs, reopenable from both Settings surfaces.
- Board surface opacity preference with live preview.
- Card opacity preference for items on the board.
- Board theme preference with Cork, Poster, and System views.
- Optional custom title-bar and board-surface colors with native color wells.
- Board size preference with Compact, Standard, and Large modes for easier drag-and-drop staging.
- Slide edge preference for top, bottom, left, and right.
- Keyboard shortcut preference with a lightweight native recorder and reset action.
- Launch-at-login preference through `SMAppService`, including system approval guidance in packaged builds.
- Drag-and-drop image imports from Finder.
- Drag-and-drop plain text imports.
- Drag-and-drop URL imports as dedicated URL cards.
- Drag-and-drop file imports as dedicated file cards.
- Durable read-only security-scoped bookmarks for imported images and files in sandboxed builds.
- Resizable cards with a selected-card bottom-right handle.
- Minimum and maximum card sizes.
- Edge-aware movement and resizing bounds.
- Hover and selected states for direct manipulation.
- Downsampled cached thumbnails for large local image cards.
- URL-card context menu actions, including opening links in the default browser.
- File-card context menu actions, including opening files and revealing them in Finder.
- Normal window stacking so other app windows can come forward when clicked, with the global shortcut and menu bar command bringing Cork back to the front.
- JSON-backed persistence in Application Support.
- Autosave for board selection, board changes, template creation, card creation, card editing, image replacement, per-card appearance, card connections, card movement, card resizing, and card actions.
- Autosave for app preferences, including board surface opacity, card opacity, theme, custom board colors, size, slide edge, launch-at-login intent, keyboard shortcut, and Quick Start completion.
- A separate `CorkCore` target for board and card models.
- Unit tests for board selection, board cycling, board management, board templates, per-card appearance, card connections, card movement, card resizing, card creation, URL/file/palette card creation/editing/imports, Markdown text cards, board lifecycle commands, import resolution, app settings, preference updates, snapshot encoding, JSON persistence, and autosave.
- A native Xcode app target with App Store metadata, sandbox entitlements, privacy manifest, release configuration, and complete macOS icon assets.

Not implemented yet:

- Copied asset storage for imported files and remote images.
- Rich URL previews and favicons.
- Final App Store Connect listing, screenshots, validation, and submission.

## Run

From the project directory:

```sh
cd /Users/miguel/Projects/Cork
swift run Cork
```

Use `Command` + `Option` + `B` to show the board by default. If Cork is visible but behind another window, the shortcut brings it back to the front; press it again while Cork is frontmost to hide it. You can change the shortcut in Preferences or use the Cork menu bar item.

For a packaged build, open `Cork.xcodeproj`, select the shared `Cork App` scheme, choose `My Mac`, and run. This path compiles the icon, privacy manifest, sandbox entitlements, and Launch at Login support into `Cork.app`.

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
Packaging/
  AppIcon/             Unmasked 1024px source artwork
  Assets.xcassets/     Complete macOS AppIcon set
  Info.plist           Bundle and App Store metadata
  Cork.entitlements    App Sandbox capabilities
  PrivacyInfo.xcprivacy
docs/
  app-store-release.md
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

Iteration 11 packaging is active. Team-signed Debug builds and a signed universal Release archive are working; the next release slice is packaged-app QA and storefront preparation.

- Run the packaged-app checklist, including file/image relaunch persistence, the global shortcut, and Launch at Login.
- Prepare the privacy policy, support URL, listing copy, and screenshots.
- Validate and upload the signed archive through Xcode Organizer.

See [docs/app-store-release.md](docs/app-store-release.md) for the release workflow and [docs/milestones.md](docs/milestones.md) for the broader build path.
