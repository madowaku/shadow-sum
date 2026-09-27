# NOXSUM Playtest Harness v0.1

## Start

From the `shadow-sum` project root:

```powershell
.\tools\playtest.ps1
```

The command validates `C:\Dev\Projects\noxsum-lab\exports\playtest_current.json`, copies it to `data/playtest/current.json`, and starts Godot 4.7 at `PT-001` in the current NOXSUM game screen. The generator checkout and export must exist before using the default command. To play any compatible pack now:

```powershell
.\tools\playtest.ps1 -Pack .\data\playtest\blind_flow20_aha20_v0_1.json
```

`-Stage PT-013` starts directly at that question. `-NoLaunch` validates and copies the pack without opening Godot. A pack may be an array of stage objects or an object with a `stages` array; stage IDs must be unique `PT-001` style IDs. The supplied blind deck contains 40 stages.

## In the game

The header and puzzle controls are the NOXSUM controls. The playtest screen shows the PT ID and hides Grant story titles, stage selection, HOME, ranking, and generator metadata. The OBSERVE action becomes **解答を見る / REVEAL**. A normal clear keeps the NOXSUM clear effects and opens four required 1–5 ratings plus an optional note. Revealing the answer shows the solution on the board, then asks for **NARUHODO / FLAT / UNFAIR** and an optional note. Submitting advances to the next PT stage. After the final stage, the screen shows the result file's absolute location.

Progress is stored in `user://noxsum_playtest.json`; ratings are saved after every submission in `user://noxsum_playtest_results.json`. The results JSON has a `results` object keyed by PT ID. Each record includes the outcome, ratings or reveal reaction, optional note, timing/action counts, and `source_id` when supplied by the generator. The pack SHA-256 is saved with both files, so data from a different pack is not loaded as current progress.

The Grant36 deck and its `user://noxsum_grant36_v1.json` save are separate. `data/playtest/current.json` is local and Git-ignored. Playtest data is excluded from the Android and Web export presets, and the playtest CLI entry is available only in debug builds.

## Checks

```powershell
.\tools\playtest.ps1 -Pack .\data\playtest\blind_flow20_aha20_v0_1.json -NoLaunch
& 'C:\Users\hiro\Desktop\Godot_v4.7-stable_win64.exe' --headless --path . --script res://tools/playtest_smoke.gd
& 'C:\Users\hiro\Desktop\Godot_v4.7-stable_win64.exe' --headless --path . --script res://tools/playtest_entry_smoke.gd -- --campaign=playtest --stage PT-013
```
