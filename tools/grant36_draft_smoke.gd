extends "res://tools/grant20_v03_smoke.gd"

const Router = preload("res://src/campaign_main.gd")
const SMOKE_SAVE: String = "user://grant36_draft_smoke_only.json"

func _run() -> void:
	var protected_paths: Array[String] = [
		"user://shadow_sum_grant18_progress_v1.json",
		"user://shadow_sum_grant_experiments_v0_1.json",
		"user://shadow_sum_cause_light_v0_1.json",
		"user://shadow_sum_light_height_v0_1.json",
		"user://shadow_sum_flat_plate_v0_1.json",
		"user://shadow_sum_grant14_v0_2.json",
		"user://shadow_sum_grant20_v0_3.json",
		"user://shadow_sum_grant36_v0_4_draft.json"
	]
	var before: Array[String] = []
	for path: String in protected_paths:
		before.append(FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>")
	if FileAccess.file_exists(SMOKE_SAVE):
		DirAccess.remove_absolute(SMOKE_SAVE)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = (load("res://scenes/grant36_draft.tscn") as PackedScene).instantiate()
	game.progress_path = SMOKE_SAVE
	root.add_child(game)
	await process_frame
	await process_frame
	check(game.grant36_draft and game.campaign_id == "grant36_v0_4_draft", "draft identity")
	check(game.stages.size() == 36 and game.stage()["id"] == "GR21", "draft starts GR21")
	check(game.stage_picker.item_count == 36 and game.stage_picker.selected == 20, "unlocked stage picker")
	check(game.observation_buttons.is_empty(), "one observation only")
	check(game.hint_button.disabled, "missing hints disabled")
	game.whisper()
	check(game.hint_level == 0 and game.status_label.text.is_empty(), "no missing-hint lookup")

	# Exercise the real option menu with mouse opening and keyboard confirmation.
	_tap(game.stage_picker)
	# Respect PopupMenu's opening guard before sending the confirmation key.
	await create_timer(0.4).timeout
	var popup: PopupMenu = game.stage_picker.get_popup()
	check(popup.visible, "stage picker opens")
	popup.set_focused_item(28)
	var accept: InputEventKey = InputEventKey.new()
	accept.keycode = KEY_ENTER
	accept.pressed = true
	Input.parse_input_event(accept)
	await process_frame
	accept.pressed = false
	Input.parse_input_event(accept)
	check(game.stage()["id"] == "GR29", "stage picker jumps to FOG")
	popup.hide()

	var pool: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://generated/grant36_candidates.json"))
	var by_id: Dictionary = {}
	for candidate: Dictionary in pool["candidates"]:
		by_id[candidate["id"]] = candidate
	var wrong_worlds: int = 0
	for number: int in range(20, 36):
		game.load_stage(number)
		await process_frame
		await process_frame
		var entry: Dictionary = game.stage()
		var fog: Array = entry.get("fog_cells", [])
		for index: int in 25:
			var cell_code: String = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
			check(game.target_cells[index].unknown == fog.has(cell_code), "FOG display " + entry["id"] + " " + cell_code)
			check(not game.live_cells[index].unknown, "CURRENT stays observed")
		_solve_current()
		check(game.stage_solved and game.completed.has(entry["id"]), "mouse solution " + entry["id"])
		var expected_shadow: Array[int] = []
		for value: Variant in entry["solution_complete_shadow"]:
			expected_shadow.append(int(value))
		check(game.current_shadow == expected_shadow, "Godot / generator shadow " + entry["id"])
		if not fog.is_empty():
			var target: Dictionary = entry["observations"][0]["target"]
			var altered: Array = game.current_shadow.duplicate()
			for cell_code: String in fog:
				altered[Optics.cell(cell_code)] += 5
			check(Optics.matches(altered, target, fog), "hidden values unconstrained " + entry["id"])
			check(not Optics.matches(game.current_shadow, target), "unknown is not zero " + entry["id"])
			for cell_code: String in target:
				if int(target[cell_code]) == 0:
					altered[Optics.cell(cell_code)] = 1
					break
			check(not Optics.matches(altered, target, fog), "observed zero still constrains " + entry["id"])
			check(game.observation_label.text.contains("UNOBSERVED"), "FOG explanation")
		var candidate: Dictionary = by_id[entry["generator_candidate_id"]]
		for near: Dictionary in candidate["near_miss_worlds"]:
			var world: Dictionary = near["world"]
			var near_posts: Array = []
			var near_types: Dictionary = {}
			for obj: Dictionary in world["objects"]:
				var pos: int = Optics.cell(obj["cell"])
				near_posts.append(pos)
				near_types[str(pos)] = obj["type"]
			var near_shutters: Array = [] if world["shutter"] == null else [int(world["shutter"])]
			check(not Optics.solved(entry, near_posts, near_shutters, world["lights"], near_types), "near miss rejected " + entry["id"])
			wrong_worlds += 1
		await create_timer(0.95).timeout
		check(not game.next_button.disabled, "clear animation unlocks NEXT " + entry["id"])
	check(game.completed.size() == 16 and wrong_worlds == 64, "sixteen saves, sixty-four rejected worlds")
	_tap(game.next_button)
	check(game.stage()["id"] == "GR21" and game.stage_picker.selected == 20, "final replay returns GR21")

	# Four objects, return to inventory, undo, reset, and missing-hint safety.
	game.load_stage(35)
	await process_frame
	_drag(game.plate_inventory, game.sockets[12])
	check(game.posts.has(12), "draft plate drag")
	_drag(game.sockets[12], game.plate_inventory)
	check(not game.posts.has(12), "draft plate returns to inventory")
	game.undo_move()
	check(game.posts.has(12), "undo restores returned plate")
	game.reset_stage()
	check(game.posts.is_empty() and game.history.is_empty(), "draft reset")

	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		root.size = dimensions
		for number: int in range(20, 36):
			game.load_stage(number)
			await process_frame
			await process_frame
			_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))

	var resumed: Control = (load("res://scenes/grant36_draft.tscn") as PackedScene).instantiate()
	resumed.progress_path = SMOKE_SAVE
	root.add_child(resumed)
	await process_frame
	check(resumed.completed.size() == 16 and resumed.stage()["id"] == "GR36", "draft save reload")
	resumed.queue_free()
	game.queue_free()
	await process_frame
	var router: Control = Router.new()
	root.add_child(router)
	await process_frame
	check(router.get_child(0).grant20_v03, "default remains GRANT20")
	router._launch("grant36-draft")
	await process_frame
	var routed: Control = router.get_child(0)
	check(routed.grant36_draft and routed.stages.size() == 36, "campaign argument routes draft")
	check(routed.progress_path == "user://shadow_sum_grant36_v0_4_draft.json", "separate default draft save")
	router.queue_free()
	await process_frame
	for index: int in protected_paths.size():
		var path: String = protected_paths[index]
		var after: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>"
		check(before[index] == after, "player save unchanged " + path)
	DirAccess.remove_absolute(SMOKE_SAVE)
	print("Grant36 draft smoke: %d failures; 16 mouse solutions, 64 wrong worlds, 4 FOG stages" % failures)
	quit(1 if failures else 0)
