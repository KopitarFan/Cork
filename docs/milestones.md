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
- Configure board opacity.
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
- Added a board opacity preference with live board preview.
- Added a slide-edge preference with `Top`, `Bottom`, `Left`, and `Right` options.
- Wired the board panel to show and hide from the selected slide edge.
- Added launch-at-login preference plumbing through `SMAppService`.
- Disabled the launch-at-login toggle in SwiftPM debug runs where Cork is not packaged as a `.app`.
- Added settings tests for defaults, backward-compatible decoding, JSON persistence, store updates, autosave, and quit-time flush behavior.

Automated verification:

- `swift test --quiet` passed with 156 tests and 0 failures.
- `swift build` passed.
- `git diff --check` passed.

Remaining:

- Make the global shortcut configurable.
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
