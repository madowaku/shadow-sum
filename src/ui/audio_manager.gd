extends Node

## Small, self-contained audio layer for the main puzzle.
##
## Music owns one looping player while short SFX use a tiny pool so a place,
## release and solve cue can overlap without cutting each other off.

const BGM_PATH := "res://assets/bgm/ガラス張りの三角錐.mp3"
const BGM_VOLUME_DB := -19.0
const SFX_VOLUME_DB := -11.0
const SFX_PATHS := {
	"ui": "res://assets/audio/kenney/ui_click.ogg",
	"release": "res://assets/audio/kenney/ui_release.ogg",
	"switch": "res://assets/audio/kenney/ui_switch.ogg",
	"place": "res://assets/audio/kenney/glass_light.ogg",
	"solve": "res://assets/audio/kenney/glass_medium.ogg",
	"drag": "res://assets/audio/kenney/metal_light.ogg"
}
const SFX_POOL_SIZE := 4

var muted := false
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _next_player := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_bgm_player()
	for _index in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.name = "SFX%02d" % _index
		player.volume_db = SFX_VOLUME_DB
		add_child(player)
		sfx_players.append(player)
	_apply_volume()


func _build_bgm_player() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGM"
	bgm_player.volume_db = BGM_VOLUME_DB
	var stream := load(BGM_PATH) as AudioStream
	if stream == null:
		push_warning("Could not load BGM: %s" % BGM_PATH)
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	bgm_player.stream = stream
	add_child(bgm_player)
	if not muted:
		bgm_player.play()


func set_muted(value: bool) -> void:
	muted = value
	_apply_volume()
	if not muted and bgm_player != null and bgm_player.stream != null and not bgm_player.playing:
		bgm_player.play()


func play_sfx(kind: String, volume_offset_db: float = 0.0) -> void:
	if muted or sfx_players.is_empty():
		return
	var stream := _stream_for(kind)
	if stream == null:
		return
	var player := sfx_players[_next_player % sfx_players.size()]
	_next_player = (_next_player + 1) % sfx_players.size()
	player.stream = stream
	player.volume_db = SFX_VOLUME_DB + volume_offset_db
	player.play()


func stop_all() -> void:
	if bgm_player != null:
		bgm_player.stop()
	for player in sfx_players:
		player.stop()


func _stream_for(kind: String) -> AudioStream:
	if _streams.has(kind):
		return _streams[kind] as AudioStream
	var path: String = String(SFX_PATHS.get(kind, ""))
	if path.is_empty():
		return null
	var stream := load(path) as AudioStream
	if stream != null:
		_streams[kind] = stream
	return stream


func _apply_volume() -> void:
	if bgm_player != null:
		bgm_player.volume_db = -80.0 if muted else BGM_VOLUME_DB
	for player in sfx_players:
		player.volume_db = -80.0 if muted else SFX_VOLUME_DB
