extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Glass metal smoke: %s" % message)
	quit(1)

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("could not load main scene")
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var phase := OS.get_environment("SHADOW_SUM_GLASS_PHASE")
	if phase.is_empty():
		phase = "all"

	if not _check_script(scene):
		return
	if phase == "script":
		print("Glass metal smoke script OK")
		quit(0)
		return

	if not _check_arrays(scene):
		return
	if phase == "arrays":
		print("Glass metal smoke arrays OK")
		quit(0)
		return

	if not _check_children(scene):
		return
	if phase == "children" or phase == "inventory":
		print("Glass metal smoke inventory OK")
		quit(0)
		return

	if phase == "solve" or phase == "all":
		if not await _check_stage001_solve(scene):
			return
		if phase == "solve":
			print("Glass metal smoke solve OK")
			quit(0)
			return

	if phase == "hidden" or phase == "all":
		if not await _check_hidden_glass(scene):
			return
		if phase == "hidden":
			print("Glass metal smoke hidden glass OK")
			quit(0)
			return

	if phase == "drag" or phase == "all":
		if not await _check_drag(scene):
			return
		if phase == "drag":
			print("Glass metal smoke drag OK")
			quit(0)
			return

	if phase != "all":
		_fail("unknown phase %s" % phase)
		return

	print("Glass metal smoke OK: material slots, frosted clues, physical Posts and drag isolation")
	quit(0)

func _check_script(scene: Node) -> bool:
	var script := scene.get_script() as Script
	var script_path := script.resource_path if script != null else ""
	if not script_path.ends_with("glass_metal_main.gd"):
		_fail("main scene is not using glass_metal_main.gd: %s" % script_path)
		return false
	return true

func _check_arrays(scene: Node) -> bool:
	if scene.socket_visuals.size() != 25 or scene.post_visuals.size() != 25:
		_fail("expected 25 material slots, got sockets=%d posts=%d" % [scene.socket_visuals.size(), scene.post_visuals.size()])
		return false
	if scene.clue_glass_visuals.size() != 25 or scene.live_glass_visuals.size() != 25:
		_fail("expected 25 target/live glass overlays, got target=%d live=%d" % [scene.clue_glass_visuals.size(), scene.live_glass_visuals.size()])
		return false
	return true

func _check_children(scene: Node) -> bool:
	for index in 25:
		var button := scene.post_buttons[index] as Button
		if button.get_node_or_null("SocketVisual") == null or button.get_node_or_null("PostVisual") == null:
			_fail("missing material child at socket %d" % index)
			return false
	return true

func _check_stage001_solve(scene: Node) -> bool:
	scene._load_stage(0)
	var c3 := 2 * 5 + 2
	if (scene.post_visuals[c3] as Control).visible:
		_fail("empty C3 should not display a Post")
		return false
	scene._toggle_post(2, 2)
	await create_timer(0.30).timeout
	if not scene.stage_solved or not (scene.post_visuals[c3] as Control).visible:
		_fail("Stage001 solve or Post material visibility failed")
		return false
	return true

func _check_hidden_glass(scene: Node) -> bool:
	scene._load_stage(3)
	await process_frame
	var hidden_found := false
	for index in 25:
		var r := index / 5
		var c := index % 5
		if int(scene.stages[3]["clues"][r][c]) < 0:
			hidden_found = true
			var glass = scene.clue_glass_visuals[index]
			if glass == null or not bool(glass.hidden):
				_fail("hidden clue %d did not enter frosted state" % index)
				return false
			break
	if not hidden_found:
		_fail("Stage004 unexpectedly contains no hidden clue")
		return false
	return true

func _check_drag(scene: Node) -> bool:
	scene._load_stage(1)
	scene._toggle_post(1, 1) # B2
	await process_frame
	var before: Array = scene.posts.duplicate(true)
	var source := 1 * 5 + 1
	if not scene._begin_post_drag(source, scene._post_center(source)):
		_fail("could not start occupied Post drag")
		return false
	await process_frame
	if scene.posts != before:
		_fail("drag preview mutated authoritative Posts")
		return false
	if scene.drag_ghost == null or not scene.drag_ghost.visible or scene.drag_ghost.get_node_or_null("GhostPostVisual") == null:
		_fail("physical drag ghost missing")
		return false
	scene._finish_post_drag(source)
	return true
