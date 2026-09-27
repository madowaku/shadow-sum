# MOBILE_UI_FIX v0.1 review

NOXSUM now reflows at widths up to 480 logical pixels. At 360×800 and 405×900, the header, two shadow plates, board, pose tray, compact Night Log entry, and bottom actions fit without game-area scrolling. OBSERVE opens a clue sheet; its open state and clue level survive language changes. The 720×900 layout keeps the desktop Night Log.

Concept A informs the app icon in assets/nox/v0.6/app_icon.png. Concept B informs the HOME painting in assets/nox/v0.6/archive_puzzle_window.png. The live NOXSUM wordmark remains unchanged. Matching English and Japanese OGP cards are in assets/ogp/.

## Review images

| Viewport | HOME | GR01 | GR07 | GR28 | GR29 | GR36 | Night Log |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 360×800 | [HOME](previews/mobile_ui_v01/360x800/home.png) | [GR01](previews/mobile_ui_v01/360x800/gr01.png) | [GR07](previews/gr07_stable_v01/360_gr07.png) | [GR28](previews/mobile_ui_v01/360x800/gr28.png) | [GR29](previews/mobile_ui_v01/360x800/gr29.png) | [GR36](previews/mobile_ui_v01/360x800/gr36.png) | [OPEN](previews/mobile_ui_v01/360x800/gr01_night_log_open.png) |
| 405×900 | [HOME](previews/mobile_ui_v01/405x900/home.png) | [GR01](previews/mobile_ui_v01/405x900/gr01.png) | [GR07](previews/gr07_stable_v01/405_gr07.png) | [GR28](previews/mobile_ui_v01/405x900/gr28.png) | [GR29](previews/mobile_ui_v01/405x900/gr29.png) | [GR36](previews/mobile_ui_v01/405x900/gr36.png) | [OPEN](previews/mobile_ui_v01/405x900/gr01_night_log_open.png) |
| 720×900 | [HOME](previews/mobile_ui_v01/720x900/home.png) | [GR01](previews/mobile_ui_v01/720x900/gr01.png) |  |  |  | [GR36](previews/mobile_ui_v01/720x900/gr36.png) |  |

For a prior local baseline, see [the saved 405×900 Japanese stage preview](previews/web_v05/stage_ja_405.jpg). It predates the latest puzzle-data sync and is not a capture of deployed production.

## Verification

Run tools/nox_mobile_ui_smoke.gd with Godot 4.7. It checks all 36 records at 360×800, 405×900, and 720×900 in Japanese and English; every mobile clue sheet; core bounds; title and prompt clipping; 44px touch controls; solve and reduced-motion layout; GR29 FOG; GR32 inventory; and GR36 missing sockets. The existing presentation, locale, and UX smokes pass at 405×900 and 720×900. The independent final Grant36 v0.5 validator passes. The HTTP-served Chromium regression also confirms the Opening → GR01 → GR07 route at 360×800 and 405×900, with no page or console errors.

The current Web export and browser checks are local. Netlify production has not been deployed.
