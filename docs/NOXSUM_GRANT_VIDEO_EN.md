# NOXSUM — English grant application video

Created: 2026-09-27. User preference: English on-screen text, no narration.

Updated: 2026-09-27. Gameplay re-recorded with NOX afterimages from release source `11ad65c` (gameplay implementation `708b020`). The seven scenes, 90-second timeline, English text, crops, D5 overlays, music and sound mix are unchanged.

## Deliverable

- `builds/grant-video/NOXSUM_Grant_EN_90s_1080p.mp4`
- 90 seconds, 1920 × 1080, 30 fps, H.264 / AAC.
- Editable composition: `NoxsumGrantEN`, in `tools/noxsum-opening-remotion/src/grant/`.
- Quiet music, real game sound effects, English game UI and English editorial text.

## Storyboard / English script

| Time | Actual footage | English message |
| --- | --- | --- |
| 00:00–00:08 | Existing NOX / window artwork; the cat fades away | **NOX is gone. The shadows remember.** A quiet logic mystery. |
| 00:08–00:15 | GR01: place SIT at C3 | **Where was NOX?** Place a trace of the cat. Match the recorded shadows. |
| 00:15–00:22 | GR02: B2 + C3; overlapping shadows | **One cat. Several moments.** Each trace is a different moment. Overlapping shadows add up. |
| 00:22–00:29 | GR03: B4 + B5 + C5 | **A convincing wrong answer.** Three traces. One seemingly perfect match. |
| 00:29–00:35.5 | Hold the wrong GR03 answer; magnify both plates and outline D5 | **Every shadow fits. Except one.** All marked squares agree. But D5 should be clear. |
| 00:35.5–00:41.5 | Remove C5, then place A5 | **Read the empty squares.** Move the trace. Test the whole record. |
| 00:41.5–00:48 | Hold the adopted GR03 B solution | **Absence is evidence.** Now every square agrees — including the empty ones. |
| 00:48–00:54 | GR09: STAND at C3 | **A different pose. A different shadow.** STAND reaches farther. |
| 00:54–01:00 | GR11: rotate WALK at C3 | **Turn the pose. Turn the shadow.** WALK changes the direction of its trace. |
| 01:00–01:08 | GR08: C2 + D4, move SLEEP to column C | **Even a nap changes the clues.** SLEEP blocks light from above. Slide it along the rail to reshape the evidence. The same placement. A different set of shadows. |
| 01:08–01:15 | GR24: shaped board, B1 + E2 + C4 | **Fewer places. Sharper deductions.** Shaped boards narrow the possibilities. A missing position changes what the shadows can mean. |
| 01:15–01:22 | GR36: mixed poses / shaped board | **Simple rules. Layers of logic.** Combine poses, light and board shapes. Find the arrangement that explains it all. No timer. Time to think. |
| 01:22–01:30 | NOXSUM / NOX end slate | **Read what remains.** Playable browser prototype. 36 records · English / Japanese. In active development. |

The footage is reordered to explain the design; it does not imply this is the campaign's stage order.

## Gameplay provenance

`tools/grant_video_capture.gd` instantiates the real `src/experiment_main.gd` with the canonical `data/noxsum_grant36_v1.json`. It uses real placement, rotation and shutter APIs and checks each resulting solved state. There is no replacement puzzle simulation in Remotion.

The canonical deck SHA-256 at capture is `d7db564e4bf74cd4bc180c2212bd065b75ab2f6dc1a9e88fd8b917c330d6808f`.

- GR03 adopted answer: **B4, A5, B5**.
- Demonstrated wrong answer: **B4, B5, C5**. All positive target cells agree, but it creates a shadow at **D5**, where the record is empty.
- Both enlarged plates show the same footage, in sync with the main view. The gold D5 outlines are editorial overlays.
- Recording uses a separate `NOXSUM_GrantVideoCapture` user-data directory. It does not overwrite the player's normal settings or progress.
- Automated afterimage recording checks are saved in `builds/grant-video/afterimage/capture-checks.json` and `audio-capture-checks.json`.
- Both capture passes passed all 34 checks, with zero Godot errors or warnings. Checks cover placement hold/fade, settled board alpha of 45%, SLEEP alpha of 100%, solved states, and GR03 differing from the target only at empty D5 before correction.
- Placement retains 100% alpha for 0.25 seconds, then fades over 0.40 seconds. All filmed board placements use the real afterimage implementation, including STAND and WALK; SLEEP remains opaque.
- The original MP4, gameplay source and poster are preserved under `builds/grant-video/submitted-2026-09-27/`. The immutable `grant-submission-2026` tag remains at `10520036a2ce207d43900c4bdf614172c4bb133f`.

## Assets and music

All artwork, cat poses and typefaces come from the existing NOXSUM project. No new stock imagery or generated artwork was needed.

Music: **論理的思考 / Logical Thinking**, **Phalene**; existing `assets/bgm/logical_thinking.mp3`.

- [Track source](https://opentracks.com/bgm/detail/9090)
- [OpenTracks license](https://opentracks.com/help/articles/license/)
- [Phalene's conditions](https://opentracks.com/creator/detail/260)

The music is used as background accompaniment, with reduced volume and fades. The source license and creator conditions were checked for video use on 2026-09-27. The end slate includes a courtesy credit.

## Grant fit

The [Draknek grant page](https://grants.draknek.org/) and [application form](https://docs.google.com/forms/d/e/1FAIpQLSduUZpwiB6dIjBoSqBBrDkdNIgXo52lFI475SC1BYsPgOf9sA/viewform) were checked on 2026-09-27. The form requests a video link and accepts gameplay with or without commentary and/or a trailer. It does not require polished editing or specify a runtime. This 90-second version is an editorial choice.

The video demonstrates a playable puzzle and its deductions. It makes no claims about funding allocation, team identity, or release date. To submit, upload the MP4 to a service that provides a playable URL and paste that URL into the form. This task does not publish the video or submit an application.

## Editing and rendering

From `tools/noxsum-opening-remotion`:

```powershell
npm ci
npm run lint
npx remotion studio --no-open
npx remotion render src/index.ts NoxsumGrantEN ../../builds/grant-video/NOXSUM_Grant_EN_90s_1080p.mp4 --codec=h264 --crf=18 --pixel-format=yuv420p --audio-bitrate=192k
```

The source uses seven separately editable scenes and an explicit `TransitionSeries`. Existing opening compositions are preserved. The gameplay file and music are local under `public/grant/`.

The capture tool supports `-- --frames` for high-resolution JPEG frames and `--output` for a separate capture directory. The afterimage intermediates stay under ignored `builds/grant-video/afterimage/`.

Capture twice at fixed 30 fps with Godot 4.7: a Movie Maker pass for synchronized real game audio, and a JPEG pass for 1440 × 1800 footage of the same logical 720 × 900 UI. Both runs execute the same action timeline. From the repository root, with `$godot` pointing to the Godot console executable:

```powershell
& $godot --path . --debug --ignore-error-breaks --fixed-fps 30 --disable-vsync --write-movie builds/grant-video/afterimage/gameplay.avi --script res://tools/grant_video_capture.gd -- --output res://builds/grant-video/afterimage
Copy-Item builds/grant-video/afterimage/capture-checks.json builds/grant-video/afterimage/audio-capture-checks.json
& $godot --path . --debug --ignore-error-breaks --fixed-fps 30 --disable-vsync --script res://tools/grant_video_capture.gd -- --frames --output res://builds/grant-video/afterimage
ffmpeg -y -framerate 30 -start_number 0 -i builds/grant-video/afterimage/frames/%05d.jpg -i builds/grant-video/afterimage/gameplay.avi -map 0:v:0 -map 1:a:0 -frames:v 2879 -c:v libx264 -preset medium -crf 16 -pix_fmt yuv420p -c:a aac -b:a 192k -shortest -movflags +faststart builds/grant-video/afterimage/gameplay.mp4
Copy-Item builds/grant-video/afterimage/gameplay.mp4 tools/noxsum-opening-remotion/public/grant/gameplay.mp4
```

The resulting local source has 2,879 frames (95.966667 seconds), matching the original source length and every existing `trimBefore` value. Then run the render command above. The poster uses unchanged opening artwork.

## Afterimage render verification — 2026-09-27

- Final MP4: 10,038,163 bytes; H.264, 1920 × 1080, 30 fps, 2,700 video frames / 90.000 seconds. AAC stereo audio is 90.048 seconds including codec padding.
- SHA-256: `3dabc454341145a5fa8d75b2f29c8bbf0c1c51869b81dc1d4440d3e0e75eb251`. Sidecar: `builds/grant-video/NOXSUM_Grant_EN_90s_1080p.mp4.sha256`.
- `npm run lint` and Remotion render passed. The complete MP4 decoded successfully; no black interval of 0.2 seconds or more was detected. Audio peak: -12.9 dBFS, with no clipping.
- Final-frame spot checks confirm GR01/02 afterimages, the GR03 wrong / removal / corrected sequence and synchronized D5 enlargement, readable STAND/WALK poses, opaque SLEEP, and the closing slate. Evidence frames and decode log: `builds/grant-video/afterimage/qa/`.
- The five saved game-layout snapshots match the original capture, preserving the editorial crop and D5 highlight alignment. Game logic, shadow calculation, deck and save format were not changed for this re-recording.
