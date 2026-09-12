extends "res://src/interaction_main.gd"

# SHADOW SUM v0.1.3b MAGNETIC SNAP Tuning
#
# The interaction contract stays the same:
# - tap remains cheap,
# - drag preview never mutates authoritative puzzle state,
# - release commits once.
#
# This layer only makes PICK → SLIDE → CLICK more forgiving and tactile.

const SNAP_RADIUS_COMPACT := 31.0
const SNAP_RADIUS_DESKTOP := 34.0
const GHOST_LIFT_COMPACT := 18.0
const GHOST_LIFT_DESKTOP := 14.0
const SNAP_SCALE := 1.075
const SOURCE_DIM := Color(1.0, 1.0, 1.0, 0.42)
const SNAP_WARM := Color("#dfffff")

var snapped_pointer_index := -1


func _pointer_move(position: Vector2) -> void:
	drag_pointer = position
	if drag_active:
		var hover_index := _drag_target_at(position)
		snapped_pointer_index = hover_index
		_update_drag_ghost(position)
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
		var release_index := _drag_target_at(position)
		if not _is_valid_drag_target(release_index):
			release_index = drag_source_index
		_finish_post_drag(release_index)
		snapped_pointer_index = -1
		get_viewport().set_input_as_handled()
	else:
		drag_candidate_index = -1


func _begin_post_drag(index: int, pointer_position := Vector2(-1.0, -1.0)) -> bool:
	var started := super._begin_post_drag(index, pointer_position)
	if not started:
		return false

	snapped_pointer_index = index
	_apply_drag_socket_readability(index)
	_update_drag_ghost(drag_pointer)
	return true


func _set_drag_target(index: int) -> bool:
	var previous := drag_target_index
	var changed := super._set_drag_target(index)
	if not changed:
		return false

	_apply_drag_socket_readability(index)
	if index != previous and index >= 0 and index < post_buttons.size():
		var button := post_buttons[index] as Button
		button.pivot_offset = button.size * 0.5
		button.scale = Vector2(1.02, 1.02)
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(SNAP_SCALE, SNAP_SCALE), 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(button, "scale", Vector2(1.045, 1.045), 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return true


func _finish_post_drag(index: int) -> bool:
	var moved := super._finish_post_drag(index)
	snapped_pointer_index = -1
	return moved


func _drag_target_at(position: Vector2) -> int:
	# Exact socket hit always wins.
	var direct := _post_index_at(position)
	if _is_valid_drag_target(direct):
		return direct

	# Otherwise find the nearest valid socket inside a forgiving magnetic radius.
	var radius := SNAP_RADIUS_COMPACT if compact_layout else SNAP_RADIUS_DESKTOP
	var best_index := -1
	var best_distance := radius
	for index in post_buttons.size():
		if not _is_valid_drag_target(index):
			continue
		var distance := position.distance_to(_post_center(index))
		if distance <= best_distance:
			best_distance = distance
			best_index = index
	return best_index


func _update_drag_ghost(position: Vector2) -> void:
	if drag_ghost == null:
		return

	var lift := GHOST_LIFT_COMPACT if compact_layout else GHOST_LIFT_DESKTOP
	var visual_center := position - Vector2(0.0, lift)

	# When a socket has magnetic ownership, bias the floating Post slightly toward it.
	# Keep some pointer-follow so the piece still feels held rather than teleported.
	if snapped_pointer_index >= 0 and _is_valid_drag_target(snapped_pointer_index):
		var socket_center := _post_center(snapped_pointer_index) - Vector2(0.0, lift * 0.35)
		visual_center = visual_center.lerp(socket_center, 0.38)

	drag_ghost.position = visual_center - drag_ghost.size * 0.5
	drag_ghost.rotation = sin(Time.get_ticks_msec() * 0.008) * 0.018


func _apply_drag_socket_readability(target: int) -> void:
	# _render_drag_preview resets button modulation, so re-state the two important
	# locations after every magnetic target change: where the Post came from and
	# where it will land.
	if drag_source_index >= 0 and drag_source_index < post_buttons.size():
		var source_button := post_buttons[drag_source_index] as Button
		source_button.modulate = SOURCE_DIM
		source_button.scale = Vector2.ONE
	if target >= 0 and target < post_buttons.size():
		var target_button := post_buttons[target] as Button
		target_button.modulate = SNAP_WARM if target != drag_source_index else PICK_COLOR


func _hide_drag_ghost() -> void:
	super._hide_drag_ghost()
	if drag_ghost != null:
		drag_ghost.rotation = 0.0


func _reset_drag_button_visuals() -> void:
	super._reset_drag_button_visuals()
	snapped_pointer_index = -1
