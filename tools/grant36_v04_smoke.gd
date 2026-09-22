extends "res://tools/grant_experiment_smoke.gd"

func _select_inventory(kind: String) -> void:
	if kind == "normal" and game.inventory.visible:
		_tap(game.inventory)
	elif kind == "tall":
		if game.tall_inventory.visible:
			_tap(game.tall_inventory)
		elif game.inventory.visible:
			_tap(game.inventory)
	elif kind.begins_with("plate_") and game.plate_inventory.visible:
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
		if stage.get("tall", false) or stage.get("solution_tall", []).has(code):
			kind = "tall"
		_place(kind, code)

func _run() -> void:
	var protected_paths: Array[String] = [
		"user://shadow_sum_grant18_progress_v1.json",
		"user://shadow_sum_grant_experiments_v0_1.json",
		"user://shadow_sum_cause_light_v0_1.json",
		"user://shadow_sum_light_height_v0_1.json",
		"user://shadow_sum_flat_plate_v0_1.json",
		"user://shadow_sum_grant14_v0_2.json",
		"user://shadow_sum_grant20_v0_3.json"
	]
	var protected_contents: Array[String] = []
	for path: String in protected_paths:
		protected_contents.append(FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>")

	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.grant36_v04 = true
	game.progress_path = "user://grant36_v04_smoke_only.json"
	if FileAccess.file_exists(game.progress_path):
		DirAccess.remove_absolute(game.progress_path)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	await process_frame

	check(game.campaign_id == "grant36_v0_4", "campaign id")
	check(game.stages.size() == 36, "36 stages loaded")
	check(game.stage()["id"] == "GR01", "starts GR01")

	# Deep section and FROST presentation.
	game.load_stage(20)
	check(game.stage()["title"] == "DEEP OVERLAP", "GR21 starts deep section")
	game.load_stage(28)
	await process_frame
	check(game.stage()["id"] == "GR29", "GR29 first frost")
	var hidden: Array = game.stage()["observations"][0]["hidden_cells"]
	check(hidden.size() == 4, "GR29 has four frosted cells")
	for code: String in hidden:
		check(game.target_cells[Optics.cell(code)].unknown, "frost rendered " + code)
	check(not game.live_cells[Optics.cell(hidden[0])].unknown, "CURRENT never frosted")

	# Solve all 36 with actual mouse input.
	for stage_number: int in 36:
		game.load_stage(stage_number)
		await process_frame
		await process_frame
		_solve_current()
		check(game.stage_solved, "mouse solution " + game.stage()["id"])
		if not game.stage_solved:
			push_error("State at failure: posts=%s types=%s lights=%s shutters=%s" % [game.posts, game.post_types, game.lights, game.shutters])
		await create_timer(0.96).timeout
		check(game.completed.has(game.stage()["id"]), "completion saved " + game.stage()["id"])

	# Frost is unknown, not zero: mutate only hidden readings and still match.
	game.load_stage(28)
	var solution_posts: Array = [Optics.cell("B2"), Optics.cell("C3"), Optics.cell("D4")]
	var hidden_variant: Dictionary = game.stage()["observations"][0]["target"].duplicate()
	hidden_variant["A2"] = 99
	var actual: Array[int] = Optics.compute_shadow(solution_posts, ["TOP", "LEFT", "RIGHT"])
	check(Optics.matches(actual, hidden_variant, game.stage()["observations"][0]["hidden_cells"]), "frost ignores hidden reading")
	check(not Optics.matches(actual, hidden_variant, []), "same mutation fails when visible")

	# Final Deep Calibration combines every core cause and keeps inventory escape.
	game.load_stage(35)
	await process_frame
	check(game.stage()["title"] == "DEEP CALIBRATION", "GR36 final title")
	_drag(game.plate_inventory, game.sockets[Optics.cell("C4")])
	check(game.plate_inventory.visible, "GR36 plate inventory remains visible")
	_drag(game.sockets[Optics.cell("C4")], game.plate_inventory)
	check(not game.posts.has(Optics.cell("C4")), "GR36 plate can return to inventory")
	game.reset_stage()
	_solve_current()
	check(game.stage_solved, "GR36 exact integrated state")

	var wrong_types: Dictionary = {
		str(Optics.cell("B2")): "normal",
		str(Optics.cell("B3")): "tall",
		str(Optics.cell("C4")): "plate_v"
	}
	check(
		not Optics.solved(
			game.stage(),
			[Optics.cell("B2"), Optics.cell("B3"), Optics.cell("C4")],
			[2],
			["TOP", "LEFT", "BOTTOM"],
			wrong_types
		),
		"GR36 wrong plate orientation rejected"
	)

	# WHISPER must never mutate a deep puzzle.
	game.load_stage(35)
	var initial_posts: Array = game.posts.duplicate()
	var initial_types: Dictionary = game.post_types.duplicate()
	var initial_lights: Array = game.lights.duplicate()
	var initial_shutters: Array = game.shutters.duplicate()
	for index: int in 3:
		game.whisper()
	check(game.posts == initial_posts, "GR36 hints do not place")
	check(game.post_types == initial_types, "GR36 hints do not rotate")
	check(game.lights == initial_lights, "GR36 hints do not switch lamps")
	check(game.shutters == initial_shutters, "GR36 hints do not move shutter")

	# Layout on compact and wide targets.
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		root.size = dimensions
		for stage_number: int in 36:
			game.load_stage(stage_number)
			await process_frame
			await process_frame
			_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))

	# Dedicated save reload and isolation.
	for stage_number: int in 36:
		game.completed[game.stages[stage_number]["id"]] = true
	game._save_progress()
	var resumed: Control = Experiment.new()
	resumed.grant36_v04 = true
	resumed.progress_path = game.progress_path
	root.add_child(resumed)
	await process_frame
	check(resumed.completed.size() == 36 and resumed.campaign_id == "grant36_v0_4", "Grant36 save reload")
	resumed.queue_free()

	for index: int in protected_paths.size():
		var path: String = protected_paths[index]
		var after: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>"
		check(after == protected_contents[index], "existing campaign save unchanged")
	DirAccess.remove_absolute(game.progress_path)
	game.queue_free()
	await process_frame
	print("Grant36 v0.4 smoke: %d failures" % failures)
	quit(1 if failures else 0)
