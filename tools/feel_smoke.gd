extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Feel smoke: could not load main scene")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	if scene.stages.size() < 3:
		push_error("Feel smoke: expected at least three stages")
		quit(1)
		return

	# Stage 001: placement + solve chime.
	scene._load_stage(0)
	scene._toggle_post(2, 2) # C3
	await create_timer(0.28).timeout
	if not scene.stage_solved:
		push_error("Feel smoke: Stage 001 did not solve")
		quit(1)
		return

	# Stage 002: B2 then C3 produces a level-2 overlap.
	scene._load_stage(1)
	scene._toggle_post(1, 1) # B2
	scene._toggle_post(2, 2) # C3
	await create_timer(0.28).timeout
	var shadow_two := scene.ShadowRules.compute_shadow(scene.posts)
	if int(shadow_two[2][1]) != 2:
		push_error("Feel smoke: expected a double shadow at B3")
		quit(1)
		return

	# Stage 003: C2 + B3 + D3 produces the first level-3 shadow at C3.
	scene._load_stage(2)
	scene._toggle_post(1, 2) # C2
	scene._toggle_post(2, 1) # B3
	scene._toggle_post(2, 3) # D3
	await create_timer(0.32).timeout
	var shadow_three := scene.ShadowRules.compute_shadow(scene.posts)
	if int(shadow_three[2][2]) != 3:
		push_error("Feel smoke: expected a full shadow at C3")
		quit(1)
		return

	print("Feel smoke OK: place, solve, double overlap, full overlap")
	quit(0)
