extends Control

const Experiment: GDScript = preload("res://src/experiment_main.gd")
const Campaign: GDScript = preload("res://src/campaign_main.gd")
const Optics: GDScript = preload("res://src/experiment_optics.gd")
const P0_RESULT: String = "user://grant36_v05_smoke_result.json"
const SMOKE_SAVE: String = "user://grant36_v05_smoke_only.json"
const BONUS_SMOKE_SAVE: String = "user://grant36_v05_bonus_smoke_only.json"

var failures: int = 0
var failure_labels: Array[String] = []
var game: Control

func _ready() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures += 1
		failure_labels.append(label)
		push_error("GRANT36 v0.5 smoke: " + label)

func _press(point: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = true
	get_tree().root.push_input(event)

func _release(point: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = false
	get_tree().root.push_input(event)

func _tap(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	_press(point)
	_release(point)
	await get_tree().process_frame

func _drag(source: Control, destination: Control) -> void:
	_press(source.get_global_rect().get_center())
	await get_tree().process_frame
	var move: InputEventMouseMotion = InputEventMouseMotion.new()
	move.position = destination.get_global_rect().get_center()
	move.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_tree().root.push_input(move)
	await get_tree().process_frame
	_release(move.position)
	await get_tree().process_frame

func _code_to_index(cell_code: String) -> int:
	return Optics.cell(cell_code)

func _stage_index(id: String) -> int:
	for index: int in game.stages.size():
		if game.stages[index]["id"] == id:
			return index
	return -1

func _select_inventory(kind: String) -> void:
	if kind == "normal":
		await _tap(game.inventory)
	elif kind == "tall":
		await _tap(game.tall_inventory)
	elif kind == "plate_v" or kind == "plate_h":
		await _tap(game.plate_inventory)

func _place_mouse(kind: String, cell_code: String) -> void:
	await _select_inventory(kind)
	var socket: Button = game.sockets[_code_to_index(cell_code)]
	await _tap(socket)
	if kind == "plate_h":
		await _tap(socket)

func _solve_replacement(stage_id: String) -> void:
	var index: int = _stage_index(stage_id)
	_check(index >= 0, stage_id + " is present in campaign")
	if index < 0:
		return
	game.load_stage(index)
	await get_tree().process_frame
	await get_tree().process_frame
	var stage_data: Dictionary = game.stage()
	var types: Dictionary = stage_data["solution_post_types"]
	for cell_code: String in stage_data["solution"]:
		await _place_mouse(str(types[cell_code]), cell_code)
	_check(game.stage_solved, stage_id + " solved through real mouse input")
	_check(Optics.solved(stage_data, game.posts, game.shutters, game.lights, game.post_types),
		stage_id + " runtime exact typed clear")
	_check(game.completed.has(stage_id), stage_id + " isolated progress saved")
	await get_tree().create_timer(1.1).timeout
	_check(not game.next_button.disabled, stage_id + " clear presentation completes")

func _bounds(node: Node, viewport: Rect2) -> void:
	for child: Node in node.get_children():
		if child is Control:
			var control: Control = child
			if control.is_visible_in_tree():
				_check(viewport.grow(1.5).encloses(control.get_global_rect()),
					"layout bounds " + str(control.name) + " at " + str(control.get_global_rect()))
		_bounds(child, viewport)

func _target(shadow: Array[int]) -> Dictionary:
	var result: Dictionary = {}
	for index: int in 25:
		var cell_code: String = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
		result[cell_code] = shadow[index]
	return result

func _p0_regression() -> void:
	var posts: Array[int] = [0, 6, 12, 18]
	var lights: Array[String] = ["TOP", "LEFT", "RIGHT", "BOTTOM"]
	var shutters: Array[int] = []
	var substitute_types: Dictionary = {"0": "normal", "6": "normal", "12": "tall", "18": "normal"}
	var substitute_shadow: Array[int] = Optics.compute_shadow(posts, lights, shutters, substitute_types)
	var stage: Dictionary = {
		"id": "GR34-P0-REGRESSION", "posts": 4,
		"normal_posts": 2, "tall_posts": 1, "plate_posts": 1,
		"observations": [{"active_lights": lights, "target": _target(substitute_shadow)}]
	}
	_check(Optics.matches(substitute_shadow, stage["observations"][0]["target"]),
		"P0 regression target matches a total-count-only Plate substitution")
	_check(not Optics.solved(stage, posts, shutters, lights, substitute_types),
		"P0 exact inventory rejects Normal substituted for Plate")
	var exact_types: Dictionary = {"0": "normal", "6": "normal", "12": "tall", "18": "plate_v"}
	var exact_shadow: Array[int] = Optics.compute_shadow(posts, lights, shutters, exact_types)
	stage["observations"][0]["target"] = _target(exact_shadow)
	_check(Optics.solved(stage, posts, shutters, lights, exact_types),
		"valid Normal/Tall/Plate inventory still clears")
	_check(not Optics.solved(stage, posts, shutters, lights,
		{"0": "normal", "6": "normal", "12": "tall"}),
		"missing Plate type metadata is rejected")
	_check(not Optics.valid_post_type("plate"), "generic Plate alias is not silently Normal")
	var legacy: Dictionary = {
		"posts": 1,
		"observations": [{"active_lights": lights, "target": _target(Optics.compute_shadow([0], lights, [], {"0": "normal"}))}]
	}
	_check(not Optics.solved(legacy, [0], [], lights, {"0": "plate"}),
		"legacy alias cannot use Normal optics and clear")
	_check(Optics.board_shape_mask({"posts": 1}).size() == 25,
		"missing boardShape preserves the full board")
	_check(Optics.board_shape_mask({"boardShape": {"mask": ["11111", "11111"]}}).is_empty(),
		"malformed boardShape fails closed")

func _test_mask_interaction() -> void:
	var index: int = _stage_index("GR24")
	game.load_stage(index)
	await get_tree().process_frame
	var forbidden: int = -1
	var allowed: int = -1
	for socket_index: int in 25:
		if game.board_mask[socket_index] == 0 and forbidden < 0:
			forbidden = socket_index
		if game.board_mask[socket_index] == 1 and allowed < 0:
			allowed = socket_index
	_check(forbidden >= 0 and allowed >= 0, "GR24 mask contains legal and missing sockets")
	if forbidden < 0 or allowed < 0:
		return
	_check(game.sockets[forbidden].disabled, "missing socket disabled")
	_check(game.sockets[forbidden].get_child(0).kind == "socket_missing",
		"missing socket has absent-metal appearance, separate from FOG")
	game.toggle_post(forbidden)
	_check(not game.posts.has(forbidden), "click toggle cannot place on missing socket")
	await _tap(game.inventory)
	await _drag(game.inventory, game.sockets[forbidden])
	_check(game.posts.is_empty(), "mouse drag from inventory cannot land on missing socket")
	await _tap(game.sockets[allowed])
	_check(game.posts == [allowed], "mouse places a Post on a legal socket")
	await _drag(game.sockets[allowed], game.sockets[forbidden])
	_check(game.posts == [allowed], "dragging a Post onto missing socket rejects safely")
	game.undo_move()
	_check(game.posts.is_empty(), "undo returns to legal prior state")
	game.history.append({
		"posts": [forbidden], "post_types": {str(forbidden): "normal"},
		"shutters": [], "lights": game.lights.duplicate(), "observation": 0,
		"selected_post_type": "normal"
	})
	game.undo_move()
	_check(not game.posts.has(forbidden), "undo sanitizes an illegal historic post")
	game.reset_stage()
	_check(game.posts.is_empty() and game.posts.all(func(post: int) -> bool: return game.board_mask[post] == 1),
		"reset leaves only legal board state")

func _test_bottom_light_input() -> void:
	game.load_stage(_stage_index("GR22"))
	await get_tree().process_frame
	await get_tree().process_frame
	var bottom: Button = game.lamps["BOTTOM"]
	_check(bottom.visible and bottom.modulate.a > 0.9, "GR22 installed BOTTOM light is visible")
	_check(not bottom.disabled, "GR22 installed BOTTOM light is interactive")
	_check(not game.lights.has("BOTTOM"), "GR22 BOTTOM starts inactive")
	await _tap(bottom)
	_check(game.lights.has("BOTTOM"), "GR22 mouse tap activates BOTTOM light")
	await _tap(bottom)
	_check(not game.lights.has("BOTTOM"), "GR22 second mouse tap deactivates BOTTOM light")

func _test_plate_return() -> void:
	game.load_stage(_stage_index("GR28"))
	await get_tree().process_frame
	await _select_inventory("plate_v")
	var legal: int = -1
	for socket_index: int in 25:
		if game.board_mask[socket_index] == 1:
			legal = socket_index
			break
	if legal < 0:
		_check(false, "GR28 has an available Plate socket")
		return
	await _tap(game.sockets[legal])
	_check(game.posts.has(legal) and game.plate_inventory.visible,
		"placed Plate remains returnable through movable inventory")
	await _drag(game.sockets[legal], game.plate_inventory)
	_check(not game.posts.has(legal) and game.plate_inventory.visible,
		"Flat Plate returns to its own inventory by mouse drag")

func _test_campaign_route() -> void:
	var selector: Control = Campaign.new()
	selector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(selector)
	await get_tree().process_frame
	selector.call("_launch", "grant36-v05")
	await get_tree().process_frame
	await get_tree().process_frame
	var routed: Node = selector.get_child(0)
	_check(bool(routed.get("grant36_v05")), "campaign selector routes grant36-v05 to its isolated feature flag")
	_check(str(routed.get("campaign_id")) == "grant36-v05", "campaign route loads the v0.5 campaign identity")
	selector.queue_free()
	await get_tree().process_frame

func _test_save_reload() -> void:
	game._save_progress()
	var save_text: String = FileAccess.get_file_as_string(SMOKE_SAVE)
	var parsed: Variant = JSON.parse_string(save_text)
	_check(parsed is Dictionary and parsed.get("campaign", "") == "grant36-v05",
		"progress uses grant36-v05 campaign id")
	_check(save_text.find("shadow_sum_grant36_v0_5.json") < 0,
		"smoke uses a separate progress file")
	# Current saves only contain completion/playtest records; a forged legacy board payload
	# must not restore an object on a socket that is absent in the new campaign.
	var forged: Dictionary = {
		"campaign": "grant36-v05",
		"completed": {"GR24": true},
		"playtest": {},
		"posts": [0],
		"post_types": {"0": "normal"}
	}
	var file: FileAccess = FileAccess.open(SMOKE_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify(forged))
	file.close()
	var resumed: Control = Experiment.new()
	resumed.grant36_v05 = true
	resumed.progress_path = SMOKE_SAVE
	resumed.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(resumed)
	await get_tree().process_frame
	_check(resumed.campaign_id == "grant36-v05" and resumed.posts.is_empty(),
		"reload does not restore forged or illegal board posts")
	_check(resumed.board_mask.size() == 25, "reloaded stage validates its board mask")
	resumed.queue_free()
	await get_tree().process_frame

func _test_bonus() -> void:
	var selector: Control = Campaign.new()
	selector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(selector)
	await get_tree().process_frame
	selector.call("_launch", "grant36-v05-bonus")
	await get_tree().process_frame
	await get_tree().process_frame
	var routed: Node = selector.get_child(0)
	_check(bool(routed.get("grant36_v05_bonus")) and str(routed.get("campaign_id")) == "grant36-v05-bonus",
		"bonus selector routes to its own campaign")
	selector.queue_free()
	await get_tree().process_frame

	if FileAccess.file_exists(BONUS_SMOKE_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BONUS_SMOKE_SAVE))
	var previous_game: Control = game
	var bonus: Control = Experiment.new()
	bonus.grant36_v05_bonus = true
	bonus.progress_path = BONUS_SMOKE_SAVE
	bonus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bonus)
	game = bonus
	get_tree().root.size = Vector2i(405, 900)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game.campaign_id == "grant36-v05-bonus" and game.stages.size() == 1 and game.stage()["id"] == "BS01",
		"one-stage bonus campaign loads independently")
	_check(game.status_label.text.find("staircase") >= 0, "bonus intro explains the silhouette")
	var bonus_stage: Dictionary = game.stage()
	var authored_posts: Array = []
	var authored_types: Dictionary = {}
	for cell_code: String in bonus_stage["solution"]:
		var post_index: int = Optics.cell(cell_code)
		authored_posts.append(post_index)
		authored_types[str(post_index)] = str(bonus_stage["solution_post_types"][cell_code])
	for removed_index: int in authored_posts:
		var reduced_posts: Array = authored_posts.duplicate()
		reduced_posts.erase(removed_index)
		var reduced_types: Dictionary = authored_types.duplicate()
		reduced_types.erase(str(removed_index))
		var reduced_shadow: Array[int] = Optics.compute_shadow(
			reduced_posts, bonus_stage["observations"][0]["active_lights"], [], reduced_types)
		_check(not Optics.matches(reduced_shadow, bonus_stage["observations"][0]["target"]),
			"BS01 target visibly needs every authored Post; removing " + str(removed_index) + " changes the shadow")
	await _tap(game.hint_button)
	_check(game.hint_level == 1 and game.status_label.text.find("outline") >= 0,
		"bonus first Whisper focuses on board shape")
	await _tap(game.hint_button)
	await _tap(game.hint_button)
	_check(game.hint_level == 3 and game.hint_button.disabled, "all three bonus Whispers remain usable")
	var missing: int = Optics.cell("C5")
	_check(game.board_mask[missing] == 0 and game.sockets[missing].disabled,
		"decisive missing C5 socket is unavailable")
	await _tap(game.sockets[missing])
	_check(game.posts.is_empty(), "mouse cannot place on decisive missing socket")
	await _solve_replacement("BS01")
	_check(game.next_button.text == "REPLAY", "bonus completion offers replay")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(BONUS_SMOKE_SAVE))
	_check(parsed is Dictionary and parsed.get("campaign", "") == "grant36-v05-bonus"
		and parsed.get("completed", {}).has("BS01"), "bonus progress uses isolated campaign identity")
	_bounds(game, Rect2(Vector2.ZERO, Vector2(405, 900)))
	get_tree().root.size = Vector2i(720, 900)
	await get_tree().process_frame
	await get_tree().process_frame
	_bounds(game, Rect2(Vector2.ZERO, Vector2(720, 900)))
	game = previous_game
	bonus.queue_free()
	await get_tree().process_frame
	if FileAccess.file_exists(BONUS_SMOKE_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BONUS_SMOKE_SAVE))

func _run() -> void:
	var protected_paths: Array[String] = [
		"user://shadow_sum_grant20_v0_3.json",
		"user://shadow_sum_grant36_v0_5.json",
		"user://shadow_sum_grant36_v0_5_bonus.json",
		"user://shadow_sum_jev_review_v0_1.json",
		"user://shadow_sum_grant36_v0_4_draft.json"
	]
	var protected_contents: Array[String] = []
	for path: String in protected_paths:
		protected_contents.append(FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>")
	if FileAccess.file_exists(SMOKE_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_tree().root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.grant36_v05 = true
	game.progress_path = SMOKE_SAVE
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(game.campaign_id == "grant36-v05", "campaign id")
	_check(game.stages.size() == 36, "36 stages loaded")
	_check(game.stage()["id"] == "GR01", "clean isolated save starts at GR01")
	_p0_regression()
	await _test_campaign_route()
	await _test_bottom_light_input()
	await _test_mask_interaction()
	await _test_plate_return()

	# FOG must remain unknown evidence, not a zero.
	game.load_stage(_stage_index("GR29"))
	await get_tree().process_frame
	var fog_name: String = str(game.stage()["fog_cells"][0])
	var fog_index: int = Optics.cell(fog_name)
	_check(game.target_cells[fog_index].unknown, "GR29 fog renders unknown on the target screen")
	_check(not game.target_cells[Optics.cell("A1")].unknown or fog_name == "A1",
		"visible target cells remain observed")

	# Exercise every replacement with actual mouse clicks and exact typed inventory.
	for stage_id: String in ["GR24", "GR25", "GR28", "GR29", "GR32", "GR34", "GR35", "GR36"]:
		await _solve_replacement(stage_id)

	# Reload each replacement at compact and wide sizes and keep every control inside the viewport.
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		get_tree().root.size = dimensions
		for stage_id: String in ["GR24", "GR25", "GR28", "GR29", "GR32", "GR34", "GR35", "GR36"]:
			game.load_stage(_stage_index(stage_id))
			await get_tree().process_frame
			await get_tree().process_frame
			_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))

	await _test_save_reload()
	await _test_bonus()
	for index: int in protected_paths.size():
		var path: String = protected_paths[index]
		var after: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>"
		_check(after == protected_contents[index], "existing campaign save unchanged: " + path)
	if FileAccess.file_exists(SMOKE_SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	var report: Dictionary = {
		"failures": failures, "failure_labels": failure_labels,
		"campaign_id": "grant36-v05", "mouse_solved_replacements": 8, "mouse_solved_bonus": 1,
		"bottom_light_input": true, "mask_interactions": true, "plate_return": true, "fog_unknown": true,
		"layout_sizes": ["405x900", "720x900"],
	}
	var output: FileAccess = FileAccess.open(P0_RESULT, FileAccess.WRITE)
	output.store_string(JSON.stringify(report))
	output.close()
	game.queue_free()
	await get_tree().process_frame
	print("GRANT36 v0.5 runtime smoke: %d failures" % failures)
	await get_tree().create_timer(0.4).timeout
	get_tree().quit(1 if failures else 0)
