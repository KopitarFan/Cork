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
14. Double-click the image card and verify Cork offers `Rename`, `Replace Image...`, and `Cancel`.
15. Choose `Rename`, change the title, and save.
16. Double-click the image card again, choose `Replace Image...`, and select a different local image.
17. Verify the thumbnail changes while the renamed title stays unchanged.
18. Quit Cork from the menu bar.
19. Relaunch Cork.

Expected:

- New cards appear near the visible center of the board.
- Created cards are selected immediately.
- Text note edits update the visible card.
- Checklist lines become checklist entries.
- `[x]` and `- [x]` checklist lines are marked complete.
- Local image cards show a thumbnail when the file is still available.
- Double-clicking an image card clearly offers both rename and image-replacement paths.
- Replacing from the double-click chooser preserves the card's title, layout, and appearance.
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
14. Move or rename the source file in Finder, relaunch Cork, and verify the bookmark follows it when macOS can resolve the move.
15. Delete the source file, relaunch Cork, and verify the card shows a missing-file state.

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
- File and image cards created before bookmark support may need to be imported again before they work in a sandboxed build.
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
5. Move the Board Surface Opacity slider down and back up.
6. Verify the board surface opacity changes live while cards remain at their current opacity.
7. Move the Card Opacity slider down and back up.
8. Verify card opacity changes live while the board surface remains at its current opacity.
9. Choose each Board Theme option: `Cork`, `Poster`, and `System`.
10. Verify the board background updates while the Preferences window remains usable.
11. Enable `Custom Board Colors`.
12. Change the `Title Bar Color` and `Board Surface Color` with the color wells.
13. Verify changing `Title Bar Color` only changes the title bar chrome and does not change the board surface swatch or hex value.
14. Verify changing `Board Surface Color` only changes the board surface and does not change the title bar swatch or hex value.
15. Verify the board colors change live and cards remain readable.
16. Click `Swap Colors` and verify the title-bar and board-surface color values trade places.
17. Click `Reset Colors` and verify the custom colors return to the default Cork tones.
18. Disable `Custom Board Colors` and verify the selected preset theme returns.
19. Choose each Board Size option: `Compact`, `Standard`, and `Large`.
20. Verify the board panel resizes cleanly without losing card interaction.
21. Choose each Slide Edge option: `Top`, `Bottom`, `Left`, and `Right`.
22. After each edge change, hide Cork and show it again.
23. Quit and relaunch Cork.
24. Verify the selected surface opacity, card opacity, theme, custom color setting, board size, and slide edge restore after relaunch.
25. Open Preferences and click the keyboard shortcut recorder.
26. Press a new shortcut with at least one modifier, such as `Control` + `Option` + `B`.
27. Hide and show Cork with the new shortcut.
28. Quit and relaunch Cork.
29. Verify the new shortcut still works and the menu bar Show/Hide item displays the updated shortcut when possible.
30. Reopen Preferences and click `Reset` next to the shortcut.
31. Verify `Command` + `Option` + `B` works again.
32. Click the recorder, press a bare letter key without modifiers, and verify Cork rejects it without changing the saved shortcut.
33. Open Preferences and inspect the Launch at Login row.

Expected:

- Preferences opens from the menu bar and is not hidden behind the board.
- Board surface opacity updates immediately and persists after relaunch.
- Card opacity updates immediately and persists after relaunch.
- Board surface opacity and card opacity do not change each other.
- Board theme changes update the board surface and persist after relaunch.
- Custom board colors update live, title-bar and board-surface values stay independent, persist after relaunch, and can be disabled to restore the selected preset theme.
- Cork theme feels like a corkboard surface without hurting card readability.
- Poster theme feels lighter and remains readable.
- System theme keeps the previous native glass/grid feel.
- Board size changes resize the panel while preserving card interaction.
- Compact size leaves more of the source app visible for drag-and-drop staging.
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
- Whether board surface opacity unexpectedly changed card opacity.
- Whether card opacity unexpectedly changed board surface opacity.
- Whether a theme reduced card readability.
- Whether custom board colors failed to restore, reset, disable, or persist.
- Whether a board size made controls cramped or unreachable.
- Whether the board appeared from the wrong edge.
- Whether the board appeared off-screen or behind another Cork window.
- Whether Preferences was hidden by the board.
- Whether the shortcut recorder stayed in recording mode.
- Whether an invalid shortcut replaced the previous working shortcut.
- Whether the menu bar shortcut label became stale after changing Preferences.
- Whether the Launch at Login row was enabled in an unexpected build type.

## Per-Card Appearance and Board Templates

Run this section when card appearance or built-in board templates change.

Steps:

1. Launch Cork with `swift run Cork` and show the board in `Standard` size.
2. Select a text or checklist card.
3. Open the board title-bar `Card` menu and choose `Card Appearance...`.
4. Enable the custom background, choose a visibly different color, select `Serif`, and save.
5. Verify only the selected card changes color and font; neighboring cards must remain unchanged.
6. Right-click a different card, choose `Appearance...`, select another color and `Monospaced`, and save.
7. Verify the first card keeps its appearance and both cards remain readable.
8. Select a third card, open the menu bar `Selected Card` menu, choose `Card Appearance...`, select `System`, leave the custom background disabled, and save.
9. Duplicate one of the customized cards and verify its duplicate keeps the same background and font.
10. Reopen appearance for one customized card, disable its custom background, choose `Rounded`, and verify its normal card-type background returns.
11. Open the board title-bar `Board` menu and inspect `New Board From Template`.
12. Verify it lists `Agile Sprint`, `Kanban`, `Vision Board`, `Weekly Schedule`, `Random Arrangement`, `Project Hub`, `Writing Room`, and `SWOT Analysis`.
13. Create an `Agile Sprint` board, accept or change its suggested name, and verify the sprint goal plus Backlog, In Progress, Review, and Done cards appear.
14. Create a `Vision Board` from the menu bar `Boards` menu and verify its image placeholders, intention, and palette appear.
15. Create `Random Arrangement`, then move, resize, edit, duplicate, and delete its starter cards.
16. Switch among the template boards and verify they behave like ordinary editable boards.
17. Quit and relaunch Cork.
18. Verify the template boards and every customized card appearance restore correctly.

Expected:

- Background and font changes apply only to the selected card.
- Light and dark custom colors keep card text readable.
- `System`, `Rounded`, `Serif`, and `Monospaced` update card text without changing card frames.
- Card appearance is available from the card context menu, board title-bar `Card` menu, and menu bar `Selected Card` menu.
- Duplicated cards preserve their source appearance.
- Disabling a custom background restores the card type's normal background.
- Both Board menus expose the same eight templates.
- Template creation produces a new selected board with editable starter cards and a sensible suggested name.
- Template cards can be moved, resized, edited, duplicated, deleted, and restyled normally.
- Per-card appearance and template boards persist after relaunch.

Failure notes:

- Which card changed unexpectedly when editing another card's appearance.
- Which color and macOS appearance mode caused poor contrast.
- Whether a font choice changed layout or failed to affect some card text.
- Which command surface was missing `Card Appearance...` or a template.
- Which template had missing, overlapping, clipped, or uneditable starter cards.
- Whether template creation changed an existing board instead of creating a new one.
- Whether appearance or template cards disappeared after relaunch.

## Image Replacement, Quick Board Switching, and Card Connections

Run this section when image replacement, board cycling, or card connections change.

Steps:

1. Launch Cork with `swift run Cork`, show the board, and create or select an image card.
2. Note the image card's title, position, size, background color, and font.
3. Double-click the image card and verify the action chooser offers `Rename`, `Replace Image...`, and `Cancel`.
4. Choose `Rename`, change the title, and verify the thumbnail does not change.
5. Double-click again, choose `Replace Image...`, and select a different local image.
6. Verify the preview updates while the renamed title, position, size, background, and font stay unchanged.
7. Open the board title-bar `Card` menu and choose `Replace Image...` with another image.
8. Right-click the image card, choose `Replace Image...`, and repeat once more.
9. Use the menu bar `Selected Card` menu to replace the image again.
10. Switch to a library with at least three boards and press `Control` + `Tab` repeatedly.
11. Verify Cork selects the next board and wraps from the last board to the first.
12. Press `Control` + `Shift` + `Tab` repeatedly and verify reverse wraparound.
13. Open both Board menus and verify `Next Board` and `Previous Board` perform the same actions.
14. Click `String` in the board title bar and verify the control turns red and the pointer becomes a crosshair over the board.
15. Press on one card, drag toward a different card, and verify a curved red string previews from the source card to the pointer.
16. Verify the source card gets a dashed red outline and the card under the pointer receives its normal hover treatment.
17. Release over the target card and verify the string snaps to both card edges with pin-like endpoints.
18. Without clicking `String` again, draw a second string between another pair and verify the tool remains active for repeat drawing.
19. Click `String` again and verify its selected state and crosshair disappear, then move a card normally.
20. Turn `String` on again, begin drawing, release over the board background, and verify no connection is created and the tool remains active.
21. Press Escape and verify String mode exits. Turn it on again and press Escape without beginning a drag; verify it still exits cleanly.
22. Move and resize connected cards and verify each string follows their edges without blocking card interaction.
23. Use the `Card` menu's two-step workflow to connect a pair with `Connect with Line` and verify it renders as a restrained straight line.
24. Use the two-step workflow on an existing string pair and choose `Connect with Line`; verify the string changes style instead of creating a duplicate.
25. Start a menu-based connection and click the `x` in the title-bar connection status; verify the pending connection cancels without adding a line.
26. Select a connected card and choose `Remove Card Connections`; verify every connection touching that card disappears while unrelated connections remain.
27. Create another connection, delete one endpoint card, and verify its connection disappears automatically.
28. Duplicate a board containing connections and verify the copied board connects the copied cards rather than the originals.
29. Quit and relaunch Cork.
30. Verify replacement images, the selected board, and all remaining connections restore correctly.

Expected:

- Replacing an image changes only the image source.
- Double-clicking an image card offers rename and replacement without conflating the two actions.
- Image replacement is available from double-click, right-click, and both Selected Card menus.
- Board cycling wraps forward and backward and clears stale card selection.
- The keyboard shortcuts work while Cork is visible and active; they do not register additional system-wide hot keys.
- The selected String tool replaces card movement with a clear crosshair drawing mode and previews the connection live.
- String mode supports repeat drawing, exits from the same title-bar control or Escape, and ignores invalid background and same-card drops.
- Starting a connection clearly marks its source until completion or cancellation.
- Line and string connections remain behind cards and follow movement and resizing live.
- Reconnecting the same pair changes its style without creating overlapping duplicates.
- Connection removal, card deletion, board switching, and board duplication leave no dangling endpoints.
- Connections and replacement image references persist after relaunch.

Failure notes:

- Which image-replacement entry point failed or changed unrelated card state.
- Whether the image-card double-click chooser showed the wrong actions or changed the image while renaming.
- Whether a large replacement image reintroduced movement or resize slowdown.
- Which board order or wrap direction was wrong.
- Whether `Control` + `Tab` conflicted with another Cork action.
- Whether String mode failed to show its selected state, crosshair, preview, target hover, repeat behavior, or Escape cancellation.
- Which connection style failed to render, track, persist, or clean up.
- Whether a connection appeared above cards or blocked clicking and dragging.
- Whether a duplicated board's connections still pointed at the original cards.

## Card Name Hovers and Quick Start

Run this section when card hover presentation, first-run behavior, or Settings commands change.

Steps:

1. Quit any running Cork process, then launch this build with `swift run Cork`.
2. If this settings profile has not seen the guide, verify `Welcome to Cork` opens automatically in front of other Cork windows.
3. Verify the guide shows the currently configured Cork shortcut and concise guidance for imports, boards, card-name hovers, and strings.
4. Choose `Preferences...` in the guide and verify the guide closes as Preferences opens in front.
5. Open `Quick Start Guide...` from the menu bar and choose `Show Cork`; verify the guide closes and the board comes forward.
6. Quit and relaunch Cork, then verify the guide does not open automatically a second time.
7. Open the board title-bar `Settings` menu and verify both `Preferences...` and `Quick Start Guide...` are present and work.
8. Hover text, checklist, image, URL, file, and palette cards and verify each name appears in a compact label.
9. Hover cards against the top, left, right, and bottom board edges and verify long names truncate without leaving the board.
10. Move and resize a hovered card, then use String mode across two cards and verify the labels never block pointer interaction.

Expected:

- The Quick Start guide is automatically presented only while its persisted seen flag is false.
- The guide remains reopenable from both the menu bar and board Settings menu.
- The displayed shortcut updates from the saved shortcut setting.
- Show Cork and Preferences close the guide and bring the requested surface forward.
- Hover labels show the card title, or `Untitled Card` for a blank title, without changing selection or hit testing.
- Labels choose an above-card or below-card position and remain within the visible board width.

Failure notes:

- Whether the guide opened behind Cork, appeared on every launch, or never appeared for an unseen settings state.
- Which guide action failed to close the window or bring the requested surface forward.
- Which Settings surface was missing the guide command.
- Which card type displayed the wrong or stale name.
- Which board edge, long title, drag, resize, or String interaction caused clipping or pointer interference.

## Board UI Polish

Run this section when the board header, board switcher, selected-card menus, theme surface, display size, or window stacking changes.

Steps:

1. Launch Cork with `swift run Cork`.
2. Show Cork.
3. Use the board title-bar switcher to change between at least three boards.
4. Verify pinned boards appear above unpinned boards in the switcher.
5. Verify the title-bar controls are visibly labeled `Add`, `String`, `Card`, `Board`, and `Settings`.
6. Open the title-bar `Settings` menu and choose `Preferences...`.
7. Create a new board from the board actions menu, then switch back to the previous board from the title bar.
8. Select a card and use the board title-bar Selected Card menu to edit, duplicate, and delete a card.
9. Select another card and use the menu bar Selected Card menu to edit, duplicate, and delete a card.
10. Verify the board title bar and menu bar both expose Add Card, Selected Card, Boards, Settings, and Quick Start workflows.
11. Open Preferences and choose the `Cork` theme.
12. Move, resize, select, edit, duplicate, and delete cards on the Cork theme.
13. Repeat the card interaction check on the `Poster` and `System` themes.
14. Choose `Compact` board size.
15. Hide Cork, place Finder or Safari content in the visible area outside the compact board, then show Cork again.
16. Drag an image, file, URL, or text snippet from the exposed source area onto Cork.
17. With Cork visible, click another app window that is partially visible outside the board.
18. Verify that app window comes in front of Cork.
19. Press the Cork shortcut or use the menu bar command to bring Cork back to the front.
20. Press the Cork shortcut again while Cork is frontmost and verify it hides.
21. Choose `Standard` and `Large` board sizes and verify the board resizes cleanly.
22. Quit and relaunch Cork.
23. Verify the selected board, theme, custom color setting, per-card appearances, and board size restore correctly.

Expected:

- The title-bar switcher lists the same boards as the menu bar `Boards` menu.
- Selecting a board from the title bar changes the visible board immediately.
- The switcher remains usable in Compact, Standard, and Large sizes.
- Add Card, Selected Card, Boards, and Settings workflows are available from both the menu bar and the board title bar, with the direct String tool on the board.
- Both Settings surfaces expose Preferences and the Quick Start guide.
- Title-bar controls are understandable without relying on hover help.
- Preferences opens from the board title bar and remains in front of the board.
- Selected-card edit, duplicate, and delete actions behave the same from both surfaces.
- Themes change the board surface without changing card data.
- Cards remain readable and interactive on every theme.
- Compact board size leaves enough of the underlying app visible to start drag-and-drop from outside Cork.
- Other app windows can come in front of Cork when clicked.
- The global shortcut and menu bar command bring Cork back to the front when it is visible behind another window.
- The global shortcut still hides Cork when Cork is already frontmost.
- Imported cards still land at the drop point and persist after relaunch.
- Theme, custom color, per-card appearance, and board size choices persist after relaunch.

Failure notes:

- Which board name or pinned state was wrong in the switcher.
- Whether switching boards affected the wrong board or lost selection.
- Which command was missing from either the menu bar or title bar.
- Which title-bar control was unclear or too cramped.
- Whether Preferences was missing from the title bar or opened behind the board.
- Whether selected-card actions differed between menu bar and title bar.
- Which theme made cards hard to read.
- Which board size made controls cramped or clipped.
- Which source app was used for compact-mode drag-and-drop.
- Whether another app could not come in front of Cork when clicked.
- Whether the shortcut hid Cork instead of bringing it forward when Cork was behind another window.
- Whether a dragged item created the wrong card type or landed in the wrong place.

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
5. Show Cork from the menu.
6. Click another app window so it comes in front of Cork.
7. Open the menu bar item and choose the first Cork command to bring Cork back to the front.
8. Hide Cork from the menu while Cork is frontmost.
9. Quit Cork from the menu.

Expected:

- Cork behaves like an accessory/menu bar utility.
- Board switching is immediate.
- The first menu item changes from showing Cork to bringing Cork forward when Cork is visible but behind another window.
- Other app windows can cover Cork when clicked.
- Quit exits the process cleanly.

Failure notes:

- Dock icon appears unexpectedly.
- Menu item text is stale.
- Cork stays above other app windows after clicking them.
- The menu bar command hides Cork when it should bring Cork forward.
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

## Packaged App and Launch at Login

Run this section from the shared `Cork App` Xcode scheme after selecting a signing team. Do not use `swift run Cork` for these checks.

Steps:

1. Build and run Cork from Xcode and verify the illustrated Cork icon is present in the built app.
2. Verify Cork appears only in the menu bar and does not remain in the Dock.
3. Open Preferences and confirm `Launch at Login` is enabled as an interactive control.
4. Turn `Launch at Login` on.
5. If Cork reports that approval is required, choose `Open Login Items Settings`, allow Cork, return to Preferences, close it, and reopen it.
6. Quit and relaunch Cork; confirm the toggle still matches System Settings.
7. Log out and log back in when convenient; confirm Cork starts as a menu bar utility without showing the board unexpectedly.
8. Turn `Launch at Login` off, reopen Preferences, and confirm it remains off.
9. Drag an image and a non-image file onto Cork, quit, relaunch, and verify both references still render and open.
10. Confirm existing boards, preferences, the global shortcut, menu bar commands, and board animation still work in the packaged build.

Expected:

- The packaged app has the correct icon, menu bar behavior, and no Dock presence.
- Launch at Login follows the system's actual service state.
- Approval-required status is understandable and links to the correct System Settings pane.
- Disabling Launch at Login unregisters Cork.
- Board and preference persistence use Cork's sandbox container.
- Imported images and file cards remain usable after relaunch.

Release gate:

- New external file and image references now store durable security-scoped bookmarks. Step 9 must pass in the signed packaged build before submission.

Failure notes:

- Whether the app was signed and launched from the `Cork App` scheme.
- The Launch at Login message and state shown in Preferences.
- Cork's status under System Settings > General > Login Items & Extensions.
- Whether the imported item came from Finder, Safari, an open panel, or another source.
- Whether the failure happened immediately or only after relaunch.

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
Board UI polish:
Preferences and system behavior:
Packaged app and launch at login:
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
