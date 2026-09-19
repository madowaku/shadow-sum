extends SceneTree

const Rules = preload("res://src/shadow_rules.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Shadow ink smoke: " + message)

func running(tween: Tween) -> bool:
	return tween != null and tween.is_valid() and tween.is_running()

func _solve(scene: Node, index: int) -> void:
	scene._load_stage(index)
	for code_value in scene.stages[index]["solution"]:
		var code: String = String(code_value)
		scene._toggle_post(int(code.substr(1)) - 1, code.unicode_at(0) - 65)

func _assert_rest(scene: Node) -> void:
	for glass in scene.live_glass_visuals:
		check(is_zero_approx(glass.display_level) and not running(glass.ink_tween), "stale LIVE after stage/reset")
	for post in scene.post_visuals:
		check(not post.visible and not running(post.seat_tween) and is_equal_approx(post.seat_scale, 1.0), "stale Post seat")
	for index in 25:
		var glass: Control = scene.clue_glass_visuals[index] as Control
		var hidden_clue: bool = int(scene.stages[scene.stage_index]["clues"][index / 5][index % 5]) < 0
		check(not running(glass.ink_tween) and not glass.revealed, "stale reveal")
		check(is_equal_approx(glass.fog_amount, 1.0 if hidden_clue else 0.0), "stale fog")

func _run() -> void:
	create_timer(30.0).timeout.connect(func() -> void:
		push_error("Shadow ink smoke timed out")
		quit(1))
	var packed: PackedScene = load("res://scenes/main.tscn") as PackedScene
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	check(is_equal_approx(scene.SOLVE_BREATH, 0.45), "solve breath duration changed")
	var script: Script = scene.get_script() as Script
	while script != null and script.resource_path != "res://src/shadow_ink_main.gd":
		script = script.get_base_script()
	check(script != null, "SHADOW INK is missing from the actual script inheritance chain")
	for inventory in [scene.socket_visuals, scene.post_visuals, scene.clue_glass_visuals, scene.live_glass_visuals]:
		check(inventory.size() == 25, "material inventory changed")
		for visual in inventory:
			check(visual.mouse_filter == Control.MOUSE_FILTER_IGNORE, "material intercepts input")

	# Interrupted material and semantic updates start at the current display.
	scene._load_stage(2)
	var before: Array = scene.posts.duplicate(true)
	var cell: PanelContainer = scene.live_cells[12] as PanelContainer
	var glass: Control = scene.live_glass_visuals[12] as Control
	scene._update_live_cell(cell, 3)
	var first: Tween = glass.ink_tween
	var first_color: Tween = cell.get_meta("semantic_tween") as Tween
	await create_timer(0.06).timeout
	var midway: float = glass.display_level
	check(midway > 0.0 and midway < 3.0, "ink did not interpolate")
	var midway_color: Color = (cell.get_theme_stylebox("panel") as StyleBoxFlat).bg_color
	scene._update_live_cell(cell, 1)
	check(not first_color.is_valid(), "old semantic color tween survived")
	check((cell.get_theme_stylebox("panel") as StyleBoxFlat).bg_color == midway_color, "semantic replacement snapped")
	check(not first.is_valid(), "old ink tween survived replacement")
	check(is_equal_approx(midway, glass.display_level), "replacement snapped instead of continuing")
	await create_timer(0.26).timeout
	check(is_equal_approx(glass.display_level, 1.0), "latest ink target did not win")
	check((cell.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.is_equal_approx(scene._shadow_style(1, false, false).bg_color), "semantic color missed latest target")
	check(scene.posts == before, "material animation changed Posts")
	scene._update_live_cell(cell, 3)
	scene._reset_stage()
	_assert_rest(scene)
	await create_timer(0.30).timeout
	_assert_rest(scene)

	# Real Stage002/003 transitions, including level 2 and level 3.
	for index in [0, 1, 2]:
		_solve(scene, index)
		var solved_posts: Array = scene.posts.duplicate(true)
		await create_timer(0.27).timeout
		var shadow: Array = Rules.compute_shadow(scene.posts)
		for i in 25:
			check(is_equal_approx(scene.live_glass_visuals[i].display_level, float(shadow[i / 5][i % 5])), "actual density did not settle")
		check(scene.posts == solved_posts, "seat/solve changed Posts")

	# Rapid socket crossings replace, never queue, ink tweens.
	scene._load_stage(3)
	scene._toggle_post(1, 1)
	check(is_equal_approx(scene.post_visuals[6].seat_scale, 0.94), "tap did not start mechanical seat")
	check(scene.post_buttons[6].scale == Vector2.ONE, "seat changed hit target transform")
	before = scene.posts.duplicate(true)
	check(scene._begin_post_drag(6, scene._post_center(6)), "drag failed to start")
	var old: Array[Tween] = []
	for target in [7, 8, 9, 14, 13, 12, 11, 10, 5, 0, 1, 2, 3]:
		for visual in scene.live_glass_visuals:
			if running(visual.ink_tween):
				old.append(visual.ink_tween)
		scene._set_drag_target(target)
	check(scene.posts == before, "preview mutated Posts")
	await create_timer(0.12).timeout
	for tween in old:
		check(not running(tween), "preview tween backlog")
	check(not scene._finish_post_drag(6), "cancel committed")
	await create_timer(0.26).timeout
	var authoritative: Array = Rules.compute_shadow(before)
	for i in 25:
		check(is_equal_approx(scene.live_glass_visuals[i].display_level, float(authoritative[i / 5][i % 5])), "cancel did not restore authoritative display")
	check(scene.posts == before, "cancel mutated Posts")
	check(scene._begin_post_drag(6, scene._post_center(6)), "second drag failed")
	scene._set_drag_target(7)
	check(scene._finish_post_drag(7), "valid drop failed")
	var expected: Array = before.duplicate(true)
	expected[1][1] = false
	expected[1][2] = true
	check(scene.posts == expected, "drop did not commit exactly one move")
	check(not scene._finish_post_drag(7) and scene.posts == expected, "duplicate release committed")
	check(scene.post_visuals[7].visible and is_equal_approx(scene.post_visuals[7].seat_scale, 0.94), "drop seat missing")
	await create_timer(0.20).timeout
	check(is_equal_approx(scene.post_visuals[7].seat_scale, 1.0), "seat did not finish")
	check(not scene.socket_visuals[6].occupied and scene.socket_visuals[7].occupied, "socket state stale")
	scene._load_stage(3)
	_assert_rest(scene)
	for i in 25:
		if int(scene.stages[3]["clues"][i / 5][i % 5]) < 0:
			check(scene.clue_glass_visuals[i].clue_hidden and scene.clue_glass_visuals[i].fog_amount == 1.0, "Stage004 frost lost")
			check(scene.clue_cells[i].get_child(0).text == "?", "Stage004 question mark lost")

	# Every authored hidden board must finish before the unchanged breath.
	for stage in range(3, scene.stages.size()):
		_solve(scene, stage)
		check(scene.stage_solved and scene.next_button.disabled, "solve/breath contract changed")
		before = scene.posts.duplicate(true)
		await create_timer(0.10).timeout
		check(scene.next_button.disabled, "NEXT unlocked early")
		await create_timer(0.33).timeout
		var truth: Array = Rules.compute_shadow(before)
		for i in 25:
			var target: Control = scene.clue_glass_visuals[i] as Control
			if int(scene.stages[stage]["clues"][i / 5][i % 5]) < 0:
				check(target.revealed and is_zero_approx(target.fog_amount), "reveal missed breath deadline")
				check(is_equal_approx(target.display_level, float(truth[i / 5][i % 5])) and not running(target.ink_tween), "density/glint unfinished by breath")
			else:
				check(not target.revealed and is_zero_approx(target.glint), "visible TARGET joined solve parade")
		check(scene.posts == before, "reveal mutated Posts")
		await create_timer(0.06).timeout
		check(not scene.next_button.disabled, "NEXT did not unlock after breath")

	# Interrupt reveal before its delayed cells start; verify again after all old deadlines.
	for action in ["reset", "load", "back", "next"]:
		_solve(scene, 3)
		await create_timer(0.025).timeout
		match action:
			"reset": scene._reset_stage()
			"load": scene._load_stage(1)
			"back": scene._go_previous_stage()
			"next": scene._next_stage()
		print("Navigation ", action, " -> stage ", scene.stage_index)
		_assert_rest(scene)
		await create_timer(0.55).timeout
		_assert_rest(scene)
		check(scene.next_button.text == "NEXT  ›", "stale breath changed new stage NEXT")
	# Reset an active drag and prevent late release from committing to the new board.
	scene._load_stage(3)
	scene._toggle_post(1, 1)
	scene._begin_post_drag(6, scene._post_center(6))
	scene._set_drag_target(7)
	scene._reset_stage()
	check(not scene.drag_active and not scene._finish_post_drag(7), "reset retained an old drag")
	_assert_rest(scene)
	await create_timer(0.55).timeout
	_assert_rest(scene)
	print("Shadow ink smoke: %d failures; latest state, seat, drag, all hidden reveals, navigation and breath checked" % failures)
	for child in scene.get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
	# Fixed-fps simulation outruns the real-time audio mixer. Drain stopped
	# playback only after all assertions; this does not relax motion deadlines.
	OS.delay_msec(100)
	await process_frame
	scene.queue_free()
	await process_frame
	quit(1 if failures else 0)
