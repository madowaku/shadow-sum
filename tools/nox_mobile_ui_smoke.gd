extends SceneTree

const Home = preload("res://src/nox_home.gd")
const L = preload("res://src/nox_locale.gd")
const Settings = preload("res://src/nox_settings.gd")
const SMOKE_SAVE: String = "user://nox_mobile_ui_smoke_only.json"
const STAGES: Array[int] = [0, 27, 28, 35]
var original_language: String = "en"
var original_motion: Variant = false
var capture_dir: String = ""

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	original_language = L.language()
	original_motion = Settings.read_value("reduced_motion", false)
	capture_dir = OS.get_environment("NOXSUM_CAPTURE_DIR")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	for viewport_size: Vector2i in [Vector2i(360, 800), Vector2i(405, 900), Vector2i(720, 900)]:
		root.size = viewport_size
		L.set_language("ja")
		var home: Control = Home.new()
		root.add_child(home)
		await process_frame
		await create_timer(0.7).timeout
		if not _inside(home.find_child("PlayButton", true, false) as Control, viewport_size):
			_fail("HOME play outside " + str(viewport_size))
			return
		for control_name: String in ["LanguageButton", "SettingsButton", "AboutButton", "HowToPlayButton", "GalleryButton"]:
			var control: Control = home.find_child(control_name, true, false) as Control
			if not _inside(control, viewport_size) or control.size.y < 44.0:
				_fail("HOME target " + control_name + " outside/too small at " + str(viewport_size))
				return
		await _capture("home", viewport_size)
		home.queue_free()
		await process_frame
		var game: Control = (load("res://scenes/experiments.tscn") as PackedScene).instantiate()
		game.nox_campaign = true
		game.initial_stage_index = 0
		root.add_child(game)
		await process_frame
		await process_frame
		game.stage_guide.hide()
		for stage_index: int in STAGES:
			game.load_stage(stage_index)
			await process_frame
			if not _check_stage(game, viewport_size, stage_index):
				return
			await _capture("gr%02d" % (stage_index + 1), viewport_size)
			if stage_index == 0 and viewport_size.x <= 480:
				game.hint_button.pressed.emit()
				await process_frame
				if game.hint_level != 1 or not (game.find_child("NightLogOverlay", true, false) as Control).visible:
					_fail("OBSERVE did not open the first clue")
					return
				game.toggle_language()
				await process_frame
				if game.hint_level != 1 or not (game.find_child("NightLogOverlay", true, false) as Control).visible:
					_fail("language switch lost the open clue")
					return
				game.toggle_language()
				await process_frame
				var sheet: Control = game.find_child("NightLogSheet", true, false) as Control
				if not _inside(sheet, viewport_size):
					_fail("Night Log sheet outside " + str(viewport_size))
					return
				await _capture("gr01_night_log_open", viewport_size)
				(game.find_child("NightLogClose", true, false) as Button).pressed.emit()
				await process_frame
		game.progress_path = SMOKE_SAVE
		Settings.write_value("reduced_motion", false)
		game.load_stage(0)
		game.toggle_post(12)
		await create_timer(1.4).timeout
		if not game.stage_solved or not _inside(game.find_child("ActionBar", true, false) as Control, viewport_size):
			_fail("solve animation pushed controls outside " + str(viewport_size))
			return
		Settings.write_value("reduced_motion", true)
		game.load_stage(0)
		await process_frame
		var board_rect: Rect2 = (game.find_child("WhereWasNox", true, false) as Control).get_global_rect()
		game.toggle_post(12)
		await process_frame
		if not game.stage_solved or (game.find_child("WhereWasNox", true, false) as Control).get_global_rect() != board_rect:
			_fail("reduced-motion solve changed the board layout at " + str(viewport_size))
			return
		Settings.write_value("reduced_motion", original_motion)
		game.load_stage(31)
		await process_frame
		if not game.inventory.visible or not game.tall_inventory.visible or not game.plate_inventory.visible:
			_fail("GR32 pose types missing")
			return
		for language_code: String in ["en", "ja"]:
			L.set_language(language_code)
			game.sync_stage_language(language_code)
			for index: int in 36:
				game.load_stage(index)
				await process_frame
				if not _check_stage(game, viewport_size, index):
					return
				if viewport_size.x <= 480:
					for clue_index: int in 3:
						game.whisper()
						await process_frame
						var trigger: Button = game.find_child("NightLogTrigger", true, false) as Button
						trigger.pressed.emit()
						await process_frame
						if not _inside(game.find_child("NightLogSheet", true, false) as Control, viewport_size):
							_fail("GR%02d clue %d sheet outside %s" % [index + 1, clue_index + 1, str(viewport_size)])
							return
						(game.find_child("NightLogClose", true, false) as Button).pressed.emit()
						await process_frame
		game.queue_free()
		await process_frame
	L.set_language(original_language)
	Settings.write_value("reduced_motion", original_motion)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	print("NOXSUM_MOBILE_UI_OK HOME, GR01/28/29/36, Night Log, GR32, JP/EN at 360x800, 405x900, 720x900")
	quit()

func _check_stage(game: Control, viewport_size: Vector2i, stage_index: int) -> bool:
	var core: Array[Control] = [
		game.find_child("HomeButton", true, false) as Control,
		game.find_child("LanguageButton", true, false) as Control,
		game.stage_picker,
		game.title_label,
		game.find_child("RecordedPlate", true, false) as Control,
		game.find_child("ReconstructionPlate", true, false) as Control,
		game.find_child("WhereWasNox", true, false) as Control,
		game.find_child("ActionBar", true, false) as Control
	]
	for node: Control in core:
		if not _inside(node, viewport_size):
			_fail("GR%02d core outside %s: %s %s" % [stage_index + 1, str(viewport_size), str(node.name) if node != null else "null", str(node.get_global_rect()) if node != null else ""])
			return false
	for button: Button in game.sockets:
		if not _inside(button, viewport_size) or button.size.x < 40.0 or button.size.y < 40.0:
			_fail("GR%02d socket outside/too small at %s: %s" % [stage_index + 1, str(viewport_size), button.name])
			return false
	for button: Button in [game.inventory, game.tall_inventory, game.plate_inventory, game.back_button, game.undo_button, game.hint_button, game.next_button]:
		if button.visible and (not _inside(button, viewport_size) or button.size.y < 44.0 or button.size.x < 44.0):
			_fail("GR%02d control outside/too small at %s: %s %s" % [stage_index + 1, str(viewport_size), button.name, str(button.get_global_rect())])
			return false
	for direction: String in game.lamps:
		var lamp: Button = game.lamps[direction] as Button
		if lamp.visible and lamp.modulate.a > 0.1 and (not _inside(lamp, viewport_size) or (viewport_size.x <= 480 and (lamp.size.x < 44.0 or lamp.size.y < 44.0))):
			_fail("GR%02d light outside %s: %s" % [stage_index + 1, str(viewport_size), direction])
			return false
	if viewport_size.x <= 480:
		if game.rail.get_parent().visible:
			for rail_button: Button in game.rail_buttons:
				if not _inside(rail_button, viewport_size) or rail_button.size.x < 44.0 or rail_button.size.y < 44.0:
					_fail("GR%02d rail target outside/too small" % (stage_index + 1))
					return false
		var trigger: Button = game.find_child("NightLogTrigger", true, false) as Button
		var overlay: Control = game.find_child("NightLogOverlay", true, false) as Control
		if not trigger.visible or overlay.visible or not _inside(trigger, viewport_size):
			_fail("GR%02d Night Log collapsed state invalid" % (stage_index + 1))
			return false
		if game.find_child("NightLog", true, false).get_parent().name != "NightLogHost":
			_fail("GR%02d Night Log still occupies main column" % (stage_index + 1))
			return false
	if stage_index == 28 and game.target_cells.filter(func(cell: Control) -> bool: return cell.unknown).is_empty():
		_fail("GR29 FOG missing")
		return false
	if stage_index == 35:
		var missing_count: int = 0
		for button: Button in game.sockets:
			if button.get_child(0).kind == "socket_missing":
				missing_count += 1
				if not button.disabled or button.mouse_filter != Control.MOUSE_FILTER_IGNORE:
					_fail("GR36 missing socket is interactive")
					return false
		if missing_count == 0:
			_fail("GR36 board shape missing")
			return false
	var font: Font = game.title_label.get_theme_font("font")
	var title_width: float = font.get_string_size(game.title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, game.title_label.get_theme_font_size("font_size")).x
	if title_width > game.title_label.size.x + 1.0:
		_fail("GR%02d title clips at %s: %.1f > %.1f" % [stage_index + 1, str(viewport_size), title_width, game.title_label.size.x])
		return false
	for label: Label in [game.observation_label, game.find_child("BoardCaption", true, false) as Label]:
		var label_font: Font = label.get_theme_font("font")
		var line_width: float = label_font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
		if label.visible and line_width > label.size.x + 1.0:
			_fail("GR%02d %s clips at %s: %.1f > %.1f" % [stage_index + 1, label.name, str(viewport_size), line_width, label.size.x])
			return false
	return true

func _inside(node: Control, viewport_size: Vector2i) -> bool:
	if node == null:
		return false
	var rect: Rect2 = node.get_global_rect()
	return rect.size.x > 0.0 and rect.size.y > 0.0 and rect.position.x >= -1.0 and rect.position.y >= -1.0 and rect.end.x <= float(viewport_size.x) + 1.0 and rect.end.y <= float(viewport_size.y) + 1.0

func _capture(name: String, viewport_size: Vector2i) -> void:
	if capture_dir.is_empty():
		return
	var directory: String = capture_dir.path_join("%dx%d" % [viewport_size.x, viewport_size.y])
	DirAccess.make_dir_recursive_absolute(directory)
	await create_timer(0.75).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name + ".png"))

func _fail(message: String) -> void:
	L.set_language(original_language)
	Settings.write_value("reduced_motion", original_motion)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	push_error(message)
	quit(1)
