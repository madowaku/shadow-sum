extends "res://src/magnetic_main.gd"

# SHADOW SUM v0.1.4 ONE MORE PUZZLE Flow
#
# Solving should feel complete, but never interrupt the player's momentum.
# The existing full-shadow reveal remains the hero moment. This layer only
# adds a short viewing beat, then turns NEXT into an inviting continuation.

const SOLVE_BREATH := 0.45
const NEXT_PULSE_SCALE := 1.055

var solve_flow_serial := 0


func _load_stage(index: int) -> void:
	solve_flow_serial += 1
	super._load_stage(index)
	_restore_next_button_resting_state()


func _reset_stage() -> void:
	solve_flow_serial += 1
	super._reset_stage()
	_restore_next_button_resting_state()


func _play_solve_beat() -> void:
	# Preserve the optical payoff first.
	super._play_solve_beat()

	if next_button == null:
		return

	# The solution exists immediately, but give the complete shadow a tiny moment
	# to be seen before inviting another problem.
	solve_flow_serial += 1
	var serial := solve_flow_serial
	next_button.disabled = true
	next_button.text = "COMPLETE  ◐"
	next_button.modulate = Color(1.0, 1.0, 1.0, 0.58)
	_release_next_after_breath(serial)


func _release_next_after_breath(serial: int) -> void:
	await get_tree().create_timer(SOLVE_BREATH).timeout
	if serial != solve_flow_serial or not stage_solved or next_button == null:
		return

	if stage_index >= stages.size() - 1:
		next_button.text = "FINISH  ◐"
	else:
		next_button.text = "NEXT SHADOW  ›"
	next_button.disabled = false
	next_button.pivot_offset = next_button.size * 0.5
	next_button.modulate = Color.WHITE
	next_button.scale = Vector2(0.94, 0.94)

	var tween := create_tween()
	tween.tween_property(next_button, "scale", Vector2(NEXT_PULSE_SCALE, NEXT_PULSE_SCALE), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(next_button, "scale", Vector2.ONE, 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var glow := create_tween()
	glow.tween_property(next_button, "modulate", COLOR_GOLD_HOT, 0.08)
	glow.tween_property(next_button, "modulate", Color.WHITE, 0.20)


func _restore_next_button_resting_state() -> void:
	if next_button == null:
		return
	next_button.text = "NEXT  ›"
	next_button.scale = Vector2.ONE
	next_button.modulate = Color.WHITE
