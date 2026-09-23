# NOXSUM × GRANT36 v0.5 final sync

The NOXSUM HOME and presentation remain the product entry point. Normal PLAY, CONTINUE, and stage select now route to the final `grant36-v05` campaign. The shipped campaign data is `data/grant36_v0_5.json`, copied without semantic edits from `feature/grant36-v0.5-board-shapes`. Its canonical JSON SHA-256 is `77aa04b701dbbeaf34ac57d65817ee35168dfff44dbbdacf8a37dfb328fb8f59`.

HOME and gameplay share `user://shadow_sum_grant36_v0_5.json` and the `grant36-v05` campaign identity. The HOME selector lists all 36 traces, allows direct selection, and scrolls vertically at compact widths. Previous Grant20 saves remain separate. Developer campaigns remain behind explicit arguments.

The v0.5 optics and runtime enforce the 5×5 board mask, unobstructed shadow rays across absent sockets, FOG as unknown evidence, Tall reach, Plate orientation and return, exact Normal/Tall/Plate inventory, and fixed versus selectable lights. The eight replacement records are GR24, GR25, GR28, GR29, GR32, GR34, GR35, and GR36. GR28 is **PLATE IN THE GAP**, with Normal×2, Plate×1, four fixed lights, no movable shutter, and mask `10101 / 11111 / 00100 / 11111 / 10101`.

## Verification

- `python tools/validate_grant36_v05.py`: 36/36 exact-unique; six board-shape fixtures and 128 candidates pass.
- `python tools/validate_noxsum_grant36_sync.py`: entire 36-stage array matches the final semantic digest; HOME, router, progress, masks, and GR28 sentinel pass.
- `tools/grant36_v05_smoke.tscn`: eight replacements solved with mouse input; typed inventory, Plate return, FOG, mask click/drag/undo, BOTTOM, and compact/wide bounds pass.
- `tools/noxsum_grant36_sync_smoke.gd`: actual HOME → GR28 selection, fresh 36-stage collection, GR01 solve and HOME progress after return/restart, GR22/23/27/31 BOTTOM toggles, ten stage/control spot checks, and 360×800 / 405×900 / 720×900 bounds pass. Explicit `--campaign=grant36-v05 --stage GR28` and default `--stage GR28` routes also pass.
- Existing Grant20, Flat Plate, Light & Height, and Unknown Godot smoke scripts pass. The Grant18 and Grant20 Python validators and stage-analysis tests pass.
- Web release export opened in Chromium. HOME, all ten requested spot-check stages, an actual mouse solve of GR28, and progress on return to HOME were checked. GR36 and the 36/36 selector were opened. The browser console had zero errors and warnings.

## Family-test Web build

Godot 4.7 with matching single-threaded Web export templates:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64_console.exe" --headless --path . --export-release "NOXSUM Web"
python -m http.server 8766 --bind 127.0.0.1 --directory builds/web
```

Open `http://127.0.0.1:8766/` from this machine. The local build files are in `builds/web/`; `export_presets.cfg` reproduces the release export and includes only the final Grant36 stage JSON. The build starts at `res://scenes/home.tscn`. The distributable archive is `builds/NOXSUM_Grant36_v0_5_final_sync.zip` (22,460,111 bytes; SHA-256 `c15da461807d357ee900fd72f9a6aa0edbfe41fa541d332b74ca506f2ef5bf32`).
