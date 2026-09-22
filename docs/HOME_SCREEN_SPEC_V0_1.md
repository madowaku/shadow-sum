# HOME_SCREEN_SPEC v0.1

## Goal

Turn SHADOW SUM startup from a direct prototype boot into a deliberate Grant-demo entrance.

The HOME screen should communicate three things within a few seconds:

1. this is a puzzle about light and shadow,
2. the presentation is quiet, precise, and instrument-like,
3. PLAY leads directly into the current GRANT20 campaign.

## Scope

HOME v0.1 includes:

- title and subtitle,
- procedural optical-lab background,
- PLAY,
- CONTINUE,
- LEVEL SELECT,
- SETTINGS,
- QUIT,
- local progress readout,
- local SFX/fullscreen preferences,
- short fade transition into gameplay,
- MENU return from Grant20 gameplay.

Out of scope:

- store UI,
- account/profile systems,
- achievements,
- mobile-specific menu redesign,
- multiple save slots,
- final localization pass,
- final BGM integration.

## Visual direction

Keywords:

- optical laboratory
- black anodized metal
- frosted glass
- calibration
- thin measurement lines
- restrained cyan light
- warm calibration gold
- low motion
- high contrast

The HOME background is drawn procedurally so it stays responsive at the existing 405x900 reference viewport and wider desktop windows.

Ambient motion must stay subtle. The desired feel is:

`click / slide / align / settle`

not flashy arcade motion.

## Navigation

### PLAY

Starts GR01 without deleting existing progress.

### CONTINUE

Loads the first incomplete Grant20 stage.

Disabled when no Grant20 progress exists.

### LEVEL SELECT

Shows GR01-GR20.

Unlocked stages are:

- already completed stages,
- the current first incomplete stage.

Later stages remain disabled.

### SETTINGS

v0.1 includes:

- SFX ON/OFF
- Fullscreen ON/OFF

Preferences are stored at:

`user://shadow_sum_settings.json`

Gameplay procedural SFX reads the same setting.

### QUIT

Exits the application.

## Progress

Grant20 progress remains authoritative at:

`user://shadow_sum_grant20_v0_3.json`

HOME does not mutate completion state.

It only reads completion state for:

- CONTINUE,
- progress text,
- level unlocking.

## Campaign handoff

HOME sets a temporary root metadata value:

`shadow_sum_start_stage`

Then it changes to:

`res://scenes/campaign.tscn`

`campaign_main.gd` forwards the requested stage into the Grant20 experiment scene before `_ready()`.

Command-line developer flows remain available:

- `--dev-selector`
- `--campaign`
- `--campaign=...`
- `--stage`

When those flags are present, HOME immediately hands control to the existing campaign launcher.

## Gameplay return

Grant20 footer adds:

`MENU`

This returns to:

`res://scenes/home.tscn`

It does not change or reset progress.

## Files

Added:

- `scenes/home.tscn`
- `src/home_screen.gd`
- `src/ui/home_lab_background.gd`

Modified:

- `project.godot`
- `src/campaign_main.gd`
- `src/experiment_main.gd`

## Acceptance checklist

- [ ] Normal startup opens HOME.
- [ ] Developer command-line campaign launch still bypasses HOME.
- [ ] PLAY opens GR01.
- [ ] CONTINUE opens the first incomplete Grant20 stage.
- [ ] CONTINUE is disabled on a fresh save.
- [ ] LEVEL SELECT respects progression.
- [ ] SETTINGS persists SFX and fullscreen.
- [ ] Gameplay procedural SFX respects the HOME SFX preference.
- [ ] MENU returns from Grant20 to HOME.
- [ ] HOME remains readable at 405x900.
- [ ] HOME remains readable at 720x900.
- [ ] HOME remains readable at 1280x720.
- [ ] Keyboard focus is visible.
- [ ] Escape closes HOME overlays.
- [ ] No Grant20 puzzle logic changes.

## Follow-up polish

After the current audio branch/assets are merged:

- connect the shared BGM player to HOME,
- keep music continuous across HOME -> gameplay,
- add Music volume/toggle to SETTINGS,
- add the final logo treatment,
- tune intro and transition timing from captured play footage.
