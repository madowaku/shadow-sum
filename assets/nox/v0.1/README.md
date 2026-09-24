# NOX v0.1 asset set

Initial Godot-ready NOX exports based on the supplied character sheet and NOXSUM asset brief.

| Asset | Export | Size | Background |
| --- | --- | ---: | --- |
| Sitting board piece | [nox_sit.png](board/nox_sit.png) | 1024 × 1024 | Transparent |
| Upright standing board piece, three-quarter side view | [nox_stand.png](board/nox_stand.png) | 1024 × 1024 | Transparent |
| Sleeping board piece | [nox_sleep.png](board/nox_sleep.png) | 1024 × 1024 | Transparent |
| Walking board piece, horizontal | [nox_walk.png](board/nox_walk.png) | 1024 × 1024 | Transparent |
| Walking board piece, depth direction | [nox_walk_v.png](board/nox_walk_v.png) | 1024 × 1024 | Transparent |
| Neutral bust portrait | [nox_bust_neutral.png](ui/nox_bust_neutral.png) | 1024 × 1024 | Transparent |
| NOX silhouette | [nox_silhouette.png](ui/nox_silhouette.png) | 512 × 512 | Transparent |
| NOXSUM app icon master | [noxsum_app_icon_master.png](brand/noxsum_app_icon_master.png) | 1024 × 1024 | Opaque, square |

Board-piece scale is separated by pose: sitting is the medium form, standing is taller, and sleeping is the low, wide form. The board PNGs are centered horizontally and leave transparent safety space around their visible pixels. Their intended placement anchor is Bottom Center; use the alpha bounds when aligning the art to a cell baseline because the transparent padding is not identical for every pose.

The character images contain illustrated fur shading only. Puzzle-rule shadows, shadow direction, and shadow strength stay in separate Godot layers or code. No contact-shadow overlay is included in this set.

All files are PNGs with an unembedded color profile and are intended for Godot's standard sRGB texture import. The transparent exports have an alpha channel; the icon alpha is fully opaque. The icon master has no rounded corners so platform masking can be applied later.

## WALK: directional Flat Plate

WALK is the NOXSUM character pose for the directional Flat Plate (also referred to as Flat Post). The base pose follows WALK A from the supplied walking concept sheet: a calm stride with an elongated body and a low tail. These are two static orientation sprites.

| Engine state | WALK asset | Body axis / heading | Responds to light |
| --- | --- | --- | --- |
| `plate_h` | `board/nox_walk.png` | Horizontal / right | TOP and BOTTOM |
| `plate_v` | `board/nox_walk_v.png` | Depth / away from the viewer | LEFT and RIGHT |

A 90-degree turn swaps these two views while retaining the same cell and ground anchor. Represent rotation around the cat's vertical axis by switching the view; rotating the upright PNG 90 degrees on screen would put the cat on its side. The existing puzzle keys and optical rules remain the mapping used by the source assets.

WALK exports use the individual processed frame with native alpha, zero chroma-key thresholds, and a padded main-component bounding box. This keeps fine fur edges and prevents faint disconnected alpha pixels from controlling the sprite's framing. Both exports use a 1024-pixel canvas, 0.80 fit scale, and bottom alignment.

## Source and processing

- Generated with OpenAI ImageGen in Codex on 2026-09-23, using the user-provided NOX character sheet as the reference. Follow-on poses use the preceding generated NOX image to keep the character consistent.
- Raw ImageGen outputs remain in `C:\Users\hiro\.codex\generated_images\01a0ccd8-54f6-7702-b593-52e673aca044` and are mapped in `metadata/`.
- Exact generation prompts, including the standing pose, both WALK orientations, and the revised bust prompt, are in [prompts](prompts/).
- Final files were exported from untouched raw images with the `generate2dsprite.py process` one-cell pipeline. Board pieces and bust use a 0.76–0.86 fit scale; silhouette uses 0.80 at 512 px; the icon uses 1.00 at 1024 px. Pipeline settings and source paths are recorded in [metadata](metadata/).
- The attached reference image was used only as a visual reference; it is not bundled in this asset folder.

These are source assets ready to load by `res://assets/nox/v0.1/...`. They are not wired into an existing scene yet.
