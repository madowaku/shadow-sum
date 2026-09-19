extends SceneTree

# Optional rendered QA: run with --fixed-fps 60 (without --headless).
# Output is supplied explicitly; captures never enter the source tree.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var directory: String = OS.get_environment("SHADOW_SUM_CAPTURE_DIR")
	if directory.is_empty():
		push_error("Set SHADOW_SUM_CAPTURE_DIR for rendered QA")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(directory)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(405, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	viewport.add_child(scene)
	await process_frame
	await process_frame
	scene._load_stage(2)
	for frame in 330:
		match frame:
			12: scene._toggle_post(1, 2)
			36: scene._toggle_post(2, 1)
			60: scene._toggle_post(2, 3)
			96: scene._load_stage(3)
			108: scene._toggle_post(1, 1)
			120: scene._toggle_post(1, 3)
			132: scene._toggle_post(2, 4)
			156: scene._toggle_post(3, 3)
			204: scene._reset_stage()
			216: scene._toggle_post(1, 1)
			228: scene._begin_post_drag(6, scene._post_center(6))
			231: scene._pointer_move(scene._post_center(7))
			234: scene._pointer_move(scene._post_center(8))
			237: scene._pointer_move(scene._post_center(9))
			240: scene._finish_post_drag(6)
			258: scene._begin_post_drag(6, scene._post_center(6))
			261: scene._pointer_move(scene._post_center(7))
			270: scene._finish_post_drag(7)
		await process_frame
		await RenderingServer.frame_post_draw
		if frame % 3 == 0:
			var picture: Image = viewport.get_texture().get_image()
			picture.save_png(directory.path_join("frame_%03d.png" % frame))
	print("Rendered SHADOW INK QA: 110 frames at 405x900")
	viewport.queue_free()
	await process_frame
	quit(0)
