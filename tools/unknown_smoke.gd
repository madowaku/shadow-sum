extends SceneTree

const Rules = preload("res://src/shadow_rules.gd")
var failures: int = 0
var case_number: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Unknown smoke: " + message)

func _new_scene(size: Vector2i = Vector2i(405, 900), resume_path: String = "") -> Node:
	var viewport: SubViewport = SubViewport.new()
	viewport.size = size
	if not OS.get_environment("SHADOW_SUM_CAPTURE_DIR").is_empty():
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var scene: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	case_number += 1
	# Separate disposable progress fixtures; never read or remove player saves.
	scene.progress_path = "user://unknown_smoke_case_%d.json" % case_number if resume_path.is_empty() else resume_path
	if resume_path.is_empty() and FileAccess.file_exists(scene.progress_path):
		DirAccess.remove_absolute(scene.progress_path)
	viewport.add_child(scene)
	await process_frame
	await process_frame
	await process_frame
	return scene

func _dispose(scene: Node) -> void:
	for child in scene.get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
	OS.delay_msec(100)
	scene.get_parent().queue_free()
	await process_frame

func _snapshot(scene: Node) -> Dictionary:
	return {
		"posts": scene.posts.duplicate(true), "stages": scene.stages.duplicate(true),
		"stage_index": scene.stage_index, "count": Rules.count_posts(scene.posts),
		"completed": scene.completed_stage_ids.duplicate(true), "solved": scene.stage_solved,
		"hint_index": scene.whisper_index, "hint_serial": scene.whisper_serial,
		"hint_catalog": scene.whisper_catalog.duplicate(true),
		"save": FileAccess.get_file_as_string(scene.progress_path) if FileAccess.file_exists(scene.progress_path) else "<absent>"
	}

func _grammar(scene: Node) -> void:
	for i in 25:
		var clue: int = int(scene.stages[scene.stage_index]["clues"][i / 5][i % 5])
		var glass: Control = scene.clue_glass_visuals[i] as Control
		check(glass.clue_hidden == (clue < 0) and not glass.revealed, "onboarding changed hidden/reveal state")
		check(is_equal_approx(glass.fog_amount, 1.0 if clue < 0 else 0.0), "onboarding changed fog")
		check(glass.value == maxi(0, clue) and is_equal_approx(glass.display_level, float(maxi(0, clue))), "onboarding changed density")
		if clue < 0:
			check(scene.clue_cells[i].get_child(0).text == "?", "question mark lost")
		check(glass.mouse_filter == Control.MOUSE_FILTER_IGNORE, "material intercepted input")
		check(scene.clue_cells[i].scale == Vector2.ONE and scene.clue_cells[i].modulate == Color.WHITE, "onboarding transformed the panel")
	for button in scene.post_buttons:
		check(not button.disabled, "onboarding locked input")

func _rest(scene: Node) -> void:
	check(not scene.unknown_intro_active and scene.unknown_intro_beat == 0, "intro still active")
	for glass in scene.clue_glass_visuals:
		check(is_zero_approx(glass.notation_strength) and not glass.notation_owned, "stale notation rim")

func _bounds(node: Node, canvas: Rect2) -> void:
	for child in node.get_children():
		if child is Control and child.is_visible_in_tree():
			check(canvas.grow(1.5).encloses(child.get_global_rect()), "control outside canvas: " + str(child.name))
		_bounds(child, canvas)

func _sequence(size: Vector2i) -> void:
	var scene: Node = await _new_scene(size)
	var layer: Script = scene.get_script()
	while layer != null and layer.resource_path != "res://src/unknown_main.gd":
		layer = layer.get_base_script()
	check(layer != null, "UNKNOWN layer missing from main inheritance")
	for stage in 3:
		scene._load_stage(stage)
		await create_timer(0.15).timeout
		check(not scene.unknown_intro_active and not scene.unknown_intro_shown_this_session, "intro fired in Stage001-003")
	scene._load_stage(3)
	check(scene.unknown_intro_active and scene.unknown_intro_shown_this_session, "first Stage004 entry did not schedule intro")
	var expected_clear: int = -1
	var expected_fog: int = -1
	for i in 25:
		var clue: int = int(scene.stages[3]["clues"][i / 5][i % 5])
		if clue == 0 and expected_clear < 0:
			expected_clear = i
		if clue == -1 and expected_fog < 0:
			expected_fog = i
	check(expected_clear >= 0 and expected_fog >= 0, "Stage004 grammar examples absent")
	check(scene.unknown_clear_index == expected_clear and scene.unknown_fog_index == expected_fog, "examples not selected from actual data")
	var before: Dictionary = _snapshot(scene)
	var normal_status: String = scene.status_label.text
	check(scene._current_whispers().is_empty(), "Stage004 must not acquire WHISPER content")
	for beat in [1, 2, 3]:
		await create_timer(0.25 if beat == 1 else (1.0 if beat == 2 else 1.2)).timeout
		check(scene.unknown_intro_beat == beat, "beat order/timing changed")
		var copy: String = scene.status_label.text
		check(copy == "CLEAR GLASS  =  NO SHADOW" if beat == 1 else (copy in ["FOGGED GLASS  =  SHADOW UNOBSERVED", "FOGGED  =  UNOBSERVED"] if beat == 2 else copy == "UNKNOWN  ≠  ZERO"), "wrong teaching copy")
		check(_snapshot(scene) == before, "onboarding mutated authoritative state")
		_grammar(scene)
		var highlighted: int = expected_clear if beat == 1 else expected_fog
		check(scene.clue_glass_visuals[highlighted].notation_strength > 0.0, "selected cell was not emphasized")
		for i in 25:
			if i != highlighted:
				check(is_zero_approx(scene.clue_glass_visuals[i].notation_strength), "unrelated TARGET emphasized")
		var font: Font = scene.status_label.get_theme_font("font")
		check(font.get_string_size(copy, HORIZONTAL_ALIGNMENT_LEFT, -1, scene.status_label.get_theme_font_size("font_size")).x <= scene.status_label.size.x + 1.0, "copy overflows status")
		_bounds(scene, Rect2(Vector2.ZERO, Vector2(size)))
		var capture_directory: String = OS.get_environment("SHADOW_SUM_CAPTURE_DIR")
		if not capture_directory.is_empty() and DisplayServer.get_name() != "headless":
			DirAccess.make_dir_recursive_absolute(capture_directory)
			await RenderingServer.frame_post_draw
			(scene.get_parent() as SubViewport).get_texture().get_image().save_png(capture_directory.path_join("unknown_%d_beat%d.png" % [size.x, beat]))
	await create_timer(0.85).timeout
	_rest(scene)
	check(scene.status_label.text == normal_status and _snapshot(scene) == before, "normal status/state not restored")
	_grammar(scene)
	scene._reset_stage()
	scene._go_previous_stage()
	scene._load_stage(3)
	await create_timer(0.2).timeout
	_rest(scene)
	check(scene.unknown_intro_shown_this_session, "session flag was reset")
	# Existing SHADOW INK reveal and flow after notation teaching.
	for code_value in scene.stages[3]["solution"]:
		var code: String = String(code_value)
		scene._toggle_post(int(code.substr(1)) - 1, code.unicode_at(0) - 65)
	check(scene.stage_solved and scene.next_button.disabled, "solve/breath changed")
	await create_timer(0.43).timeout
	var shadow: Array = Rules.compute_shadow(scene.posts)
	for i in 25:
		var glass: Control = scene.clue_glass_visuals[i] as Control
		if int(scene.stages[3]["clues"][i / 5][i % 5]) < 0:
			check(glass.revealed and is_zero_approx(glass.fog_amount) and is_equal_approx(glass.display_level, float(shadow[i / 5][i % 5])), "SHADOW INK reveal regressed")
	await create_timer(0.1).timeout
	check(not scene.next_button.disabled, "NEXT did not unlock")
	print("Unknown sequence/layout/solve OK: ", size)
	await _dispose(scene)

func _cancellation(action: String) -> void:
	var scene: Node = await _new_scene()
	scene._load_stage(3)
	await create_timer(0.02 if action == "early" else (0.25 if action == "post" or action == "drag" else 1.3)).timeout
	var serial: int = scene.unknown_intro_serial
	match action:
		"early", "post": scene.post_buttons[6].pressed.emit()
		"drag":
			scene.post_buttons[6].pressed.emit()
			check(scene._begin_post_drag(6, scene._post_center(6)), "drag input blocked")
			scene._finish_post_drag(6)
		"reset": scene.reset_button.pressed.emit()
		"back": scene.back_button.pressed.emit()
		"load": scene._load_stage(1)
		"next": scene._next_stage() # Unsolved NEXT remains blocked by existing flow.
		"hint": scene._on_hint_pressed() # No Stage004 WHISPER is synthesized.
	check(scene.unknown_intro_serial > serial, "cancel did not invalidate serial")
	_rest(scene)
	if action in ["early", "post", "drag"]:
		check(Rules.count_posts(scene.posts) == 1 and scene.posts[1][1], "placement was blocked or changed")
	var after: Dictionary = _snapshot(scene)
	var expected_status: String = scene.status_label.text
	await create_timer(3.4).timeout
	_rest(scene)
	check(scene.status_label.text == expected_status and _snapshot(scene) == after, "stale callback overwrote new status/state after " + action)
	scene._load_stage(3)
	await create_timer(0.2).timeout
	_rest(scene)
	_grammar(scene)
	print("Unknown cancellation OK: ", action)
	await _dispose(scene)

func _resume_and_hint_priority() -> void:
	var scene: Node = await _new_scene()
	for index in 3:
		scene._load_stage(index)
		for code_value in scene.stages[index]["solution"]:
			var code: String = String(code_value)
			scene._toggle_post(int(code.substr(1)) - 1, code.unicode_at(0) - 65)
		await create_timer(0.5).timeout
	scene.next_button.pressed.emit()
	check(scene.stage_index == 3 and scene.unknown_intro_active, "natural progression did not trigger Stage004")
	var saved_path: String = scene.progress_path
	scene._reset_stage()
	await create_timer(0.2).timeout
	await _dispose(scene)
	scene = await _new_scene(Vector2i(405, 900), saved_path)
	check(scene.stage_index == 3 and not scene.stage_solved and scene.unknown_intro_active, "restart did not teach resumed unsolved Stage004")
	var save_before: String = FileAccess.get_file_as_string(saved_path)
	await create_timer(1.3).timeout
	check(scene.unknown_intro_beat == 2, "resumed intro did not progress")
	check(FileAccess.get_file_as_string(saved_path) == save_before, "onboarding wrote save data")
	scene._load_stage(2)
	scene.hint_button.pressed.emit()
	var hint_copy: String = scene.status_label.text
	var hint_index: int = scene.whisper_index
	check(hint_index == 1, "actual Stage003 WHISPER did not run")
	await create_timer(1.4).timeout
	check(scene.status_label.text == hint_copy and scene.whisper_index == hint_index, "old onboarding overwrote WHISPER")
	await create_timer(2.0).timeout
	check(scene.status_label.text == "Shape the observed shadow.", "WHISPER status restoration regressed")
	_rest(scene)
	print("Unknown resume/save/WHISPER priority OK")
	await _dispose(scene)

func _run() -> void:
	create_timer(90.0).timeout.connect(func() -> void:
		push_error("Unknown smoke timed out")
		quit(1))
	for size in [Vector2i(405, 900), Vector2i(676, 900), Vector2i(720, 900)]:
		await _sequence(size)
	for action in ["early", "post", "drag", "reset", "back", "load", "next", "hint"]:
		await _cancellation(action)
	await _resume_and_hint_priority()
	print("Unknown smoke: %d failures; one-shot notation, non-destruction, cancellation, reveal and three layouts" % failures)
	quit(1 if failures else 0)
