extends "res://tools/grant_experiment_smoke.gd"

func _select_inventory(kind: String) -> void:
	if kind == "normal" and game.inventory.visible:
		_tap(game.inventory)
	elif kind == "tall" and game.tall_inventory.visible:
		_tap(game.tall_inventory)
	elif kind.begins_with("plate_") and game.plate_inventory.visible:
		_tap(game.plate_inventory)

func _place(kind: String, code: String) -> void:
	_select_inventory(kind)
	_tap(game.sockets[Optics.cell(code)])
	if kind == "plate_h":
		_tap(game.sockets[Optics.cell(code)])

func _solve_current() -> void:
	var current: Dictionary = game.stage()
	for direction: String in current.get("solution_lights", []):
		if not game.lights.has(direction):
			_tap(game.lamps[direction])
	if current.get("movable_shutter", false):
		var desired: int = int(current["solution_shutter"])
		if game.shutters != [desired]:
			_tap(game.rail_buttons[desired])
	var expected_types: Dictionary = current.get("solution_post_types", {})
	for code: String in current["solution"]:
		var kind: String = str(expected_types.get(code, "normal"))
		_place(kind, code)

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.jev_review = true
	game.progress_path = "user://jev_review_smoke_only.json"
	if FileAccess.file_exists(game.progress_path):
		DirAccess.remove_absolute(game.progress_path)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	await process_frame

	var expected_candidates: Array[String] = [
		"three_plate_light_shutter-005",
		"three_plate_light_shutter-006",
		"fog_plate_shutter-010",
		"fog_height_light-007",
		"fog_height_light-006",
		"dense_height_plate_shutter-017",
		"dense_height_plate_shutter-004",
		"finale-015",
		"finale-010"
	]
	check(game.campaign_id == "jev_review_v0_1", "review campaign id")
	check(game.stages.size() == 9, "nine focused review stages")
	for index: int in expected_candidates.size():
		check(game.stages[index]["generator_candidate_id"] == expected_candidates[index], "candidate order %02d" % [index + 1])
	check(game.stages[0]["title"] == "GR28 / VARIANT A", "blind A label")
	check(game.stages[1]["title"] == "GR28 / VARIANT B", "blind B label")
	check(not game.stages[0].has("hints"), "review stages expose no hints")
	check(game.hint_button.disabled, "WHISPER disabled in review campaign")

	# FOG must be physically unknown, never interpreted as zero.
	var probe: Array[int] = []
	probe.resize(25)
	probe.fill(0)
	probe[Optics.cell("A1")] = 3
	check(Optics.matches(probe, {}, ["A1"]), "ignored FOG cell does not constrain target")
	check(not Optics.matches(probe, {}, []), "same cell constrains target when not fogged")

	game.load_stage(2)
	await process_frame
	var fog_cells: Array = game.stage().get("fog_cells", [])
	check(not fog_cells.is_empty(), "GR30 check contains FOG")
	var rendered_fog: int = 0
	for surface: Control in game.target_cells:
		rendered_fog += int(surface.unknown)
	check(rendered_fog == fog_cells.size(), "FOG renders as frosted unknown cells")
	check(game.observation_label.text.contains("FOG"), "FOG count is visible")

	# Solve all nine review variants using the authored exact solution metadata.
	for stage_number: int in 9:
		game.load_stage(stage_number)
		await process_frame
		await process_frame
		_solve_current()
		check(game.stage_solved, "mouse solution " + game.stage()["id"])
		if not game.stage_solved:
			push_error("Review solve failed: %s posts=%s types=%s lights=%s shutters=%s" % [
				game.stage()["generator_candidate_id"], game.posts, game.post_types, game.lights, game.shutters
			])
		await create_timer(0.96).timeout
		check(game.completed.has(game.stage()["id"]), "review completion saved " + game.stage()["id"])

	# Dedicated progress stays isolated from Grant20.
	game._save_progress()
	var resumed: Control = Experiment.new()
	resumed.jev_review = true
	resumed.progress_path = game.progress_path
	root.add_child(resumed)
	await process_frame
	check(resumed.campaign_id == "jev_review_v0_1", "review save reload")
	check(resumed.completed.size() == 9, "all review completions reload")
	resumed.queue_free()

	DirAccess.remove_absolute(game.progress_path)
	game.queue_free()
	await process_frame
	print("Jev review smoke: %d failures" % failures)
	quit(1 if failures else 0)
