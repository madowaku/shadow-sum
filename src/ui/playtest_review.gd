extends Control

signal submitted(rating: Dictionary)

const N = preload("res://src/ui/nox_theme.gd")

var scores: Dictionary = {}
var score_buttons: Dictionary = {}
var reaction: String = ""
var reaction_buttons: Dictionary = {}
var notes: LineEdit
var submit_button: Button
var body: VBoxContainer
var stage_id: String = ""
var revealed: bool = false

func _ready() -> void:
	name = "PlaytestReview"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.04, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.name = "PlaytestPanel"
	panel.add_theme_stylebox_override("panel", N.box(Color("#101b27"), N.BRASS, 14, 14))
	panel.custom_minimum_size.x = minf(380.0, get_viewport_rect().size.x - 24.0)
	center.add_child(panel)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size.y = minf(570.0, get_viewport_rect().size.y - 48.0)
	panel.add_child(scroll)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)

func present_solved(id: String) -> void:
	stage_id = id
	revealed = false
	scores.clear()
	score_buttons.clear()
	reaction = ""
	_build_form()
	show()

func present_revealed(id: String) -> void:
	stage_id = id
	revealed = true
	scores.clear()
	reaction = ""
	reaction_buttons.clear()
	_build_form()
	show()

func _build_form() -> void:
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var heading: Label = N.label(body, stage_id + ("  /  解答確認" if revealed else "  /  プレイ評価"), 18, N.BRASS, true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if revealed:
		var prompt: Label = N.label(body, "解答を見て、どう感じましたか？", 12)
		prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var reactions: Array[String] = ["NARUHODO", "FLAT", "UNFAIR"]
		var labels: Array[String] = ["なるほど！", "ふつう", "理不尽"]
		for index: int in reactions.size():
			var button: Button = N.button(labels[index], 36)
			button.toggle_mode = true
			button.pressed.connect(_select_reaction.bind(reactions[index]))
			body.add_child(button)
			reaction_buttons[reactions[index]] = button
	else:
		_add_score_row("flow_feel", "気持ちよさ")
		_add_score_row("aha", "なるほど感")
		_add_score_row("frustration", "総当たり感")
		_add_score_row("want_next", "もう一問")
	N.label(body, "メモ（任意）", 12, N.SOFT)
	notes = LineEdit.new()
	notes.name = "PlaytestNotes"
	notes.placeholder_text = "気づいたことがあれば"
	notes.custom_minimum_size.y = 38
	body.add_child(notes)
	submit_button = N.button("次へ", 44, true)
	submit_button.name = "PlaytestSubmit"
	submit_button.disabled = true
	submit_button.pressed.connect(_submit)
	body.add_child(submit_button)

func _add_score_row(key: String, label_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	body.add_child(row)
	var label: Label = N.label(row, label_text, 12)
	label.custom_minimum_size.x = 93
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var buttons: Array[Button] = []
	for value: int in 5:
		var button: Button = N.button(str(value + 1), 34)
		button.toggle_mode = true
		button.custom_minimum_size.x = 38
		button.pressed.connect(_select_score.bind(key, value + 1))
		row.add_child(button)
		buttons.append(button)
	score_buttons[key] = buttons

func _select_score(key: String, value: int) -> void:
	scores[key] = value
	var buttons: Array = score_buttons[key]
	for index: int in buttons.size():
		(buttons[index] as Button).button_pressed = index + 1 == value
	_update_submit()

func _select_reaction(value: String) -> void:
	reaction = value
	for key: String in reaction_buttons:
		(reaction_buttons[key] as Button).button_pressed = key == value
	_update_submit()

func _update_submit() -> void:
	submit_button.disabled = reaction.is_empty() if revealed else scores.size() != 4

func _submit() -> void:
	if submit_button.disabled:
		return
	var result: Dictionary = {"outcome": "revealed" if revealed else "solved", "notes": notes.text.strip_edges()}
	if revealed:
		result["reveal_reaction"] = reaction
	else:
		for key: String in scores:
			result[key] = scores[key]
	submitted.emit(result)

func show_complete(path: String) -> void:
	for child: Node in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var heading: Label = N.label(body, "プレイテスト完了", 20, N.BRASS, true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	N.label(body, "評価結果の保存場所", 12)
	var location: LineEdit = LineEdit.new()
	location.name = "PlaytestResultsPath"
	location.text = path
	location.editable = false
	location.custom_minimum_size.y = 42
	body.add_child(location)
	show()
