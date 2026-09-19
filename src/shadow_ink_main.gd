extends "res://src/glass_metal_main.gd"

# Only presentation state lives here. All input, solve, hints and save calls
# continue through the existing inheritance chain.
var ink_immediate: bool = true
var presentation_serial: int = 0
var ink_revealing: bool = false

func _ready() -> void:
	super._ready()
	ink_immediate = false

func _load_stage(index: int) -> void:
	_cancel_ink_presentation()
	super._load_stage(index)
	ink_immediate = false

func _reset_stage() -> void:
	_cancel_ink_presentation()
	super._reset_stage()
	ink_immediate = false

func _cancel_ink_presentation() -> void:
	presentation_serial += 1
	ink_immediate = true
	ink_revealing = false
	if not posts.is_empty():
		_hide_drag_ghost()
		_reset_drag_button_visuals()
	_clear_drag_state()
	for visual in clue_glass_visuals + live_glass_visuals + post_visuals:
		if is_instance_valid(visual):
			visual.cancel_motion()
	for cell in live_cells:
		var old_tween: Tween = cell.get_meta("semantic_tween") as Tween if cell.has_meta("semantic_tween") else null
		if old_tween != null and old_tween.is_valid():
			old_tween.kill()
		cell.set_meta("shadow_level", -1)

func _ensure_glass_visual(cell: PanelContainer, target_surface: bool, index: int) -> Control:
	var visual: Control = super._ensure_glass_visual(cell, target_surface, index)
	visual.motion_enabled = true
	visual.immediate_updates = ink_immediate
	visual.preview_updates = drag_active
	return visual

func _update_clue_cell(cell: PanelContainer, clue: int) -> void:
	if ink_revealing and stage_solved:
		return
	super._update_clue_cell(cell, clue)

func _apply_glass_metal_skin() -> void:
	if not ink_revealing:
		super._apply_glass_metal_skin()

func _animate_post_press(r: int, c: int, adding: bool) -> void:
	if adding:
		(post_visuals[r * 5 + c] as Control).mechanical_seat()

func _animate_drag_seat(target: int) -> void:
	(post_visuals[target] as Control).mechanical_seat()

func _animate_socket_capture(_button: Button) -> void:
	# SocketVisual's active rim already supplies magnetic ownership feedback.
	pass

func _animate_live_settle(_cell: PanelContainer, _value: int, _previous: int) -> void:
	# Keep glass stationary; the existing StyleBox still owns semantic color.
	pass

func _animate_shadow_projection(_r: int, _c: int, _adding: bool) -> void:
	# Material seep replaces the old panel scale wipe.
	pass

func _delayed_match_feedback(_indices: Array) -> void:
	# Material depth supplies the quiet visual confirmation.
	pass

func _delayed_overlap_feedback(level: int, _indices: Array) -> void:
	var serial: int = presentation_serial
	await get_tree().create_timer(0.085).timeout
	if serial != presentation_serial:
		return
	# Preserve existing audio; remove only the competing cell squash/flash.
	if level >= 3:
		_play_micro_tone(132.0, 92.0, 0.125, 0.24, -10.0)
	else:
		_play_micro_tone(245.0, 185.0, 0.085, 0.19, -13.0)

func _play_solve_materials() -> void:
	_reveal_hidden_target_cells()

func _reveal_hidden_target_cells() -> void:
	ink_revealing = true
	# Preserve the authored full-shadow reveal, including alternative solutions.
	var solution: Array = ShadowRules.make_empty_posts()
	for code_value in stages[stage_index]["solution"]:
		var code: String = String(code_value)
		solution[int(code.substr(1)) - 1][code.unicode_at(0) - 65] = true
	var shadow: Array = ShadowRules.compute_shadow(solution)
	var rank: int = 0
	for index in clue_cells.size():
		var r: int = index / 5
		var c: int = index % 5
		if int(stages[stage_index]["clues"][r][c]) >= 0:
			continue
		var cell: PanelContainer = clue_cells[index] as PanelContainer
		var visual: Control = clue_glass_visuals[index] as Control
		cell.add_theme_stylebox_override("panel", _shadow_style(int(shadow[r][c]), false, true))
		(cell.get_child(0) as Label).text = ""
		# Bound even a future fully-hidden board to 0.43s, inside flow's 0.45s.
		visual.reveal_density(int(shadow[r][c]), minf(float(rank) * 0.012, 0.20))
		rank += 1
