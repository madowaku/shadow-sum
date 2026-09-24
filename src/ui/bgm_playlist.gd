extends Node

const Settings = preload("res://src/nox_settings.gd")

## Plays one full pass of each track before returning to the first.
const TRACKS: Array[AudioStream] = [
	preload("res://assets/bgm/the_most_human_computer.mp3"),
	preload("res://assets/bgm/logical_thinking.mp3"),
	preload("res://assets/bgm/オルゴールワールド_Track1.mp3"),
	preload("res://assets/bgm/ガラス張りの三角錐.mp3")
]
const MUSIC_VOLUME_DB: float = -19.0

var music_player: AudioStreamPlayer
var current_track_index: int = -1
var playback_enabled: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = MUSIC_VOLUME_DB
	music_player.finished.connect(_play_next)
	add_child(music_player)
	set_enabled(Settings.sound_enabled())

func set_enabled(enabled: bool) -> void:
	playback_enabled = enabled
	if not is_instance_valid(music_player):
		return
	if not playback_enabled:
		music_player.stop()
		music_player.stream = null
		current_track_index = -1
		return
	if not music_player.playing:
		_play_next()

func _play_next() -> void:
	if not playback_enabled:
		return
	for _attempt: int in TRACKS.size():
		current_track_index = (current_track_index + 1) % TRACKS.size()
		var stream: AudioStream = TRACKS[current_track_index]
		if stream == null:
			continue
		if stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = false
		music_player.stream = stream
		music_player.play()
		return
	push_warning("No BGM tracks could be loaded.")

func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
		music_player.stream = null
