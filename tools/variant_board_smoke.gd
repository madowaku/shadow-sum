extends SceneTree

const Shape = preload("res://src/board_shape.gd")
const Rules = preload("res://src/shadow_rules.gd")
const DATA: String = "res://data/variant_boards_v0_1.json"
const SAVE: String = "user://variant_board_smoke.json"
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("Variant board: " + message)

func _cleanup() -> void:
	for path: String in [SAVE, SAVE + ".session.json", SAVE + ".session.json.tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func _new_game(dimensions: Vector2i) -> Control:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var game: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	game.stage_path = DATA
	game.progress_path = SAVE
	viewport.add_child(game)
	for frame: int in 4:
		await process_frame
	return game

func _capture(game: Control, label: String) -> void:
	var directory: String = OS.get_environment("SHADOW_SUM_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(directory)
	await create_timer(0.2).timeout
	await RenderingServer.frame_post_draw
	var viewport: SubViewport = game.get_parent()
	check(viewport.get_texture().get_image().save_png(directory.path_join(label + ".png")) == OK, "capture " + label)

func _dispose(game: Control) -> void:
	await create_timer(0.15).timeout
	game.get_parent().queue_free()
	await process_frame

func _run() -> void:
	_cleanup()
	var data: Array = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var shape: RefCounted = Shape.new()
	check(shape.load_stage({}) and shape.get_enabled_socket_count() == 25, "default full board")
	check(shape.load_stage(data[0]) and shape.get_enabled_socket_count() == 9, "CROSS socket count")
	for cell: Vector2i in [Vector2i(-1, 0), Vector2i(0, -1), Vector2i(5, 0), Vector2i(0, 5)]:
		check(not shape.is_socket_enabled(cell.y, cell.x), "bounds")
	var malformed: Array = [null, [], {}, {"type": "wall"}, {"type": "mask", "width": 5, "height": 5, "mask": ["00000", "00000", "00000", "00000", "00000"]}]
	for change: Array in [["width", 4], ["width", "5"], ["width", true], ["height", 6], ["mask", null], ["mask", ["11111"]], ["mask", ["1111", "11111", "11111", "11111", "11111"]], ["mask", ["11x11", "11111", "11111", "11111", "11111"]], ["mask", [11111, 11111, 11111, 11111, 11111]]]:
		var bad_shape: Dictionary = data[0]["boardShape"].duplicate(true)
		bad_shape[change[0]] = change[1]
		malformed.append(bad_shape)
	var excessive: Dictionary = data[0].duplicate(true)
	excessive["posts"] = 10
	check(not shape.load_stage(excessive, false), "too many Posts for sockets")
	for invalid: Variant in malformed:
		var bad: Dictionary = {"posts": 3, "boardShape": invalid}
		check(not Shape.validation_error(bad).is_empty(), "malformed diagnostic")
		check(not shape.load_stage(bad, false) and shape.get_enabled_socket_count() == 25, "malformed fallback")
	for stage: Dictionary in data:
		shape.load_stage(stage)
		var original: Array = Rules.make_empty_posts()
		for code: String in stage["solution"]:
			original[int(code.substr(1)) - 1][code.unicode_at(0) - 65] = true
		check(Rules.compute_shadow(original) == Rules.compute_shadow(shape.filter_posts(original)), "shadow math unchanged by shape " + stage["title"])
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		_cleanup()
		var game: Control = await _new_game(dimensions)
		check(game.board_shape.get_enabled_socket_count() == 9, "mask loaded before UI")
		var reference_rects: Array[Rect2] = []
		for button: Button in game.post_buttons:
			reference_rects.append(button.get_global_rect())
		for index: int in 25:
			var button: Button = game.post_buttons[index]
			var enabled: bool = game.is_socket_enabled(int(index / 5.0), index % 5)
			check(button.get_node("SocketVisual").visible == enabled, "socket visibility")
			check(not button.get_node("PostVisual").visible, "empty Post remains hidden")
			check(button.disabled == not enabled, "socket disabled state")
			check(Rect2(Vector2.ZERO, Vector2(dimensions)).encloses(button.get_global_rect()), "socket on screen")
			check(button.size.x > 0 and button.size.y > 0, "socket nonzero size")
			for other: int in index:
				check(not button.get_global_rect().intersects(game.post_buttons[other].get_global_rect()), "sockets do not overlap")
			if not enabled:
				check(button.mouse_filter == Control.MOUSE_FILTER_IGNORE and button.focus_mode == Control.FOCUS_NONE and button.tooltip_text.is_empty(), "inert disabled plate")
				game._set_socket_active(index, true)
				check(not game.socket_visuals[index].active, "no disabled hover")
		# Mouse/touch events hit the same inert plate before any placement.
		var silent_children: int = game.get_child_count()
		for pressed: bool in [true, false]:
			var mouse: InputEventMouseButton = InputEventMouseButton.new()
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.position = game._post_center(0)
			mouse.pressed = pressed
			game.get_viewport().push_input(mouse)
			var touch: InputEventScreenTouch = InputEventScreenTouch.new()
			touch.position = game._post_center(0)
			touch.pressed = pressed
			game.get_viewport().push_input(touch)
		check(game.get_child_count() == silent_children, "disabled inputs produce no audio nodes")
		game._toggle_post(0, 0)
		game._toggle_post(-1, 0)
		game.post_buttons[0].pressed.emit()
		check(Rules.count_posts(game.posts) == 0 and game.undo_history.is_empty(), "disabled/debug/bounds placement rejected")
		game.post_buttons[2].grab_focus()
		var accept: InputEventKey = InputEventKey.new()
		accept.keycode = KEY_SPACE
		accept.pressed = true
		game.get_viewport().push_input(accept)
		accept = accept.duplicate()
		accept.pressed = false
		game.get_viewport().push_input(accept)
		await process_frame
		check(game.posts[0][2], "keyboard enabled placement")
		# Touch drag starts at C1, previews E3, then releases over unmachined D1.
		var touch_down: InputEventScreenTouch = InputEventScreenTouch.new()
		touch_down.position = game._post_center(2)
		touch_down.pressed = true
		game.get_viewport().push_input(touch_down)
		var touch_move: InputEventScreenDrag = InputEventScreenDrag.new()
		touch_move.position = game._post_center(14)
		game.get_viewport().push_input(touch_move)
		game.get_viewport().push_input(touch_move)
		check(game.drag_active and game.drag_target_index == 14, "touch valid preview")
		touch_move = touch_move.duplicate()
		touch_move.position = game._post_center(3)
		game.get_viewport().push_input(touch_move)
		check(game.drag_target_index == -1 and game._drag_target_at(game._post_center(3)) == -1, "touch disabled plate clears magnetic preview")
		var touch_up: InputEventScreenTouch = touch_down.duplicate()
		touch_up.position = touch_move.position
		touch_up.pressed = false
		game.get_viewport().push_input(touch_up)
		check(not game.drag_active and game.posts[0][2] and not game.posts[2][4], "touch invalid drop restores source")
		check(game._begin_post_drag(2), "begin drag")
		check(game._set_drag_target(12), "enabled preview")
		game._pointer_move(game._post_center(0))
		check(game.drag_target_index == -1 and game.snapped_pointer_index == -1, "disabled clears preview")
		check(not game._is_valid_drag_target(0), "disabled drop rejected")
		game._pointer_up(game._post_center(0))
		check(game.posts[0][2] and Rules.count_posts(game.posts) == 1 and not game.drag_active, "invalid drop returns to source")
		game._begin_post_drag(2)
		game._set_drag_target(12)
		check(game._finish_post_drag(12) and game.posts[2][2], "valid drag commits")
		game._undo_move()
		check(game.posts[0][2] and not game.posts[2][2], "undo drag")
		game._reset_stage()
		check(Rules.count_posts(game.posts) == 0, "reset")
		game._undo_move()
		check(game.posts[0][2], "undo reset")
		# Exercise the actual saved-session parser, retaining the valid coordinate.
		game._save_session()
		var payload: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE + ".session.json"))
		check(not payload.has("boardShape"), "mask not persisted")
		payload["posts"][0][0] = true
		var file: FileAccess = FileAccess.open(SAVE + ".session.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(payload))
		file.close()
		game._restore_session()
		check(game.posts[0][2] and not game.posts[0][0] and Rules.count_posts(game.posts) == 1, "invalid restored Post filtered")
		game._save_session()
		await _dispose(game)
		game = await _new_game(dimensions)
		check(game.board_shape.get_enabled_socket_count() == 9 and game.posts[0][2] and Rules.count_posts(game.posts) == 1, "restart applies shape before restoring valid Post")
		game._reset_stage()
		await _capture(game, "cross_%d" % dimensions.x)
		# Every authored solution goes through live placement, clear and animation.
		for stage_index: int in data.size():
			game._load_stage(stage_index)
			check(game.clue_cells.size() == 25 and game.live_cells.size() == 25, "screens stay 5x5")
			for index: int in 25:
				check(game.post_buttons[index].get_global_rect() == reference_rects[index], "board spacing and frame unchanged")
			for code: String in data[stage_index]["solution"]:
				game._toggle_post(int(code.substr(1)) - 1, code.unicode_at(0) - 65)
			check(game.stage_solved, "authored solution clears " + data[stage_index]["title"])
			await create_timer(0.55).timeout
			check(not game.next_button.disabled, "clear animation releases NEXT")
			check(game.completed_stage_ids.has(stage_index + 1), "clear persisted")
			if data[stage_index]["title"] == "HOLLOW":
				check(not game.is_socket_enabled(1, 2), "HOLLOW interior disabled")
				check(Rules.compute_shadow(game.posts)[1][2] == 1, "HOLLOW interior receives shadow")
				check(game.live_glass_visuals[7].display_level == 1.0, "HOLLOW interior shadow rendered")
			if data[stage_index]["title"] in ["HOLLOW", "BRIDGE"]:
				await _capture(game, "%s_%d" % [data[stage_index]["title"].to_lower(), dimensions.x])
		# Compare full-board and masked shadows, including the socket-free interior.
		var full_stages: Array = JSON.parse_string(FileAccess.get_file_as_string(game.STAGE_PATH))
		game.stages = full_stages
		game._load_stage(1)
		check(game.board_shape.get_enabled_socket_count() == 25, "variant to NORMAL resets mask")
		for index: int in 25:
			check(game.post_buttons[index].get_node("SocketVisual").visible, "NORMAL socket restored")
			check(game.post_buttons[index].focus_mode == Control.FOCUS_ALL, "NORMAL focus restored")
		await _capture(game, "normal_%d" % dimensions.x)
		await _dispose(game)
	_cleanup()
	print("Variant board smoke: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
