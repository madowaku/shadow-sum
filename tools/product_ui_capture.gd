extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory: String = OS.get_environment("SHADOW_SUM_CAPTURE_DIR")
	if directory.is_empty():
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	for width: int in [360, 390, 405, 720]:
		var viewport: SubViewport = SubViewport.new()
		viewport.size = Vector2i(width, 800 if width == 360 else (844 if width == 390 else 900))
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var game: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate()
		game.progress_path = directory.path_join("capture_%d_%d.json" % [width, Time.get_ticks_usec()])
		viewport.add_child(game)
		game._load_stage(0)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(directory.path_join("start_%d.png" % width))
		var column: VBoxContainer = game.get_child(1).get_child(0)
		for child: Control in column.get_children():
			print("UI %d %s %s" % [width, child.get_class(), child.get_global_rect()])
		game.product_ui.open_help()
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(directory.path_join("help_%d.png" % width))
		game.product_ui.close_help()
		game._toggle_post(2, 2)
		await create_timer(0.6).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(directory.path_join("solved_%d.png" % width))
		game._load_stage(3)
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(directory.path_join("fog_%d.png" % width))
		viewport.queue_free()
		await process_frame
	quit()
