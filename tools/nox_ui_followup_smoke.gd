extends SceneTree

const Home = preload("res://src/nox_home.gd")
const Locale = preload("res://src/nox_locale.gd")
const Settings = preload("res://src/nox_settings.gd")
const SMOKE_SAVE: String = "user://nox_ui_followup_smoke.json"

var old_language: String = "en"
var old_sound: bool = false
var old_bgm: Variant = 100.0
var old_se: Variant = 100.0
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	old_language = Locale.language()
	old_sound = Settings.sound_enabled()
	old_bgm = Settings.read_value("bgm_volume", 100.0)
	old_se = Settings.read_value("se_volume", 100.0)
	capture_dir = OS.get_environment("NOXSUM_CAPTURE_DIR")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	Settings.write_value("sound", false)
	Settings.write_value("bgm_volume", 100.0)
	Settings.write_value("se_volume", 100.0)
	Settings.apply_audio()
	for viewport_size: Vector2i in [Vector2i(360, 800), Vector2i(405, 900)]:
		Settings.write_value("sound", false)
		Settings.apply_audio()
		root.size = viewport_size
		Locale.set_language("en")
		var home: Control = Home.new()
		root.add_child(home)
		await create_timer(0.7).timeout
		var sound: Button = home.find_child("SoundButton", true, false) as Button
		await _capture("home", viewport_size)
		if sound == null or sound.size.y < 44.0 or sound.get_global_rect().end.x > viewport_size.x or sound.text != "SOUND OFF":
			_fail("HOME sound button is missing or clipped")
			return
		sound.pressed.emit()
		await process_frame
		if not Settings.sound_enabled() or sound.text != "SOUND ON":
			_fail("HOME sound toggle did not enable audio")
			return
		home._open_settings()
		await process_frame
		var bgm: HSlider = home.find_child("BGMVolumeSlider", true, false) as HSlider
		var se: HSlider = home.find_child("SEVolumeSlider", true, false) as HSlider
		if bgm == null or se == null:
			_fail("BGM/SE volume sliders missing")
			return
		bgm.value = 35.0
		se.value = 60.0
		await process_frame
		var playlist: Node = root.get_node_or_null("BgmPlaylist")
		var player: AudioStreamPlayer = playlist.get("music_player") as AudioStreamPlayer
		if not is_equal_approx(Settings.bgm_volume(), 35.0) or not is_equal_approx(Settings.se_volume(), 60.0) or not is_equal_approx(player.volume_db, -19.0 + Settings.volume_offset_db(35.0)):
			_fail("independent volume settings did not persist or update BGM")
			return
		await _capture("settings", viewport_size)
		home._close_modal()
		home.queue_free()
		await process_frame
		var game: Control = (load("res://scenes/experiments.tscn") as PackedScene).instantiate()
		game.nox_campaign = true
		game.initial_stage_index = 0
		root.add_child(game)
		await process_frame
		game.stage_guide.hide()
		game.progress_path = SMOKE_SAVE
		var sit_badge: Label = game.inventory.find_child("CountText", true, false) as Label
		if sit_badge == null or sit_badge.text != "LEFT 1":
			_fail("GR01 SIT remaining count missing")
			return
		if not is_equal_approx(game.sound_player.volume_db, Settings.volume_offset_db(60.0)):
			_fail("SE volume was not applied to stage player")
			return
		await _capture("gr01", viewport_size)
		game.toggle_post(12)
		await create_timer(1.3).timeout
		if not game.stage_solved or not game.clear_continue.visible or game.next_button.disabled or sit_badge.text != "LEFT 0":
			_fail("clear CTA or remaining count did not update")
			return
		await _capture("gr01_clear", viewport_size)
		game.clear_continue.pressed.emit()
		await process_frame
		if game.stage_index != 1 or game.clear_continue.visible:
			_fail("clear CTA did not advance to next trace")
			return
		game.load_stage(31)
		await process_frame
		if not game.tall_inventory.visible or not game.plate_inventory.visible:
			_fail("mixed inventory missing")
			return
		await _capture("gr32_inventory", viewport_size)
		var mixed_count: Label = game.inventory.find_child("CountText", true, false) as Label
		game.toggle_post(0)
		await process_frame
		if mixed_count.text != "LEFT 0":
			_fail("mixed inventory count did not decrease after placing SIT")
			return
		game.undo_move()
		await process_frame
		if mixed_count.text != "LEFT 1":
			_fail("mixed inventory count did not recover after UNDO")
			return
		game.queue_free()
		await process_frame
	Settings.write_value("sound", old_sound)
	Settings.write_value("bgm_volume", old_bgm)
	Settings.write_value("se_volume", old_se)
	Settings.apply_audio()
	_stop_test_audio()
	Locale.set_language(old_language)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	print("NOXSUM_UI_FOLLOWUP_OK sound button, BGM/SE sliders, inventory counts, clear CTA at 360x800 and 405x900")
	quit()

func _capture(name: String, viewport_size: Vector2i) -> void:
	if capture_dir.is_empty():
		return
	var directory: String = capture_dir.path_join("%dx%d" % [viewport_size.x, viewport_size.y])
	DirAccess.make_dir_recursive_absolute(directory)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name + ".png"))

func _stop_test_audio() -> void:
	var playlist: Node = root.get_node_or_null("BgmPlaylist")
	if playlist == null:
		return
	playlist.call("set_enabled", false)
	var player: AudioStreamPlayer = playlist.get("music_player") as AudioStreamPlayer
	if player != null:
		player.stop()
		player.stream = null

func _fail(message: String) -> void:
	Settings.write_value("sound", old_sound)
	Settings.write_value("bgm_volume", old_bgm)
	Settings.write_value("se_volume", old_se)
	Settings.apply_audio()
	_stop_test_audio()
	Locale.set_language(old_language)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	push_error(message)
	quit(1)
