# NOXSUM — Grant 36 Web presentation

NOXSUM is a quiet logic mystery in the Nocturnal Optical Archive. Each plate sums shadows left in several moments. The player reconstructs **where NOX was and in which pose**; the plate does not establish an order of events or NOX's final fate.

## Player route

- Default Godot startup opens a full-screen HOME with the moonlit archive, NOX at the window, a PLAY/CONTINUE button, ABOUT, HOW TO PLAY, GALLERY, and SETTINGS.
- GALLERY exposes all 36 records across six chapters. Returning HOME preserves progress, and CONTINUE opens the next unsolved record.
- The stage compares RECORDED SHADOW with RECONSTRUCTION. The board is WHERE WAS NOX? and the player places SIT, STAND, or directional WALK traces, selects light sources, and moves SLEEP on the rail when available.
- OBSERVE gives authored, canon-aligned clues on every record. TRACE MATCHED acknowledges a solve; RECONSTRUCTION COMPLETE appears when all 36 are solved. There is no claim that NOX returned.
- Sound and reduced-motion settings persist on the device. Each record save is separate from the previous experiment campaigns.

## Content and art

The product deck is data/noxsum_grant36_v1.json. Its eight replacement problem definitions follow the final feature/grant36-v0.5-board-shapes source at commit 42a4b5b. GR01–GR20 teach foundations and mechanics; GR21–GR33 build advanced reasoning; GR34–GR36 integrate them on shaped boards. The v0.5 problems replace GR24, GR25, GR28, GR29, GR32, GR34, GR35, and GR36; the other 28 Nox records remain from the existing campaign with only the source's internal review_only metadata omitted. GR36, THE SHAPED FINALE, keeps TOP, LEFT, RIGHT, and BOTTOM fixed and active, and asks players to read overlaps and absences on its shaped board. Its mask controls where NOX can be placed while the recorded shadow plate remains complete. The NOXSUM save is user://noxsum_grant36_v1.json. The world copy is in src/nox_story.gd and sparse milestone notes appear at the opening, mechanic introductions, chapter turns, and final plate.

The portrait HOME painting is assets/nox/v0.4/archive_window.png. Godot renders the logo, navigation, and all text live. The [NOX character lock](../assets/nox/CHARACTER_LOCK_v0.1.md) fixes the white-dominant black-and-gray coat across HOME and SIT/STAND/WALK/SLEEP art. The old prototype campaigns remain available through --campaign flags.

## Web target

The Grant deliverable is a Godot 4.7 Web export for a PC browser. The base viewport is 720×900; the HOME, GALLERY, and stages reflow at 405×900. See [export instructions](NOXSUM_WEB_EXPORT.md). The local release artifact is builds/web/index.html and its adjacent JS, WASM, PCK, and icon files. Serve the folder over HTTP or HTTPS.

## Verification

The project smoke script checks all 36 stage routes, HOME navigation, a recorded solve, and bounds at 720×900 and 405×900:

```powershell
$g = Join-Path $env:USERPROFILE 'tools\godot-4.7\Godot_v4.7-stable_win64_console.exe'
$env:NOXSUM_WIDTH = '720'; & $g --headless --path . --script res://tools/nox_presentation_smoke.gd -d --ignore-error-breaks
$env:NOXSUM_WIDTH = '405'; & $g --headless --path . --script res://tools/nox_presentation_smoke.gd -d --ignore-error-breaks
```

The Grant36 draft smoke checks the 16 added puzzles' mouse solutions, 64 wrong worlds, and four fog records. The Web build was also opened through a local HTTP server in Chromium at both target sizes. GALLERY, stage entry, a full Stage 01 solve, return HOME, and saved progress were exercised with the mouse. The browser console reported zero errors or warnings.

## Visual previews

- [HOME, 720×900](previews/web_v04/browser_home_720.jpg)
- [HOME, 405×900](previews/web_v04/browser_home_405.jpg)
- [Stage 01 solved, 405×900](previews/web_v04/browser_solved_405.jpg)
- [GALLERY, 405×900](previews/web_v04/browser_gallery_405.jpg)
## Language and wordmark

English and Japanese can be switched from the HOME header, the HOME settings panel, and the stage header. The choice is saved in `user://noxsum_settings.cfg`. Switching on a stage preserves the current reconstruction and clue level. Chapter headings, all 36 titles and notes, hints, controls, tooltips, and outcome copy have both languages. A bundled Noto Sans JP fallback supplies Japanese glyphs in the Web export; its OFL notice is in `assets/fonts/NotoSansJP-OFL.txt`.

The X in NOXSUM is drawn from two pale diagonal ribbons carrying translucent dark bands. Their intersection receives both bands and a dark center, making the extra shadow density visible in the wordmark at the HOME and stage sizes.

Japanese browser previews: [HOME 405×900](previews/web_v05/home_ja_405.jpg), [GALLERY 405×900](previews/web_v05/gallery_ja_405.jpg), [stage 405×900](previews/web_v05/stage_ja_405.jpg), and [settings 405×900](previews/web_v05/settings_ja_405.jpg).

## First-play and completion UX

The first unsolved visit to Trace 01 opens a four-step bilingual guide. The stage keeps a `?` button in the Night Log so players can reopen it. Short inline prompts advance from comparing the two plates to choosing a pose, placing NOX, and matching every shade. The selection and placement controls give a small pulse and tone; shadow changes tween across the reconstruction plate. Reduced-motion mode shows each state immediately.

A solve now scans both plates with brass light and small glints, plays a restrained three-note chime, then shows the matched record count and enables NEXT. Clearing Trace 36 **after all 36 records are complete** opens a dedicated bilingual finale: 36 points connect into one record path. It celebrates reconstruction without fixing NOX's fate. HOME then offers `VIEW RECORDS` / `記録を見直す` instead of CONTINUE.

The bottom light input is active in every NOXSUM stage that allows light selection. When the selected-light limit is full, the Night Log explains that one light must be turned off before another can be chosen. Fixed light mounts remain fixed as specified by each puzzle.

## Latest verification

On 2026-09-24, `tools/nox_presentation_smoke.gd`, `tools/nox_locale_smoke.gd`, and `tools/nox_ux_smoke.gd` passed at 405×900 and 720×900. The UX smoke verified the GR36 fixed-light rule, rejection of missing shaped-board sockets, and runtime solves for all eight v0.5 replacements; the bottom light remains interactive in all 10 selectable traces. The independent v0.5 validator re-enumerated all 36 stages and 128 candidates: every candidate was unique, each replacement had two survivors when its board mask was removed, and malformed-mask and FOG unknown-as-zero checks passed. The Nox deck matches the final v0.5 puzzle source after excluding the source's internal `review_only` flags. The exported-Web Chromium check predates this puzzle-data sync. No Web export or deployment was run for this change.

Previously captured v0.6 previews: [first-play guide, 405×900](previews/web_v06/guide_final_405.jpg), [Trace 36, 720×900](previews/web_v06/stage36_720.jpg), [Japanese finale, 720×900](previews/web_v06/finale_ja_720.jpg), and [completed HOME, 405×900](previews/web_v06/home_complete_ja_405.jpg).

Latest UI review: [Trace 36 with directional OFF lights and horizontal WALK, 405×900](previews/nox_ui_trace36_ja_405_final.jpg) and [the top light switched ON, 405×900](previews/nox_ui_trace36_light_on_ja_405_final.jpg). Japanese locale smoke now checks all 108 clue steps across 36 traces at both target widths.