extends "res://tools/grant_experiment_smoke.gd"

func _run() -> void:
	var protected_paths: Array[String] = ["user://shadow_sum_grant18_progress_v1.json", "user://shadow_sum_grant_experiments_v0_1.json"]
	var protected_contents: Array[String] = []
	for path: String in protected_paths:
		protected_contents.append(FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.cause_light = true
	game.progress_path = "user://cause_light_smoke_only.json"
	if FileAccess.file_exists(game.progress_path):
		DirAccess.remove_absolute(game.progress_path)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	await process_frame
	check(game.lights.size() == 2, "H01 two sources")
	check(game.lamps["RIGHT"].modulate.a == 0 and game.lamps["BOTTOM"].modulate.a == 0, "H01 absent lamps")
	game.load_stage(1)
	check(game.lights.size() == 4, "H02 four lights")
	game.toggle_post(6)
	check(game.current_shadow[1] == 1, "BOTTOM upward contribution")
	game.load_stage(2)
	game.toggle_post(6)
	game.move_shutter(3)
	for direction: String in ["LEFT", "BOTTOM", "RIGHT"]:
		var old_lights: Array = game.lights.duplicate()
		game.tap_light(direction)
		check(game.lights.size() == 3 and not game.lights.has(direction), "exactly one dark: " + direction)
		check(game.posts == [6] and game.shutters == [3], "swap preserves world")
		var depth: int = game.history.size()
		game.tap_light(direction)
		check(game.history.size() == depth and game.lights.size() == 3, "dark tap no-op")
		game.undo_move()
		check(game.lights == old_lights, "UNDO restores lights")
	game.tap_light("LEFT")
	game.tap_light("TOP")
	check(not game.lights.has("TOP") and game.lights.size() == 3, "TOP can become dark again")
	game.toggle_post(18)
	check(not game.stage_solved, "wrong OFF rejected")
	game.tap_light("RIGHT")
	check(game.stage_solved, "H03 exact state solves")
	var old: Array = game.motions.duplicate()
	game.reset_stage()
	for motion: Tween in old:
		check(not motion.is_valid(), "RESET kills tweens")
	check(game.posts.is_empty() and game.shutters == [0] and game.lights == ["LEFT", "RIGHT", "BOTTOM"], "RESET complete initial state")
	for stage_number: int in [3, 4, 5]:
		game.load_stage(stage_number)
		game.toggle_post(6)
		game.move_shutter(2)
		await process_frame
		await process_frame
		var position_before: Vector2 = game.sockets[0].global_position
		_tap(game.observation_buttons[1])
		await process_frame
		await process_frame
		check(game.observation_index == 1 and game.posts == [6] and game.shutters == [2], "observation preserves world")
		check(game.sockets[0].global_position == position_before, "board must not move")
		if stage_number == 4:
			check(game.lights.size() == 3 and game.lamps["BOTTOM"].get_child(0).active, "H05 B adds BOTTOM")
			_tap(game.observation_buttons[0])
			check(game.lights.size() == 2 and not game.lamps["BOTTOM"].get_child(0).active, "H05 A two visual lights")
	game.load_stage(3)
	var rejected: int = 0
	for first: int in 25:
		for second: int in range(first + 1, 25):
			for slot: int in 5:
				var candidate: Array = [first, second]
				if Optics.matches(Optics.compute_shadow(candidate, ["TOP", "LEFT"], [slot]), game.stage()["observations"][0]["target"]):
					if not Optics.solved(game.stage(), candidate, [slot], ["TOP", "LEFT"]):
						rejected += 1
	check(rejected == 3, "H04 requires both observations")
	var blocked: Array[int] = Optics.compute_shadow([6, 16, 18], ["TOP"], [1])
	check(blocked[11] == 0 and blocked[21] == 0 and blocked[23] == 1, "H06 one plate blocks both B posts")
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		root.size = dimensions
		for stage_number: int in 6:
			game.load_stage(stage_number)
			await process_frame
			await process_frame
			_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))
	# Every solution goes through actual mouse events, including shutters and lamps.
	for stage_number: int in 6:
		game.load_stage(stage_number)
		await process_frame
		await process_frame
		for code: String in game.stage()["solution"]:
			_tap(game.sockets[Optics.cell(code)])
		_tap(game.rail_buttons[int(game.stage()["solution_shutter"])])
		if stage_number == 2:
			_tap(game.lamps["RIGHT"])
		check(game.stage_solved, "mouse solution H%02d" % (stage_number + 1))
		await create_timer(0.96).timeout
		check(game.completed.has(game.stage()["id"]) and not game.next_button.disabled, "completion/save")
		if not OS.get_environment("SHADOW_SUM_CAPTURE_DIR").is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OS.get_environment("SHADOW_SUM_CAPTURE_DIR").path_join("H%02d.png" % (stage_number + 1)))
		old = game.motions.duplicate()
		_tap(game.next_button)
		if stage_number < 5:
			for motion: Tween in old:
				check(not motion.is_valid(), "NEXT kills tweens")
	game.load_stage(4)
	game.toggle_post(6)
	await process_frame
	await process_frame
	old = game.motions.duplicate()
	_tap(game.back_button)
	for motion: Tween in old:
		check(not motion.is_valid(), "BACK kills tweens")
	game.load_stage(2)
	for index: int in 3:
		game.whisper()
	check(game.posts.is_empty() and game.hint_level == 3, "hints never place answers")
	game.reset_stage()
	await create_timer(1.0).timeout
	check(game.status_label.text.is_empty() and not game.stage_solved, "no stale callbacks")
	var resumed: Control = Experiment.new()
	resumed.cause_light = true
	resumed.progress_path = game.progress_path
	root.add_child(resumed)
	check(resumed.completed.size() == 6 and resumed.campaign_id == "cause_light_v0_1", "H save reload")
	resumed.queue_free()
	for index: int in protected_paths.size():
		var path: String = protected_paths[index]
		var after: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else "<absent>"
		check(after == protected_contents[index], "existing campaign save unchanged")
	DirAccess.remove_absolute(game.progress_path)
	game.queue_free()
	await process_frame
	print("Cause & Light smoke: %d failures" % failures)
	quit(1 if failures else 0)
