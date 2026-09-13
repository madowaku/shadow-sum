extends "res://src/progress_main.gd"

const WHISPER_PATH := "res://data/whispers_v0_1.json"

var whisper_catalog: Dictionary = {}
var whisper_index := 0
var hint_button: Button

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
	var whisper: Dictionary = whispers[whisper_index]
	whisper_index += 1
	status_label.text = String(whisper.get("text", "Look again."))
	status_label.add_theme_color_override("font_color", COLOR_CYAN_HOT)
	_refresh_hint_button()

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
	whisper_index = 0
	super._load_stage(index)
	_refresh_hint_button()

func _reset_stage() -> void:
	whisper_index = 0
	super._reset_stage()
	_refresh_hint_button()

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
