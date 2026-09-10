extends SceneTree

const TARGET_WINDOW_SIZE := Vector2i(360, 800)

func _initialize() -> void:
	root.size = TARGET_WINDOW_SIZE
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

	var visible_rect := scene.get_viewport().get_visible_rect()
	if not scene.compact_layout:
		push_error("Layout smoke: 360x800 window did not enter compact layout; visible rect=%s" % visible_rect)
		quit(1)
		return

	# canvas_items + expand uses logical canvas coordinates. At a 360x800 window,
	# the 405x900 base canvas scales uniformly while preserving the 9:20 aspect.
	if absf(visible_rect.size.x - 405.0) > 2.0 or absf(visible_rect.size.y - 900.0) > 2.0:
		push_error("Layout smoke: unexpected logical canvas for 360x800: %s" % visible_rect.size)
		quit(1)
		return

	var offenders: Array[String] = []
	_check_control_bounds(scene, visible_rect, offenders)
	if not offenders.is_empty():
		push_error("Layout smoke: controls outside logical 360x800 canvas: %s" % ", ".join(offenders))
		quit(1)
		return

	if scene.clue_cells.is_empty() or scene.post_buttons.is_empty():
		push_error("Layout smoke: expected puzzle controls")
		quit(1)
		return

	var clue_cell := scene.clue_cells[0] as Control
	var post_button := scene.post_buttons[0] as Control
	if clue_cell.size.x > 34.0 or clue_cell.size.y > 34.0:
		push_error("Layout smoke: compact clue cell is too large: %s" % clue_cell.size)
		quit(1)
		return
	if post_button.size.x < 47.0 or post_button.size.y < 47.0:
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

	print("Layout smoke OK: 360x800 -> 405x900 logical canvas fits and Stage 001 remains playable")
	quit(0)


func _check_control_bounds(node: Node, viewport_rect: Rect2, offenders: Array[String]) -> void:
	for child in node.get_children():
		if child is Control:
			var control := child as Control
			if control.visible:
				var rect := control.get_global_rect()
				var epsilon := 1.5
				if rect.position.x < viewport_rect.position.x - epsilon or rect.position.y < viewport_rect.position.y - epsilon or rect.end.x > viewport_rect.end.x + epsilon or rect.end.y > viewport_rect.end.y + epsilon:
					offenders.append("%s:%s" % [control.name, rect])
		_check_control_bounds(child, viewport_rect, offenders)
