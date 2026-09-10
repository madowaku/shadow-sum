extends SceneTree

const COMPACT_LOGICAL_SIZE := Vector2i(405, 900)
const DESKTOP_LOGICAL_SIZE := Vector2i(720, 900)

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Layout smoke: could not load main scene")
		quit(1)
		return

	if not await _run_case(packed, COMPACT_LOGICAL_SIZE, true, true):
		quit(1)
		return
	if not await _run_case(packed, DESKTOP_LOGICAL_SIZE, false, false):
		quit(1)
		return

	print("Layout smoke OK: compact 405x900 and desktop 720x900 both fit")
	quit(0)


func _run_case(packed: PackedScene, logical_size: Vector2i, expect_compact: bool, exercise_stage: bool) -> bool:
	var viewport := SubViewport.new()
	viewport.size = logical_size
	viewport.disable_3d = true
	root.add_child(viewport)

	var scene := packed.instantiate()
	viewport.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var visible_rect := scene.get_viewport().get_visible_rect()
	if scene.compact_layout != expect_compact:
		push_error("Layout smoke: compact=%s expected=%s at %s; visible=%s" % [scene.compact_layout, expect_compact, logical_size, visible_rect])
		viewport.queue_free()
		return false

	var offenders: Array[String] = []
	_check_control_bounds(scene, visible_rect, offenders)
	if not offenders.is_empty():
		push_error("Layout smoke: controls outside %s logical canvas: %s" % [logical_size, ", ".join(offenders)])
		viewport.queue_free()
		return false

	if scene.clue_cells.is_empty() or scene.post_buttons.is_empty():
		push_error("Layout smoke: expected puzzle controls at %s" % logical_size)
		viewport.queue_free()
		return false

	var clue_cell := scene.clue_cells[0] as Control
	var post_button := scene.post_buttons[0] as Control
	if expect_compact:
		if clue_cell.size.x > 34.0 or clue_cell.size.y > 34.0:
			push_error("Layout smoke: compact clue cell is too large: %s" % clue_cell.size)
			viewport.queue_free()
			return false
		if post_button.size.x < 47.0 or post_button.size.y < 47.0:
			push_error("Layout smoke: compact post target is too small: %s" % post_button.size)
			viewport.queue_free()
			return false
	else:
		if clue_cell.size.x < 47.0 or post_button.size.x < 57.0:
			push_error("Layout smoke: desktop controls were unexpectedly compact: clue=%s post=%s" % [clue_cell.size, post_button.size])
			viewport.queue_free()
			return false

	if exercise_stage:
		scene._load_stage(0)
		scene._toggle_post(2, 2) # C3
		await create_timer(0.30).timeout
		if not scene.stage_solved:
			push_error("Layout smoke: Stage 001 did not solve at compact size")
			viewport.queue_free()
			return false

	viewport.queue_free()
	await process_frame
	return true


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
