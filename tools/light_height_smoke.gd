extends "res://tools/grant_experiment_smoke.gd"

func _select_and_place(kind: String, code: String) -> void:
	if kind == "tall":
		_tap(game.tall_inventory)
	else:
		_tap(game.inventory)
	_tap(game.sockets[Optics.cell(code)])

func _tap_solution_lights() -> void:
	for direction: String in game.stage().get("solution_lights", []):
		_tap(game.lamps[direction])

func _run() -> void:
	var protected_paths: Array[String] = [
		"user://shadow_sum_grant18_progress_v1.json",
		"user://shadow_sum_grant_experiments_v0_1.json",
		"user://shadow_sum_cause_light_v0_1.json"
	]
	var protected_contents: Array[String] = []
	for path: String in protected_paths:
		protected_contents.append(FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>")

	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.light_height = true
	game.progress_path = "user://light_height_smoke_only.json"
	if FileAccess.file_exists(game.progress_path):
		DirAccess.remove_absolute(game.progress_path)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	await process_frame

	check(game.campaign_id == "light_height_v0_1", "campaign id")
	check(game.stage()["id"] == "LC01", "starts LC01")
	check(game.posts == [Optics.cell("C3")], "LC01 fixed Post")
	check(game.lights.is_empty(), "LC01 lights start dark")
	check(game.lamps["BOTTOM"].visible, "four mounts remain visible")

	# Light Combination: every solution uses real lamp input.
	for stage_number: int in 4:
		game.load_stage(stage_number)
		await process_frame
		_tap_solution_lights()
		if not game.stage().has("fixed_posts"):
			for code: String in game.stage()["solution"]:
				_tap(game.sockets[Optics.cell(code)])
		check(game.stage_solved, "LC%02d mouse solution" % (stage_number + 1))

	# Exact light count is a cap, not a one-off switch.
	game.load_stage(0)
	_tap(game.lamps["TOP"])
	_tap(game.lamps["LEFT"])
	var before: Array = game.lights.duplicate()
	_tap(game.lamps["RIGHT"])
	check(game.lights == before and game.lights.size() == 2, "LC01 cannot exceed two lights")
	game.reset_stage()
	check(game.lights.is_empty(), "free lights reset to dark")

	# TP01: one Tall Post, fixed three-light world.
	game.load_stage(4)
	await process_frame
	_tap(game.sockets[Optics.cell("C3")])
	check(game.post_types.get(str(Optics.cell("C3"))) == "tall", "TP01 places Tall Post")
	check(game.stage_solved, "TP01 solves")

	# TP02: drag Tall from its own inventory, then click-place Normal.
	game.load_stage(5)
	await process_frame
	_drag(game.tall_inventory, game.sockets[Optics.cell("C3")])
	check(game.post_types.get(str(Optics.cell("C3"))) == "tall", "Tall inventory drag keeps type")
	_select_and_place("normal", "D4")
	check(game.post_types.get(str(Optics.cell("D4"))) == "normal", "Normal inventory selection keeps type")
	check(game.stage_solved, "TP02 mixed heights solve")

	# Undo must restore both position and type.
	game.load_stage(5)
	await process_frame
	_select_and_place("tall", "C3")
	_select_and_place("normal", "D4")
	check(game.stage_solved, "TP02 second solve")
	game.load_stage(6)
	_select_and_place("tall", "C3")
	_select_and_place("normal", "B2")
	check(game.post_types.get(str(Optics.cell("C3"))) == "tall", "TP03 Tall seated")
	game.undo_move()
	check(not game.posts.has(Optics.cell("B2")) and game.post_types.get(str(Optics.cell("C3"))) == "tall", "UNDO preserves remaining type")
	_select_and_place("normal", "B2")
	_select_and_place("normal", "D4")
	check(game.stage_solved, "TP03 mixed solution")

	# TP04 combines unknown light subset with unknown height assignment.
	game.load_stage(7)
	await process_frame
	_tap(game.lamps["LEFT"])
	_tap(game.lamps["RIGHT"])
	_select_and_place("tall", "B2")
	_select_and_place("normal", "D2")
	check(game.stage_solved, "TP04 Light + Height solve")
	var swapped: Dictionary = {str(Optics.cell("B2")): "normal", str(Optics.cell("D2")): "tall"}
	check(not Optics.solved(game.stage(), [Optics.cell("B2"), Optics.cell("D2")], [], ["LEFT", "RIGHT"], swapped), "TP04 swapped heights rejected")

	# Layout and save isolation.
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		root.size = dimensions
		for stage_number: int in 8:
			game.load_stage(stage_number)
			await process_frame
			await process_frame
			_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))

	for stage_number: int in 8:
		game.completed[game.stages[stage_number]["id"]] = true
	game._save_progress()
	var resumed: Control = Experiment.new()
	resumed.light_height = true
	resumed.progress_path = game.progress_path
	root.add_child(resumed)
	await process_frame
	check(resumed.completed.size() == 8 and resumed.campaign_id == "light_height_v0_1", "Light & Height save reload")
	resumed.queue_free()

	for index: int in protected_paths.size():
		var path: String = protected_paths[index]
		var after: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>"
		check(after == protected_contents[index], "existing campaign save unchanged")
	DirAccess.remove_absolute(game.progress_path)
	game.queue_free()
	await process_frame
	print("Light & Height smoke: %d failures" % failures)
	quit(1 if failures else 0)
