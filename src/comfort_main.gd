extends "res://src/unknown_main.gd"

# Player convenience only; rules, previews and clear progression stay upstream.
var undo_button: Button
var undo_history: Array = []
var comfort_ready: bool = false
const HISTORY_LIMIT: int = 100
const ProductUI = preload("res://src/ui/product_ui.gd")
var product_ui: Control

func _ready() -> void:
	super._ready()
	undo_button = Button.new()
	undo_button.name = "UndoButton"
	undo_button.text = "UNDO"
	undo_button.pressed.connect(_undo_move)
	var footer: HBoxContainer = reset_button.get_parent() as HBoxContainer
	footer.add_child(undo_button)
	footer.move_child(undo_button, reset_button.get_index() + 1)
	_restore_session()
	comfort_ready = true
	_apply_responsive_layout()
	_refresh_undo()
	product_ui = ProductUI.new()
	add_child(product_ui)

func _apply_responsive_layout() -> void:
	super._apply_responsive_layout()
	if is_instance_valid(product_ui) and product_ui.is_node_ready():
		product_ui.reflow()

func _apply_night_static_skin() -> void:
	super._apply_night_static_skin()
	if is_instance_valid(product_ui) and product_ui.is_node_ready():
		product_ui.reflow()

func _update_all() -> void:
	super._update_all()
	if is_instance_valid(product_ui) and product_ui.is_node_ready():
		product_ui.refresh()

func _refresh_progress_ui() -> void:
	super._refresh_progress_ui()
	if is_instance_valid(product_ui) and product_ui.is_node_ready():
		product_ui.refresh()

func _play_micro_tone(start_hz: float, end_hz: float, duration: float, amplitude: float, volume_db: float) -> void:
	if is_instance_valid(product_ui) and product_ui.muted:
		return
	super._play_micro_tone(start_hz, end_hz, duration, amplitude, volume_db)

func _apply_night_footer_skin() -> void:
	super._apply_night_footer_skin()
	if undo_button == null:
		return
	var footer: HBoxContainer = undo_button.get_parent() as HBoxContainer
	footer.add_theme_constant_override("separation", 6 if compact_layout else 9)
	for child: Node in footer.get_children():
		if child is Button:
			var button: Button = child as Button
			button.custom_minimum_size = Vector2(60 if compact_layout else 104, 44)
			if button == next_button and compact_layout:
				button.custom_minimum_size.x = 92

func _load_stage(index: int) -> void:
	undo_history.clear()
	super._load_stage(index)
	_refresh_undo()
	_save_session()

func _toggle_post(r: int, c: int) -> void:
	var before: Array = posts.duplicate(true)
	super._toggle_post(r, c)
	_record_move(before)

func _finish_post_drag(index: int) -> bool:
	var before: Array = posts.duplicate(true)
	var moved: bool = super._finish_post_drag(index)
	_record_move(before)
	return moved

func _reset_stage() -> void:
	var before: Array = posts.duplicate(true)
	var was_solved: bool = stage_solved
	super._reset_stage()
	if was_solved:
		undo_history.clear()
	else:
		_record_move(before)
	_refresh_undo()
	_save_session()

func _record_move(before: Array) -> void:
	if before == posts:
		return
	if stage_solved:
		undo_history.clear()
	else:
		undo_history.append(before)
		if undo_history.size() > HISTORY_LIMIT:
			undo_history.pop_front()
	_refresh_undo()
	_save_session()

func _refresh_undo() -> void:
	if undo_button != null:
		undo_button.disabled = stage_solved or undo_history.is_empty()

func _undo_move() -> void:
	if stage_solved or undo_history.is_empty():
		return
	_cancel_unknown_intro(false)
	whisper_serial += 1
	for motion: Variant in hint_tweens:
		if motion is Tween and motion.is_valid():
			motion.kill()
	_reset_hint_visuals()
	_cancel_ink_presentation()
	posts = undo_history.pop_back()
	ink_immediate = false
	_update_all()
	_refresh_hint_button()
	_refresh_undo()
	_save_session()

func _session_path() -> String:
	# Follows test/profile overrides; never touches another profile's save.
	return progress_path + ".session.json"

func _clear_signature() -> String:
	var ids: Array = completed_stage_ids.keys()
	ids.sort()
	return JSON.stringify(ids)

func _stage_signature(index: int) -> String:
	var stage: Dictionary = stages[index]
	return JSON.stringify([stage["id"], stage["posts"], stage["clues"], stage["solution"]]).sha256_text()

func _save_session() -> void:
	if not comfort_ready or stages.is_empty():
		return
	var payload: Dictionary = {"version": 1, "clears": _clear_signature()}
	if not stage_solved:
		payload["stage_id"] = int(stages[stage_index]["id"])
		payload["fingerprint"] = _stage_signature(stage_index)
		payload["posts"] = posts
	var temporary: String = _session_path() + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("Could not save current puzzle")
		return
	file.store_string(JSON.stringify(payload))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK or DirAccess.rename_absolute(temporary, _session_path()) != OK:
		push_warning("Could not replace current puzzle save")

func _restore_session() -> void:
	if not FileAccess.file_exists(_session_path()):
		return
	var file: FileAccess = FileAccess.open(_session_path(), FileAccess.READ)
	if file == null:
		return
	var parser: JSON = JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return
	var payload: Variant = parser.data
	if not payload is Dictionary or payload.get("version") != 1 or payload.get("clears") != _clear_signature():
		return
	var saved_index: int = -1
	for index: int in stages.size():
		if payload.get("stage_id") == int(stages[index]["id"]):
			saved_index = index
			break
	if saved_index < 0 or saved_index > _highest_unlocked_stage_index():
		return
	if payload.get("fingerprint") != _stage_signature(saved_index):
		return
	var board: Variant = payload.get("posts")
	if not board is Array or board.size() != ShadowRules.BOARD_SIZE:
		return
	for row: Variant in board:
		if not row is Array or row.size() != ShadowRules.BOARD_SIZE:
			return
		for value: Variant in row:
			if not value is bool:
				return
	var count: int = ShadowRules.count_posts(board)
	var required: int = int(stages[saved_index]["posts"])
	if count > required:
		return
	if count == required and ShadowRules.matches_visible_clues(ShadowRules.compute_shadow(board), stages[saved_index]["clues"]):
		return
	if saved_index != stage_index:
		_load_stage(saved_index)
	_cancel_ink_presentation()
	posts = board.duplicate(true)
	_update_all()
	ink_immediate = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_save_session()
