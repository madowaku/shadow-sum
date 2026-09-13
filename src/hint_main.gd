extends "res://src/progress_main.gd"

const WHISPER_PATH := "res://data/whispers_v0_1.json"
const WHISPER_TEXT_TIME := 3.2
const HINT_CYAN := Color("#b7fbff")
const HINT_GOLD := Color("#ffe0a0")
const HINT_RED := Color("#ef8d82")

var whisper_catalog: Dictionary = {}
var whisper_index := 0
var whisper_serial := 0
var hint_button: Button
var hint_tweens: Array = []

func _ready() -> void:
	super._ready()
	var file := FileAccess.open(WHISPER_PATH, FileAccess.READ)
	if file != null:
		var parsed = JSON.parse_string(file.get_as_text())
		if parsed is Dictionary:
			whisper_catalog = parsed
	_build_hint_button()
	_refresh_hint_button()
	_apply_responsive_layout()

func _build_hint_button() -> void:
	if next_button == null or next_button.get_parent() == null:
		return
	var footer := next_button.get_parent() as HBoxContainer
	if footer == null:
		return
	hint_button = Button.new()
	hint_button.name = "HintButton"
	hint_button.text = "HINT ◐"
	_style_footer_button(hint_button, false)
	hint_button.pressed.connect(_on_hint_pressed)
	var next_index := next_button.get_index()
	footer.add_child(hint_button)
	footer.move_child(hint_button, next_index)

func _on_hint_pressed() -> void:
	var whispers := _current_whispers()
	if stage_solved or whispers.is_empty() or whisper_index >= whispers.size():
		return
	whisper_serial += 1
	var serial := whisper_serial
	_reset_hint_visuals()
	var whisper: Dictionary = whispers[whisper_index]
	whisper_index += 1
	status_label.text = String(whisper.get("text", "Look again."))
	status_label.add_theme_color_override("font_color", HINT_CYAN)
	if bool(whisper.get("emphasize_post_counter", false)):
		_pulse_control(counter_label, HINT_GOLD, 1.035, 1)
	var targets = whisper.get("targets", [])
	if targets is Array:
		for item in targets:
			if item is Dictionary:
				_play_hint_target(item as Dictionary, serial)
	var sequence = whisper.get("sequence", [])
	if sequence is Array:
		for item in sequence:
			if item is Dictionary:
				_play_sequence_item(item as Dictionary, serial)
	_refresh_hint_button()
	_restore_status_after_hint(serial)

func _current_whispers() -> Array:
	if stages.is_empty():
		return []
	var key := str(int(stages[stage_index]["id"]))
	var value = whisper_catalog.get(key, [])
	return value if value is Array else []

func _refresh_hint_button() -> void:
	if hint_button == null:
		return
	var whispers := _current_whispers()
	if stage_solved or whispers.is_empty():
		hint_button.disabled = true
		hint_button.text = "HINT ◐"
		return
	if whisper_index == 0:
		hint_button.text = "HINT ◐"
	elif whisper_index == 1:
		hint_button.text = "HINT I"
	elif whisper_index == 2:
		hint_button.text = "HINT II"
	else:
		hint_button.text = "HINT III"
	hint_button.disabled = whisper_index >= whispers.size()

func _load_stage(index: int) -> void:
	whisper_serial += 1
	whisper_index = 0
	_reset_hint_visuals()
	super._load_stage(index)
	_refresh_hint_button()

func _reset_stage() -> void:
	whisper_serial += 1
	whisper_index = 0
	_reset_hint_visuals()
	super._reset_stage()
	_refresh_hint_button()

func _play_solve_beat() -> void:
	whisper_serial += 1
	_reset_hint_visuals()
	if hint_button != null:
		hint_button.disabled = true
	super._play_solve_beat()

func _restore_status_after_hint(serial: int) -> void:
	await get_tree().create_timer(WHISPER_TEXT_TIME).timeout
	if serial != whisper_serial or stage_solved:
		return
	_update_all()
	_refresh_hint_button()

func _play_sequence_item(item: Dictionary, serial: int) -> void:
	var delay := float(item.get("delay", 0.0))
	if delay > 0.0:
		await get_tree().create_timer(delay).timeout
	if serial == whisper_serial and not stage_solved:
		_play_hint_target(item, serial)

func _play_hint_target(item: Dictionary, serial: int) -> void:
	if serial != whisper_serial:
		return
	var index := _cell_to_index(String(item.get("cell", "")))
	if index < 0:
		return
	var surface := String(item.get("surface", ""))
	var effect := String(item.get("effect", "pulse"))
	var control: Control = null
	if surface == "clue" and index < clue_cells.size():
		control = clue_cells[index] as Control
	elif surface == "socket" and index < post_buttons.size():
		control = post_buttons[index] as Control
	if control == null:
		return
	var color := HINT_GOLD if surface == "socket" else HINT_CYAN
	var repeats := 2 if effect == "pulse" else 1
	if effect == "contradiction":
		color = HINT_RED
		repeats = 2
	elif effect == "forced_empty":
		color = COLOR_MUTED.lightened(0.2)
	elif effect == "assume_empty":
		color = HINT_CYAN
	elif effect == "forced_filled":
		color = HINT_GOLD
	_pulse_control(control, color, 1.06, repeats)

func _pulse_control(control: Control, color: Color, peak: float, repeats: int) -> void:
	if control == null:
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE
	control.modulate = Color.WHITE
	var tween := create_tween()
	hint_tweens.append(tween)
	for _i in repeats:
		tween.tween_property(control, "modulate", color, 0.10)
		tween.parallel().tween_property(control, "scale", Vector2(peak, peak), 0.10)
		tween.tween_property(control, "modulate", Color.WHITE, 0.16)
		tween.parallel().tween_property(control, "scale", Vector2.ONE, 0.16)

func _reset_hint_visuals() -> void:
	for cell_value in clue_cells:
		var cell := cell_value as Control
		cell.scale = Vector2.ONE
		cell.modulate = Color.WHITE
	for button_value in post_buttons:
		var button := button_value as Control
		button.scale = Vector2.ONE
		button.modulate = Color.WHITE
	if counter_label != null:
		counter_label.scale = Vector2.ONE
		counter_label.modulate = Color.WHITE
	hint_tweens.clear()

func _cell_to_index(code: String) -> int:
	if code.length() < 2:
		return -1
	var c := code.unicode_at(0) - 65
	var r := int(code.substr(1)) - 1
	if c < 0 or c >= ShadowRules.BOARD_SIZE or r < 0 or r >= ShadowRules.BOARD_SIZE:
		return -1
	return r * ShadowRules.BOARD_SIZE + c

func _apply_responsive_layout() -> void:
	super._apply_responsive_layout()
	if hint_button == null or next_button == null or next_button.get_parent() == null:
		return
	var footer := next_button.get_parent() as HBoxContainer
	if footer == null:
		return
	var width := 78.0 if compact_layout else 104.0
	footer.add_theme_constant_override("separation", 7 if compact_layout else 9)
	for child in footer.get_children():
		if child is Button:
			(child as Button).custom_minimum_size = Vector2(width, 34 if compact_layout else 36)
