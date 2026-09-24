extends SceneTree

const GameScript = preload("res://src/experiment_main.gd")
const Optics = preload("res://src/experiment_optics.gd")
const Settings = preload("res://src/nox_settings.gd")
const Locale = preload("res://src/nox_locale.gd")
const SAVE: String = "user://nox_ux_smoke.json"

var previous_tutorial: Variant
var previous_motion: Variant
var previous_language: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	previous_tutorial = Settings.read_value("tutorial_seen", false)
	previous_motion = Settings.read_value("reduced_motion", false)
	previous_language = Locale.language()
	Settings.write_value("tutorial_seen", true)
	Settings.write_value("reduced_motion", false)
	Locale.set_language("en")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var width: int = int(OS.get_environment("NOXSUM_WIDTH")) if not OS.get_environment("NOXSUM_WIDTH").is_empty() else 405
	root.size = Vector2i(width, 900)
	var game: Control = GameScript.new()
	game.nox_campaign = true
	game.progress_path = SAVE
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	if game.stage_guide == null or game.finale_overlay == null:
		_fail("guide or finale missing")
		return
	if not game.observation_label.text.contains("①"):
		_fail("first step guidance missing")
		return
	var guide_button: Button = game.find_child("StageGuideButton", true, false) as Button
	if guide_button == null:
		_fail("stage help button missing")
		return
	guide_button.pressed.emit()
	await process_frame
	if not game.stage_guide.visible:
		_fail("help button did not open guide")
		return
	game.stage_guide.dismiss()
	await process_frame
	var inventory_press: InputEventMouseButton = InputEventMouseButton.new()
	inventory_press.button_index = MOUSE_BUTTON_LEFT
	inventory_press.pressed = true
	inventory_press.position = game.inventory.size * 0.5
	var inventory_release: InputEventMouseButton = InputEventMouseButton.new()
	inventory_release.button_index = MOUSE_BUTTON_LEFT
	inventory_release.pressed = false
	inventory_release.position = game.inventory.get_global_rect().get_center()
	game._start_pointer(inventory_press, "post", -1)
	game._input(inventory_release)
	if not game.pose_chosen or not game.observation_label.text.contains("②"):
		_fail("selecting a pose did not advance the guidance")
		return
	game.toggle_post(12)
	await create_timer(1.4).timeout
	if not game.stage_solved or not game.status_label.text.contains("TRACE MATCHED"):
		_fail("first puzzle feedback missing")
		return
	if game.next_button.disabled:
		_fail("next button not enabled after solve")
		return
	game.completed.clear()
	game.load_stage(35)
	await process_frame
	var finale_data: Dictionary = game.stage()
	if not game.title_label.text.contains("THE SHAPED FINALE") or game.stage().get("free_light_selection", false) or game.stage().get("movable_shutter", false):
		_fail("Trace 36 must be THE SHAPED FINALE with fixed light and shutter rules")
		return
	if game.lights.size() != 4 or not game.lights.has("TOP") or not game.lights.has("LEFT") or not game.lights.has("RIGHT") or not game.lights.has("BOTTOM"):
		_fail("Trace 36 must keep all four fixed light directions active")
		return
	var fixed_light_snapshot: Array = game.lights.duplicate()
	for direction: String in ["TOP", "LEFT", "RIGHT", "BOTTOM"]:
		if not finale_data.get("installed_lights", []).has(direction) or not game.lamps[direction].disabled:
			_fail("Trace 36 light sources must stay installed and fixed")
			return
	game.tap_light("BOTTOM")
	if game.lights != fixed_light_snapshot:
		_fail("Trace 36 allowed a fixed light source to change")
		return
	var missing_socket_count: int = 0
	var empty_world: Array = game.posts.duplicate()
	var finale_mask: PackedByteArray = Optics.board_shape_mask(finale_data)
	for index: int in 25:
		if finale_mask[index] == 0:
			missing_socket_count += 1
			if game._socket_enabled(index) or not game.sockets[index].disabled or game.sockets[index].mouse_filter != Control.MOUSE_FILTER_IGNORE or game.sockets[index].get_child(0).kind != "socket_missing":
				_fail("Trace 36 rendered or enabled a missing board socket")
				return
			game.toggle_post(index)
			if game.posts != empty_world or game._drop_destination(game.sockets[index].get_global_rect().get_center()) != -1:
				_fail("Trace 36 accepted a placement on a missing socket")
				return
	if missing_socket_count == 0 or not game.status_label.text.contains("overlap"):
		_fail("Trace 36 must present a shaped board and deep-reading prompt")
		return
	_solve_final(game)
	await create_timer(1.7).timeout
	if not game.stage_solved or game.finale_overlay.visible:
		_fail("finale should wait until all 36 records are complete")
		return
	game.completed.clear()
	for index: int in 35:
		game.completed["GR%02d" % (index + 1)] = true
	game.load_stage(35)
	_solve_final(game)
	await create_timer(1.8).timeout
	if not game.stage_solved or game.completed.size() != 36 or not game.finale_overlay.visible:
		_fail("36th completion did not present the finale")
		return
	var finale_card: Control = game.finale_overlay.find_child("FinaleCard", true, false) as Control
	if finale_card == null or finale_card.get_global_rect().position.y < 0.0 or finale_card.get_global_rect().end.y > float(root.size.y):
		_fail("finale card outside viewport")
		return
	var finale_actions: Control = game.finale_overlay.find_child("FinaleActions", true, false) as Control
	for action: Node in finale_actions.get_children():
		if (action as Control).get_global_rect().end.x > finale_card.get_global_rect().end.x:
			_fail("finale action outside card")
			return
	game.finale_overlay.set_language("ja")
	if Locale.language() != "ja":
		_fail("finale language switch did not persist")
		return
	game.finale_overlay.dismiss()
	Settings.write_value("reduced_motion", true)
	game.completed.clear()
	game.load_stage(0)
	game.toggle_post(12)
	if not game.stage_solved or game.clear_seal.visible or game.status_label.text.is_empty():
		_fail("reduced motion solve feedback missing or animated")
		return
	var bottom_checks: int = 0
	for index: int in 36:
		game.load_stage(index)
		await process_frame
		if game.stage().get("free_light_selection", false) and game.stage().get("installed_lights", []).has("BOTTOM"):
			var before: bool = game.lights.has("BOTTOM")
			if not before and game.stage().has("active_light_count") and game.lights.size() >= int(game.stage()["active_light_count"]):
				for direction: String in game.lights.duplicate():
					if direction != "BOTTOM":
						game.tap_light(direction)
						break
			if game.lamps["BOTTOM"].disabled:
				_fail("bottom light disabled on trace %02d" % (index + 1))
				return
			game.tap_light("BOTTOM")
			if game.lights.has("BOTTOM") == before:
				_fail("bottom light failed to toggle on trace %02d" % (index + 1))
				return
			bottom_checks += 1
		if game.next_button.get_global_rect().end.y > float(root.size.y) + 1.0:
			_fail("footer outside viewport on trace %02d: %s" % [index + 1, str(game.next_button.get_global_rect())])
			return
	if bottom_checks < 10:
		_fail("expected bottom-light checks across the campaign")
		return
	var replacement_solves: int = 0
	for index: int in [23, 24, 27, 28, 31, 33, 34, 35]:
		game.completed.clear()
		game.load_stage(index)
		_solve_final(game)
		if not game.stage_solved:
			_fail("final v0.5 replacement did not solve at GR%02d" % (index + 1))
			return
		replacement_solves += 1
	print("NOX_UX_OK guide, progressive guidance, first solve, final gate, finale, language, reduced motion, %d bottom-light traces, %d final replacements, 36 layouts at %d" % [bottom_checks, replacement_solves, width])
	await _cleanup(game)

func _solve_final(game: Control) -> void:
	var entry: Dictionary = game.stage()
	game.posts.clear()
	game.post_types.clear()
	for code: String in entry["solution"]:
		var cell: int = Optics.cell(code)
		game.posts.append(cell)
		game.post_types[str(cell)] = str(entry["solution_post_types"].get(code, "normal"))
	game.lights = entry.get("solution_lights", entry["observations"][0]["active_lights"]).duplicate()
	game.shutters = entry.get("fixed_shutters", []).duplicate()
	if entry.get("movable_shutter", false):
		game.shutters = [int(entry["solution_shutter"])]
	game._refresh(false)

func _stop_audio_players() -> void:
	for node: Node in root.find_children("*", "AudioStreamPlayer", true, false):
		var player: AudioStreamPlayer = node as AudioStreamPlayer
		player.stop()
		player.stream = null

func _cleanup(game: Control) -> void:
	await create_timer(0.18).timeout
	_stop_audio_players()
	game.queue_free()
	await process_frame
	Settings.write_value("tutorial_seen", previous_tutorial)
	Settings.write_value("reduced_motion", previous_motion)
	Locale.set_language(previous_language)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	quit()

func _fail(message: String) -> void:
	push_error(message)
	_stop_audio_players()
	Settings.write_value("tutorial_seen", previous_tutorial)
	Settings.write_value("reduced_motion", previous_motion)
	Locale.set_language(previous_language)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	quit(1)
