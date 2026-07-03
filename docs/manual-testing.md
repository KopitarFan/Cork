# Manual Testing Guide

This guide covers the awkward macOS cases that are hard to prove with unit tests: full-screen Spaces, multiple desktops, menu bar behavior, global hot keys, display geometry, user-facing card creation flows, and drag-and-drop imports.

Use the relevant sections before closing each milestone and whenever Cork's windowing, hot-key, menu bar, persistence, card creation, or import behavior changes.

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
- The board slides down from the top edge.
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

Steps:

1. Use the board header board-actions menu to create a new board.
2. Give it a unique name.
3. Add one text note to the new board.
4. Rename the board.
5. Switch to another board from the menu bar.
6. Switch back to the renamed board.
7. Quit and relaunch Cork.
8. Verify the renamed board and its card are still present.
9. Create a temporary board.
10. Delete the temporary board.
11. Try deleting the only remaining board if the library has just one board.

Expected:

- New boards are selected immediately.
- Board names trim extra whitespace.
- Blank board names are ignored.
- Renamed boards appear in both the header and menu bar.
- Deleting a board requires confirmation.
- Cancel is the default-safe path in the delete confirmation.
- Cork prevents deleting the final remaining board.
- Board switching, board names, and board deletion persist across relaunch.

Failure notes:

- Whether the selected board changed unexpectedly.
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
- Non-image file drops create text placeholder cards containing the file path.
- Plain text drops create text cards.
- URL drops create text placeholder cards containing the URL.
- Imported cards are selected after creation.
- Imported cards can be moved, deleted, and duplicated like manually created cards.
- Imported card positions and content persist across relaunch.
- Unsupported or empty drops do not crash Cork or block future drops.

Known current limitations:

- URL drops are placeholder text cards, not dedicated URL cards.
- Non-image file drops are placeholder text cards, not dedicated file cards.
- Local files are referenced, not copied into Application Support.
- If a referenced image file is moved or deleted, Cork cannot render its thumbnail.

Failure notes:

- Source app and type: Finder image, Finder file, browser URL, selected text.
- Whether the card appeared at the drop point.
- Whether the drop created the wrong card type.
- Whether multiple dropped files preserved a sensible order.
- Whether imported content disappeared after relaunch.
- Whether a referenced source file moved between runs.

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

The current shortcut is `Command` + `Option` + `B`. Other apps may already use it.

Steps:

1. Launch Cork.
2. Press `Command` + `Option` + `B` in Finder.
3. Press it in Safari.
4. Press it in a full-screen app.
5. Open the menu bar item and use "Show Cork" and "Hide Cork."

Expected:

- The shortcut toggles Cork in common apps.
- Menu bar commands still work if the shortcut is unavailable.
- If registration fails, Cork should not crash.

Known Milestone 1 limitation:

- Hot-key registration failure is currently logged with `NSLog`; there is no user-facing diagnostic yet.

Failure notes:

- Which app had focus.
- Whether the app consumed the shortcut.
- Whether the menu bar fallback worked.
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
