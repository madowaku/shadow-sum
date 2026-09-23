# NOXSUM VISUAL SOURCE-OF-TRUTH RECOVERY

## Incident

The production deploy at https://noxsum.netlify.app is still using an **older NOXSUM visual package**.

The gameplay/puzzle sync is not the issue. The problem is that the final presentation work used the visual assets and HOME implementation already present on `codex/noxsum-grant36-final-sync`, but those files were themselves older than the user's latest NOXSUM look.

Repository evidence:
- `codex/noxsum-grant36-final-sync` and `feature/noxsum-integration-v0.1` share the same old NOX asset blobs for `nox_sit.svg`, `nox_stand.svg`, `nox_sleep.svg`, `noxsum_icon.svg`.
- They also share the same `src/ui/home_lab_background.gd` blob.
- Therefore applying GLASS & METAL on top of that branch cannot recover a newer visual direction that never entered that branch.

The current production screenshot showing the old dark-grid optical-lab HOME is the wrong visual source.

## Non-negotiable rule

**Do not use GitHub branch age or the current sync branch as the visual source of truth.**

The source of truth for visuals is the newest working NOXSUM version on the user's machine, especially the work done after the NOX world / coat-pattern / HOME redesign.

Likely places to inspect:
- `C:\Dev\Projects\shadow-sum`
- `C:\Users\hiro\grant36-v05-board-shapes`
- `C:\Users\hiro\noxsum-grant36-final-sync`
- any additional NOXSUM worktrees under `C:\Users\hiro\`
- uncommitted changes and untracked assets
- reflog / local-only commits / detached worktrees if applicable

## Goal

Recover the **latest actual NOXSUM visual implementation** from the user's local machine and combine it with:
- final GRANT36 v0.5 36-stage logic/data
- current BGM restoration
- current save/progress sync
- current web-safe audio behavior

Do not redesign from memory. Recover and preserve the newest existing implementation first.

## Step 1: inventory every local source before changing anything

Run and record:
- `git worktree list`
- `git branch -avv`
- `git status --short` in every relevant worktree
- `git log --all --decorate --oneline --date-order -n 100`
- `git reflog --all --date=iso -n 200`

Search for recent NOXSUM visual files by path/hash/mtime:
- `src/home_screen.gd`
- `src/ui/home_lab_background.gd`
- `src/ui/*nox*`
- `assets/nox/**`
- HOME screenshots/mockups
- new NOX front/side/back references
- any white/black/gray calico coat-rule assets
- any recently created HOME background/frame/piece art
- any replacement gameplay surface or inventory art

Also search for files created or modified in the last 3 days under the repository/worktrees, including untracked files.

Create:
`docs/NOXSUM_VISUAL_SOURCE_AUDIT.md`

It must list every candidate source, path, branch/worktree, commit (if any), modification time, and file hashes.

## Step 2: identify the newest coherent visual set

The newest coherent set must match the user's most recent NOXSUM direction, including:
- NOX is a white/black/gray calico cat
- latest fixed coat-pattern rules and front/side/back consistency if implemented
- latest HOME layout, not the old generic optical-lab prototype
- latest gameplay piece art for SIT / STAND / WALK/FLAT where implemented
- current NOXSUM product identity

Do not infer the winner solely by timestamp if files are partial. Prefer the latest coherent set that visibly matches the recent local screenshots/reference work.

Generate side-by-side screenshots of every plausible candidate HOME at 405x900 and 720x900 and put them under:
`output/visual-source-audit/`

Do not proceed to a new production build until the chosen source is clearly documented.

## Step 3: port final puzzle/runtime INTO the chosen visual source

This time reverse the integration direction:

**latest visual build is the base**
+
**Grant36 v0.5 logic/data is transplanted into it**

Preserve:
- exact GR01–GR36 data
- GR28 = PLATE IN THE GAP
- Board Shape
- FOG
- Tall
- Plate
- BOTTOM fixes
- progress/save sync
- BGM
- sound persistence
- web audio first-gesture handling

Do not replace the latest HOME or NOX assets with files from `feature/noxsum-integration-v0.1`.

## Step 4: visual regression guard

Add a validator/smoke guard that fingerprints the chosen visual source.

At minimum assert:
- expected HOME script/hash or explicit version marker
- expected NOX primary asset hashes
- expected HOME/background asset hashes
- expected gameplay presentation version marker

Add a human-readable constant such as:
`NOXSUM_VISUAL_VERSION = "final-2026-09-23"`

The build must fail if an older visual package is accidentally exported again.

## Step 5: rebuild and compare before deployment

Create a fresh Web build in a NEW directory:
`builds/NOXSUM_Grant36_v0_5_visual_recovery/`

Before ZIP/export handoff:
1. open the current production `https://noxsum.netlify.app`
2. open the new local Web build
3. capture HOME screenshots of both at the same size
4. create a comparison image/report
5. explicitly state the concrete visual differences proving that the new build is not the old production HOME

Also capture:
- HOME
- GR01
- GR28
- GR29
- GR36

## Definition of done

Do not claim completion until:
- the visual source audit is written
- newest local NOXSUM visual source is identified
- latest HOME visibly differs from the currently deployed old HOME
- newest NOX art is present
- final Grant36 v0.5 logic remains unchanged
- BGM remains present
- all logical validators pass
- 360/405/720 layout checks pass
- new visual fingerprint guard passes
- fresh Web build and ZIP are generated
- comparison screenshots demonstrate the old-production-vs-new-build difference

**Do not deploy automatically.**
Wait for the user to visually approve the new HOME screenshot first.
