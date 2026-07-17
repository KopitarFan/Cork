# Cork Milestones

Cork should be built in thin, complete slices. Each milestone should leave the app runnable and keep the architecture easy to change.

## Iteration 1: Native Shell and Board Surface

Status: complete.

Completed: 2026-07-01.

Scope:

- Create the Swift package and app targets.
- Add a menu bar item.
- Add a global toggle shortcut.
- Add a top-edge slide-in board panel.
- Render sample boards and draggable cards.
- Add model tests for board selection and item movement.

Exit criteria:

- Cork runs locally with `swift run Cork`.
- The menu bar item can show and hide the board.
- `Command` + `Option` + `B` can show and hide the board.
- Sample cards can be dragged.
- `swift test` passes.

Closeout verification:

- Manual core-flow testing passed.
- Awkward-case testing from `docs/manual-testing.md` passed.
- Full-screen Spaces, multiple desktops, hot-key behavior, menu bar behavior, sleep/wake, display changes, and animation feel were verified as acceptable for Milestone 1.

## Iteration 2: Persistence

Status: complete.

Completed: 2026-07-01.

Goal: Cork remembers boards and card positions across launches.

Scope:

- Add a `BoardRepository` abstraction.
- Save all boards.
- Save the selected board ID.
- Save card frames and content.
- Restore state on launch.
- Fall back to sample boards on first launch or unreadable state.
- Add tests for repository round trips.

Implementation notes:

- Start with the simplest reliable local storage.
- Keep persistence out of SwiftUI views.
- Prefer Application Support for user data.
- Decide whether the first implementation should use SwiftData or JSON after modeling the repository boundary.

Exit criteria:

- Move a card, quit Cork, relaunch Cork, and see the card in the moved position.
- Switch boards, quit Cork, relaunch Cork, and see the same selected board.
- Saved state tests pass.

Completed:

- Added `BoardLibrarySnapshot`.
- Added the `BoardRepository` persistence boundary.
- Added `JSONBoardRepository`.
- Wired app startup to load from Application Support.
- Added debounced autosave for board selection and card movement.
- Added quit-time autosave flushing.
- Added repository, snapshot, and autosave tests.
- Added persistence acceptance tests for missing-save fallback, selected board restore, moved card restore, and full board-library round trips.

Closeout verification:

- Manual persistence testing passed.
- Moving cards persisted across relaunch.
- Selected board persisted across relaunch.
- Persistence branch was committed, pushed, reviewed, merged, and landed on `main`.

## Iteration 3: Selection and Card Actions

Status: complete.

Completed: 2026-07-01.

Goal: users can work with cards intentionally, not just drag samples.

Scope:

- Add selected-card state.
- Add keyboard movement for selected cards.
- Add delete card.
- Add duplicate card.
- Add a minimal contextual card menu.
- Add visible focus/selection treatment that still feels native and quiet.

Exit criteria:

- A card can be selected with pointer interaction.
- A selected card can be moved with keyboard commands.
- A selected card can be deleted and duplicated.
- Card actions are routed through the store or command layer.

Completed:

- Added selected-card state.
- Added pointer selection and canvas-click selection clearing.
- Added subtle selected-card treatment.
- Added arrow-key movement for selected cards.
- Added delete and duplicate commands.
- Added card context menu actions.
- Added store tests for selection, movement, delete, duplicate, clamping, and autosave behavior.

Closeout verification:

- Manual card interaction testing passed.
- Selecting each card works.
- Clicking the board background clears selection without breaking future selection.
- Drag movement works for each card.
- Arrow-key and `Shift` + arrow-key movement work for the selected card.
- `Command-D`, Delete, and right-click Duplicate/Delete work.
- Layout and action results persist across relaunch.

## Iteration 4: Real Card Creation

Status: complete.

Completed: 2026-07-02.

Goal: users can build a useful board without editing sample data.

Scope:

- Add text note creation.
- Add checklist creation.
- Add local image card creation.
- Add board creation.
- Add board rename.
- Add board deletion with confirmation.

Implementation notes:

- Keep editing lightweight and contextual.
- Avoid turning the board into a complex editor.
- Let new cards appear near the visible center or last pointer/drop location.

Exit criteria:

- A user can create, edit, move, and delete text notes.
- A user can create, edit, move, and delete checklists.
- A user can add an image card from a local file.
- Boards can be created, renamed, switched, and deleted.

Completed:

- Added store commands for creating text, checklist, and image cards.
- Added store commands for editing text, checklist, and image cards.
- Added store commands for creating, renaming, and deleting boards.
- Added native AppKit dialogs for lightweight card and board editing.
- Added local image creation through `NSOpenPanel`.
- Added board header controls for card creation, card editing, and board actions.
- Added menu bar commands for card creation and board management.
- Added double-click and right-click Edit for cards.
- Added local image thumbnail rendering for file-backed image cards.
- Added tests for card creation, card editing, board lifecycle commands, clamping, autosave, and rejection cases.

Closeout verification:

- Manual real-card creation testing passed.
- Text notes can be created, edited, moved, deleted, persisted, and restored.
- Checklists can be created, edited, moved, deleted, persisted, and restored.
- Local image cards can be created from file picker selections and persisted.
- Boards can be created, renamed, switched, deleted with confirmation, persisted, and restored.
- Step 7 automated verification passed: `swift test`, `swift build`, and `git diff --check`.
- `swift test` passed with 64 tests and 0 failures.

## Iteration 5: Drag and Drop Imports

Status: complete.

Completed: 2026-07-02.

Goal: the board feels like a native macOS drop target.

Scope:

- Accept image drops from Finder and Safari.
- Accept file drops from Finder.
- Accept URL drops from browsers.
- Accept plain text drops.
- Add an import resolver that converts dropped providers into card creation intents.
- Keep copied asset storage in view as a follow-up.

Implementation notes:

- Start with referenced local files.
- Keep security-scoped bookmarks in mind for sandboxed builds.
- Drops should land at the pointer location when possible.

Exit criteria:

- Dropping an image creates an image card.
- Dropping a file creates a file card.
- Dropping a URL creates a URL card.
- Dropping plain text creates a text card.
- Failed imports do not crash or block the app.

Completed:

- Added a `BoardImportIntent` model for import commands.
- Added a `BoardImportResolver` in `CorkCore` for pasteboard-independent import classification.
- Added an AppKit `BoardDropResolver` adapter for `NSPasteboard` values.
- Added `BoardStore.importItems(_:at:constrainedTo:)`.
- Wired the board input layer to accept image, file, URL, and plain-text drops.
- Dropped image files create image cards backed by file references.
- Dropped plain text creates text cards.
- Dropped URLs create dedicated URL cards.
- Dropped non-image files create dedicated file cards.
- Drops land at the board-coordinate drop point and multiple file drops are staggered.
- Added tests for import resolution, store import commands, clamping, autosave, empty imports, multiple file imports, and precedence rules.

Closeout verification:

- Manual drag-and-drop testing passed.
- Finder image drops create image cards at the drop point.
- Plain text drops create text cards.
- Browser URL drops create dedicated URL cards.
- Non-image file drops create dedicated file cards.
- Imported cards can be moved, persisted, and restored.
- Step 7 automated verification passed: `swift test`, `swift build`, and `git diff --check`.
- `swift test` passed with 80 tests and 0 failures.

Deferred:

- Rich URL previews and favicons.
- Copied asset storage in Application Support.
- Security-scoped bookmarks for sandboxed referenced files.

## Iteration 6: Resizing and Layout Polish

Status: complete.

Completed: 2026-07-02.

Goal: cards feel stable, direct, and pleasant under repeated use.

Scope:

- Add card resizing.
- Add minimum and maximum card sizes.
- Add edge-aware movement bounds.
- Add basic snap or alignment assistance if it feels useful.
- Improve hover and selected states.
- Tune animations for opening, closing, dragging, and resizing.

Exit criteria:

- Cards can be resized without layout jumps.
- Cards remain within usable board bounds.
- Text does not overflow awkwardly in normal card sizes.
- Repeated drag and resize interactions feel smooth.

Completed:

- Added `BoardStore.resizeItem(_:to:constrainedTo:)`.
- Added `BoardStore.resizeSelectedItem(to:constrainedTo:)`.
- Added minimum and maximum card size defaults.
- Added edge-aware resize clamping that keeps cards inside the board.
- Added a selected-card bottom-right resize handle.
- Added pointer hover state and drag/resize cursor feedback.
- Improved card content clipping so text, checklists, and images stay inside resized frames.
- Replaced full-size image decoding during rendering with a downsampled thumbnail view backed by `ImageIO` and `NSCache`.
- Added tests for resize bounds, min/max sizes, selected-item resizing, autosave, debounced resize autosave, and persistence round trips.

Closeout verification:

- Manual resizing and layout-polish testing passed.
- Text, checklist, and image cards resize without layout jumps.
- Cards remain within board bounds when moved and resized.
- Large local image cards can be dragged and resized without the earlier slowdown.
- Resized card frames persist across relaunch.
- Step 7 automated verification passed: `swift test`, `swift build`, and `git diff --check`.
- `swift test` passed with 92 tests and 0 failures.

Deferred:

- Snap or alignment assistance. The current direct-manipulation behavior feels sufficient for this slice.

## Iteration 7: More Card Types

Status: complete.

Completed: 2026-07-08.

Goal: Cork supports the core ambient-context item types.

Scope:

- Markdown notes.
- URL cards.
- File cards.
- Color palette cards.
- Simple text snippet cards if they differ meaningfully from notes.

Implementation notes:

- Add one card type at a time.
- Each card type should have a narrow domain payload and renderer.
- Rich previews should be optional and cached.

Exit criteria:

- The board supports text, checklist, image, URL, file, markdown, and palette cards.
- Each type can be created, moved, persisted, and deleted.

Completed:

- Added a `URLCard` domain payload.
- Added `BoardItemContent.url`.
- Added `BoardStore.createURLCard(...)`.
- Added `BoardStore.updateURLCard(...)`.
- Changed web URL imports to create dedicated URL cards instead of text placeholder cards.
- Added a URL card renderer with visible card-type icon treatment.
- Added native URL editing through double-click, the board header edit button, and the existing edit command path.
- Added right-click `Open Link` for URL cards, routed through `NSWorkspace`.
- Added `TextCardFormat` so text cards can render as plain text or Markdown.
- Added Markdown note creation and editing through the existing text-card dialog.
- Added Markdown rendering for headings, line breaks, lists, and inline emphasis.
- Added a `FileCard` domain payload.
- Added `BoardItemContent.file`.
- Added `BoardStore.createFileCard(...)`.
- Changed non-image file imports to create dedicated file cards instead of text placeholder cards.
- Added a file card renderer with native document icon treatment, path display, and missing-file state.
- Added right-click `Open File` and `Reveal in Finder` for file cards, routed through `NSWorkspace`.
- Added a `ColorPaletteCard` domain payload.
- Added `BoardItemContent.palette`.
- Added `BoardStore.createColorPaletteCard(...)`.
- Added `BoardStore.updateColorPaletteCard(...)`.
- Added color palette creation from the board header and menu bar.
- Added palette parsing for comma-, semicolon-, space-, and newline-separated hex values.
- Added a palette card renderer with normalized hex labels, swatches, and overflow count.
- Added tests for URL, Markdown, file, and palette card creation, editing, import routing, clamping, autosave, snapshot encoding, and persistence.

Closeout verification:

- Manual URL-card testing passed.
- Manual Markdown note testing passed.
- Manual file-card testing passed.
- Manual color-palette testing passed.
- Dragged browser URLs create URL cards.
- URL card icons, title, host, and URL text are visible.
- Markdown notes can be created, edited, moved, resized, duplicated, deleted, persisted, and restored.
- Dragged non-image files create file cards.
- File cards can be moved, resized, duplicated, deleted, opened, revealed in Finder, persisted, and restored.
- Palette cards can be created, edited, moved, resized, duplicated, deleted, persisted, and restored.
- URL cards can be edited, moved, resized, duplicated, deleted, opened, persisted, and restored.
- Automated verification passed: `swift test`, `swift build`, and `git diff --check`.
- `swift test` passed with 121 tests and 0 failures.

Deferred:

- Rich URL previews and favicons.
- Copied asset storage in Application Support.
- Security-scoped bookmarks for sandboxed referenced files.
- A distinct simple-snippet card type. Plain text notes cover the current need.

## Iteration 8: Board Management

Status: complete.

Completed: 2026-07-09.

Goal: multiple boards become practical for everyday use.

Scope:

- Improve board switching from the menu bar.
- Add pinned or favorite boards.
- Add board ordering.
- Add duplicate board.
- Add a simple board picker if the menu becomes crowded.

Exit criteria:

- A user with several boards can switch quickly.
- Pinned boards are easy to reach.
- Board management remains lightweight.

Completed:

- Added `CorkBoard.isPinned` and `CorkBoard.sortIndex` management metadata with backward-compatible decoding for older saved boards.
- Added `BoardStore` commands for pinning, unpinning, reordering, and duplicating boards.
- Normalized board ordering after create, move, duplicate, and delete operations.
- Duplicating a board creates a selected copy with fresh card IDs.
- Updated the menu bar `Boards` menu to list all boards, with pinned boards first.
- Added current-board menu actions for pin/unpin, duplicate, move up/down, rename, and delete.
- Mirrored board-management actions in the board header ellipsis menu.
- Added tests for board metadata decoding, pinning, ordering, duplication, autosave, and persistence.

Closeout verification:

- Manual board-management testing covered board listing, pin/unpin, duplicate, move up/down, relaunch persistence, and the `Boards` menu placement.
- Fixed the confusing extra current-board row that appeared under `New Board` after pinning and unpinning.
- Automated verification passed: `swift test`, `swift build`, and `git diff --check`.
- `swift test` passed with 134 tests and 0 failures.

Deferred:

- A separate board picker. The current menu remains light enough for this milestone.

## Iteration 9: Preferences and System Behavior

Status: in progress.

Goal: Cork becomes configurable without becoming fussy.

Scope:

- Configure global shortcut.
- Configure slide edge.
- Configure board surface opacity.
- Configure card opacity.
- Configure launch at login.
- Add multi-monitor behavior.
- Add optional active-application show/hide rules.

Exit criteria:

- Preferences are discoverable but not central to the app.
- Settings persist reliably.
- Defaults remain strong enough that configuration is optional.

Completed so far:

- Added `AppSettings` for app-level preferences.
- Added `SettingsRepository`, `JSONSettingsRepository`, and `SettingsStore`.
- Store settings in `~/Library/Application Support/Cork/settings.json`.
- Added a native Preferences window opened from the menu bar.
- Fixed Preferences window ordering so it opens above the board.
- Added a board surface opacity preference with live board preview.
- Added a separate card opacity preference for items on the board.
- Added a slide-edge preference with `Top`, `Bottom`, `Left`, and `Right` options.
- Wired the board panel to show and hide from the selected slide edge.
- Added launch-at-login preference plumbing through `SMAppService`.
- Disabled the launch-at-login toggle in SwiftPM debug runs where Cork is not packaged as a `.app`.
- Restored Launch at Login in the packaged app target, synchronized the preference with the system service state, and added approval guidance plus a direct Login Items settings button.
- Added `HotKeyConfiguration` and `HotKeyModifier` to model user-configurable global shortcuts.
- Added `HotKeyController` to observe settings and re-register the active global shortcut.
- Added a native shortcut recorder to Preferences with validation, status messaging, and reset-to-default behavior.
- Updated the menu bar Show/Hide command to display the saved shortcut when it can be represented as a menu key equivalent.
- Switched the menu bar extra to a reliable native grid symbol declaration.
- Added an on-board title-bar switcher for changing boards from the board surface.
- Added a selected-card action menu to both the menu bar and board title bar.
- Mirrored Add Card, Selected Card, Boards, and Settings command surfaces across the menu bar and board title bar.
- Reorganized the board title-bar controls into labeled `Add`, `String`, `Card`, `Board`, and `Settings` groups.
- Added `BoardTheme` with Cork, Poster, and System board surfaces.
- Made the Cork board surface the default theme.
- Added persisted per-card appearance controls for an optional background color and font design.
- Added card appearance commands to the card context menu and both Selected Card menus.
- Added built-in Agile Sprint, Kanban, Vision Board, Weekly Schedule, Random Arrangement, Project Hub, Writing Room, and SWOT Analysis templates.
- Added template creation to the menu bar and board title-bar Board menus.
- Added image replacement from the card context menu and both Selected Card menus while preserving card metadata.
- Added an image-card double-click chooser for renaming the card or replacing its image.
- Added `Control` + `Tab` and `Control` + `Shift` + `Tab` board cycling with wraparound and mirrored Board menu commands.
- Added persisted card connections with straight-line and curved red-string rendering.
- Added a two-step source/target connection workflow, visible source-card state, style switching, cancellation, and per-card connection removal.
- Added a selected `String` title-bar tool with crosshair mode, live string preview, direct card-to-card dragging, repeat drawing, and Escape cancellation.
- Added automatic connection cleanup when cards are deleted and endpoint remapping when boards are duplicated.
- Added optional custom title-bar and board-surface colors with independent native color wells, swap, and reset actions.
- Added `BoardDisplayMode` with Compact, Standard, and Large panel sizes.
- Wired display-mode changes into live board-panel geometry updates.
- Added Preferences controls for board theme and board size.
- Changed the board panel to normal window stacking so other app windows can come forward when clicked.
- Updated the global shortcut and menu-bar toggle to bring Cork forward when it is visible but behind another window.
- Added compact hover labels that reveal card names while preserving drag, resize, and connection hit testing.
- Added a native Quick Start window with the current shortcut, import guidance, board basics, and direct Show Cork and Preferences actions.
- Added one-time first-run presentation backed by persisted settings, with reopen commands in both the menu bar and board Settings menu.
- Added settings tests for defaults, backward-compatible decoding, JSON persistence, store updates, surface opacity, card opacity, theme updates, custom board colors, display-mode updates, Quick Start state, shortcut validation, shortcut autosave, and quit-time flush behavior.
- Added tests for per-card appearance defaults, normalization, backward-compatible decoding, duplication, autosave, template metadata, template contents, fresh card IDs, and template-based board creation.
- Added tests for board cycling, connection persistence, backward-compatible decoding, validation, style updates, autosave, removal, card deletion cleanup, and duplicate-board endpoint remapping.

Automated verification:

- `swift test --quiet` passed with 228 tests and 0 failures.
- `swift build` passed.
- `git diff --check` passed.

Manual verification:

- Preferences still opens above the board.
- Keyboard shortcut changes persist across relaunch.
- The default `Command` + `Option` + `B` shortcut can be restored.
- Invalid bare-key shortcut input is rejected.
- The menu bar Show/Hide command remains available as a fallback.
- The menu bar command and global shortcut can bring Cork back to the front when it is visible behind another window.
- Existing saved boards remained intact after the shortcut-preferences changes; a blank board can simply mean the selected board has no cards.

Manual verification needed for current branch:

- Board title-bar switcher lists and changes boards.
- Selected-card actions work from both the menu bar and board title bar.
- Other app windows can come in front of Cork when clicked, and Cork can be brought back with the shortcut or menu bar command.
- Cork, Poster, and System themes are visually acceptable and persist across relaunch.
- Per-card background and font choices affect only the selected card, remain readable, and persist across relaunch.
- All built-in templates create named boards with editable starter cards from both Board menus.
- Image replacement preserves the selected image card's title, frame, appearance, and connections.
- Board cycling wraps in both directions and works from the keyboard and both Board menus.
- The title-bar `String` tool draws directly between cards, stays active for repeat drawing, and exits from the control or Escape.
- Line and string connections track moved or resized cards, persist across relaunch, and clean up safely.
- Custom board colors update live, reset correctly, can be disabled, and persist across relaunch.
- Board surface opacity and card opacity can be adjusted independently.
- Compact, Standard, and Large board sizes update the panel geometry and persist across relaunch.
- Compact mode leaves enough of the underlying app visible to make drag-and-drop staging easier.
- Hovering every card type reveals its name without blocking interaction or clipping at board edges.
- The Quick Start guide appears once for a fresh settings state and remains available from both Settings surfaces.

Remaining:

- Verify launch-at-login behavior in a packaged `.app` build.
- Decide how much multi-monitor behavior belongs in this milestone versus packaging/release readiness.
- Keep active-application show/hide rules as optional follow-up unless the settings architecture needs it now.

## Iteration 10: Search and Quick Capture

Goal: users can quickly add and recover ambient context.

Scope:

- Add search across board names and card content.
- Add Quick Capture shortcut for a new text note.
- Add optional capture-to-current-board behavior.
- Add Apple Shortcuts integration if the command layer is ready.

Exit criteria:

- Search finds boards and card content quickly.
- Quick Capture creates a note without navigating the app.
- Shortcuts integration uses the same underlying commands as the app.

## Iteration 11: Packaging and Release Readiness

Status: in progress.

Started: 2026-07-16.

Goal: Cork can be installed and run like a normal macOS utility.

Scope:

- Add a dedicated app project or packaging workflow.
- Add app icon and menu bar symbol.
- Add bundle identifier.
- Add sandbox and entitlements where appropriate.
- Add release build documentation.
- Add a simple manual QA checklist.

Exit criteria:

- Cork builds as a `.app`.
- Cork can be launched outside SwiftPM.
- The menu bar item, global shortcut, persistence, and board window work in a packaged build.

Completed so far:

- Created clean illustrated, unmasked 1024x1024 Cork app-icon master artwork following Apple's current square layout guidance.
- Added a complete macOS `AppIcon.appiconset` with 1x and 2x assets from 16x16 through 512x512.
- Validated the asset catalog with Xcode's asset compiler, producing `AppIcon.icns` and `Assets.car` without warnings.
- Documented the packaging asset layout and the next app-target step in `Packaging/README.md`.
- Added a persisted first-run Quick Start experience suitable for fresh packaged installs.
- Added `Cork.xcodeproj` with a shared `Cork App` scheme and a native macOS application target that links the local `CorkCore` package product.
- Added App Store bundle metadata, Productivity category, version/build settings, accessory-app behavior, and encryption declaration.
- Added App Sandbox, user-selected read-only file access, app-scoped bookmark entitlement support, and Hardened Runtime configuration.
- Added a privacy manifest declaring no tracking or data collection for the current app.
- Attached the complete icon asset catalog and privacy manifest to the app target.
- Added a Release configuration that archives a universal Apple silicon and Intel `Cork.app`.
- Added a packaged-app release guide and manual QA coverage.
- Hardened Launch at Login handling for enabled, disabled, approval-required, unavailable, and error states.
- Verified that the Debug app build and unsigned Release archive succeed through Xcode.
- Added backward-compatible bookmark fields to image and file cards.
- Capture read-only app-scoped bookmarks from Finder drops and native image selection.
- Resolve security-scoped file access only while generating thumbnails, checking files, opening files, or revealing them in Finder.
- Preserve bookmarks through rename, replacement, duplication, autosave, JSON reload, and older-board decoding.
- Configured signing team `FLJNW3455S` and bundle identifier `net.miguelrodriguez.Cork`.
- Verified a warning-free team-signed Debug build and signed universal Release archive with the intended sandbox entitlements.
- Expanded bookmark creation, replacement, backward compatibility, and JSON persistence coverage to 228 tests.

Next:

- Verify Cork's file references, global hot key, persistence, and Launch at Login behavior in the signed packaged build.
- Prepare the public privacy policy, support URL, App Store description, and 16:10 screenshots.
- Validate and upload the signed archive through Xcode Organizer.

## Backlog

- Image galleries.
- Rich URL previews.
- Board opacity presets.
- Import/export board archive.
- iCloud sync investigation.
- Per-app board automation.
- Command palette.
- Undo and redo.
- Accessibility audit.
- Crash logging strategy.
