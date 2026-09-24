extends Control

signal closed

const N = preload("res://src/ui/nox_theme.gd")
const Locale = preload("res://src/nox_locale.gd")

const STEPS: Array[Dictionary] = [
	{
		"heading": "01  Read the plate",
		"en": "Compare RECORDED SHADOW and RECONSTRUCTION. Darker squares mean overlapping shadows; ? is unrecorded.",
		"ja": "「記録された影」と「再構築」を比べよう。濃いマスほど影が重なり、？は未記録の場所。",
	},
	{
		"heading": "02  Place a NOX trace",
		"en": "Tap a pose, then a square, or drag the pose onto a square. SIT, STAND, and WALK are NOX at different moments. Tap WALK to turn it.",
		"ja": "姿勢を選び、マスをタップ。ドラッグでも置ける。どれもNOXの別の瞬間。「歩く」はタップで回転。",
	},
	{
		"heading": "03  Observe the light",
		"en": "Switch available lights. Put SLEEP on the rail to block the top light in its column.",
		"ja": "使える光源を切り替えよう。「眠る」をレールに置くと、その列の上の光を遮る。",
	},
	{
		"heading": "04  Let the shadows agree",
		"en": "UNDO takes back a move. RESET clears the board. OBSERVE offers a clue.",
		"ja": "「一手戻す」で戻り、「やり直す」で配置を消す。「観察」で手がかりを読もう。",
	},
]

var _language: String = "en"
var _reduced_motion: bool = false
var _return_focus: Control
var _motion_tween: Tween
var _dismiss_pending: bool = false
var _title: Label
var _close_button: Button
var _play_button: Button
var _step_headings: Array[Label] = []
var _step_bodies: Array[Label] = []
var _panel: PanelContainer


func _ready() -> void:
	name = "NoxStageGuide"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	N.ensure_japanese_font()
	_build_ui()
	resized.connect(_responsive)
	_responsive()
	hide()


func present(language: String, reduced_motion: bool) -> void:
	if not visible:
		_return_focus = get_viewport().gui_get_focus_owner()
	set_language(language)
	_reduced_motion = reduced_motion
	_dismiss_pending = false
	_close_button.disabled = false
	_play_button.disabled = false
	_cancel_motion_tween()
	show()
	if _reduced_motion:
		modulate.a = 1.0
	else:
		modulate.a = 0.0
		_motion_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_motion_tween.tween_property(self, "modulate:a", 1.0, 0.16)
	_play_button.grab_focus()


func dismiss() -> void:
	if not visible or _dismiss_pending:
		return
	_cancel_motion_tween()
	if _reduced_motion:
		_finish_dismiss()
		return
	_dismiss_pending = true
	_close_button.disabled = true
	_play_button.disabled = true
	_motion_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_motion_tween.tween_property(self, "modulate:a", 0.0, 0.12)
	_motion_tween.tween_callback(_finish_dismiss)


func set_language(language: String) -> void:
	_language = "ja" if language == "ja" else "en"
	if _title == null:
		return
	_title.text = _copy("HOW TO PLAY")
	_close_button.text = _copy("CLOSE  ×")
	_play_button.text = "はじめる" if _language == "ja" else "LET'S PLAY"
	for index: int in STEPS.size():
		var step: Dictionary = STEPS[index]
		var heading_text: String = _copy(str(step["heading"]))
		_step_headings[index].text = heading_text.substr(heading_text.find(" ") + 1).strip_edges()
		_step_bodies[index].text = str(step["ja"] if _language == "ja" else step["en"])


func _build_ui() -> void:
	var scrim: ColorRect = ColorRect.new()
	scrim.name = "Scrim"
	scrim.color = Color(0.01, 0.02, 0.04, 0.88)
	scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var frame: MarginContainer = N.margin(self, 18)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	frame.add_child(center)

	_panel = PanelContainer.new()
	_panel.name = "GuidePanel"
	_panel.add_theme_stylebox_override("panel", N.box(Color("#101a25"), Color(N.BRASS, 0.56), 6, 16))
	center.add_child(_panel)

	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	_title = N.label(header, "", 21, N.IVORY, true)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_close_button = N.button("", 40)
	_close_button.name = "CloseGuide"
	_close_button.custom_minimum_size.x = 94
	_close_button.pressed.connect(dismiss)
	header.add_child(_close_button)

	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.name = "GuideScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var steps_column: VBoxContainer = VBoxContainer.new()
	steps_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	steps_column.add_theme_constant_override("separation", 9)
	scroll.add_child(steps_column)
	for index: int in STEPS.size():
		var card: PanelContainer = PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_theme_stylebox_override("panel", N.box(Color("#14212b"), Color("#344451"), 4, 10))
		steps_column.add_child(card)
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var number: Label = N.label(row, "%02d" % (index + 1), 12, N.BRASS)
		number.custom_minimum_size.x = 30
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var copy: VBoxContainer = VBoxContainer.new()
		copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		copy.add_theme_constant_override("separation", 4)
		row.add_child(copy)
		var heading: Label = N.label(copy, "", 15, N.IVORY, true)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var body: Label = N.label(copy, "", 13, N.SOFT)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_constant_override("line_spacing", 3)
		_step_headings.append(heading)
		_step_bodies.append(body)

	_play_button = N.button("", 58, true)
	_play_button.name = "LetsPlay"
	_play_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_play_button.add_theme_font_size_override("font_size", 20)
	_play_button.pressed.connect(dismiss)
	column.add_child(_play_button)
	set_language(_language)


func _responsive() -> void:
	if _panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	_panel.custom_minimum_size = Vector2(
		minf(540.0, maxf(280.0, viewport_size.x - 36.0)),
		minf(620.0, maxf(320.0, viewport_size.y - 64.0))
	)


func _copy(key: String) -> String:
	return str(Locale.JAPANESE.get(key, key)) if _language == "ja" else key


func _cancel_motion_tween() -> void:
	if _motion_tween != null and _motion_tween.is_running():
		_motion_tween.kill()
	_motion_tween = null


func _finish_dismiss() -> void:
	_dismiss_pending = false
	hide()
	modulate.a = 1.0
	closed.emit()
	if is_instance_valid(_return_focus) and _return_focus.is_inside_tree():
		_return_focus.grab_focus()
	_return_focus = null


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		dismiss()
		get_viewport().set_input_as_handled()
