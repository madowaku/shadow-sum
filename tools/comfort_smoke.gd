extends SceneTree

const Rules = preload("res://src/shadow_rules.gd")
const SAVE: String = "user://comfort_smoke_progress.json"
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Comfort smoke: " + message)

func _cleanup() -> void:
	for path: String in [SAVE, SAVE + ".session.json", SAVE + ".session.json.tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func _new(size: Vector2i = Vector2i(405, 900)) -> Node:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	if not OS.get_environment("SHADOW_SUM_CAPTURE_DIR").is_empty():
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	scene.progress_path = SAVE
	viewport.add_child(scene)
	for _frame: int in 4:
		await process_frame
	return scene

func _dispose(scene: Node) -> void:
	for child: Node in scene.get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
	OS.delay_msec(100)
	scene.get_parent().queue_free()
	await process_frame

func _write(payload: Variant) -> void:
	var file: FileAccess = FileAccess.open(SAVE + ".session.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

func _run() -> void:
	_cleanup()
	var scene: Node = await _new()
	check(scene.get_script().resource_path == "res://src/comfort_main.gd", "wrong root")
	check(scene.undo_button.disabled, "fresh undo enabled")
	var stages_before: Array = scene.stages.duplicate(true)
	scene._toggle_post(0, 0)
	check(scene.undo_history.size() == 1 and not scene.undo_button.disabled, "placement history")
	var placed: Array = scene.posts.duplicate(true)
	scene._toggle_post(0, 1)
	check(scene.undo_history.size() == 1 and scene.posts == placed, "rejected placement added history")
	scene._toggle_post(0, 0)
	check(scene.undo_history.size() == 2, "removal history")
	scene.undo_button.pressed.emit()
	check(scene.posts == placed, "undo removal")
	scene._begin_post_drag(0)
	scene._set_drag_target(1)
	var save_before: String = FileAccess.get_file_as_string(SAVE + ".session.json")
	scene._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(scene.posts == placed and scene.undo_history.size() == 1, "preview mutated committed state")
	check(save_before == FileAccess.get_file_as_string(SAVE + ".session.json"), "pause persisted preview")
	scene._finish_post_drag(-1)
	check(scene.undo_history.size() == 1, "cancel added history")
	scene._begin_post_drag(0)
	scene._set_drag_target(1)
	check(scene._finish_post_drag(1), "valid drop rejected")
	check(scene.undo_history.size() == 2, "drag must be one history entry")
	scene._undo_move()
	check(scene.posts == placed, "undo drag")
	scene._begin_post_drag(0)
	scene._set_drag_target(1)
	scene._undo_move()
	check(not scene.drag_active and Rules.count_posts(scene.posts) == 0, "undo did not cancel preview")
	await create_timer(0.3).timeout
	for visual: Control in scene.live_glass_visuals:
		check(is_zero_approx(visual.display_level), "old preview tween survived undo")
	scene._toggle_post(0, 0)
	scene.reset_button.pressed.emit()
	check(Rules.count_posts(scene.posts) == 0, "reset failed")
	scene._undo_move()
	check(scene.posts == placed, "reset not undoable")
	check(scene.completed_stage_ids.is_empty() and scene.stages == stages_before, "comfort changed puzzle/progress")
	await _dispose(scene)
	scene = await _new()
	check(scene.stage_index == 0 and scene.posts == placed and not scene.stage_solved, "restart lost partial board")
	check(scene.undo_history.is_empty(), "old session history retained")
	check(scene.live_glass_visuals[1].display_level == 1.0, "restored material density")
	scene._reset_stage()
	await _dispose(scene)
	scene = await _new()
	check(Rules.count_posts(scene.posts) == 0, "reset did not persist")
	scene._toggle_post(2, 2)
	check(scene.stage_solved and scene.undo_button.disabled and scene.completed_stage_ids.has(1), "solve changed")
	check(scene.next_button.disabled, "solve breath bypassed")
	scene._undo_move()
	check(scene.stage_solved, "undo rolled back clear")
	await create_timer(0.5).timeout
	check(not scene.next_button.disabled, "solve breath did not finish")
	await _dispose(scene)
	scene = await _new()
	check(scene.stage_index == 1 and Rules.count_posts(scene.posts) == 0, "solved checkpoint overrode progress")
	# Unlock Stage004 using normal solves.
	scene._toggle_post(1, 1)
	scene._toggle_post(2, 2)
	scene._load_stage(2)
	scene._toggle_post(0, 0)
	scene._on_hint_pressed()
	var consumed_hint: int = scene.whisper_index
	scene._undo_move()
	check(consumed_hint == 1 and scene.whisper_index == consumed_hint, "undo refunded a hint")
	scene._toggle_post(1, 2)
	scene._toggle_post(2, 1)
	scene._toggle_post(2, 3)
	scene._load_stage(3)
	check(scene.undo_history.is_empty(), "stage change retained history")
	scene._toggle_post(0, 0)
	var stage_four_posts: Array = scene.posts.duplicate(true)
	await _dispose(scene)
	scene = await _new()
	check(scene.stage_index == 3 and scene.posts == stage_four_posts, "Stage004 restart")
	for index: int in 25:
		if int(scene.stages[3]["clues"][int(index / 5.0)][index % 5]) < 0:
			check(scene.clue_cells[index].get_child(0).text == "?" and scene.clue_glass_visuals[index].fog_amount == 1.0, "restore revealed unknown")
	var hint_before: int = scene.whisper_index
	scene._toggle_post(0, 1)
	scene._undo_move()
	check(scene.whisper_index == hint_before and not scene.unknown_intro_active, "undo changed hint usage or left intro running")
	var valid: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE + ".session.json"))
	await _dispose(scene)
	# Reject corrupt, stale, locked, oversized and already-solved snapshots.
	var cases: Array = [[], {"version": 99}, valid.duplicate(true), valid.duplicate(true), valid.duplicate(true), valid.duplicate(true), valid.duplicate(true), valid.duplicate(true)]
	cases[2]["posts"] = [[true]]
	cases[3]["posts"][0][0] = "true"
	cases[4]["fingerprint"] = "changed puzzle"
	cases[5]["clears"] = "[]"
	cases[6]["stage_id"] = 18
	for row: Array in cases[7]["posts"]:
		row.fill(true)
	for payload: Variant in cases:
		_write(payload)
		scene = await _new()
		check(scene.stage_index == 3 and Rules.count_posts(scene.posts) == 0, "invalid snapshot accepted")
		check(scene.completed_stage_ids.size() == 3, "invalid snapshot changed clears")
		await _dispose(scene)
	var solved: Dictionary = valid.duplicate(true)
	solved["posts"] = Rules.make_empty_posts()
	var stage_data: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/stages_v0_1.json"))
	for code: String in stage_data[3]["solution"]:
		solved["posts"][int(code.substr(1)) - 1][code.unicode_at(0) - 65] = true
	_write(solved)
	scene = await _new()
	check(not scene.stage_solved and scene.completed_stage_ids.size() == 3 and Rules.count_posts(scene.posts) == 0, "snapshot awarded a clear")
	await _dispose(scene)
	var broken_file: FileAccess = FileAccess.open(SAVE + ".session.json", FileAccess.WRITE)
	broken_file.store_string("{truncated")
	broken_file.close()
	scene = await _new()
	check(Rules.count_posts(scene.posts) == 0, "malformed JSON accepted")
	await _dispose(scene)
	_write(valid)
	scene = await _new()
	scene._reset_stage()
	for code: String in scene.stages[3]["solution"]:
		scene._toggle_post(int(code.substr(1)) - 1, code.unicode_at(0) - 65)
	await create_timer(0.44).timeout
	check(scene.stage_solved, "Stage004 no longer solves")
	for index: int in 25:
		if int(scene.stages[3]["clues"][int(index / 5.0)][index % 5]) < 0:
			check(scene.clue_glass_visuals[index].fog_amount == 0.0, "solve reveal regressed")
	await _dispose(scene)
	for size: Vector2i in [Vector2i(405, 900), Vector2i(676, 900), Vector2i(720, 900)]:
		scene = await _new(size)
		var footer: HBoxContainer = scene.undo_button.get_parent()
		var previous: Rect2 = Rect2()
		for child: Node in footer.get_children():
			var button: Button = child as Button
			var bounds: Rect2 = button.get_global_rect()
			check(Rect2(Vector2.ZERO, Vector2(size)).encloses(bounds), "footer out of bounds")
			check(bounds.size.y >= 44.0 and bounds.size.x >= 48.0, "small footer hit target")
			check(not previous.intersects(bounds), "overlapping footer")
			previous = bounds
		var capture: String = OS.get_environment("SHADOW_SUM_CAPTURE_DIR")
		if not capture.is_empty() and DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			(scene.get_parent() as SubViewport).get_texture().get_image().save_png(capture.path_join("comfort_%d.png" % size.x))
		await _dispose(scene)
	_cleanup()
	print("Comfort smoke: %d failures; undo, reset, preview isolation, restart, save validation, solve and layouts" % failures)
	quit(1 if failures > 0 else 0)
