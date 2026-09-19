extends "res://src/shadow_ink_main.gd"

# Notation teaching only. This flag is intentionally session-local, never saved.
var unknown_intro_shown_this_session: bool = false
var unknown_intro_serial: int = 0
var unknown_intro_active: bool = false
var unknown_intro_beat: int = 0
var unknown_clear_index: int = -1
var unknown_fog_index: int = -1

func _load_stage(index: int) -> void:
	_cancel_unknown_intro(false)
	super._load_stage(index)
	_maybe_start_unknown_intro()

func _maybe_start_unknown_intro() -> void:
	if unknown_intro_shown_this_session or stages.is_empty() or stage_solved:
		return
	if int(stages[stage_index]["id"]) != 4:
		return
	unknown_clear_index = -1
	unknown_fog_index = -1
	var clues: Array = stages[stage_index]["clues"]
	for r in ShadowRules.BOARD_SIZE:
		for c in ShadowRules.BOARD_SIZE:
			var clue: int = int(clues[r][c])
			var index: int = r * ShadowRules.BOARD_SIZE + c
			if clue == 0 and unknown_clear_index < 0:
				unknown_clear_index = index
			if clue == -1 and unknown_fog_index < 0:
				unknown_fog_index = index
	if unknown_clear_index < 0 or unknown_fog_index < 0:
		return
	# Consume the session opportunity before the delay: early input cancels it too.
	unknown_intro_shown_this_session = true
	unknown_intro_active = true
	unknown_intro_serial += 1
	_run_unknown_intro(unknown_intro_serial)

func _unknown_intro_current(serial: int) -> bool:
	return unknown_intro_active and serial == unknown_intro_serial and not stage_solved and int(stages[stage_index]["id"]) == 4

func _run_unknown_intro(serial: int) -> void:
	await get_tree().create_timer(0.12).timeout
	if not _unknown_intro_current(serial):
		return
	_show_unknown_beat(1, unknown_clear_index)
	await get_tree().create_timer(1.0).timeout
	if not _unknown_intro_current(serial):
		return
	_show_unknown_beat(2, unknown_fog_index)
	await get_tree().create_timer(1.2).timeout
	if not _unknown_intro_current(serial):
		return
	_show_unknown_beat(3, unknown_fog_index)
	await get_tree().create_timer(0.8).timeout
	if _unknown_intro_current(serial):
		_cancel_unknown_intro(true)

func _show_unknown_beat(beat: int, index: int) -> void:
	unknown_intro_beat = beat
	_set_unknown_copy()
	(clue_glass_visuals[index] as Control).emphasize_notation(0.36 if beat == 3 else 0.52)

func _set_unknown_copy() -> void:
	var copy: String = "CLEAR GLASS  =  NO SHADOW"
	if unknown_intro_beat == 2:
		copy = "FOGGED GLASS  =  SHADOW UNOBSERVED"
		var font: Font = status_label.get_theme_font("font")
		var font_size: int = status_label.get_theme_font_size("font_size")
		if font.get_string_size(copy, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > status_label.size.x:
			copy = "FOGGED  =  UNOBSERVED"
	elif unknown_intro_beat == 3:
		copy = "UNKNOWN  ≠  ZERO"
	status_label.text = copy

func _cancel_unknown_intro(restore_status: bool) -> void:
	var was_active: bool = unknown_intro_active
	unknown_intro_serial += 1
	unknown_intro_active = false
	unknown_intro_beat = 0
	for index in [unknown_clear_index, unknown_fog_index]:
		if index >= 0 and index < clue_glass_visuals.size():
			(clue_glass_visuals[index] as Control).clear_notation_emphasis()
	if was_active and restore_status and status_label != null:
		# Use the established status/navigation path, not a cached copy.
		_update_all()

func _toggle_post(r: int, c: int) -> void:
	_cancel_unknown_intro(true)
	super._toggle_post(r, c)

func _begin_post_drag(index: int, pointer_position: Vector2 = Vector2(-1.0, -1.0)) -> bool:
	_cancel_unknown_intro(true)
	return super._begin_post_drag(index, pointer_position)

func _reset_stage() -> void:
	_cancel_unknown_intro(false)
	super._reset_stage()

func _go_previous_stage() -> void:
	_cancel_unknown_intro(true)
	super._go_previous_stage()

func _next_stage() -> void:
	_cancel_unknown_intro(true)
	super._next_stage()

func _on_hint_pressed() -> void:
	_cancel_unknown_intro(true)
	super._on_hint_pressed()

func _play_solve_materials() -> void:
	_cancel_unknown_intro(false)
	super._play_solve_materials()

func _apply_responsive_layout() -> void:
	super._apply_responsive_layout()
	if unknown_intro_active and unknown_intro_beat > 0:
		_set_unknown_copy()
