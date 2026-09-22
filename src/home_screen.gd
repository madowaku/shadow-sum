extends Control

const T = preload("res://src/night_tokens.gd")
const LabBackground = preload("res://src/ui/home_lab_background.gd")

const CAMPAIGN_SCENE := "res://scenes/campaign.tscn"
const STAGE_DATA := "res://data/grant20_v0_3.json"
const PROGRESS_PATH := "user://shadow_sum_grant20_v0_3.json"
const SETTINGS_PATH := "user://shadow_sum_settings.json"

var stages: Array = []
var completed: Dictionary = {}
var settings: Dictionary = {
	"sfx_enabled": true,
	"fullscreen": false,
}

var menu_column: VBoxContainer
var continue_button: Button
var continue_info: Label
var level_overlay: Control
var settings_overlay: Control
var sfx_button: Button
var fullscreen_button: Button
var sound_player: AudioStreamPlayer

func _ready() -> void:
	if _has_developer_launch_args():
		get_tree().change_scene_to_file(CAMPAIGN_SCENE)
		return

	_load_stage_data()
	_load_progress()
	_load_settings()
	_build_ui()
	_apply_window_setting()
	_play_intro()

func _has_developer_launch_args() -> bool:
	var args := OS.get_cmdline_user_args()
	return args.has("--dev-selector") or args.has("--stage") or args.has("--campaign") or _has_prefixed_arg(args, "--campaign=")

func _has_prefixed_arg(args: PackedStringArray, prefix: String) -> bool:
	for argument: String in args:
		if argument.begins_with(prefix):
			return true
	return false

func _load_stage_data() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(STAGE_DATA))
	if parsed is Array:
		stages = parsed

func _load_progress() -> void:
	completed.clear()
	if not FileAccess.file_exists(PROGRESS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PROGRESS_PATH))
	if parsed is Dictionary and parsed.get("campaign", "") == "grant20_v0_3":
		completed = parsed.get("completed", {}).duplicate()

func _load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
	if parsed is Dictionary:
		settings["sfx_enabled"] = bool(parsed.get("sfx_enabled", true))
		settings["fullscreen"] = bool(parsed.get("fullscreen", false))

func _save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(settings, "	"))

func _build_ui() -> void:
	var background: Control = LabBackground.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var veil := ColorRect.new()
	veil.color = Color(0.01, 0.018, 0.024, 0.22)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_top", 34)
	margin.add_theme_constant_override("margin_bottom", 18)
	add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = "SHADOW SUM"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", T.display_font())
	title.add_theme_font_size_override("font_size", 39)
	title.add_theme_color_override("font_color", T.TEXT_PRIMARY)
	title.modulate.a = 0.0
	title.name = "Title"
	column.add_child(title)

	var axis := HSeparator.new()
	axis.custom_minimum_size = Vector2(170, 6)
	axis.modulate = Color(T.CYAN, 0.42)
	column.add_child(axis)

	var subtitle := Label.new()
	subtitle.text = "A PUZZLE OF LIGHT, SHADOW, AND ALIGNMENT"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_override("font", T.instrument_font())
	subtitle.add_theme_font_size_override("font_size", 9)
	subtitle.add_theme_color_override("font_color", T.TEXT_MUTED)
	subtitle.modulate.a = 0.0
	subtitle.name = "Subtitle"
	column.add_child(subtitle)

	var showcase := Control.new()
	showcase.custom_minimum_size.y = 250
	showcase.size_flags_vertical = Control.SIZE_EXPAND_FILL
	showcase.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(showcase)

	var readout := Label.new()
	readout.text = "OPTICAL CALIBRATION ARRAY  /  READY"
	readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	readout.add_theme_font_override("font", T.instrument_font())
	readout.add_theme_font_size_override("font_size", 9)
	readout.add_theme_color_override("font_color", Color(T.CYAN_SOFT, 0.72))
	column.add_child(readout)

	menu_column = VBoxContainer.new()
	menu_column.alignment = BoxContainer.ALIGNMENT_CENTER
	menu_column.add_theme_constant_override("separation", 9)
	menu_column.modulate.a = 0.0
	column.add_child(menu_column)

	var play := _menu_button("PLAY", true)
	play.pressed.connect(_start_campaign.bind(0))
	menu_column.add_child(play)

	continue_button = _menu_button("CONTINUE", false)
	continue_button.pressed.connect(_continue_campaign)
	menu_column.add_child(continue_button)

	continue_info = Label.new()
	continue_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_info.add_theme_font_override("font", T.instrument_font())
	continue_info.add_theme_font_size_override("font_size", 9)
	continue_info.add_theme_color_override("font_color", T.TEXT_MUTED)
	menu_column.add_child(continue_info)

	var level_select := _menu_button("LEVEL SELECT", false)
	level_select.pressed.connect(_open_level_select)
	menu_column.add_child(level_select)

	var settings_button := _menu_button("SETTINGS", false)
	settings_button.pressed.connect(_open_settings)
	menu_column.add_child(settings_button)

	var quit := _menu_button("QUIT", false)
	quit.custom_minimum_size.x = 160
	quit.pressed.connect(get_tree().quit)
	menu_column.add_child(quit)

	_update_progress_readout()

	var footer := Label.new()
	footer.text = "PROTOTYPE v0.3   |   GRANT DEMO   |   © madowaku"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_override("font", T.instrument_font())
	footer.add_theme_font_size_override("font_size", 8)
	footer.add_theme_color_override("font_color", Color(T.TEXT_MUTED, 0.72))
	column.add_child(footer)

	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)

	_build_level_overlay()
	_build_settings_overlay()

	play.grab_focus()

func _menu_button(label: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(278, 50 if primary else 46)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_override("font", T.instrument_font())
	button.add_theme_font_size_override("font_size", 13 if primary else 12)
	button.add_theme_color_override("font_color", T.TEXT_PRIMARY if not primary else Color("#F5FBFD"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", T.CYAN)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.035, 0.055, 0.068, 0.82), T.LINE_MEDIUM, 1))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.055, 0.09, 0.11, 0.90), T.CYAN_SOFT if primary else T.LINE_BRIGHT, 1))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.075, 0.12, 0.14, 0.94), T.CYAN, 2))
	button.add_theme_stylebox_override("focus", _focus_style(T.CYAN if primary else T.LINE_BRIGHT))
	button.mouse_entered.connect(_hover_button.bind(button, true))
	button.mouse_exited.connect(_hover_button.bind(button, false))
	button.pressed.connect(_play_click)
	return button

func _button_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func _focus_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.draw_center = false
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.expand_margin_left = 2
	style.expand_margin_right = 2
	style.expand_margin_top = 2
	style.expand_margin_bottom = 2
	return style

func _hover_button(button: Button, entered: bool) -> void:
	if button.disabled:
		return
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * (1.015 if entered else 1.0), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _play_intro() -> void:
	var title := get_node_or_null("MarginContainer") as Node
	var actual_title := find_child("Title", true, false) as Label
	var subtitle := find_child("Subtitle", true, false) as Label
	var tween := create_tween()
	if actual_title != null:
		actual_title.position.y -= 8
		tween.tween_property(actual_title, "modulate:a", 1.0, 0.35)
		tween.parallel().tween_property(actual_title, "position:y", actual_title.position.y + 8, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if subtitle != null:
		tween.tween_property(subtitle, "modulate:a", 1.0, 0.25)
	tween.tween_property(menu_column, "modulate:a", 1.0, 0.30)

func _update_progress_readout() -> void:
	var done := _completed_count()
	var resume := _resume_index()
	continue_button.disabled = stages.is_empty()
	if stages.is_empty():
		continue_info.text = "Campaign data unavailable"
		return
	if done <= 0:
		continue_info.text = "No calibration record yet"
	else:
		var stage_id := str(stages[resume]["id"])
		continue_info.text = "Progress %02d / %02d   ·   Next %s" % [done, stages.size(), stage_id]

func _completed_count() -> int:
	var count := 0
	for entry: Dictionary in stages:
		if completed.has(str(entry["id"])):
			count += 1
	return count

func _resume_index() -> int:
	if stages.is_empty():
		return 0
	var index := 0
	while index < stages.size() and completed.has(str(stages[index]["id"])):
		index += 1
	return clampi(index, 0, stages.size() - 1)

func _continue_campaign() -> void:
	_start_campaign(_resume_index())

func _start_campaign(index: int) -> void:
	if stages.is_empty():
		return
	get_tree().root.set_meta("shadow_sum_start_stage", clampi(index, 0, stages.size() - 1))
	var fade := ColorRect.new()
	fade.color = Color(0.01, 0.015, 0.02, 0.0)
	fade.mouse_filter = Control.MOUSE_FILTER_STOP
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade)
	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.28)
	tween.tween_callback(func() -> void: get_tree().change_scene_to_file(CAMPAIGN_SCENE))

func _build_level_overlay() -> void:
	level_overlay = _overlay_shell()
	var panel := _overlay_panel(level_overlay, Vector2(330, 470))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	_overlay_title(column, "LEVEL SELECT")

	var progress := Label.new()
	progress.text = "CALIBRATION RECORD  %02d / %02d" % [_completed_count(), stages.size()]
	progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress.add_theme_font_override("font", T.instrument_font())
	progress.add_theme_font_size_override("font_size", 9)
	progress.add_theme_color_override("font_color", T.TEXT_MUTED)
	column.add_child(progress)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)

	var resume := _resume_index()
	for index: int in stages.size():
		var button := Button.new()
		button.text = "%02d" % [index + 1]
		button.custom_minimum_size = Vector2(62, 46)
		button.add_theme_font_override("font", T.instrument_font())
		var id := str(stages[index]["id"])
		var unlocked := index <= resume or completed.has(id)
		button.disabled = not unlocked
		button.tooltip_text = "%s / %s" % [id, str(stages[index].get("title", ""))]
		button.pressed.connect(_start_campaign.bind(index))
		button.pressed.connect(_play_click)
		grid.add_child(button)

	var back := _menu_button("BACK", false)
	back.custom_minimum_size = Vector2(180, 44)
	back.pressed.connect(func() -> void: level_overlay.visible = false)
	column.add_child(back)

func _build_settings_overlay() -> void:
	settings_overlay = _overlay_shell()
	var panel := _overlay_panel(settings_overlay, Vector2(330, 300))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	_overlay_title(column, "SETTINGS")

	sfx_button = _menu_button("", false)
	sfx_button.pressed.connect(_toggle_sfx)
	column.add_child(sfx_button)

	fullscreen_button = _menu_button("", false)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	column.add_child(fullscreen_button)

	var note := Label.new()
	note.text = "Audio and display preferences are saved locally."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 10)
	note.add_theme_color_override("font_color", T.TEXT_MUTED)
	column.add_child(note)

	var back := _menu_button("BACK", false)
	back.custom_minimum_size = Vector2(180, 44)
	back.pressed.connect(func() -> void: settings_overlay.visible = false)
	column.add_child(back)
	_refresh_settings_labels()

func _overlay_shell() -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.70)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	return overlay

func _overlay_panel(overlay: Control, minimum: Vector2) -> MarginContainer:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum
	panel.add_theme_stylebox_override("panel", _button_style(Color("#0D1419"), T.LINE_BRIGHT, 1))
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)
	return margin

func _overlay_title(parent: Node, text_value: String) -> void:
	var title := Label.new()
	title.text = text_value
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", T.display_font())
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", T.TEXT_PRIMARY)
	parent.add_child(title)

func _open_level_select() -> void:
	level_overlay.visible = true

func _open_settings() -> void:
	_refresh_settings_labels()
	settings_overlay.visible = true

func _toggle_sfx() -> void:
	settings["sfx_enabled"] = not bool(settings["sfx_enabled"])
	_save_settings()
	_refresh_settings_labels()

func _toggle_fullscreen() -> void:
	settings["fullscreen"] = not bool(settings["fullscreen"])
	_save_settings()
	_apply_window_setting()
	_refresh_settings_labels()

func _refresh_settings_labels() -> void:
	if sfx_button != null:
		sfx_button.text = "SFX        " + ("ON" if bool(settings["sfx_enabled"]) else "OFF")
	if fullscreen_button != null:
		fullscreen_button.text = "FULLSCREEN " + ("ON" if bool(settings["fullscreen"]) else "OFF")

func _apply_window_setting() -> void:
	if bool(settings["fullscreen"]):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _play_click() -> void:
	if not bool(settings.get("sfx_enabled", true)):
		return
	if sound_player == null:
		return
	var wave := AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var bytes := PackedByteArray()
	bytes.resize(970)
	for index: int in 485:
		var envelope := pow(1.0 - float(index) / 485.0, 3.0)
		var sample := sin(TAU * 1180.0 * float(index) / 22050.0) * envelope
		bytes.encode_s16(index * 2, int(sample * 1300.0))
	wave.data = bytes
	sound_player.stream = wave
	sound_player.play()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_overlay.visible:
			settings_overlay.visible = false
			get_viewport().set_input_as_handled()
		elif level_overlay.visible:
			level_overlay.visible = false
			get_viewport().set_input_as_handled()
