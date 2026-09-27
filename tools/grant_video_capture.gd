extends SceneTree
## Deterministic footage of the real game. Uses a separate user-data directory.

const Game = preload("res://src/experiment_main.gd")
const Settings = preload("res://src/nox_settings.gd")
const Locale = preload("res://src/nox_locale.gd")
const Optics = preload("res://src/experiment_optics.gd")

var game: Control
var frame: int = 0
var running: bool = false
var checks: Array = []
var output: String = "res://builds/grant-video"
var save_frames: bool = false

func _initialize() -> void:
	ProjectSettings.set_setting("application/config/use_custom_user_dir", true)
	ProjectSettings.set_setting("application/config/custom_user_dir_name", "NOXSUM_GrantVideoCapture")
	call_deferred("_start")

func _start() -> void:
	print("CAPTURE_PROFILE ", OS.get_user_data_dir())
	if not OS.get_user_data_dir().contains("NOXSUM_GrantVideoCapture"):
		push_error("Refusing to write settings outside isolated capture profile.")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(OS.get_user_data_dir())
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	var output_option: int = arguments.find("--output")
	if output_option >= 0 and output_option + 1 < arguments.size():
		output = arguments[output_option + 1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	save_frames = OS.get_cmdline_user_args().has("--frames")
	if save_frames:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.path_join("frames")))
	Settings.write_value("tutorial_seen", true)
	Settings.write_value("sound", true)
	Settings.write_value("bgm_volume", 0)
	Settings.write_value("se_volume", 60)
	Settings.write_value("reduced_motion", false)
	Locale.set_language("en")
	Settings.apply_audio()
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_size = Vector2i(720, 900)
	root.size = Vector2i(1440, 1800)
	game = Game.new()
	game.nox_campaign = true
	game.initial_stage_index = 0
	game.progress_path = "user://grant_video_capture_only.json"
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	game.completed.clear()
	running = true

func _process(_delta: float) -> bool:
	if not running:
		return false
	frame += 1
	if save_frames and frame <= 2879:
		_save_frame(frame - 1)
	match frame:
		60: _snapshot("gr01_start")
		120: _place("C3")
		126: _check_opacity("GR01 placement hold", "C3", 1.0)
		133:
			var opacity: float = game.sockets[Optics.cell("C3")].get_child(0).nox_opacity()
			_record_check("GR01 placement fade", opacity > 0.45 and opacity < 1.0)
		144: _check_opacity("GR01 settled trace", "C3", 0.45)
		220: _check("GR01", true)
		300: game.load_stage(1)
		360: _place("B2")
		420: _place("C3")
		510: _check("GR02", true)
		600: game.load_stage(2)
		690: _place("B4")
		750: _place("B5")
		810: _place("C5")
		900:
			_check("GR03 wrong: extra D5", false)
			var target: Dictionary = game.stage()["observations"][0]["target"]
			var mismatches: Array[String] = []
			for index: int in 25:
				var code: String = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
				if game.current_shadow[index] != int(target.get(code, 0)):
					mismatches.append(code)
			_record_check("GR03 wrong differs only at empty D5", mismatches == ["D5"] and int(target.get("D5", 0)) == 0 and game.current_shadow[Optics.cell("D5")] == 1)
			_snapshot("gr03_wrong")
		1080: _place("C5")
		1200: _place("A5")
		1320:
			_check("GR03 adopted B", true)
			_snapshot("gr03_solved")
		1440: game.load_stage(8)
		1560: _place("C3", "tall")
		1650: _check("GR09", true)
		1680: game.load_stage(10)
		1790: game.rotate_plate(Optics.cell("C3"))
		1860: _check("GR11", true)
		1920: game.load_stage(7)
		1980: _place("C2")
		2010: _place("D4")
		2130: game.move_shutter(2)
		2200: _check("GR08", true)
		2250: game.load_stage(23)
		2310: _place("B1")
		2370: _place("E2")
		2430: _place("C4")
		2490:
			_check("GR24", true)
			_snapshot("gr24_solved")
		2550: game.load_stage(35)
		2610: _place("A2")
		2640: _place("B4")
		2700: _place("C3", "tall")
		2730: _place("C2", "plate_h")
		2820:
			_check("GR36", true)
			_snapshot("gr36_solved")
		2880:
			var report: FileAccess = FileAccess.open(output.path_join("capture-checks.json"), FileAccess.WRITE)
			report.store_string(JSON.stringify(checks, "  "))
			print("CAPTURE_DONE ", checks)
			game.sound_player.stop()
			game.sound_player.stream = null
			var music: Node = root.get_node_or_null("BgmPlaylist")
			if music != null:
				music.music_player.stop()
				music.music_player.stream = null
			game.free()
			quit()
	return false

func _place(code: String, kind: String = "normal") -> void:
	game.selected_post_type = kind
	game.pose_chosen = true
	game.toggle_post(Optics.cell(code))
	print("ACTION ", frame, " ", game.stage()["id"], " ", code, " ", kind)

func _check(label: String, solved: bool) -> void:
	_record_check(label, game.stage_solved == solved)
	for index: int in game.posts:
		_check_opacity(label + " trace " + str(index), String.chr(65 + index % 5) + str(int(index / 5.0) + 1), 0.45)
	for slot: int in game.shutters:
		_record_check(label + " SLEEP remains opaque", is_equal_approx(game.rail_buttons[slot].get_child(0).nox_opacity(), 1.0))

func _check_opacity(label: String, code: String, expected: float) -> void:
	_record_check(label, is_equal_approx(game.sockets[Optics.cell(code)].get_child(0).nox_opacity(), expected))

func _record_check(label: String, passed: bool) -> void:
	checks.append({"frame": frame, "label": label, "passed": passed})
	print("CHECK ", label, " ", passed)
	if not passed:
		push_error("Unexpected game result: " + label)
		quit(3)

func _snapshot(label: String) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(label + ".png"))
	var layout: Dictionary = {}
	for code: String in ["A1", "D5", "A5", "C5", "C3"]:
		var index: int = Optics.cell(code)
		layout[code] = {"target": str(game.target_cells[index].get_global_rect()), "live": str(game.live_cells[index].get_global_rect()), "socket": str(game.sockets[index].get_global_rect())}
	var file: FileAccess = FileAccess.open(output.path_join(label + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(layout, "  "))

func _save_frame(number: int) -> void:
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_jpg(output.path_join("frames/%05d.jpg" % number), 0.98)
