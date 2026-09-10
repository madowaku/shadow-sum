extends SceneTree

const TARGET_SIZE := Vector2i(360, 800)

func _initialize() -> void:
	root.size = TARGET_SIZE
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Layout smoke: could not load main scene")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	if not scene.compact_layout:
		push_error("Layout smoke: 360x800 did not enter compact layout")
		quit(1)
		return

	var offenders: Array[String] = []
	_check_control_bounds(scene, Rect2(Vector2.ZERO, Vector2(TARGET_SIZE)), offenders)
	if not offenders.is_empty():
		push_error("Layout smoke: controls outside 360x800: %s" % ", ".join(offenders))
		quit(1)
		return

	if scene.clue_cells.is_empty() or scene.post_buttons.is_empty():
		push_error("Layout smoke: expected puzzle controls")
		quit(1)
		return

	var clue_cell := scene.clue_cells[0] as Control
	var post_button := scene.post_buttons[0] as Control
	if clue_cell.size.x > 30.5 or clue_cell.size.y > 30.5:
		push_error("Layout smoke: compact clue cell is too large: %s" % clue_cell.size)
		quit(1)
		return
	if post_button.size.x < 42.0 or post_button.size.y < 42.0:
		push_error("Layout smoke: compact post target is too small: %s" % post_button.size)
		quit(1)
		return

	# Ensure the compact pass did not break the core interaction path.
	scene._load_stage(0)
	scene._toggle_post(2, 2) # C3
	await create_timer(0.30).timeout
	if not scene.stage_solved:
		push_error("Layout smoke: Stage 001 did not solve at 360x800")
		quit(1)
		return

	print("Layout smoke OK: 360x800 fits and Stage 001 remains playable")
	quit(0)


func _check_control_bounds(node: Node, viewport_rect: Rect2, offenders: Array[String]) -> void:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if control.visible:
				var rect := control.get_global_rect()
				var epsilon := 1.5
				if rect.position.x < -epsilon or rect.position.y < -epsilon or rect.end.x > viewport_rect.end.x + epsilon or rect.end.y > viewport_rect.end.y + epsilon:
					offenders.append("%s:%s" % [control.name, rect])
		_check_control_bounds(child, viewport_rect, offenders)
