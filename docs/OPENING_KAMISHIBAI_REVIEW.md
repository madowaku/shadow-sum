# NOXSUM opening kamishibai — implementation and review

Implemented in the current `C:/Dev/Projects/shadow-sum` working tree. Netlify was not deployed.

## Behavior

- HOME PLAY/CONTINUE opens the prologue when `presentation.opening_seen` is absent or false in `user://noxsum_settings.cfg`. Completion or SKIP sets it true and enters GR01 through the existing HOME fade.
- Subsequent PLAY/CONTINUE uses the existing resume route. GALLERY stage selection remains direct.
- ABOUT → PROLOGUE replays it and returns to ABOUT. Replay preserves `opening_seen`, including an initially false value.
- Six data-defined beats: 3 / 3 / 3.5 / 4 / 3 / 3 seconds, totaling 19.5 seconds (plus the existing 0.65-second stage handoff).
- Tap, click, Space and Enter advance; repeated input is debounced for 350 ms. SKIP is always a 48-CSS-pixel target. Escape finishes/skips.
- Scene 01 reuses v0.6 art at a fixed scale. The following beats use existing NOX poses and optical shadows. Scene 04 reconstructs the demonstrated record, Scene 05 reuses the solve scan, Scene 06 reuses the live wordmark and fades to GR01.
- Beat changes retain the previous frame under the incoming one and cross-fade over 280 ms (120 ms with Reduced Motion). There is no blank-frame cut, camera push, or horizontal plate slide. Copy, scene order, and total duration stay fixed.
- JP/EN uses the existing saved language. Sound OFF mutes the existing system; Sound ON retains its playlist. Reduced Motion shortens the beat fade and uses the existing reduced solve scan.
- No campaign data, puzzle state, inventory, clues, or progress are written by the opening. Only first-run completion/skip writes `opening_seen`.

## Verification

| Check | Result |
|---|---|
| `tools/nox_opening_kamishibai_smoke.gd` | PASS: first run, complete, skip, normal resume, replay, immutable progress, JP/EN, Sound OFF/ON, Reduced Motion, all three sizes, resize, debounce and exit cancellation |
| `tools/nox_mobile_ui_smoke.gd` | PASS: all 36 stages, JP/EN, HOME, 44px touch controls, clue sheet, reduced motion, and solve bounds at 360×800, 405×900, and 720×900 |
| Web debug export, `NOXSUM Web` preset | PASS; local output `builds/web-opening/index.html` |
| HTTP Chromium 360×800, DPR 2, Japanese | Six Opening scenes, first-run guide, GR01, and GR07 captured; no page/console errors |
| HTTP Chromium 405×900, DPR 2, Japanese | Six Opening scenes, first-run guide, GR01, and GR07 captured; no page/console errors |
| HTTP Chromium 720×900, DPR 1, English | Six Opening scenes captured; no page/console errors |
| Web route checks | PLAY → Opening → GR01 (existing HOW TO PLAY guide) → GR07; SKIP/resume/replay paths also pass in the opening smoke |
| Stage layout regression | GR07 footer remains within the 360×800 and 405×900 browser viewports; 44px mobile targets remain intact |
| Canonical deck | No changes to `data/noxsum_grant36_v1.json` or optical rules |
| Full resource validation | 81 resources checked, five scenes instantiated, zero errors/parse errors; 33 pre-existing warnings in the broader project |
| Existing `nox_ux_smoke.gd`, 405×900 and 720×900 | PASS: guide, solve, finale, language, Reduced Motion, ten bottom-light traces, eight replacement solves, 36 layouts |

### GR07 footer regression

The GR07 action row previously extended below the viewport. The mobile layout now caps shadow tiles at 20 px for widths up to 380 px and 26 px for other mobile widths, while keeping light and rail targets at 44 px. The board caption yields its row to the SLEEP rail on narrow screens. The action row now fits at 360×800 and 405×900.

The shared solve renderer converts global rectangles through the inverse canvas transform, so the existing brass scan aligns at DPR 2. ABOUT paragraph headings wrap on narrow windows, including when returning from a resized replay.

## Visual review

Images below are actual HTTP-served Chromium screenshots, saved at CSS viewport resolution. Mobile runs use DPR 2 and the desktop run uses DPR 1.

| Scene | 360×800 JP | 405×900 JP | 720×900 EN |
|---|---|---|---|
| 01 Archive | [PNG](previews/opening_v01/360_scene01.png) | [PNG](previews/opening_v01/405_scene01.png) | [PNG](previews/opening_v01/720_scene01.png) |
| 02 NOX / shadows | [PNG](previews/opening_v01/360_scene02.png) | [PNG](previews/opening_v01/405_scene02.png) | [PNG](previews/opening_v01/720_scene02.png) |
| 03 Overlapping record | [PNG](previews/opening_v01/360_scene03.png) | [PNG](previews/opening_v01/405_scene03.png) | [PNG](previews/opening_v01/720_scene03.png) |
| 04 Reconstruction | [PNG](previews/opening_v01/360_scene04.png) | [PNG](previews/opening_v01/405_scene04.png) | [PNG](previews/opening_v01/720_scene04.png) |
| 05 Match | [PNG](previews/opening_v01/360_scene05.png) | [PNG](previews/opening_v01/405_scene05.png) | [PNG](previews/opening_v01/720_scene05.png) |
| 06 Enter Trace 01 | [PNG](previews/opening_v01/360_scene06.png) | [PNG](previews/opening_v01/405_scene06.png) | [PNG](previews/opening_v01/720_scene06.png) |

First-run guide after the Opening: [360×800](previews/opening_v01/360_scene07.png) · [405×900](previews/opening_v01/405_scene07.png). After dismissing the existing guide: [GR01 at 360×800](previews/gr07_stable_v01/360_gr01.png) · [GR01 at 405×900](previews/gr07_stable_v01/405_gr01.png) · [GR07 at 360×800](previews/gr07_stable_v01/360_gr07.png) · [GR07 at 405×900](previews/gr07_stable_v01/405_gr07.png). ABOUT replay return after resize: [PNG](previews/opening_v01/web_replay_return.png).

## Reproduce

```powershell
$openingGodot = 'C:/Users/hiro/tools/godot-4.7/Godot_v4.7-stable_win64_console.exe'
& $openingGodot --headless --path . --script res://tools/nox_opening_kamishibai_smoke.gd -d --ignore-error-breaks
& $openingGodot --headless --path . --export-debug 'NOXSUM Web' builds/web-opening/index.html
python -m http.server 8768 --bind 127.0.0.1 --directory builds/web-opening
# In another terminal:
npx --yes --package @playwright/cli playwright-cli -s=noxopening open http://127.0.0.1:8768
npx --yes --package @playwright/cli playwright-cli -s=noxopening run-code --filename tools/nox_opening_web_capture.js
```

Local preview: http://127.0.0.1:8768/ . Human visual acceptance remains for the supplied screenshots/video; no production publication was attempted.
