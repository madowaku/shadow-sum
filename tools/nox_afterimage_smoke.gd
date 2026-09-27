extends SceneTree

const Game = preload("res://src/experiment_main.gd")
const Settings = preload("res://src/nox_settings.gd")
const Locale = preload("res://src/nox_locale.gd")
const SMOKE_SAVE: String = "user://nox_afterimage_smoke_only.json"
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func alpha(game: Control, index: int) -> float:
	return game.sockets[index].get_child(0).nox_opacity()

func press(game: Control, index: int, touch: bool = false) -> void:
	var source: Control = game.sockets[index] if index >= 0 else game.inventory
	if touch:
		var event: InputEventScreenTouch = InputEventScreenTouch.new()
		event.index = 0
		event.pressed = true
		event.position = source.size * 0.5
		game._start_pointer(event, "post", index)
	else:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = true
		event.position = source.size * 0.5
		game._start_pointer(event, "post", index)

func release(game: Control, point: Vector2, touch: bool = false) -> void:
	if touch:
		var event: InputEventScreenTouch = InputEventScreenTouch.new()
		event.index = 0
		event.position = point
		game._input(event)
	else:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		game._input(event)

func _run() -> void:
	var previous_motion: Variant = Settings.read_value("reduced_motion", false)
	var previous_tutorial: Variant = Settings.read_value("tutorial_seen", false)
	var previous_language: String = Locale.language()
	Settings.write_value("tutorial_seen", true)
	Settings.write_value("reduced_motion", false)
	Locale.set_language("en")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(360, 800)
	var game: Control = Game.new()
	game.nox_campaign = true
	game.initial_stage_index = 2
	game.progress_path = SMOKE_SAVE
	root.add_child(game)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await process_frame
	await process_frame
	# Advance presentation time explicitly to test the hold/fade boundaries.
	game.set_process(false)
	press(game, 7, true)
	release(game, game.sockets[7].get_global_rect().get_center(), true)
	check(game.posts.has(7) and is_equal_approx(alpha(game, 7), 1.0), "Touch placement must start opaque")
	check(game.live_cells[6].change_remaining > 0.0, "Placement must retain shadow feedback")
	game._update_nox_traces(0.24)
	check(is_equal_approx(alpha(game, 7), 1.0), "Placement must hold opaque for 0.25 seconds")
	game._update_nox_traces(0.21)
	check(is_equal_approx(alpha(game, 7), 0.725), "Placement must be halfway through its 0.40-second fade at 0.45 seconds")
	game._update_nox_traces(0.21)
	check(is_equal_approx(alpha(game, 7), 0.45), "Placed NOX must settle at 45%")
	check(is_equal_approx(game.inventory.get_child(0).nox_opacity(), 1.0), "Inventory must stay opaque")
	# Headless input owns the pointer; a rendered OS window can be outside the
	# real cursor or unfocused. Keep capture runs independent of the user's mouse.
	if DisplayServer.get_name() == "headless":
		var hover: InputEventMouseMotion = InputEventMouseMotion.new()
		hover.position = game.sockets[7].get_global_rect().get_center()
		hover.global_position = hover.position
		Input.parse_input_event(hover)
		await process_frame
		check(is_equal_approx(alpha(game, 7), 0.70), "Real pointer hover must reveal only its trace")
		hover = InputEventMouseMotion.new()
		hover.position = Vector2(1, 1)
		hover.global_position = hover.position
		Input.parse_input_event(hover)
		await process_frame
		check(is_equal_approx(alpha(game, 7), 0.45), "Hover exit must restore 45%")
	game.sockets[7].grab_focus()
	check(is_equal_approx(alpha(game, 7), 0.70), "Keyboard focus must reveal its trace")
	game.sockets[7].release_focus()
	press(game, 7, true)
	check(is_equal_approx(alpha(game, 7), 0.70), "Touch selection must reveal its trace")
	game._move_pointer(game.sockets[8].get_global_rect().get_center())
	check(game.drag_ghost.visible and is_equal_approx(game.drag_ghost.nox_opacity(), 1.0), "Re-dragged NOX must be opaque")
	check(is_equal_approx(game.sockets[7].modulate.a, 1.0), "Drag must not dim socket coordinates or multiply trace alpha")
	release(game, game.sockets[8].get_global_rect().get_center(), true)
	check(not game.posts.has(7) and game.posts.has(8) and is_equal_approx(alpha(game, 8), 1.0), "Re-drop must replay placement")
	game.undo_move()
	check(game.posts.has(7) and is_equal_approx(alpha(game, 7), 0.45), "Undo during fade must restore a settled trace")
	press(game, 7)
	release(game, Vector2(-100, -100))
	check(game.posts.has(7) and is_equal_approx(alpha(game, 7), 0.45), "Invalid drop must restore a settled trace")
	press(game, 7)
	release(game, game.inventory.get_global_rect().get_center())
	check(game.posts.is_empty() and game.inventory.get_child(0).occupied, "Drag return must remove the trace")
	check(is_equal_approx(game.inventory.get_child(0).nox_opacity(), 1.0), "Returned inventory must be opaque")
	game.undo_move()
	check(is_equal_approx(alpha(game, 7), 0.45), "Undo return must restore 45% without a placement flash")
	game.toggle_post(7)
	check(not game.sockets[7].get_child(0).occupied, "Remove must immediately hide the portrait")
	game.toggle_post(7)
	press(game, 7)
	game._move_pointer(game.sockets[8].get_global_rect().get_center())
	check(is_equal_approx(alpha(game, 7), 0.45), "Re-drag during placement must leave a settled origin trace")
	release(game, Vector2(-100, -100))
	game.load_stage(10)
	check(is_equal_approx(alpha(game, 12), 0.45), "Stage load must derive fixed WALK opacity without a flash")
	game.rotate_plate(12)
	check(game.sockets[12].get_child(0).post_type == "plate_h" and is_equal_approx(alpha(game, 12), 0.45), "WALK rotation must preserve pose data and trace opacity")
	game.load_stage(2)
	game.toggle_post(7)
	Settings.write_value("reduced_motion", true)
	game._update_nox_traces()
	check(is_equal_approx(alpha(game, 7), 0.45), "Enabling Reduced Motion must cancel an active fade")
	game.toggle_post(8)
	check(is_equal_approx(alpha(game, 8), 0.45), "Reduced Motion placement must settle immediately")
	game.undo_move()
	check(is_equal_approx(alpha(game, 7), 0.45), "Reduced Motion undo must derive alpha")
	game.load_stage(7)
	game.move_shutter(2)
	check(is_equal_approx(game.rail_buttons[2].get_child(0).nox_opacity(), 1.0), "SLEEP rail must remain opaque")
	Settings.write_value("reduced_motion", false)
	game.load_stage(0)
	game.toggle_post(12)
	game._update_nox_traces(0.7)
	game.sockets[12].grab_focus()
	check(game.stage_solved and is_equal_approx(alpha(game, 12), 0.45), "Solve must retain 45% even under focus")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SMOKE_SAVE))
	check(not JSON.stringify(saved).contains("opacity") and not JSON.stringify(saved).contains("nox_placement"), "Save must not persist presentation state")
	# Exercise actual frame timing as well as the deterministic boundaries above.
	game.set_process(true)
	game.load_stage(2)
	game.toggle_post(7)
	await create_timer(0.75).timeout
	check(is_equal_approx(alpha(game, 7), 0.45), "Live process must finish the placement fade")
	if not OS.get_environment("NOXSUM_CAPTURE_DIR").is_empty():
		await _capture_poses(game)
	game.queue_free()
	await process_frame
	var legacy: Control = Game.new()
	legacy.initial_stage_index = 0
	legacy.progress_path = SMOKE_SAVE
	root.add_child(legacy)
	await process_frame
	legacy.toggle_post(0)
	check(is_equal_approx(legacy.sockets[0].get_child(0).nox_opacity(), 1.0), "Legacy campaign must remain unchanged")
	legacy.queue_free()
	await process_frame
	Settings.write_value("tutorial_seen", previous_tutorial)
	Settings.write_value("reduced_motion", previous_motion)
	Locale.set_language(previous_language)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	var music: Node = root.get_node_or_null("BgmPlaylist")
	if music != null:
		music.music_player.stop()
		music.music_player.stream = null
	await create_timer(0.2).timeout
	print("NOXSUM_AFTERIMAGE_OK" if failures == 0 else "NOXSUM_AFTERIMAGE_FAILED %d" % failures)
	quit(0 if failures == 0 else 1)

func _capture_poses(game: Control) -> void:
	var directory: String = OS.get_environment("NOXSUM_CAPTURE_DIR")
	DirAccess.make_dir_recursive_absolute(directory)
	for viewport_size: Vector2i in [Vector2i(360, 800), Vector2i(720, 900)]:
		root.size = viewport_size
		for stage_number: int in [2, 7, 15, 18]:
			game.load_stage(stage_number)
			match stage_number:
				2:
					game.toggle_post(16)
					game.toggle_post(20)
					game.toggle_post(21)
				7:
					game.toggle_post(6)
					game.toggle_post(18)
				15:
					game.selected_post_type = "plate_v"
					game.toggle_post(6)
					game.selected_post_type = "plate_h"
					game.toggle_post(16)
				18:
					game.selected_post_type = "normal"
					game.toggle_post(11)
					game.selected_post_type = "tall"
					game.toggle_post(17)
					game.selected_post_type = "plate_h"
					game.toggle_post(12)
			await create_timer(1.3).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(directory.path_join("gr%02d-%d.png" % [stage_number + 1, viewport_size.x]))
