# Manual Testing Guide

This guide covers the awkward macOS cases that are hard to prove with unit tests: full-screen Spaces, multiple desktops, menu bar behavior, configurable global hot keys, display geometry, user-facing card creation flows, drag-and-drop imports, URL cards, and resizing/layout polish.

Use the relevant sections before closing each milestone and whenever Cork's windowing, hot-key, menu bar, persistence, card creation, import, or card layout behavior changes.

## Test Setup

Start from a clean run:

```sh
cd /Users/miguel/Projects/Cork
swift run Cork
```

Before testing:

- Quit any older Cork process from the menu bar item.
- Run `swift test` once if code changed.
- Note the macOS version.
- Note whether Stage Manager is on.
- Note the display setup: built-in display only, external monitor, mirrored displays, or separate displays.
- Note the Mission Control setting for "Displays have separate Spaces."

Milestone 1 is allowed to be simple. For now, a pass means Cork opens, hides, and remains recoverable without crashing, switching Spaces unexpectedly, or leaving an orphaned panel on screen.

## Baseline Smoke Test

Steps:

1. Launch Cork with `swift run Cork`.
2. Click the menu bar item.
3. Choose "Show Cork."
4. Drag each sample card.
5. Choose "Hide Cork."
6. Press `Command` + `Option` + `B`.
7. Press `Command` + `Option` + `B` again.
8. Switch boards from the menu bar.

Expected:

- Cork appears in the menu bar.
- The board slides in from the configured edge.
- The board hides without leaving artifacts.
- Cards drag smoothly and stay inside the board.
- Board switching updates the visible board.
- The app remains running as a menu bar utility.

Notes to capture:

- Animation feels too slow, too fast, or uneven.
- Board appears on an unexpected screen.
- Hot key does not work.
- Menu bar item disappears or becomes unresponsive.

## Real Card Creation

Run this section for Milestone 4 and whenever card creation, editing, board management, or persistence changes.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show the board.
3. Use the board header add-card menu to create a text note.
4. Enter a custom title and body, then save.
5. Move the text note.
6. Double-click the text note and edit the title and body.
7. Right-click the text note and delete it.
8. Use the board header add-card menu to create a checklist.
9. Enter several lines, including at least one `[x] Done item`, then save.
10. Move the checklist and edit it again.
11. Use the board header add-card menu to create an image card.
12. Choose a local image file.
13. Verify the image thumbnail appears.
14. Select the image card and use the pencil button to rename it.
15. Quit Cork from the menu bar.
16. Relaunch Cork.

Expected:

- New cards appear near the visible center of the board.
- Created cards are selected immediately.
- Text note edits update the visible card.
- Checklist lines become checklist entries.
- `[x]` and `- [x]` checklist lines are marked complete.
- Local image cards show a thumbnail when the file is still available.
- Card movement, edits, and deletion persist across relaunch.
- Canceling any creation or edit dialog leaves the board unchanged.

Failure notes:

- Which creation path failed: board header, menu bar, double-click, right-click, or pencil button.
- Whether the dialog opened behind the board or another app.
- Whether the card appeared off-screen or under another card in a confusing way.
- Whether persistence failed only before or after relaunch.
- Whether a local image file moved or was deleted between runs.

## Board Management

Run this section for Milestone 8 and whenever board metadata, the menu bar `Boards` menu, or board header board-actions menu changes.

Steps:

1. Launch Cork with `swift run Cork`.
2. Use the menu bar `Boards` menu to create three boards named `Alpha`, `Beta`, and `Gamma`.
3. Add one text note to `Beta`.
4. Open the menu bar `Boards` menu and verify `Alpha`, `Beta`, and `Gamma` are all listed.
5. Select `Beta` from the `Boards` menu.
6. Open `Boards` again and verify `Beta` has the selected-board checkmark.
7. Choose `Pin Current Board`.
8. Reopen `Boards` and verify `Beta` appears in the pinned group above unpinned boards.
9. Choose `Unpin Current Board`.
10. Reopen `Boards` and verify there is no extra `Beta` row below `New Board`; `Beta` should only appear in the board list.
11. Choose `Duplicate Current Board` and verify a `Beta Copy` board is selected.
12. Use `Move Current Board Up` and `Move Current Board Down` from the menu bar and verify the board list order changes.
13. Repeat pin/unpin, duplicate, and move from the board header ellipsis menu.
14. Rename `Beta Copy`.
15. Create a temporary board and delete it.
16. Try deleting the only remaining board if the library has just one board.
17. Quit and relaunch Cork.
18. Verify board order, pinned state, renamed boards, duplicated boards, selected board, and board contents restore correctly.

Expected:

- New boards are selected immediately.
- Board names trim extra whitespace.
- Blank board names are ignored.
- The menu bar `Boards` menu lists all boards.
- Pinned boards appear above unpinned boards.
- Selected boards show a checkmark.
- Pinned, unselected boards show a pin icon.
- Current-board actions do not create duplicate board-name rows under `New Board`.
- Duplicated boards copy their cards and are selected immediately.
- Duplicated boards are unpinned by default.
- Move up/down actions reorder the board list and disable at the top and bottom edges.
- Renamed boards appear in both the header and menu bar.
- Deleting a board requires confirmation.
- Cancel is the default-safe path in the delete confirmation.
- Cork prevents deleting the final remaining board.
- Board switching, board names, pinned state, board order, duplication, and board deletion persist across relaunch.

Failure notes:

- Whether the selected board changed unexpectedly.
- Whether a pinned board appeared in the wrong group.
- Whether a board appeared twice in the `Boards` menu.
- Whether move up/down changed the wrong board.
- Whether duplicated cards kept the original board's contents.
- Whether deleted boards came back after relaunch.
- Whether deleting the selected board chose a sensible fallback board.
- Whether menu bar board names became stale.

## Menu Bar Creation

Steps:

1. Hide the board.
2. Open the Cork menu bar item.
3. Create a text note from `New Card`.
4. Verify Cork shows the board after the card is created.
5. Hide the board again.
6. Create a checklist from `New Card`.
7. Hide the board again.
8. Create an image card from `New Card`.
9. Create a new board from the `Boards` menu.
10. Rename and delete the current board from the `Boards` menu.

Expected:

- Menu bar creation commands work while the board is hidden.
- Successful creation shows the board.
- Menu bar board actions affect the same selected board shown in the panel.
- Canceling dialogs leaves the board hidden or unchanged as appropriate.

Failure notes:

- Whether Cork failed to show the board after a successful creation.
- Whether commands affected the wrong board.
- Whether the menu dismissed before the native dialog became usable.

## Drag And Drop Imports

Run this section for Milestone 5 and whenever import resolution, persistence, or card rendering changes.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show the board.
3. Drag a `.png` or `.jpg` file from Finder onto the board.
4. Drag two image files from Finder at the same time.
5. Drag a non-image file, such as `.pdf`, `.txt`, or `.md`, from Finder.
6. Drag selected plain text from another app onto the board.
7. Drag a URL from a browser address bar onto the board.
8. Move each imported card.
9. Quit Cork from the menu bar.
10. Relaunch Cork.

Expected:

- Image file drops create image cards.
- Image cards appear near the drop point and show thumbnails while the source file is available.
- Multiple file drops create multiple cards staggered from the drop point.
- Non-image file drops create dedicated file cards containing the file name and path.
- Plain text drops create text cards.
- URL drops create dedicated URL cards.
- Imported cards are selected after creation.
- Imported cards can be moved, deleted, and duplicated like manually created cards.
- Imported card positions and content persist across relaunch.
- Unsupported or empty drops do not crash Cork or block future drops.

Known current limitations:

- Local files are referenced, not copied into Application Support.
- If a referenced image file is moved or deleted, Cork cannot render its thumbnail.
- If a referenced file is moved or deleted, Cork shows the file card as missing.
- URL cards are lightweight native cards; Cork does not fetch favicons or rich previews yet.

Failure notes:

- Source app and type: Finder image, Finder file, browser URL, selected text.
- Whether the card appeared at the drop point.
- Whether the drop created the wrong card type.
- Whether multiple dropped files preserved a sensible order.
- Whether imported content disappeared after relaunch.
- Whether a referenced source file moved between runs.

## URL Cards

Run this section for the URL-card slice of Milestone 7 and whenever URL imports, URL card editing, or link opening changes.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show the board.
3. Drag `https://github.com` or `https://www.apple.com` from a browser address bar onto the board.
4. Verify the card shows Cork's URL-card icon, title, host, and URL text.
5. Move and resize the URL card.
6. Double-click the URL card and edit the title.
7. Double-click the URL card again and edit the URL.
8. Select the URL card and use the board header pencil button to edit it.
9. Right-click the URL card and choose `Open Link`.
10. Duplicate and delete the URL card.
11. Quit Cork from the menu bar.
12. Relaunch Cork and verify the edited URL card restores correctly if it was not deleted.

Expected:

- Browser URL drops create URL cards, not text notes.
- URL cards use the visible card-type icon treatment.
- Editing accepts valid `http` and `https` URLs.
- Canceling the edit dialog leaves the URL card unchanged.
- `Open Link` opens the URL in the default browser.
- URL cards can be moved, resized, duplicated, deleted, persisted, and restored like other cards.

Known current limitations:

- Cork does not fetch site favicons.
- Cork does not render rich URL previews.
- URL cards are created through drag-and-drop imports for now, not the `New Card` menu.

Failure notes:

- Source app and URL used.
- Whether Cork created a URL card or a different card type.
- Whether the icon, title, host, or URL text was missing.
- Whether editing accepted an invalid URL or rejected a valid one.
- Whether `Open Link` launched the expected browser.

## Markdown Text Cards

Run this section for the Markdown-note slice of Milestone 7 and whenever text-card editing or rendering changes.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show the board.
3. Create a text note from the board header plus button.
4. Enable the `Markdown` checkbox.
5. Enter this body:

   ```markdown
   # Heading

   First line
   Second line with **bold** text

   - One
   - Two
   ```

6. Save the note.
7. Verify the card renders the heading, blank line spacing, line breaks, bold text, and list items.
8. Move and resize the Markdown card.
9. Double-click the card and disable the `Markdown` checkbox.
10. Verify the card shows the same body as plain text.
11. Re-enable Markdown, save, duplicate the card, then delete the duplicate.
12. Quit Cork from the menu bar.
13. Relaunch Cork and verify the Markdown card restores with its format intact.

Expected:

- Markdown is an option on text notes, not a separate menu item.
- Existing plain text notes remain plain text unless Markdown is enabled.
- Markdown headings, line breaks, blank lines, lists, and inline bold render visibly.
- Canceling the edit dialog leaves the text card unchanged.
- Markdown cards can be moved, resized, duplicated, deleted, persisted, and restored like other cards.

Known current limitations:

- Markdown support is intentionally lightweight.
- Cork does not provide a live Markdown editor or formatting toolbar.

Failure notes:

- Markdown body used.
- Whether the issue happened in create, edit, render, duplicate, or restore.
- Whether disabling and re-enabling Markdown preserved the source text.

## File Cards

Run this section for the file-card slice of Milestone 7 and whenever file imports or file actions change.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show the board.
3. Drag a non-image file from Finder onto the board, such as a `.pdf`, `.txt`, `.md`, or `.zip`.
4. Verify the card shows Cork's file-card icon treatment, title, and local path.
5. Move and resize the file card.
6. Right-click the file card and choose `Open File`.
7. Right-click the file card and choose `Reveal in Finder`.
8. Double-click the file card.
9. Select the file card and inspect the board header pencil button.
10. Duplicate and delete the file card.
11. Drag another non-image file onto the board.
12. Quit Cork from the menu bar.
13. Relaunch Cork and verify the file card restores correctly.
14. Move or delete the source file in Finder.
15. Relaunch Cork and verify the card shows a missing-file state.

Expected:

- Non-image file drops create file cards, not text notes.
- `Open File` opens the referenced file with the default app.
- `Reveal in Finder` selects the referenced file in Finder.
- Double-clicking a file card opens the referenced file.
- The board header edit button is disabled for file cards.
- Missing source files are shown clearly without crashing Cork.
- File cards can be moved, resized, duplicated, deleted, persisted, and restored like other cards.

Known current limitations:

- File cards reference local paths; Cork does not copy files into Application Support yet.
- Sandboxed builds will need security-scoped bookmarks before external file references are production-ready.
- File cards do not have an edit dialog yet.

Failure notes:

- File type and source path.
- Whether Cork created a file card or a different card type.
- Whether open, reveal, missing-file display, or restore failed.
- Whether the file was moved or deleted between launches.

## Color Palette Cards

Run this section for the palette-card slice of Milestone 7 and whenever palette parsing, rendering, or editing changes.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show the board.
3. Create a color palette from the board header plus button.
4. Use a title such as `Launch Colors`.
5. Enter these colors:

   ```text
   #FF6B6B
   4ECDC4
   #FFE66D, #292F36
   #f66
   ```

6. Save the palette.
7. Verify the card shows swatches and normalized hex labels.
8. Move and resize the palette card.
9. Double-click the card and edit the title and colors.
10. Create another palette from the menu bar while the board is hidden.
11. Duplicate and delete a palette card.
12. Quit Cork from the menu bar.
13. Relaunch Cork and verify remaining palette cards restore correctly.

Expected:

- Palette cards are available from the board header and menu bar `New Card` menus.
- Comma-, semicolon-, space-, and newline-separated hex colors are accepted.
- Three-character shorthand hex colors normalize to six-character labels.
- Empty or invalid color input falls back safely instead of crashing.
- Palette cards can be edited, moved, resized, duplicated, deleted, persisted, and restored like other cards.

Known current limitations:

- Palette cards do not copy hex values to the clipboard yet.
- Palette cards do not import from design tools yet.

Failure notes:

- Color input used.
- Whether parsing, normalization, swatch rendering, edit, duplicate, or restore failed.
- Whether menu bar creation showed the board after a successful palette was created.

## Card Resizing and Layout Polish

Run this section for Milestone 6 and whenever pointer interaction, card rendering, or layout bounds change.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show the board.
3. Select a text card.
4. Drag the bottom-right resize handle larger and smaller several times.
5. Repeat with a checklist card.
6. Repeat with an image card.
7. Move and resize cards near the top, bottom, left, and right board edges.
8. Resize a card to the smallest size Cork allows.
9. Resize a card to the largest size Cork allows.
10. Click the board background, then reselect and move each card.
11. Double-click a card to edit it.
12. Right-click a card and verify the context menu still works.
13. Drag a large local photo onto the board.
14. Wait for the real photo thumbnail to appear if the placeholder is visible.
15. Move and resize the large-photo card repeatedly.
16. Quit Cork from the menu bar.
17. Relaunch Cork and verify the resized cards restore correctly.

Expected:

- Selected cards show a clear but quiet resize handle.
- Dragging the handle resizes the selected card without layout jumps.
- Dragging the card body still moves the card.
- Cards remain inside usable board bounds.
- Text, checklist entries, and images clip cleanly inside the card.
- Hover and selected states make the active card easy to identify.
- Clicking the board background clears selection without making cards unclickable.
- Editing, deleting, duplicating, and context menus still work.
- Large image cards stay responsive while moving and resizing.
- Resized card frames persist across relaunch.

Known current limitations:

- Resize is currently bottom-right only.
- There is no snap grid or alignment guide yet.
- File-backed image thumbnails are cached in memory and regenerate after relaunch.

Failure notes:

- Which card type felt slow or jumpy.
- Whether the issue happened while moving, resizing, hovering, or editing.
- Whether the card was near a board edge.
- Whether a large photo was involved, including approximate file size and dimensions if known.
- Whether the issue persisted after quitting and relaunching Cork.

## Preferences and System Behavior

Use this section for Iteration 9 preferences work.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show Cork.
3. Open the menu bar item and choose `Preferences...`.
4. Verify the Preferences window appears in front of the board.
5. Move the Board Opacity slider down and back up.
6. Verify the board opacity changes live while the Preferences window remains usable.
7. Choose each Slide Edge option: `Top`, `Bottom`, `Left`, and `Right`.
8. After each edge change, hide Cork and show it again.
9. Quit and relaunch Cork.
10. Verify the selected opacity and slide edge restore after relaunch.
11. Open Preferences and click the keyboard shortcut recorder.
12. Press a new shortcut with at least one modifier, such as `Control` + `Option` + `B`.
13. Hide and show Cork with the new shortcut.
14. Quit and relaunch Cork.
15. Verify the new shortcut still works and the menu bar Show/Hide item displays the updated shortcut when possible.
16. Reopen Preferences and click `Reset` next to the shortcut.
17. Verify `Command` + `Option` + `B` works again.
18. Click the recorder, press a bare letter key without modifiers, and verify Cork rejects it without changing the saved shortcut.
19. Open Preferences and inspect the Launch at Login row.

Expected:

- Preferences opens from the menu bar and is not hidden behind the board.
- Board opacity updates immediately and remains persisted after relaunch.
- The board hides and reappears from the selected edge.
- Top and bottom edges behave like a horizontal board.
- Left and right edges slide horizontally from off-screen while keeping the board content usable.
- Keyboard shortcut changes take effect without restarting Cork.
- Keyboard shortcut changes persist after relaunch.
- The reset button restores the default `Command` + `Option` + `B` shortcut.
- Bare keys without modifiers are rejected.
- The menu bar Show/Hide command remains available if the shortcut is changed, rejected, or unavailable.
- In SwiftPM debug runs, Launch at Login is disabled with a packaged-app status message.

Packaged-app follow-up:

- Once Cork is built as a `.app`, the Launch at Login toggle should be tested again.
- Turning the toggle on should register Cork in macOS Login Items.
- Turning the toggle off should remove Cork from Login Items.
- Relaunching Cork should reflect the actual system Login Items state.

Failure notes:

- Which preference was changed.
- Whether the issue happened before or after relaunch.
- Whether the board appeared from the wrong edge.
- Whether the board appeared off-screen or behind another Cork window.
- Whether Preferences was hidden by the board.
- Whether the shortcut recorder stayed in recording mode.
- Whether an invalid shortcut replaced the previous working shortcut.
- Whether the menu bar shortcut label became stale after changing Preferences.
- Whether the Launch at Login row was enabled in an unexpected build type.

## Full-Screen App Spaces

Full-screen Spaces are the most important awkward case because Cork should feel like an overlay rather than an app switch.

Steps:

1. Open Safari, Notes, Xcode, or another standard macOS app.
2. Put that app into full-screen mode.
3. Keep focus inside the full-screen app.
4. Press `Command` + `Option` + `B`.
5. Drag a Cork card.
6. Press `Command` + `Option` + `B` again.
7. Move to a different full-screen app and repeat.

Ideal behavior:

- Cork appears in the current full-screen Space.
- macOS does not switch to another desktop.
- The full-screen app remains visually behind Cork.
- The board hides with the same shortcut.
- Card dragging works while the full-screen app is behind the board.

Acceptable for Milestone 1:

- Cork opens and hides reliably.
- No crash.
- No stuck panel.
- No forced desktop switch that leaves the user confused.

Failure notes:

- Did the shortcut do nothing?
- Did Cork appear on another desktop?
- Did Cork appear behind the full-screen app?
- Did the menu bar item remain usable?
- Did hiding Cork restore the full-screen app cleanly?

## Multiple Desktops

This checks ordinary Spaces without full-screen apps.

Steps:

1. Create at least two desktops in Mission Control.
2. On Desktop 1, show Cork with the shortcut.
3. Hide Cork with the shortcut.
4. Move to Desktop 2.
5. Show and hide Cork again.
6. Show Cork on Desktop 2, then switch back to Desktop 1 while Cork is visible.

Ideal behavior:

- Cork appears in the active desktop.
- Cork does not unexpectedly pull the user back to a previous desktop.
- Cork remains hideable with the shortcut wherever it is visible.

Acceptable for Milestone 1:

- Cork can be shown and hidden from each desktop.
- If it follows across desktops, record that behavior but do not treat it as a blocker unless it feels disruptive.

Failure notes:

- Which desktop was active?
- Where did Cork appear?
- Could Cork be hidden after changing desktops?
- Did macOS animate to another Space unexpectedly?

## Multiple Monitors

Run this section when an external display is available.

Steps:

1. Connect an external display.
2. Disable mirroring if possible.
3. Place the pointer on the built-in display.
4. Press `Command` + `Option` + `B`.
5. Hide Cork.
6. Place the pointer on the external display.
7. Press `Command` + `Option` + `B`.
8. Drag cards near the board edges.
9. Repeat with the external display arranged above, below, left, and right in System Settings if convenient.

Expected:

- Cork appears on the screen containing the pointer.
- The board respects the visible screen frame and does not cover the menu bar awkwardly.
- The board does not straddle displays.
- Drag bounds remain usable.
- Hide/show works from either display.

Failure notes:

- Display arrangement.
- Which screen contained the pointer.
- Which screen Cork appeared on.
- Whether the board was clipped, too wide, too tall, or under the menu bar.

## Notch and Menu Bar Geometry

This is mainly for MacBook displays with a notch or unusual menu bar geometry.

Steps:

1. Use the built-in MacBook display.
2. Show Cork.
3. Inspect the top edge, corners, and menu bar area.
4. Hide Cork.
5. Repeat while another app has a long menu bar.

Expected:

- Cork starts below the menu bar area.
- The panel does not hide behind the notch.
- The top corners and shadow look intentional.
- The slide animation begins off-screen and lands cleanly.

Failure notes:

- Panel appears too high or too low.
- Panel clips under the menu bar.
- Animation starts visibly from a strange position.

## Hot-Key Conflicts

The default shortcut is `Command` + `Option` + `B`, and users can change it in Preferences. Other apps may already use either the default shortcut or a custom shortcut.

Steps:

1. Launch Cork.
2. Press `Command` + `Option` + `B` in Finder.
3. Press it in Safari.
4. Press it in a full-screen app.
5. Open the menu bar item and use "Show Cork" and "Hide Cork."
6. Change the shortcut in Preferences to a different modifier combination.
7. Repeat the Finder, Safari, and full-screen app checks with the new shortcut.
8. Reset the shortcut to the default.

Expected:

- The shortcut toggles Cork in common apps.
- Menu bar commands still work if the shortcut is unavailable.
- If registration fails, Cork should not crash.
- Registration failures are shown in Preferences so the user has a visible fallback path.
- Reset restores the default shortcut.

Failure notes:

- Which app had focus.
- Whether the app consumed the shortcut.
- Whether the menu bar fallback worked.
- Whether Preferences displayed a registration failure message.
- Whether resetting restored the default shortcut.
- Any console message from Cork.

## Menu Bar Utility Behavior

Steps:

1. Launch Cork.
2. Verify Cork does not appear in the Dock.
3. Open the menu bar item.
4. Switch boards.
5. Show and hide Cork from the menu.
6. Quit Cork from the menu.

Expected:

- Cork behaves like an accessory/menu bar utility.
- Board switching is immediate.
- Quit exits the process cleanly.

Failure notes:

- Dock icon appears unexpectedly.
- Menu item text is stale.
- Quit leaves a running process.

## Sleep, Wake, and Display Changes

This catches stale screen geometry.

Steps:

1. Show Cork.
2. Hide Cork.
3. Put the Mac to sleep or lock the screen.
4. Wake/unlock.
5. Show Cork again.
6. If using an external display, disconnect and reconnect it.
7. Show Cork again.

Expected:

- Cork recalculates screen position after wake.
- Cork appears on the current available display.
- No blank, invisible, or unreachable panel remains.

Failure notes:

- Whether display count changed.
- Whether Cork appeared off-screen.
- Whether relaunching Cork was required.

## Animation Feel

This is subjective, but important for Cork.

Steps:

1. Show and hide Cork ten times using the shortcut.
2. Repeat from the menu bar.
3. Drag a card immediately after the board lands.
4. Toggle Cork while another app is visually busy, such as Safari or Xcode.

Expected:

- The slide-in feels quick and calm.
- The board feels like it was waiting off-screen.
- There is no loading flash.
- Dragging is responsive after the animation completes.

Notes to capture:

- Too slow.
- Too abrupt.
- Jittery.
- Shadow/material appears late.
- Board content flashes before the panel reaches its final position.

## Recording Results

Use this template in an issue, PR, or release note:

```text
Manual QA date:
macOS version:
Cork command or build:
Display setup:
Stage Manager:
Displays have separate Spaces:

Baseline smoke test:
Real card creation:
Board management:
Menu bar creation:
Drag and drop imports:
URL cards:
Card resizing and layout polish:
Preferences and system behavior:
Keyboard shortcut preferences:
Full-screen Spaces:
Multiple desktops:
Multiple monitors:
Notch/menu bar geometry:
Hot-key conflicts:
Menu bar behavior:
Sleep/wake/display changes:
Animation feel:

Issues found:
Follow-up needed:
```

## Milestone 1 Closeout Standard

Milestone 1 can be considered done when:

- Baseline smoke test passes.
- Full-screen and multiple-desktop behavior is understood and recoverable.
- Hot-key fallback through the menu bar works.
- No panel gets stuck on screen.
- No crash occurs during display, Space, or sleep/wake checks.
- Any rough edges are captured as follow-up work for later milestones.
