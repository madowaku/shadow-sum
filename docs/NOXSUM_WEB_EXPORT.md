# NOXSUM Web Export

The Grant build targets a PC browser. The **NOXSUM Web** preset keeps the existing Android preset intact and exports a Godot Web build to `builds/web/index.html`.

## Export settings

- Web canvas resize policy: Adaptive, so the canvas follows the browser viewport. The project layout uses a 720 x 900 reference and must remain legible at 405 x 900 and 360 x 800.
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

## Previous local Web export (2026-09-26)

The approved Opening v0.1, GR07 footer fix, browser title correction, v0.5 deck exclusion, and single-input Opening transition fix were exported locally with Godot 4.7's release preset to `builds/web/`. The localized `/en/` and `/ja/` pages and OGP images were generated there. The matching package is `builds/NOXSUM_Grant_Web_2026-09-26.zip` (60,819,215 bytes), containing the nine Web runtime files plus three OFL font notices in `licenses/`. SHA-256: `1450363BEA96B12E2DE4DFFC50BCB8BDDA65541B60365307D6D061F3DDD6E716`.

The PCK path table has 194 entries and includes `data/noxsum_grant36_v1.json`; `data/grant36_v0_5.json` and `data/playtest/*` are absent. ZIP CRC, safe paths, and byte-for-byte matches between the nine archived runtime files and `builds/web/` passed. Chromium loaded the export over local HTTP: browser title `NOXSUM`, 0 console errors, and 0 console warnings.

This is a local export only. Netlify production has not been deployed. The previous package remains available as `builds/NOXSUM_Grant_Web_2026-09-23.zip`.

## Previous itch.io HTML5 submission package (2026-09-26)

`builds/NOXSUM_Grant_Itchio_2026-09-26.zip` was regenerated from the local Release package above. `index.html` is at the ZIP root, and its only content change is `<base href="/">` → `<base href="./">`. The JavaScript runtime, PCK, WASM, icons, audio worklets, and license notices are byte-identical to the source ZIP. The source ZIP SHA-256 is `1450363BEA96B12E2DE4DFFC50BCB8BDDA65541B60365307D6D061F3DDD6E716`.

The itch.io ZIP SHA-256 is `C057CE5F1CC6DEC2B47DE55B6C4B4BB090C36A9210A300A9991C5724FCF6BE40`. ZIP CRC, safe paths, and unchanged non-HTML payloads passed. This package was not uploaded.

## Submitted itch.io HTML5 package (2026-09-27)

The Godot Release Web preset was rebuilt after adopting GR03 variant B. The upload ZIP is `builds/NOXSUM_Grant_Itchio_2026-09-27.zip` (60,668,621 bytes; SHA-256 `B6F3712B211D9F1A53246DF0786769B7FF4CF09A408B9F2D7A3FC351CBE02DFE`). It contains the nine runtime files and three OFL font notices (12 files total, 91,239,812 bytes extracted). `index.html` is at the ZIP root and uses `<base href="./">` for itch.io's hosted subdirectory. ZIP CRC, file allowlist, payload equality, safe paths, and itch.io size limits passed with `tools/package_noxsum_itchio.py`. This package was submitted as the playable build at https://madowaku.itch.io/noxsum; see [the Grant submission snapshot](GRANT_SUBMISSION_2026.md).

## Latest local itch.io HTML5 package — Afterimage v0.1 (2026-09-27)

`release/noxsum-grant36-final` was fast-forwarded to `codex/nox-afterimage-v01` at `708b0209a33ddb89239e48e8f0da39a3915cf736`. The Release Web export was rebuilt with Godot `4.7.stable.official.5b4e0cb0f` and the existing **NOXSUM Web** preset, then the localized OGP pages were regenerated in `builds/web/`.

- ZIP: `builds/NOXSUM_Grant_Itchio_2026-09-27_Afterimage.zip`
- SHA-256: `6F9EBAF07611842960D7DADA95D003C47B4265E0ED563A4A9ACD530E6BEC6C73`
- Size: 60,670,162 bytes; 12 files; 91,241,300 bytes extracted.
- Checksum sidecar: `builds/NOXSUM_Grant_Itchio_2026-09-27_Afterimage.zip.sha256`
- Package verification: ZIP CRC, explicit file allowlist, safe paths, payload equality, root `index.html`, relative `<base href="./">`, and size limits passed.
- Browser smoke: the ZIP was extracted and served at a local HTTP subdirectory; HOME, opening skip, first-run guide, GR01 placement, afterimage and solve were checked at 720×900 and 360×800. Browser errors/warnings: 0/0. Export errors/warnings: 0/0.
- Build/package/browser logs: `builds/afterimage-release-qa/`; browser captures: `output/playwright/nox-afterimage-release/` (local generated artifacts).

This build includes the approved 0.25-second hold and 0.40-second fade. The game logic, shadow calculation, save format and Grant36 stage data are unchanged. `grant-submission-2026` remains at `10520036a2ce207d43900c4bdf614172c4bb133f`, and the submitted ZIP above is preserved. The Afterimage ZIP has not been uploaded to itch.io.

### Netlify production deployment — 2026-09-27

The existing `noxsum` Netlify site was manually deployed from this Release Web export with Netlify CLI (`--prod --dir=builds/web`). Netlify reports the deploy as ready in the production context.

- Production: https://noxsum.netlify.app
- Immutable deploy URL: https://6ab90b8f7189d8f6a34df68b--noxsum.netlify.app
- Deploy ID: `6ab90b8f7189d8f6a34df68b`
- Admin deploy record: https://app.netlify.com/projects/noxsum/deploys/6ab90b8f7189d8f6a34df68b
- Netlify reports three generated pages (`/`, `/en/`, `/ja/`) and one asset changed. Production and unique deploy URLs plus both localized pages returned HTTP 200 with the expected NOXSUM page title.

To rebuild the Afterimage package, run:

```powershell
& "$env:USERPROFILE\tools\godot-4.7\Godot_v4.7-stable_win64_console.exe" --headless --path . --export-release "NOXSUM Web" builds/web/index.html
py tools/build_noxsum_ogp_pages.py
py tools/package_noxsum_itchio.py --date 2026-09-27 --output builds/NOXSUM_Grant_Itchio_2026-09-27_Afterimage.zip
```

The package follows itch.io's [HTML5 ZIP requirements](https://itch.io/docs/creators/html5): a root `index.html`, relative asset paths, and limits on file count and extracted sizes.

The app icon is assets/nox/v0.6/app_icon.png, selected from the front-facing NOX concept. The exported browser icon and boot splash have pixel-identical RGBA content.

## Localized OGP pages

The Web export uses the custom HTML shell at web/noxsum_web_shell.html and has English OGP metadata on the root page. After each export, run py tools/build_noxsum_ogp_pages.py.

The script copies the OGP images into the public export and creates /en/ and /ja/ share pages with language-specific metadata and images. Deploy builds/web/ as the Netlify publish directory. The canonical share URLs are https://noxsum.netlify.app/en/ and https://noxsum.netlify.app/ja/.
