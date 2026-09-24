# NOXSUM Web Export

The Grant build targets a PC browser. The **NOXSUM Web** preset keeps the existing Android preset intact and exports a Godot Web build to `builds/web/index.html`.

## Export settings

- Web canvas resize policy: Adaptive, so the canvas follows the browser viewport. The project layout uses a 720 x 900 reference and must remain legible at 405 x 900.
- Thread support: disabled. The export uses Godot's single-threaded Web templates, avoiding the cross-origin isolation headers required for threaded builds.
- Progressive Web App packaging: disabled.
- Resource filter: include project resources for runtime-loaded scenes and assets, exclude the development tools and documents, and explicitly include `data/noxsum_grant36_v1.json`. The older puzzle decks are excluded.

## Install the matching Web templates

The installed Godot 4.7 template directory already contains Android and Windows templates. The 4.7 non-Mono export archive is about 1.28 GB, so the helper reads its ZIP directory remotely and fetches only `web_nothreads_debug.zip` and `web_nothreads_release.zip` from the official GitHub release. Existing files are never overwritten.

Run from the project root with Python 3:

```powershell
py tools/fetch_godot_web_templates.py
py tools/fetch_godot_web_templates.py --install
```

The first command inspects the official package; the second installs the two matching templates under `%APPDATA%\Godot\export_templates\4.7.stable`. The helper validates HTTP byte ranges, verifies ZIP CRCs while extracting, and checks the resulting template archives.

## Export and serve

After the project is ready to export, run the Godot 4.7 console executable:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64_console.exe" --headless --path . --export-debug "NOXSUM Web"
```

Use `--export-release "NOXSUM Web"` for the release build. Godot writes the HTML, JavaScript, WebAssembly, and game data files together in `builds/web/`. Serve that folder over HTTP or HTTPS for browser checks; do not open the exported page through `file://`.

Godot references: [Exporting for the Web](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_for_web.html), [Web export options](https://docs.godotengine.org/en/4.7/classes/class_editorexportplatformweb.html), and [Exporting projects](https://docs.godotengine.org/en/4.7/tutorials/export/exporting_projects.html).

## Current release package

The verified Grant package is `builds/NOXSUM_Grant_Web_2026-09-23.zip` (51,740,573 bytes). It contains the nine Web runtime files at the ZIP root, including `index.html`, `index.wasm`, and `index.pck`, plus three OFL notices in `licenses/` for the bundled fonts. SHA-256: `50681440598361D4306B77CAE4AB7593A40F1D72BAF575793CC2140B96B0367A`.

The app icon is assets/nox/v0.5/app_icon.png, selected from the front-facing NOX concept. The exported browser icon and boot splash have pixel-identical RGBA content.
