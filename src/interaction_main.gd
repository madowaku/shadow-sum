extends "res://src/feel_polish_main.gd"

# SHADOW SUM v0.1.3 PICK → SLIDE → CLICK Interaction Pass
#
# Tap behavior stays unchanged. Dragging an occupied Post creates a temporary
# preview state: the real puzzle state is not committed until release.
# Shadows therefore follow the socket under the pointer without turning hover
# into a free solution-preview tool.

const DRAG_THRESHOLD := 9.0
const DRAG_GHOST_SIZE := 32.0
const PICK_COLOR := Color("#fff0bf")
const SNAP_COLOR := Color("#b7fbff")

var drag_candidate_index := -1
var drag_source_index := -1
var drag_target_index := -1
var drag_origin := Vector2.ZERO
var drag_pointer := Vector2.ZERO
var drag_active := false
var drag_ghost: PanelContainer


func _ready() -> void:
	super._ready()
	_build_drag_ghost()


func _input(event: InputEvent) -> void:
	if stage_solved or post_buttons.is_empty():
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_event.pressed:
			_pointer_down(mouse_event.position)
		else:
			_pointer_up(mouse_event.position)
		return

	if event is InputEventMouseMotion:
		_pointer_move((event as InputEventMouseMotion).position)
		return

	if event is InputEventScreenTouch:
		var touch_event := event as InputEventScreenTouch
		if touch_event.pressed:
			_pointer_down(touch_event.position)
		else:
			_pointer_up(touch_event.position)
		return

	if event is InputEventScreenDrag:
		_pointer_move((event as InputEventScreenDrag).position)


func _pointer_down(position: Vector2) -> void:
	if drag_active:
		return
	var index := _post_index_at(position)
	if index < 0 or not _post_is_occupied(index):
		drag_candidate_index = -1
		return

	drag_candidate_index = index
	drag_origin = position
	drag_pointer = position


func _pointer_move(position: Vector2) -> void:
	drag_pointer = position
	if drag_active:
		_update_drag_ghost(position)
		var hover_index := _post_index_at(position)
		if _is_valid_drag_target(hover_index) and hover_index != drag_target_index:
			_set_drag_target(hover_index)
		get_viewport().set_input_as_handled()
		return

	if drag_candidate_index < 0:
		return
	if position.distance_to(drag_origin) < DRAG_THRESHOLD:
		return

	_begin_post_drag(drag_candidate_index, position)
	get_viewport().set_input_as_handled()


func _pointer_up(position: Vector2) -> void:
	if drag_active:
		var release_index := _post_index_at(position)
		if not _is_valid_drag_target(release_index):
			release_index = drag_source_index
		_finish_post_drag(release_index)
		get_viewport().set_input_as_handled()
	else:
		drag_candidate_index = -1


func _begin_post_drag(index: int, pointer_position := Vector2(-1.0, -1.0)) -> bool:
	if drag_active or stage_solved or not _post_is_occupied(index):
		return false

	drag_active = true
	drag_candidate_index = -1
	drag_source_index = index
	drag_target_index = index

	if pointer_position.x < 0.0:
		pointer_position = _post_center(index)
	drag_pointer = pointer_position

	if drag_ghost != null:
		drag_ghost.visible = true
		drag_ghost.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_update_drag_ghost(pointer_position)
		var ghost_tween := create_tween()
		ghost_tween.tween_property(drag_ghost, "modulate", Color.WHITE, 0.07)
		drag_ghost.scale = Vector2(0.82, 0.82)
		ghost_tween.parallel().tween_property(drag_ghost, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_play_micro_tone(860.0, 1180.0, 0.055, 0.14, -18.0)
	_render_drag_preview(index)
	status_label.text = "PICKED  ·  slide to another socket"
	status_label.add_theme_color_override("font_color", PICK_COLOR)
	return true


func _set_drag_target(index: int) -> bool:
	if not drag_active or not _is_valid_drag_target(index):
		return false
	if index == drag_target_index:
		return true

	drag_target_index = index
	_render_drag_preview(index)

	# Tiny magnetic ticks make sockets feel physical without becoming a melody.
	var column := index % ShadowRules.BOARD_SIZE
	_play_micro_tone(470.0 + float(column) * 22.0, 520.0 + float(column) * 22.0, 0.030, 0.07, -27.0)
	return true


func _finish_post_drag(index: int) -> bool:
	if not drag_active:
		return false

	var source := drag_source_index
	var target := index if _is_valid_drag_target(index) else source
	var moved := target != source

	_hide_drag_ghost()
	_reset_drag_button_visuals()

	if not moved:
		_clear_drag_state()
		_update_all()
		_play_micro_tone(520.0, 410.0, 0.050, 0.09, -22.0)
		return false

	var before_shadow := ShadowRules.compute_shadow(posts)
	var source_r := source / ShadowRules.BOARD_SIZE
	var source_c := source % ShadowRules.BOARD_SIZE
	var target_r := target / ShadowRules.BOARD_SIZE
	var target_c := target % ShadowRules.BOARD_SIZE

	posts[source_r][source_c] = false
	posts[target_r][target_c] = true
	_clear_drag_state()
	_update_all()

	var target_button := post_buttons[target] as Button
	target_button.pivot_offset = target_button.size * 0.5
	target_button.scale = Vector2(0.84, 0.84)
	var settle := create_tween()
	settle.tween_property(target_button, "scale", Vector2(1.055, 1.055), 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	settle.tween_property(target_button, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_play_micro_tone(1120.0, 760.0, 0.060, 0.18, -14.0)
	_emit_drag_result_feedback(before_shadow)

	if stage_solved:
		_play_solve_beat()
		_play_solve_chime()
	return true


func _render_drag_preview(target: int) -> void:
	if not drag_active:
		return

	var preview: Array = posts.duplicate(true)
	var source_r := drag_source_index / ShadowRules.BOARD_SIZE
	var source_c := drag_source_index % ShadowRules.BOARD_SIZE
	preview[source_r][source_c] = false

	if target >= 0:
		var target_r := target / ShadowRules.BOARD_SIZE
		var target_c := target % ShadowRules.BOARD_SIZE
		preview[target_r][target_c] = true

	var shadow := ShadowRules.compute_shadow(preview)
	for r in ShadowRules.BOARD_SIZE:
		for c in ShadowRules.BOARD_SIZE:
			var cell_index := r * ShadowRules.BOARD_SIZE + c
			_update_live_cell(live_cells[cell_index], int(shadow[r][c]))
			_apply_post_button_style(post_buttons[cell_index], bool(preview[r][c]))
			var button := post_buttons[cell_index] as Button
			button.modulate = Color.WHITE
			button.scale = Vector2.ONE

	if target >= 0 and target < post_buttons.size():
		var target_button := post_buttons[target] as Button
		target_button.modulate = SNAP_COLOR if target != drag_source_index else PICK_COLOR
		target_button.pivot_offset = target_button.size * 0.5
		target_button.scale = Vector2(1.045, 1.045)

	counter_label.text = "POSTS  %d / %d  ·  MOVING" % [ShadowRules.count_posts(posts), int(stages[stage_index]["posts"])]
	status_label.text = "SLIDE  ·  release to click into place"
	status_label.add_theme_color_override("font_color", SNAP_COLOR)


func _emit_drag_result_feedback(before_shadow: Array) -> void:
	var after_shadow := ShadowRules.compute_shadow(posts)
	var overlap_cells: Array = []
	var match_cells: Array = []
	var highest_new_level := 0
	var clues: Array = stages[stage_index]["clues"]

	for r in ShadowRules.BOARD_SIZE:
		for c in ShadowRules.BOARD_SIZE:
			var before_value := int(before_shadow[r][c])
			var after_value := int(after_shadow[r][c])
			if before_value == after_value:
				continue

			var index := r * ShadowRules.BOARD_SIZE + c
			if after_value > before_value and after_value >= 2:
				overlap_cells.append(index)
				highest_new_level = maxi(highest_new_level, after_value)

			var clue := int(clues[r][c])
			if clue > 0 and after_value == clue:
				match_cells.append(index)

	if stage_solved:
		return
	if highest_new_level >= 2:
		_delayed_overlap_feedback(highest_new_level, overlap_cells)
	if not match_cells.is_empty():
		_delayed_match_feedback(match_cells)


func _is_valid_drag_target(index: int) -> bool:
	if index < 0 or index >= post_buttons.size() or drag_source_index < 0:
		return false
	if index == drag_source_index:
		return true
	return not _post_is_occupied(index)


func _post_is_occupied(index: int) -> bool:
	if index < 0 or index >= ShadowRules.BOARD_SIZE * ShadowRules.BOARD_SIZE:
		return false
	var r := index / ShadowRules.BOARD_SIZE
	var c := index % ShadowRules.BOARD_SIZE
	return bool(posts[r][c])


func _post_index_at(position: Vector2) -> int:
	for index in post_buttons.size():
		var button := post_buttons[index] as Button
		if button.get_global_rect().has_point(position):
			return index
	return -1


func _post_center(index: int) -> Vector2:
	if index < 0 or index >= post_buttons.size():
		return Vector2.ZERO
	var rect := (post_buttons[index] as Button).get_global_rect()
	return rect.position + rect.size * 0.5


func _build_drag_ghost() -> void:
	drag_ghost = PanelContainer.new()
	drag_ghost.name = "DragGhost"
	drag_ghost.custom_minimum_size = Vector2(DRAG_GHOST_SIZE, DRAG_GHOST_SIZE)
	drag_ghost.size = Vector2(DRAG_GHOST_SIZE, DRAG_GHOST_SIZE)
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	drag_ghost.z_index = 100
	drag_ghost.visible = false
	drag_ghost.add_theme_stylebox_override("panel", _panel_style(COLOR_GOLD_HOT, Color.WHITE, 2, int(DRAG_GHOST_SIZE * 0.5)))

	var dot := Label.new()
	dot.text = "●"
	dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dot.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dot.add_theme_color_override("font_color", Color("#182127"))
	dot.add_theme_font_size_override("font_size", 16)
	drag_ghost.add_child(dot)
	add_child(drag_ghost)


func _update_drag_ghost(position: Vector2) -> void:
	if drag_ghost == null:
		return
	drag_ghost.position = position - drag_ghost.size * 0.5


func _hide_drag_ghost() -> void:
	if drag_ghost != null:
		drag_ghost.visible = false
		drag_ghost.modulate = Color.WHITE
		drag_ghost.scale = Vector2.ONE


func _reset_drag_button_visuals() -> void:
	for button_value in post_buttons:
		var button := button_value as Button
		button.modulate = Color.WHITE
		button.scale = Vector2.ONE


func _clear_drag_state() -> void:
	drag_candidate_index = -1
	drag_source_index = -1
	drag_target_index = -1
	drag_active = false
