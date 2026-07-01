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

## Iteration 4: Real Card Creation

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

## Iteration 5: Drag and Drop Imports

Goal: the board feels like a native macOS drop target.

Scope:

- Accept image drops from Finder and Safari.
- Accept file drops from Finder.
- Accept URL drops from browsers.
- Accept plain text drops.
- Add an import resolver that converts dropped providers into card creation intents.
- Store copied assets in Application Support.

Implementation notes:

- Start with copied images and referenced files.
- Keep security-scoped bookmarks in mind for sandboxed builds.
- Drops should land at the pointer location when possible.

Exit criteria:

- Dropping an image creates an image card.
- Dropping a file creates a file card or referenced placeholder card.
- Dropping a URL creates a URL card.
- Dropping plain text creates a text card.
- Failed imports do not crash or block the app.

## Iteration 6: Resizing and Layout Polish

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

## Iteration 7: More Card Types

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

## Iteration 8: Board Management

Goal: multiple boards become practical for everyday use.

Scope:

- Improve board switching from the menu bar.
- Add pinned or favorite boards.
- Add board ordering.
- Add duplicate board.
- Add a simple board picker if the menu becomes crowded.

Exit criteria:

- A user with several boards can switch quickly.
- Favorite boards are easy to reach.
- Board management remains lightweight.

## Iteration 9: Preferences and System Behavior

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
