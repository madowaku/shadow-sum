# NOXSUM opening prototype

## English grant video (2026-09-27)

`NoxsumGrantEN` is a separate 90-second, 1920 × 1080 / 30 fps composition with actual game footage, English on-screen text and quiet music. The original opening compositions below are preserved.

The scenes are in `src/grant/`. See [the grant video storyboard and asset notes](../../docs/NOXSUM_GRANT_VIDEO_EN.md) for the English script, footage provenance and music credit.

```powershell
npx remotion render src/index.ts NoxsumGrantEN ../../builds/grant-video/NOXSUM_Grant_EN_90s_1080p.mp4 --codec=h264 --crf=18 --pixel-format=yuv420p --audio-bitrate=192k
```

## Original opening

A frame-driven, silent Remotion prototype for the NOXSUM first-launch opening. It is separate from the Godot game. Both compositions use the same 210-frame / 30 fps timeline.

- `NoxsumOpeningPortrait`: 405 × 900
- `NoxsumOpeningLandscape`: 1600 × 900

## Preview

From this directory:

```powershell
npm install
py prepare_assets.py
npx remotion studio --no-open
```

Open the printed local URL and select a composition. Check frames 34, 44, 52, 78, 88, 96, 130, 140, 165, 179, 190, 204, and 209. Layers with names such as **NOX Sit**, **Sit Shadow**, **Board Ghost**, and **NOXSUM Title** can be selected and edited in Studio. Timing values for the future Godot implementation are in [the handoff JSON](../../docs/NOXSUM_OPENING_TIMING_v0.1.json).

## Art provenance

The SIT, STAND, and WALK WEBP files in `public/nox/` come from the canonical transparent sprites in `assets/nox/v0.1/board/`. Shadows are separate Remotion layers. The city view in `public/room/` comes from the cat-free part of the current HOME illustration. `nox_window.webp` is a masked transparent cutout of the seated rear-view NOX in the current HOME illustration. The mask coordinates are kept in `prepare_assets.py` for refinement. Check any future replacement against `assets/nox/CHARACTER_LOCK_v0.1.md`.

The prototype contains no audio or explanatory text. The first-launch version key, skip inputs, reduced-motion branch, and HOME transition are Godot integration work; this Remotion package supplies the composition and timing for that work.



