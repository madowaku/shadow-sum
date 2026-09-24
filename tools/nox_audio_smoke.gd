extends SceneTree

const Settings = preload("res://src/nox_settings.gd")

var original_sound: bool = false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	original_sound = Settings.sound_enabled()
	var playlist: Node = root.get_node_or_null("BgmPlaylist")
	if playlist == null:
		_fail("BgmPlaylist autoload missing")
		return
	var player: AudioStreamPlayer = playlist.get("music_player") as AudioStreamPlayer
	Settings.write_value("sound", false)
	Settings.apply_audio()
	await process_frame
	if player.playing or int(playlist.get("current_track_index")) != -1:
		_fail("BGM must be stopped while sound is OFF")
		return
	Settings.write_value("sound", true)
	Settings.apply_audio()
	await process_frame
	for index: int in 4:
		if int(playlist.get("current_track_index")) != index or not player.playing or player.stream == null:
			_fail("track %d did not start after sound was enabled" % (index + 1))
			return
		if index < 3:
			player.finished.emit()
			await process_frame
	Settings.write_value("sound", false)
	Settings.apply_audio()
	await process_frame
	if player.playing or int(playlist.get("current_track_index")) != -1:
		_fail("BGM did not stop when sound was turned OFF")
		return
	Settings.write_value("sound", original_sound)
	Settings.apply_audio()
	playlist.call("set_enabled", false)
	print("NOXSUM_AUDIO_OK OFF by default fallback, ON starts all four tracks in order, OFF stops playback")
	quit()

func _fail(message: String) -> void:
	Settings.write_value("sound", original_sound)
	Settings.apply_audio()
	push_error(message)
	quit(1)
