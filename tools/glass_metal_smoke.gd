extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Glass metal smoke: could not load main scene")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	var script_path := String(scene.get_script().resource_path)
	if not script_path.ends_with("glass_metal_main.gd"):
		push_error("Glass metal smoke: main scene is not using glass_metal_main.gd: %s" % script_path)
		quit(1)
		return

	if scene.socket_visuals.size() != 25 or scene.post_visuals.size() != 25:
		push_error("Glass metal smoke: expected 25 material slots, got sockets=%d posts=%d" % [scene.socket_visuals.size(), scene.post_visuals.size()])
		quit(1)
		return
	if scene.clue_glass_visuals.size() != 25 or scene.live_glass_visuals.size() != 25:
		push_error("Glass metal smoke: expected 25 target/live glass overlays")
		quit(1)
		return

	for index in 25:
		var button := scene.post_buttons[index] as Button
		if button.get_node_or_null("SocketVisual") == null or button.get_node_or_null("PostVisual") == null:
			push_error("Glass metal smoke: missing material child at socket %d" % index)
			quit(1)
			return

	# Stage 001: C3 must become a visible physical Post and still solve normally.
	scene._load_stage(0)
	var c3 := 2 * 5 + 2
	if (scene.post_visuals[c3] as Control).visible:
		push_error("Glass metal smoke: empty C3 should not display a Post")
		quit(1)
		return
	scene._toggle_post(2, 2)
	await create_timer(0.30).timeout
	if not scene.stage_solved or not (scene.post_visuals[c3] as Control).visible:
		push_error("Glass metal smoke: Stage001 solve or Post material visibility failed")
		quit(1)
		return

	# Stage 004 must present authored hidden clues through the frosted-glass state.
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
				push_error("Glass metal smoke: hidden clue %d did not enter frosted state" % index)
				quit(1)
				return
			break
	if not hidden_found:
		push_error("Glass metal smoke: Stage004 unexpectedly contains no hidden clue")
		quit(1)
		return

	# Drag preview keeps the authoritative Posts untouched and uses the same
	# physical Post for the floating ghost.
	scene._load_stage(1)
	scene._toggle_post(1, 1) # B2
	await process_frame
	var before: Array = scene.posts.duplicate(true)
	var source := 1 * 5 + 1
	if not scene._begin_post_drag(source, scene._post_center(source)):
		push_error("Glass metal smoke: could not start occupied Post drag")
		quit(1)
		return
	await process_frame
	if scene.posts != before:
		push_error("Glass metal smoke: drag preview mutated authoritative Posts")
		quit(1)
		return
	if scene.drag_ghost == null or not scene.drag_ghost.visible or scene.drag_ghost.get_node_or_null("GhostPostVisual") == null:
		push_error("Glass metal smoke: physical drag ghost missing")
		quit(1)
		return
	scene._finish_post_drag(source)

	print("Glass metal smoke OK: material slots, frosted clues, physical Posts and drag isolation")
	quit(0)
