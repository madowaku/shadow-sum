extends "res://src/flow_main.gd"

# SHADOW SUM v0.1.5 KEEP THE LIGHT Progress Pass
#
# Progress stays deliberately quiet:
# - first-time clears are persisted to user://,
# - restart resumes at the first unsolved shadow,
# - previous cleared puzzles remain replayable,
# - the next difficulty band lights up after every group of three.
#
# The campaign remains linear. No stage-select wall is placed in front of play.

const DEFAULT_PROGRESS_PATH := "user://shadow_sum_progress_v0_1.json"
const PROGRESS_VERSION := 1
const TIER_START_IDS := [1, 4, 7, 10, 13, 16]
const TIER_NAMES := ["INTRO", "EASY", "MEDIUM", "HARD", "ECLIPSE", "UMBRA"]

var progress_path := DEFAULT_PROGRESS_PATH
var completed_stage_ids: Dictionary = {}
var progress_loaded := false
var back_button: Button


func _ready() -> void:
	if progress_path == DEFAULT_PROGRESS_PATH and OS.has_environment("SHADOW_SUM_PROGRESS_PATH"):
		var override_path := OS.get_environment("SHADOW_SUM_PROGRESS_PATH")
		if not override_path.is_empty():
			progress_path = override_path

	super._ready()
	_build_progress_controls()
	_load_progress()
	progress_loaded = true
	_load_stage(_resume_stage_index())
	_refresh_progress_ui()


func _load_stage(index: int) -> void:
	super._load_stage(index)
	if progress_loaded:
		_refresh_progress_ui()


func _reset_stage() -> void:
	super._reset_stage()
	if progress_loaded:
		_refresh_progress_ui()


func _update_all() -> void:
	super._update_all()
	if not progress_loaded or stages.is_empty() or counter_label == null:
		return
	var completed_count := completed_stage_ids.size()
	var stage: Dictionary = stages[stage_index]
	var required := int(stage["posts"])
	var placed := ShadowRules.count_posts(posts)
	counter_label.text = "POSTS  %d / %d   ·   LIGHT  %d / %d" % [placed, required, completed_count, stages.size()]
	_refresh_navigation_buttons()


func _play_solve_beat() -> void:
	var unlocked_before := _unlocked_tier_count()
	var first_clear := _record_current_stage_clear()
	var unlocked_after := _unlocked_tier_count()

	super._play_solve_beat()

	if first_clear and unlocked_after > unlocked_before:
		_show_tier_unlock(unlocked_after - 1)
	_refresh_progress_ui()


func _next_stage() -> void:
	# Replay stages may be advanced without solving again, but never beyond the
	# first currently unlocked unsolved stage.
	if not stage_solved and not _is_stage_completed(stage_index):
		return
	var max_index := _highest_unlocked_stage_index()
	if stage_index >= max_index:
		if _all_stages_completed():
			status_label.text = "ALL LIGHTS KEPT  ◐"
		return
	_load_stage(stage_index + 1)


func _go_previous_stage() -> void:
	if stage_index <= 0:
		return
	_load_stage(stage_index - 1)


func _build_progress_controls() -> void:
	if reset_button == null or reset_button.get_parent() == null:
		return
	var footer := reset_button.get_parent() as HBoxContainer
	if footer == null:
		return

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "‹  BACK"
	_style_footer_button(back_button, false)
	back_button.custom_minimum_size = Vector2(88, 34)
	back_button.pressed.connect(_go_previous_stage)
	footer.add_child(back_button)
	footer.move_child(back_button, 0)


func _record_current_stage_clear() -> bool:
	if not progress_loaded or stages.is_empty():
		return false
	var id := int(stages[stage_index]["id"])
	if completed_stage_ids.has(id):
		return false
	completed_stage_ids[id] = true
	_save_progress()
	return true


func _load_progress() -> void:
	completed_stage_ids.clear()
	if not FileAccess.file_exists(progress_path):
		return

	var file := FileAccess.open(progress_path, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return
	if int(parsed.get("version", 0)) != PROGRESS_VERSION:
		return

	var completed = parsed.get("completed", [])
	if not (completed is Array):
		return
	for value in completed:
		var id := int(value)
		if id >= 1 and id <= stages.size():
			completed_stage_ids[id] = true


func _save_progress() -> void:
	var completed: Array[int] = []
	for key in completed_stage_ids.keys():
		completed.append(int(key))
	completed.sort()

	var payload := {
		"version": PROGRESS_VERSION,
		"completed": completed,
	}
	var file := FileAccess.open(progress_path, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save SHADOW SUM progress: %s" % progress_path)
		return
	file.store_string(JSON.stringify(payload))


func _resume_stage_index() -> int:
	if stages.is_empty():
		return 0
	for index in stages.size():
		if not _is_stage_completed(index):
			return index
	return stages.size() - 1


func _highest_unlocked_stage_index() -> int:
	# The first unsolved puzzle is always unlocked. Everything after it waits.
	return _resume_stage_index()


func _is_stage_completed(index: int) -> bool:
	if index < 0 or index >= stages.size():
		return false
	return completed_stage_ids.has(int(stages[index]["id"]))


func _all_stages_completed() -> bool:
	return not stages.is_empty() and completed_stage_ids.size() >= stages.size()


func _unlocked_tier_count() -> int:
	if stages.is_empty():
		return 1
	var unlocked_stage_id := _highest_unlocked_stage_index() + 1
	var count := 0
	for start_id in TIER_START_IDS:
		if int(start_id) <= unlocked_stage_id:
			count += 1
	return maxi(1, count)


func _show_tier_unlock(tier_index: int) -> void:
	if tier_index < 0 or tier_index >= TIER_NAMES.size() or status_label == null:
		return
	var serial := solve_flow_serial
	_show_tier_unlock_delayed(serial, String(TIER_NAMES[tier_index]))


func _show_tier_unlock_delayed(serial: int, tier_name: String) -> void:
	await get_tree().create_timer(0.24).timeout
	if serial != solve_flow_serial or not stage_solved:
		return
	status_label.text = "%s LIGHT UNLOCKED" % tier_name
	status_label.add_theme_color_override("font_color", COLOR_GOLD_HOT)
	status_label.modulate = Color(1.0, 1.0, 1.0, 0.35)
	var tween := create_tween()
	tween.tween_property(status_label, "modulate", Color.WHITE, 0.18)


func _refresh_progress_ui() -> void:
	if not progress_loaded or stages.is_empty():
		return
	var stage: Dictionary = stages[stage_index]
	var required := int(stage["posts"])
	var placed := ShadowRules.count_posts(posts)
	counter_label.text = "POSTS  %d / %d   ·   LIGHT  %d / %d" % [placed, required, completed_stage_ids.size(), stages.size()]
	_refresh_navigation_buttons()


func _refresh_navigation_buttons() -> void:
	if back_button != null:
		back_button.disabled = stage_index <= 0

	if next_button == null or stages.is_empty():
		return

	# During the v0.1.4 solve breath, Flow owns NEXT completely.
	if stage_solved:
		return

	if _is_stage_completed(stage_index) and stage_index < _highest_unlocked_stage_index():
		next_button.disabled = false
		next_button.text = "NEXT  ›"
	else:
		next_button.disabled = true
		next_button.text = "NEXT  ›"
