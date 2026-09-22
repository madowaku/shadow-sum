extends "res://tools/grant_experiment_smoke.gd"

func _select_inventory(kind: String) -> void:
	if kind == "normal":
		_tap(game.inventory)
	elif kind == "tall":
		_tap(game.tall_inventory)
	elif kind.begins_with("plate_"):
		_tap(game.plate_inventory)

func _place(kind: String, code: String) -> void:
	_select_inventory(kind)
	_tap(game.sockets[Optics.cell(code)])
	if kind == "plate_h":
		_tap(game.sockets[Optics.cell(code)])

func _solve_current() -> void:
	var stage: Dictionary = game.stage()

	for direction: String in stage.get("solution_lights", []):
		_tap(game.lamps[direction])

	if stage.get("movable_shutter", false):
		_tap(game.rail_buttons[int(stage["solution_shutter"])])

	var fixed_codes: Array = stage.get("fixed_posts", [])
	var expected_types: Dictionary = stage.get("solution_post_types", {})

	for code: String in stage["solution"]:
		if fixed_codes.has(code):
			if expected_types.get(code, "") == "plate_h":
				_tap(game.sockets[Optics.cell(code)])
			continue

		var kind: String = str(expected_types.get(code, "normal"))
		if stage.get("tall", false):
			kind = "tall"
		elif stage.get("solution_tall", []).has(code):
			kind = "tall"
		_place(kind, code)

func _run() -> void:
	var protected_paths: Array[String] = [
		"user://shadow_sum_grant18_progress_v1.json",
		"user://shadow_sum_grant_experiments_v0_1.json",
		"user://shadow_sum_cause_light_v0_1.json",
		"user://shadow_sum_light_height_v0_1.json",
		"user://shadow_sum_flat_plate_v0_1.json"
	]
	var protected_contents: Array[String] = []
	for path: String in protected_paths:
		protected_contents.append(FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>")

	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.grant14_v02 = true
	game.progress_path = "user://grant14_v02_smoke_only.json"
	if FileAccess.file_exists(game.progress_path):
		DirAccess.remove_absolute(game.progress_path)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	await process_frame

	check(game.campaign_id == "grant14_v0_2", "campaign id")
	check(game.stages.size() == 14, "14 stages loaded")
	check(game.stage()["id"] == "GR01", "starts GR01")

	# The four conceptual reveals should visibly alter the apparatus or object model.
	game.load_stage(3)
	check(game.lights.has("BOTTOM") and game.lamps["BOTTOM"].modulate.a > 0.9, "GR04 fourth lamp visible")
	game.load_stage(6)
	check(game.shutters == [2] and game.rail.get_parent().visible, "GR07 fixed shutter visible")
	game.load_stage(8)
	_tap(game.sockets[Optics.cell("C3")])
	check(game.post_types.get(str(Optics.cell("C3"))) == "tall", "GR09 Tall Post")
	check(game.current_shadow[Optics.cell("C5")] == 1, "GR09 long reach")
	game.load_stage(10)
	check(game.post_types.get(str(Optics.cell("C3"))) == "plate_v", "GR11 starts with vertical plate")
	_tap(game.sockets[Optics.cell("C3")])
	check(game.post_types.get(str(Optics.cell("C3"))) == "plate_h", "GR11 tap rotates plate")
	check(game.stage_solved, "GR11 rotation solves")

	# Solve all 14 with actual mouse input.
	for stage_number: int in 14:
		game.load_stage(stage_number)
		await process_frame
		await process_frame
		_solve_current()
		check(game.stage_solved, "mouse solution " + game.stage()["id"])
		if not game.stage_solved:
			push_error("State at failure: posts=%s types=%s lights=%s shutters=%s" % [game.posts, game.post_types, game.lights, game.shutters])
		await create_timer(0.96).timeout
		check(game.completed.has(game.stage()["id"]), "completion saved " + game.stage()["id"])
		check(not game.next_button.disabled, "NEXT breath complete " + game.stage()["id"])

	# Final calibration must reject plausible wrong causes.
	game.load_stage(13)
	await process_frame
	_tap(game.lamps["TOP"])
	_tap(game.lamps["LEFT"])
	_tap(game.lamps["RIGHT"])
	_tap(game.rail_buttons[1])
	_place("normal", "B2")
	_place("tall", "C1")
	_place("plate_v", "C4")
	check(game.stage_solved, "GR14 exact integrated state")

	game.load_stage(13)
	await process_frame
	_tap(game.lamps["TOP"])
	_tap(game.lamps["LEFT"])
	_tap(game.lamps["RIGHT"])
	_tap(game.rail_buttons[1])
	_place("normal", "B2")
	_place("tall", "C1")
	_place("plate_v", "C4")
	# Solved state is locked, so validate swapped orientation independently.
	var wrong_types: Dictionary = {
		str(Optics.cell("B2")): "normal",
		str(Optics.cell("C1")): "tall",
		str(Optics.cell("C4")): "plate_h"
	}
	check(
		not Optics.solved(
			game.stage(),
			[Optics.cell("B2"), Optics.cell("C1"), Optics.cell("C4")],
			[1],
			["TOP", "LEFT", "RIGHT"],
			wrong_types
		),
		"GR14 wrong plate orientation rejected"
	)
	var wrong_shutter_types: Dictionary = {
		str(Optics.cell("B2")): "normal",
		str(Optics.cell("C1")): "tall",
		str(Optics.cell("C4")): "plate_v"
	}
	check(
		not Optics.solved(
			game.stage(),
			[Optics.cell("B2"), Optics.cell("C1"), Optics.cell("C4")],
			[2],
			["TOP", "LEFT", "RIGHT"],
			wrong_shutter_types
		),
		"GR14 wrong shutter rejected"
	)

	# WHISPER must never place, rotate, move shutter, or switch lamps.
	game.load_stage(13)
	var initial_posts: Array = game.posts.duplicate()
	var initial_types: Dictionary = game.post_types.duplicate()
	var initial_lights: Array = game.lights.duplicate()
	var initial_shutters: Array = game.shutters.duplicate()
	for index: int in 3:
		game.whisper()
	check(game.posts == initial_posts, "GR14 hints do not place objects")
	check(game.post_types == initial_types, "GR14 hints do not rotate objects")
	check(game.lights == initial_lights, "GR14 hints do not switch lamps")
	check(game.shutters == initial_shutters, "GR14 hints do not move shutter")

	# Layout on compact and wide targets.
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		root.size = dimensions
		for stage_number: int in 14:
			game.load_stage(stage_number)
			await process_frame
			await process_frame
			_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))

	# Dedicated save reload and isolation from all earlier campaigns.
	for stage_number: int in 14:
		game.completed[game.stages[stage_number]["id"]] = true
	game._save_progress()
	var resumed: Control = Experiment.new()
	resumed.grant14_v02 = true
	resumed.progress_path = game.progress_path
	root.add_child(resumed)
	await process_frame
	check(resumed.completed.size() == 14 and resumed.campaign_id == "grant14_v0_2", "Grant14 save reload")
	resumed.queue_free()

	for index: int in protected_paths.size():
		var path: String = protected_paths[index]
		var after: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>"
		check(after == protected_contents[index], "existing campaign save unchanged")
	DirAccess.remove_absolute(game.progress_path)
	game.queue_free()
	await process_frame
	print("Grant14 v0.2 smoke: %d failures" % failures)
	quit(1 if failures else 0)
