extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	var game: Control = load("res://src/experiment_main.gd").new()
	game.progress_path = "user://experiment_capture_only.json"
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	for stage_number: int in [0, 3, 4, 5, 9]:
		game.load_stage(stage_number)
		if stage_number == 3:
			game.toggle_post(12)
		if stage_number == 5:
			game.toggle_post(11)
		if stage_number == 9:
			game.toggle_post(8)
			game.move_shutter(1)
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		var output: String = OS.get_environment("SHADOW_SUM_CAPTURE_DIR")
		if not output.is_empty():
			root.get_texture().get_image().save_png(output.path_join("G%02d.png" % (stage_number + 1)))
	game.queue_free()
	await process_frame
	quit()
