extends "res://tools/grant_experiment_smoke.gd"

func _run() -> void:
	var protected_paths: Array[String] = [
		"user://shadow_sum_grant18_progress_v1.json",
		"user://shadow_sum_grant_experiments_v0_1.json",
		"user://shadow_sum_cause_light_v0_1.json",
		"user://shadow_sum_light_height_v0_1.json"
	]
	var protected_contents: Array[String] = []
	for path: String in protected_paths:
		protected_contents.append(FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>")

	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.flat_plate = true
	game.progress_path = "user://flat_plate_smoke_only.json"
	if FileAccess.file_exists(game.progress_path):
		DirAccess.remove_absolute(game.progress_path)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	await process_frame

	# P01: a fixed vertical plate becomes the solution by rotating in place.
	var c3: int = Optics.cell("C3")
	check(game.campaign_id == "flat_plate_v0_1", "campaign id")
	check(game.stage()["id"] == "P01", "starts P01")
	check(game.posts == [c3] and game.post_types.get(str(c3)) == "plate_v", "P01 fixed vertical plate")
	check(game.current_shadow[Optics.cell("B3")] == 1 and game.current_shadow[Optics.cell("D3")] == 1, "vertical plate answers side lights")
	check(game.current_shadow[Optics.cell("C2")] == 0 and game.current_shadow[Optics.cell("C4")] == 0, "vertical plate ignores top/bottom")
	_tap(game.sockets[c3])
	check(game.post_types.get(str(c3)) == "plate_h", "tap rotates fixed plate")
	check(game.stage_solved, "P01 rotation solves")

	# RESET restores orientation.
	game.reset_stage()
	check(game.post_types.get(str(c3)) == "plate_v" and not game.stage_solved, "P01 reset restores vertical")

	# P02: drag a plate, rotate it, and undo a rotation on a wrong cell.
	game.load_stage(1)
	await process_frame
	check(game.plate_inventory.visible and not game.inventory.visible and not game.tall_inventory.visible, "P02 plate-only inventory")
	_drag(game.plate_inventory, game.sockets[Optics.cell("C4")])
	check(game.post_types.get(str(Optics.cell("C4"))) == "plate_v", "plate drag starts vertical")
	check(game.plate_inventory.visible, "plate inventory remains visible after placement")
	_drag(game.sockets[Optics.cell("C4")], game.plate_inventory)
	check(game.posts.is_empty(), "placed plate can return to inventory")
	check(game.plate_inventory.visible and game.plate_inventory.get_child(0).occupied, "returned plate is available again")
	_drag(game.plate_inventory, game.sockets[Optics.cell("C4")])
	_tap(game.sockets[Optics.cell("C4")])
	check(game.post_types.get(str(Optics.cell("C4"))) == "plate_h", "plate tap rotates")
	game.undo_move()
	check(game.post_types.get(str(Optics.cell("C4"))) == "plate_v", "UNDO restores plate orientation")
	_drag(game.sockets[Optics.cell("C4")], game.sockets[Optics.cell("D4")])
	check(game.post_types.get(str(Optics.cell("D4"))) == "plate_v", "moving plate preserves orientation")
	_tap(game.sockets[Optics.cell("D4")])
	check(game.post_types.get(str(Optics.cell("D4"))) == "plate_h" and game.stage_solved, "P02 position + orientation solve")

	# P03: normal Post and vertical plate create a shared double shadow.
	game.load_stage(2)
	await process_frame
	_drag(game.inventory, game.sockets[c3])
	_drag(game.plate_inventory, game.sockets[Optics.cell("D4")])
	check(game.post_types.get(str(c3)) == "normal", "P03 normal type")
	check(game.post_types.get(str(Optics.cell("D4"))) == "plate_v", "P03 plate type")
	check(game.current_shadow[Optics.cell("C4")] == 2, "P03 overlap includes plate contribution")
	check(game.stage_solved, "P03 mixed object solve")

	# P04: fixed normal Post identifies the three active lamps; the plate explains the missing vertical trace.
	game.load_stage(3)
	await process_frame
	check(game.posts == [c3] and game.post_types.get(str(c3)) == "normal", "P04 fixed normal witness")
	check(game.lights.is_empty(), "P04 lamps start dark")
	check(game.lamps["BOTTOM"].visible and not game.lamps["BOTTOM"].get_child(0).active, "P04 bottom mount visible while dark")
	_tap(game.lamps["TOP"])
	_tap(game.lamps["LEFT"])
	_tap(game.lamps["BOTTOM"])
	check(game.lights.size() == 3 and game.lights.has("BOTTOM"), "P04 accepts a wrong three-light hypothesis")
	_tap(game.lamps["BOTTOM"])
	_tap(game.lamps["RIGHT"])
	check(game.lights.size() == 3 and not game.lights.has("BOTTOM"), "P04 light hypothesis can be corrected")
	_drag(game.plate_inventory, game.sockets[Optics.cell("C1")])
	check(game.post_types.get(str(Optics.cell("C1"))) == "plate_v", "P04 vertical plate")
	check(game.stage_solved, "P04 light + orientation solve")

	# Directional optics oracle.
	var vertical: Dictionary = {str(c3): "plate_v"}
	var horizontal: Dictionary = {str(c3): "plate_h"}
	var v_shadow: Array[int] = Optics.compute_shadow([c3], ["TOP", "LEFT", "RIGHT", "BOTTOM"], [], vertical)
	var h_shadow: Array[int] = Optics.compute_shadow([c3], ["TOP", "LEFT", "RIGHT", "BOTTOM"], [], horizontal)
	check(v_shadow[Optics.cell("B3")] == 1 and v_shadow[Optics.cell("D3")] == 1 and v_shadow[Optics.cell("C4")] == 0, "vertical oracle")
	check(h_shadow[Optics.cell("C2")] == 1 and h_shadow[Optics.cell("C4")] == 1 and h_shadow[Optics.cell("D3")] == 0, "horizontal oracle")

	# Layout and save isolation.
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		root.size = dimensions
		for stage_number: int in 4:
			game.load_stage(stage_number)
			await process_frame
			await process_frame
			_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))

	for stage_number: int in 4:
		game.completed[game.stages[stage_number]["id"]] = true
	game._save_progress()
	var resumed: Control = Experiment.new()
	resumed.flat_plate = true
	resumed.progress_path = game.progress_path
	root.add_child(resumed)
	await process_frame
	check(resumed.completed.size() == 4 and resumed.campaign_id == "flat_plate_v0_1", "Flat Plate save reload")
	resumed.queue_free()

	for index: int in protected_paths.size():
		var path: String = protected_paths[index]
		var after: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>"
		check(after == protected_contents[index], "existing campaign save unchanged")
	DirAccess.remove_absolute(game.progress_path)
	game.queue_free()
	await process_frame
	print("Flat Plate smoke: %d failures" % failures)
	quit(1 if failures else 0)
