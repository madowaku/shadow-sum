extends SceneTree

const Rules = preload("res://src/shadow_rules.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Grant18 smoke: " + message)

func _bounds(node: Node, canvas: Rect2) -> void:
	for child: Node in node.get_children():
		if child is Control and child.is_visible_in_tree():
			check(canvas.grow(1.5).encloses(child.get_global_rect()), "out of canvas: " + str(child.name))
		_bounds(child, canvas)

func _grammar(scene: Node) -> void:
	for index: int in 25:
		var r: int = int(index / 5.0)
		var c: int = index % 5
		var hidden_clue: bool = int(scene.stages[scene.stage_index]["clues"][r][c]) < 0
		var glass: Control = scene.clue_glass_visuals[index]
		check(glass.mouse_filter == Control.MOUSE_FILTER_IGNORE, "material stole input")
		check(glass.clue_hidden == hidden_clue and not glass.revealed, "hint changed observation")
		if hidden_clue:
			check(glass.fog_amount == 1.0 and scene.clue_cells[index].get_child(0).text == "?", "hint leaked hidden value")

func _capture(scene: Node, name_value: String) -> void:
	var directory: String = OS.get_environment("SHADOW_SUM_CAPTURE_DIR")
	if directory.is_empty() or DisplayServer.get_name() == "headless":
		return
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	(scene.get_parent() as SubViewport).get_texture().get_image().save_png(directory.path_join(name_value + ".png"))

func _case(size_value: Vector2i) -> void:
	var path: String = "user://grant18_smoke_%d.json" % size_value.x
	for disposable: String in [path, path + ".session.json"]:
		if FileAccess.file_exists(disposable):
			DirAccess.remove_absolute(disposable)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size_value
	if not OS.get_environment("SHADOW_SUM_CAPTURE_DIR").is_empty():
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	scene.progress_path = path
	viewport.add_child(scene)
	for _frame: int in 4:
		await process_frame
	check(scene.stages.size() == 18 and scene.stage_index == 0, "wrong campaign")
	check(scene.DEFAULT_PROGRESS_PATH == "user://shadow_sum_grant18_progress_v1.json", "grant campaign reused old player progress")
	var authored: Array = scene.stages.duplicate(true)
	for stage_number: int in 18:
		check(scene.stage_index == stage_number, "NEXT skipped or failed a stage")
		var before: Array = scene.posts.duplicate(true)
		var completed: Dictionary = scene.completed_stage_ids.duplicate(true)
		await _capture(scene, "grant18_%d_%02d" % [size_value.x, stage_number + 1])
		if size_value.x == 405:
			var hints: Array = scene._current_whispers()
			check(hints.size() == (0 if stage_number == 3 else 3), "missing authored hints")
			for hint: Dictionary in hints:
				scene.hint_button.pressed.emit()
				var label: Label = scene.status_label
				var font: Font = label.get_theme_font("font")
				check(font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x <= label.size.x + 1.0, "hint text overflows: " + String(hint["text"]))
				await create_timer(0.12).timeout
				check(scene.posts == before and scene.completed_stage_ids == completed and not scene.stage_solved, "hint mutated puzzle/progress")
				_grammar(scene)
				# Let every delayed socket/assumption effect actually execute.
				await create_timer(1.1).timeout
				check(scene.posts == before and scene.completed_stage_ids == completed and not scene.stage_solved, "delayed hint changed authoritative state")
				_grammar(scene)
		# RESET must kill the active pulse itself, not only discard references.
		var old_motions: Array = scene.hint_tweens.duplicate()
		scene._reset_stage()
		for motion: Variant in old_motions:
			check(not motion.is_valid(), "reset retained a hint Tween")
		await create_timer(0.15).timeout
		_grammar(scene)
		_bounds(scene, Rect2(Vector2.ZERO, Vector2(size_value)))
		for array_value: Array in [scene.socket_visuals, scene.post_visuals, scene.clue_glass_visuals, scene.live_glass_visuals]:
			check(array_value.size() == 25, "material array changed")
		for code_value: String in scene.stages[stage_number]["solution"]:
			scene._toggle_post(int(code_value.substr(1)) - 1, code_value.unicode_at(0) - 65)
		check(scene.stage_solved and scene.next_button.disabled, "solve or breath changed")
		check(Rules.count_posts(scene.posts) == int(scene.stages[stage_number]["posts"]), "wrong Post count")
		await create_timer(0.44).timeout
		for index: int in 25:
			check(is_zero_approx(scene.clue_glass_visuals[index].fog_amount), "reveal did not finish inside breath")
		await create_timer(0.08).timeout
		check(not scene.next_button.disabled, "NEXT stayed locked")
		check(scene.completed_stage_ids.size() == stage_number + 1, "clear not recorded once")
		scene.next_button.pressed.emit()
		await process_frame
		await process_frame
	check(scene.stage_index == 17 and scene.status_label.text == "18 SHADOWS KEPT. Thank you for playing.", "missing submission ending")
	check(scene.stages == authored, "campaign mutated at runtime")
	for child: Node in scene.get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
	OS.delay_msec(100)
	viewport.queue_free()
	await process_frame
	for disposable: String in [path, path + ".session.json"]:
		if FileAccess.file_exists(disposable):
			DirAccess.remove_absolute(disposable)
	print("Grant18: all 18 puzzles solved through NEXT at %s" % str(size_value))

func _hint_cancellation() -> void:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(405, 900)
	root.add_child(viewport)
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	scene.progress_path = "user://grant18_hint_cancel.json"
	viewport.add_child(scene)
	await process_frame
	await process_frame
	for action: String in ["placement", "stage", "drag"]:
		scene._load_stage(12)
		if action == "drag":
			scene._toggle_post(0, 0)
		scene._on_hint_pressed()
		scene._on_hint_pressed()
		await create_timer(0.1).timeout
		var motions: Array = scene.hint_tweens.duplicate()
		match action:
			"placement": scene._toggle_post(0, 0)
			"stage": scene._load_stage(13)
			"drag": scene._begin_post_drag(0)
		var copy: String = scene.status_label.text
		for motion: Variant in motions:
			check(not motion.is_valid(), action + " retained a pulse")
		await create_timer(3.5).timeout
		check(scene.status_label.text == copy, action + " retained stale copy")
		check(scene.hint_overlays.is_empty() and scene.hint_tweens.is_empty(), "late hint overlay survived")
		if action == "drag": scene._finish_post_drag(-1)
	for child: Node in scene.get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
	OS.delay_msec(100)
	viewport.queue_free()
	await process_frame
	for path: String in ["user://grant18_hint_cancel.json", "user://grant18_hint_cancel.json.session.json"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func _run() -> void:
	for size_value: Vector2i in [Vector2i(405, 900), Vector2i(676, 900), Vector2i(720, 900)]:
		await _case(size_value)
	await _hint_cancellation()
	print("Grant18 smoke: %d failures" % failures)
	quit(1 if failures else 0)
