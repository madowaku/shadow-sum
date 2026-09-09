extends Control

const ShadowRules = preload("res://src/shadow_rules.gd")
const STAGE_PATH := "res://data/stages_v0_1.json"

const CELL_SIZE := 48.0
const POST_CELL_SIZE := 58.0

const COLOR_BG := Color("#071017")
const COLOR_PANEL := Color("#0d1a22")
const COLOR_PANEL_2 := Color("#10232c")
const COLOR_LINE := Color("#26434c")
const COLOR_TEXT := Color("#d9ebed")
const COLOR_MUTED := Color("#78949a")
const COLOR_CYAN := Color("#75d8df")
const COLOR_CYAN_HOT := Color("#b7fbff")
const COLOR_GOLD := Color("#e6b86b")
const COLOR_GOLD_HOT := Color("#ffe0a0")
const COLOR_DANGER := Color("#ef8d82")

var stages: Array = []
var stage_index := 0
var posts: Array = []
var clue_cells: Array = []
var live_cells: Array = []
var post_buttons: Array = []
var emitter_labels: Dictionary = {}

var stage_label: Label
var counter_label: Label
var status_label: Label
var next_button: Button
var reset_button: Button
var stage_solved := false

func _ready() -> void:
	_load_stages()
	_build_ui()
	_load_stage(0)

func _load_stages() -> void:
	var file := FileAccess.open(STAGE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open stage data: %s" % STAGE_PATH)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Array:
		stages = parsed
	else:
		push_error("Stage JSON root must be an array.")

func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.color = COLOR_BG
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	var title := Label.new()
	title.text = "SHADOW SUM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", COLOR_TEXT)
	title.add_theme_font_size_override("font_size", 29)
	root.add_child(title)

	stage_label = Label.new()
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_color_override("font_color", COLOR_GOLD)
	stage_label.add_theme_font_size_override("font_size", 16)
	root.add_child(stage_label)

	counter_label = Label.new()
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter_label.add_theme_color_override("font_color", COLOR_MUTED)
	counter_label.add_theme_font_size_override("font_size", 13)
	root.add_child(counter_label)

	var screens := HBoxContainer.new()
	screens.alignment = BoxContainer.ALIGNMENT_CENTER
	screens.add_theme_constant_override("separation", 24)
	root.add_child(screens)

	screens.add_child(_build_shadow_screen("TARGET", clue_cells, COLOR_GOLD, true))
	screens.add_child(_build_shadow_screen("LIVE SHADOW", live_cells, COLOR_CYAN, false))

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 4
	root.add_child(spacer)

	var instrument := VBoxContainer.new()
	instrument.alignment = BoxContainer.ALIGNMENT_CENTER
	instrument.add_theme_constant_override("separation", 5)
	root.add_child(instrument)

	var north := _make_emitter("N  ◉  LIGHT", "N")
	north.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	instrument.add_child(north)

	var arrow_down := Label.new()
	arrow_down.text = "↓"
	arrow_down.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow_down.add_theme_color_override("font_color", COLOR_MUTED)
	arrow_down.add_theme_font_size_override("font_size", 18)
	instrument.add_child(arrow_down)

	var table_row := HBoxContainer.new()
	table_row.alignment = BoxContainer.ALIGNMENT_CENTER
	table_row.add_theme_constant_override("separation", 12)
	instrument.add_child(table_row)

	var west := _make_emitter("W\n◉  →", "W")
	west.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	west.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	table_row.add_child(west)

	var board_panel := PanelContainer.new()
	board_panel.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL_2, COLOR_LINE, 1, 14))
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 10)
	board_margin.add_theme_constant_override("margin_right", 10)
	board_margin.add_theme_constant_override("margin_top", 10)
	board_margin.add_theme_constant_override("margin_bottom", 10)
	board_panel.add_child(board_margin)
	var post_grid := GridContainer.new()
	post_grid.columns = ShadowRules.BOARD_SIZE
	post_grid.add_theme_constant_override("h_separation", 4)
	post_grid.add_theme_constant_override("v_separation", 4)
	board_margin.add_child(post_grid)
	_build_post_grid(post_grid)
	table_row.add_child(board_panel)

	var east := _make_emitter("E\n←  ◉", "E")
	east.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	east.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	table_row.add_child(east)

	var table_caption := Label.new()
	table_caption.text = "PLACEMENT BOARD"
	table_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	table_caption.add_theme_color_override("font_color", COLOR_MUTED)
	table_caption.add_theme_font_size_override("font_size", 11)
	instrument.add_child(table_caption)

	status_label = Label.new()
	status_label.custom_minimum_size.y = 28
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", COLOR_TEXT)
	status_label.add_theme_font_size_override("font_size", 15)
	root.add_child(status_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	root.add_child(buttons)

	reset_button = Button.new()
	reset_button.text = "RESET"
	_style_footer_button(reset_button, false)
	reset_button.pressed.connect(_reset_stage)
	buttons.add_child(reset_button)

	next_button = Button.new()
	next_button.text = "NEXT  ›"
	_style_footer_button(next_button, true)
	next_button.disabled = true
	next_button.pressed.connect(_next_stage)
	buttons.add_child(next_button)

	var legend := Label.new()
	legend.text = "bright  →  light shadow  →  double  →  full shadow"
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	legend.add_theme_color_override("font_color", COLOR_MUTED)
	legend.add_theme_font_size_override("font_size", 11)
	root.add_child(legend)

func _build_shadow_screen(title_text: String, store: Array, accent: Color, is_target: bool) -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 5)

	var label := Label.new()
	label.text = title_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", accent)
	label.add_theme_font_size_override("font_size", 12)
	column.add_child(label)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", _panel_style(COLOR_PANEL, accent.darkened(0.45), 1, 12))
	column.add_child(frame)

	var frame_margin := MarginContainer.new()
	frame_margin.add_theme_constant_override("margin_left", 8)
	frame_margin.add_theme_constant_override("margin_right", 8)
	frame_margin.add_theme_constant_override("margin_top", 8)
	frame_margin.add_theme_constant_override("margin_bottom", 8)
	frame.add_child(frame_margin)

	var grid := GridContainer.new()
	grid.columns = ShadowRules.BOARD_SIZE
	grid.add_theme_constant_override("h_separation", 3)
	grid.add_theme_constant_override("v_separation", 3)
	frame_margin.add_child(grid)
	_build_screen_grid(grid, store, is_target)
	return column

func _build_screen_grid(grid: GridContainer, store: Array, is_target: bool) -> void:
	for _i in ShadowRules.BOARD_SIZE * ShadowRules.BOARD_SIZE:
		var cell := PanelContainer.new()
		cell.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cell.add_theme_stylebox_override("panel", _shadow_style(0, false, is_target))

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", COLOR_MUTED)
		label.add_theme_font_size_override("font_size", 19)
		cell.add_child(label)
		grid.add_child(cell)
		store.append(cell)

func _build_post_grid(grid: GridContainer) -> void:
	for i in ShadowRules.BOARD_SIZE * ShadowRules.BOARD_SIZE:
		var r := i / ShadowRules.BOARD_SIZE
		var c := i % ShadowRules.BOARD_SIZE
		var button := Button.new()
		button.custom_minimum_size = Vector2(POST_CELL_SIZE, POST_CELL_SIZE)
		button.text = ""
		button.tooltip_text = "%s%d" % [String.chr(65 + c), r + 1]
		button.focus_mode = Control.FOCUS_NONE
		button.pivot_offset = Vector2(POST_CELL_SIZE * 0.5, POST_CELL_SIZE * 0.5)
		button.pressed.connect(_toggle_post.bind(r, c))
		grid.add_child(button)
		post_buttons.append(button)
		_apply_post_button_style(button, false)

func _make_emitter(text_value: String, key: String) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(64, 42)
	label.add_theme_color_override("font_color", COLOR_CYAN)
	label.add_theme_font_size_override("font_size", 12)
	emitter_labels[key] = label
	return label

func _load_stage(index: int) -> void:
	if stages.is_empty():
		return
	stage_index = clampi(index, 0, stages.size() - 1)
	posts = ShadowRules.make_empty_posts()
	stage_solved = false
	var stage: Dictionary = stages[stage_index]
	stage_label.text = "%03d  %s  ·  %s" % [int(stage["id"]), String(stage["title"]), String(stage["tier"])]
	next_button.disabled = true
	_reset_screen_transforms()
	_update_all()

func _reset_stage() -> void:
	posts = ShadowRules.make_empty_posts()
	stage_solved = false
	next_button.disabled = true
	_reset_screen_transforms()
	_update_all()

func _next_stage() -> void:
	if stage_index >= stages.size() - 1:
		status_label.text = "v0.1 COMPLETE  ◐"
		return
	_load_stage(stage_index + 1)

func _toggle_post(r: int, c: int) -> void:
	if stage_solved:
		return
	var stage: Dictionary = stages[stage_index]
	var required := int(stage["posts"])
	var adding := not bool(posts[r][c])
	if adding and ShadowRules.count_posts(posts) >= required:
		status_label.text = "All posts are in use. Tap one to move it."
		_flash_status(COLOR_DANGER)
		return

	posts[r][c] = adding
	var was_solved := stage_solved
	_update_all()
	_animate_post_press(r, c, adding)
	_animate_shadow_projection(r, c, adding)

	if stage_solved and not was_solved:
		_play_solve_beat()

func _update_all() -> void:
	if stages.is_empty():
		return
	var stage: Dictionary = stages[stage_index]
	var clues: Array = stage["clues"]
	var shadow := ShadowRules.compute_shadow(posts)
	var required := int(stage["posts"])
	var placed := ShadowRules.count_posts(posts)

	counter_label.text = "POSTS  %d / %d" % [placed, required]

	for r in ShadowRules.BOARD_SIZE:
		for c in ShadowRules.BOARD_SIZE:
			var i := r * ShadowRules.BOARD_SIZE + c
			var clue := int(clues[r][c])
			_update_clue_cell(clue_cells[i], clue)
			_update_live_cell(live_cells[i], int(shadow[r][c]))
			_apply_post_button_style(post_buttons[i], bool(posts[r][c]))
			post_buttons[i].disabled = stage_solved

	var shadows_match := ShadowRules.matches_visible_clues(shadow, clues)
	stage_solved = placed == required and shadows_match
	next_button.disabled = not stage_solved

	if stage_solved:
		status_label.text = "SHADOW COMPLETE"
		status_label.add_theme_color_override("font_color", COLOR_GOLD_HOT)
		for button in post_buttons:
			button.disabled = true
	elif int(stage["id"]) == 1 and placed == 0:
		status_label.text = "Tap a socket. Watch where its three shadows go."
		status_label.add_theme_color_override("font_color", COLOR_TEXT)
	elif int(stage["id"]) == 1:
		status_label.text = "Move the post until LIVE SHADOW matches TARGET."
		status_label.add_theme_color_override("font_color", COLOR_TEXT)
	elif placed == required:
		status_label.text = "Close. Move a post and watch the light recompute."
		status_label.add_theme_color_override("font_color", COLOR_TEXT)
	else:
		status_label.text = "Shape the observed shadow."
		status_label.add_theme_color_override("font_color", COLOR_TEXT)

func _update_clue_cell(cell: PanelContainer, clue: int) -> void:
	var label := cell.get_child(0) as Label
	if clue < 0:
		cell.add_theme_stylebox_override("panel", _shadow_style(0, true, true))
		label.text = "?"
		label.add_theme_color_override("font_color", COLOR_MUTED)
	else:
		cell.add_theme_stylebox_override("panel", _shadow_style(clue, false, true))
		label.text = ""

func _update_live_cell(cell: PanelContainer, value: int) -> void:
	var label := cell.get_child(0) as Label
	cell.add_theme_stylebox_override("panel", _shadow_style(value, false, false))
	label.text = ""

func _apply_post_button_style(button: Button, occupied: bool) -> void:
	if occupied:
		button.text = "●"
		button.add_theme_color_override("font_color", Color("#162129"))
		button.add_theme_font_size_override("font_size", 24)
		button.add_theme_stylebox_override("normal", _panel_style(COLOR_GOLD, COLOR_GOLD_HOT, 2, 13))
		button.add_theme_stylebox_override("hover", _panel_style(COLOR_GOLD_HOT, Color.WHITE, 2, 13))
		button.add_theme_stylebox_override("pressed", _panel_style(COLOR_GOLD.darkened(0.16), COLOR_GOLD_HOT, 2, 13))
	else:
		button.text = "·"
		button.add_theme_color_override("font_color", COLOR_LINE.lightened(0.2))
		button.add_theme_font_size_override("font_size", 22)
		button.add_theme_stylebox_override("normal", _panel_style(Color("#0c1820"), COLOR_LINE, 1, 12))
		button.add_theme_stylebox_override("hover", _panel_style(Color("#17313a"), COLOR_CYAN.darkened(0.25), 2, 12))
		button.add_theme_stylebox_override("pressed", _panel_style(Color("#1d3d47"), COLOR_CYAN, 2, 12))

func _animate_post_press(r: int, c: int, adding: bool) -> void:
	var i := r * ShadowRules.BOARD_SIZE + c
	var button: Button = post_buttons[i]
	button.scale = Vector2(0.82, 0.82) if adding else Vector2(1.10, 1.10)
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_shadow_projection(r: int, c: int, adding: bool) -> void:
	var projections: Array = [
		{"r": r + 1, "c": c, "emitter": "N", "direction": "down", "delay": 0.00},
		{"r": r, "c": c + 1, "emitter": "W", "direction": "right", "delay": 0.035},
		{"r": r, "c": c - 1, "emitter": "E", "direction": "left", "delay": 0.070},
	]
	for projection in projections:
		var pr := int(projection["r"])
		var pc := int(projection["c"])
		if pr < 0 or pr >= ShadowRules.BOARD_SIZE or pc < 0 or pc >= ShadowRules.BOARD_SIZE:
			continue
		var index := pr * ShadowRules.BOARD_SIZE + pc
		_animate_shadow_cell(live_cells[index], String(projection["direction"]), float(projection["delay"]), adding)
		_pulse_emitter(String(projection["emitter"]), float(projection["delay"]))

func _animate_shadow_cell(cell: PanelContainer, direction: String, delay: float, adding: bool) -> void:
	cell.modulate = Color(1, 1, 1, 0.30 if adding else 0.62)
	if adding:
		match direction:
			"left":
				cell.pivot_offset = Vector2(CELL_SIZE, CELL_SIZE * 0.5)
				cell.scale = Vector2(0.08, 1.0)
			"right":
				cell.pivot_offset = Vector2(0.0, CELL_SIZE * 0.5)
				cell.scale = Vector2(0.08, 1.0)
			_:
				cell.pivot_offset = Vector2(CELL_SIZE * 0.5, 0.0)
				cell.scale = Vector2(1.0, 0.08)
	else:
		cell.pivot_offset = Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		cell.scale = Vector2(1.06, 1.06)

	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.19).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(cell, "modulate", Color.WHITE, 0.22)

func _pulse_emitter(key: String, delay: float) -> void:
	if not emitter_labels.has(key):
		return
	var emitter := emitter_labels[key] as Label
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(emitter, "modulate", COLOR_CYAN_HOT, 0.06)
	tween.tween_property(emitter, "modulate", COLOR_CYAN, 0.18)

func _play_solve_beat() -> void:
	_reveal_hidden_target_cells()
	for i in live_cells.size():
		var cell := live_cells[i] as PanelContainer
		var tween := create_tween()
		tween.tween_interval(0.18 + float(i) * 0.012)
		tween.tween_property(cell, "modulate", COLOR_GOLD_HOT, 0.08)
		tween.tween_property(cell, "modulate", Color.WHITE, 0.20)

	var status_tween := create_tween()
	status_label.scale = Vector2(0.92, 0.92)
	status_label.pivot_offset = status_label.size * 0.5
	status_tween.tween_property(status_label, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_BACK)
	status_tween.tween_property(status_label, "scale", Vector2.ONE, 0.18)

func _reveal_hidden_target_cells() -> void:
	var stage: Dictionary = stages[stage_index]
	var solution_posts := ShadowRules.make_empty_posts()
	for code_value in stage["solution"]:
		var code := String(code_value)
		if code.length() < 2:
			continue
		var c := code.unicode_at(0) - 65
		var r := int(code.substr(1)) - 1
		if r >= 0 and r < ShadowRules.BOARD_SIZE and c >= 0 and c < ShadowRules.BOARD_SIZE:
			solution_posts[r][c] = true
	var full_shadow := ShadowRules.compute_shadow(solution_posts)
	var clues: Array = stage["clues"]
	for r in ShadowRules.BOARD_SIZE:
		for c in ShadowRules.BOARD_SIZE:
			if int(clues[r][c]) >= 0:
				continue
			var i := r * ShadowRules.BOARD_SIZE + c
			var cell := clue_cells[i] as PanelContainer
			var label := cell.get_child(0) as Label
			cell.add_theme_stylebox_override("panel", _shadow_style(int(full_shadow[r][c]), false, true))
			label.text = ""
			cell.modulate = Color(1, 1, 1, 0.25)
			var tween := create_tween()
			tween.tween_interval(0.12 + float(i) * 0.010)
			tween.tween_property(cell, "modulate", Color.WHITE, 0.20)

func _reset_screen_transforms() -> void:
	for cell_value in live_cells:
		var cell := cell_value as PanelContainer
		cell.scale = Vector2.ONE
		cell.modulate = Color.WHITE
	for cell_value in clue_cells:
		var cell := cell_value as PanelContainer
		cell.scale = Vector2.ONE
		cell.modulate = Color.WHITE
	for button_value in post_buttons:
		var button := button_value as Button
		button.scale = Vector2.ONE
		button.disabled = false

func _flash_status(color: Color) -> void:
	status_label.modulate = color
	var tween := create_tween()
	tween.tween_property(status_label, "modulate", Color.WHITE, 0.25)

func _style_footer_button(button: Button, primary: bool) -> void:
	button.custom_minimum_size = Vector2(118, 38)
	button.focus_mode = Control.FOCUS_NONE
	var base := COLOR_GOLD if primary else Color("#14242c")
	var border := COLOR_GOLD_HOT if primary else COLOR_LINE
	var text_color := Color("#172129") if primary else COLOR_TEXT
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_disabled_color", COLOR_MUTED.darkened(0.35))
	button.add_theme_stylebox_override("normal", _panel_style(base, border, 1, 10))
	button.add_theme_stylebox_override("hover", _panel_style(base.lightened(0.10), border.lightened(0.10), 2, 10))
	button.add_theme_stylebox_override("pressed", _panel_style(base.darkened(0.12), border, 2, 10))
	button.add_theme_stylebox_override("disabled", _panel_style(Color("#0b151b"), Color("#1d3037"), 1, 10))

func _shadow_style(value: int, hidden: bool, is_target: bool) -> StyleBoxFlat:
	var color: Color
	if hidden:
		color = Color("#213039")
	else:
		match value:
			0:
				color = Color("#c9e4e5")
			1:
				color = Color("#829ba0")
			2:
				color = Color("#465b61")
			3:
				color = Color("#13262d")
			_:
				color = Color("#213039")
	var border := COLOR_GOLD.darkened(0.50) if is_target else COLOR_CYAN.darkened(0.58)
	return _panel_style(color, border, 1, 5)

func _panel_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
