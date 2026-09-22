# Audio

The main puzzle uses the following audio layers:

- BGM: `assets/bgm/ガラス張りの三角錐.mp3`, supplied from [OpenTracks](https://opentracks.com/bgm/detail/8127).
- UI and gameplay SFX: the small CC0 Kenney selections in `assets/audio/kenney/`.

`src/ui/audio_manager.gd` keeps the BGM loop separate from a four-voice SFX pool. The header sound control mutes both layers, and the preference is stored beside the current progress file. Cue names follow the semantic event approach described by UISFX (https://uisfx.com/ui-sound-design): frequent placement feedback stays short and quiet, while the solve cue carries more weight.

The Kenney license files are kept next to the imported sounds. For the OpenTracks track, retain the source page and follow the license terms that applied when the file was downloaded.
