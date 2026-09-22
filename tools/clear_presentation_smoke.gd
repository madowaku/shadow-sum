extends "res://tools/grant20_v03_smoke.gd"

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.grant20_v03 = true
	game.progress_path = "user://clear_presentation_smoke_only.json"
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	game.load_stage(0)
	await process_frame
	await process_frame
	_solve_current()
	check(game.completed.has("GR01"), "solve persists before animation finishes")
	check(game.next_button.disabled, "next waits for alignment")
	game.reset_stage()
	await create_timer(1.1).timeout
	check(not game.clear_seal.visible and game.status_label.text.is_empty(), "reset cancels presentation")
	check(game.next_button.disabled, "cancelled animation cannot enable NEXT")
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(720, 900)]:
		root.size = dimensions
		game.load_stage(19)
		await process_frame
		await process_frame
		_solve_current()
		await create_timer(1.1).timeout
		check(game.status_label.text.begins_with("CALIBRATION COMPLETE"), "final stage title")
		check(game.next_button.text == "REPLAY" and not game.next_button.disabled, "final action")
		_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("user://clear_%d.png" % dimensions.x)
		game.next_stage()
		check(game.stage_index == 0 and not game.stage_solved, "replay starts clean")
		check(not game.clear_seal.visible, "replay removes seal")
	print("Clear presentation smoke: %d failures" % failures)
	quit(1 if failures > 0 else 0)
