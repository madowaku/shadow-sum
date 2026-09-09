extends Control

const ShadowRules = preload("res://src/shadow_rules.gd")
const STAGE_PATH := "res://data/stages_v0_1.json"

var stages: Array = []
var stage_index := 0
var posts: Array = []
var clue_labels: Array = []
var live_labels: Array = []
var post_buttons: Array = []

var stage_label: Label
var counter_label: Label
var status_label: Label
var next_button: Button

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
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	margin.add_child(root)

	var title := Label.new()
	title.text = "SHADOW SUM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	root.add_child(title)

	stage_label = Label.new()
	stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_label.add_theme_font_size_override("font_size", 20)
	root.add_child(stage_label)

	counter_label = Label.new()
	counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(counter_label)

	root.add_child(_section_label("TARGET SHADOW"))
	var clue_grid := GridContainer.new()
	clue_grid.columns = ShadowRules.BOARD_SIZE
	clue_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(clue_grid)
	_build_label_grid(clue_grid, clue_labels)

	root.add_child(_section_label("YOUR SHADOW"))
	var live_grid := GridContainer.new()
	live_grid.columns = ShadowRules.BOARD_SIZE
	live_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(live_grid)
	_build_label_grid(live_grid, live_labels)

	root.add_child(_section_label("PLACE POSTS"))
	var post_grid := GridContainer.new()
	post_grid.columns = ShadowRules.BOARD_SIZE
	post_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(post_grid)
	_build_post_grid(post_grid)

	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 18)
	root.add_child(status_label)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	root.add_child(buttons)

	var reset_button := Button.new()
	reset_button.text = "RESET"
	reset_button.pressed.connect(_reset_stage)
	buttons.add_child(reset_button)

	next_button = Button.new()
	next_button.text = "NEXT"
	next_button.disabled = true
	next_button.pressed.connect(_next_stage)
	buttons.add_child(next_button)

	var hint := Label.new()
	hint.text = "· clear   ░ light   ▒ double   ▓ full   ? hidden"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(hint)

func _section_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	return label

func _build_label_grid(grid: GridContainer, store: Array) -> void:
	for i in ShadowRules.BOARD_SIZE * ShadowRules.BOARD_SIZE:
		var label := Label.new()
		label.custom_minimum_size = Vector2(54, 54)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 28)
		label.text = "·"
		grid.add_child(label)
		store.append(label)

func _build_post_grid(grid: GridContainer) -> void:
	for i in ShadowRules.BOARD_SIZE * ShadowRules.BOARD_SIZE:
		var r := i / ShadowRules.BOARD_SIZE
		var c := i % ShadowRules.BOARD_SIZE
		var button := Button.new()
		button.custom_minimum_size = Vector2(54, 54)
		button.text = "·"
		button.tooltip_text = "%s%d" % [String.chr(65 + c), r + 1]
		button.pressed.connect(_toggle_post.bind(r, c))
		grid.add_child(button)
		post_buttons.append(button)

func _load_stage(index: int) -> void:
	if stages.is_empty():
		return
	stage_index = clampi(index, 0, stages.size() - 1)
	posts = ShadowRules.make_empty_posts()
	var stage: Dictionary = stages[stage_index]
	stage_label.text = "%03d  %s  ·  %s" % [int(stage["id"]), String(stage["title"]), String(stage["tier"])]
	next_button.disabled = true
	_update_all()

func _reset_stage() -> void:
	posts = ShadowRules.make_empty_posts()
	next_button.disabled = true
	_update_all()

func _next_stage() -> void:
	if stage_index >= stages.size() - 1:
		status_label.text = "v0.1 COMPLETE  ◐"
		return
	_load_stage(stage_index + 1)

func _toggle_post(r: int, c: int) -> void:
	var stage: Dictionary = stages[stage_index]
	var required := int(stage["posts"])
	if not posts[r][c] and ShadowRules.count_posts(posts) >= required:
		status_label.text = "Remove a post before placing another."
		return
	posts[r][c] = not posts[r][c]
	_update_all()

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
			clue_labels[i].text = "?" if clue < 0 else ShadowRules.glyph(clue)
			live_labels[i].text = ShadowRules.glyph(int(shadow[r][c]))
			post_buttons[i].text = "●" if posts[r][c] else "·"

	var shadows_match := ShadowRules.matches_visible_clues(shadow, clues)
	var solved := placed == required and shadows_match
	if solved:
		status_label.text = "SHADOW COMPLETE  ◑"
		next_button.disabled = false
	elif placed == required:
		status_label.text = "The shadow does not match yet."
	else:
		status_label.text = "Shape the target shadow."
		next_button.disabled = true
