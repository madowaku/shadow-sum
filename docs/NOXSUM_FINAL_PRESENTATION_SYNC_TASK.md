# NOXSUM FINAL PRESENTATION SYNC

## Why this task exists

The first family-test Web build from `codex/noxsum-grant36-final-sync` is logically correct but visually/audio-wise stale.

Observed in production:
- Grant36 v0.5 puzzle content is present.
- GR28 is the final `PLATE IN THE GAP`.
- But the gameplay presentation looks like the older experiment UI.
- BGM is missing.

Root cause confirmed in the repository:
1. Final Grant36 routing currently launches `res://scenes/experiments.tscn`, whose script is `src/experiment_main.gd`.
2. The repository's richer GLASS & METAL presentation exists separately under `src/glass_metal_main.gd`, `src/night_skin_main.gd`, and related UI visual scripts, but that presentation layer is not applied to the Grant36 experiment runtime.
3. The synced branch contains no committed BGM asset under `assets/bgm/`; `experiment_main.gd` only synthesizes/plays SFX through an `AudioStreamPlayer`.
4. Therefore the Web PCK can be logically current while still shipping an old-looking play screen with no BGM.

This task is presentation-only. Do not change the final 36 puzzle semantics.

---

## Source branches / worktrees

Primary branch to fix:
- `codex/noxsum-grant36-final-sync`

Final puzzle source of truth:
- existing synced `data/grant36_v0_5.json`
- existing Grant36 runtime/validators on the branch

Presentation references already in repo:
- `src/glass_metal_main.gd`
- `src/night_skin_main.gd`
- `src/ui/post_visual.gd`
- `src/ui/socket_visual.gd`
- `src/ui/shadow_glass_visual.gd`
- `src/night_tokens.gd`
- NOXSUM HOME + NOX assets already on the branch

Original local project may contain newer uncommitted/previously untracked audio assets:
- check `C:\Dev\Projects\shadow-sum\assets\bgm\`
- expected BGM name from prior implementation: `ガラス張りの三角錐.mp3`
- check the original project for the six existing CC0 SFX assets as well

Do not invent replacement music if the authored asset is missing. Report exactly what is absent.

---

## P0-A: make Grant36 use the current NOXSUM / GLASS & METAL presentation

Do not route Grant36 back to the old 18-stage gameplay model.

Instead, bring the established physical visual language onto the current Grant36 runtime.

Required visual language:
- NOXSUM title/product identity
- dark quiet optical-instrument background
- physical recessed socket visuals
- physical NOX/object visuals rather than plain text glyphs where the current product design provides them
- frosted glass TARGET / LIVE surfaces
- clear distinction between FOG and missing Board Shape sockets
- Tall / Plate / Normal remain instantly distinguishable
- Plate orientation remains readable
- active/inactive lamps remain readable, including BOTTOM
- current solve/clear presentation remains intact
- current NOX-specific wording and HOME remain intact

Implementation strategy:
- Prefer extracting/adapting presentation helpers from the GLASS & METAL stack into the Grant36 UI rather than replacing the Grant36 logic.
- All visual child controls must be input-transparent.
- Buttons/sockets/lights remain authoritative interaction targets.
- No presentation node may mutate puzzle state.

Acceptance:
- GR01, GR28, GR29, GR32, GR36 visually match the current product art direction, not the old experiment prototype.
- Board shape missing cells still look absent rather than merely disabled.
- FOG still looks like unobserved glass, not zero.
- NOX/object inventory visuals are consistent with gameplay pieces.

---

## P0-B: restore BGM

First inspect the original local project for the authored BGM.

Expected:
- `C:\Dev\Projects\shadow-sum\assets\bgm\ガラス張りの三角錐.mp3`
- approximately 94-second loop from the previously approved build

If present:
1. copy it into this worktree under a stable committed path, preferably `assets/bgm/`
2. ensure Godot imports it
3. add a dedicated BGM `AudioStreamPlayer` or bus separate from one-shot SFX
4. autoplay from product/game flow after browser interaction rules allow audio
5. loop cleanly
6. use the existing sound control to mute/unmute both BGM and SFX unless the product currently has separate controls
7. persist mute state
8. returning HOME -> game or changing stages must not stack multiple simultaneous BGM players

Important Web behavior:
- Browsers may block audio before the first user gesture.
- Do not treat autoplay rejection as a fatal error.
- Start/resume BGM on PLAY/CONTINUE/stage-select or first gameplay gesture.
- The visible sound state must agree with actual playback.

If the BGM asset does not exist in the local source:
- stop only the BGM portion
- report the missing expected path
- do not substitute arbitrary music

---

## P0-C: retain approved SFX

The previous approved direction used six short CC0 SFX for:
- UI click / switch
- Post placement / removal
- drag / movement
- glass / completion

Inspect the original local project and current branch for those files. If the current NOXSUM Web build uses only synthesized beeps while authored SFX exist locally, restore the authored SFX.

Do not change licenses or add unverified assets.

---

## P0-D: Web export must include presentation/audio assets

The previous deploy uploaded only 5 Web files, which is normal for Godot because assets are packed in `index.pck`. Therefore filename count is not the problem.

Verify the new export's PCK is rebuilt after visual/audio changes.

Export from the fixed worktree using the existing `NOXSUM Web` preset.

Output:
- `builds/NOXSUM_Grant36_v0_5_final_presentation/`
or the existing final-sync output location if that is already canonical.

Do not reuse the old ZIP/PCK.

---

## P1: regression tests

Add presentation/audio smoke coverage without weakening existing Grant36 tests.

Minimum automated checks:

### Presentation route
- normal HOME -> PLAY reaches Grant36 runtime with the new presentation layer active
- GR28 remains `PLATE IN THE GAP`
- final 36-stage validator remains unchanged and green

### Visual components
- GR01 has material socket/object visuals
- GR28 missing Board Shape sockets are visually unavailable
- GR29 FOG uses frosted/unobserved presentation
- Plate orientation changes visual state
- Tall and Normal are visually distinct
- visual overlays are mouse/touch transparent

### Audio
- BGM resource loads when asset exists
- only one BGM player exists after HOME -> stage -> stage transitions
- mute toggles BGM and SFX
- mute preference survives reload
- Web-safe delayed start path exists for first-user-gesture audio

### Responsive
Check:
- 360x800
- 405x900
- 720x900

No visual polish may push gameplay controls offscreen.

---

## Manual QA gate

Before producing the ZIP, run a browser build and visually inspect:
- HOME
- GR01
- GR11 or GR12 for Plate
- GR22 for BOTTOM/free lights
- GR28 for Board Shape + Plate
- GR29 for FOG
- GR32 for Tall + Plate + Board Shape
- GR36 finale

At each stage confirm:
- current NOXSUM look, not prototype look
- BGM audible after first gesture when sound is ON
- SFX audible
- sound toggle works
- no duplicate music
- puzzle semantics unchanged

Capture screenshots of GR01, GR28, GR29, GR36 for review.

---

## Definition of done

Do not call this task complete until:
- the family-test Web build no longer looks like the old experiment prototype
- Grant36 still contains exactly the approved GR01–GR36
- GR28 is still `PLATE IN THE GAP`
- GLASS & METAL / NOXSUM physical presentation is active on Grant36 gameplay
- authored BGM is present and audible after user gesture, or the exact missing local asset path is explicitly reported
- authored SFX are retained/restored where available
- mute state works and persists
- all existing Grant36 validators/smokes remain green
- 360/405/720 responsive checks pass
- a fresh Web export/ZIP is generated from the fixed worktree

Do not redeploy the old ZIP.
