extends SceneTree

const Rules = preload("res://src/shadow_rules.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Interaction smoke: could not load main scene")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	# Stage 002: fill both available Post slots without solving the board.
	scene._load_stage(1)
	scene._toggle_post(0, 0) # A1
	scene._toggle_post(1, 1) # B2
	await create_timer(0.12).timeout

	if Rules.count_posts(scene.posts) != 2 or scene.stage_solved:
		push_error("Interaction smoke: expected two unsolved Posts before drag")
		quit(1)
		return

	var source := 1 * Rules.BOARD_SIZE + 1 # B2
	var target := 1 * Rules.BOARD_SIZE + 2 # C2
	if not scene._begin_post_drag(source):
		push_error("Interaction smoke: could not pick occupied Post")
		quit(1)
		return
	if not scene._set_drag_target(target):
		push_error("Interaction smoke: could not slide to empty socket")
		quit(1)
		return

	# Preview must never mutate authoritative puzzle state.
	if not bool(scene.posts[1][1]) or bool(scene.posts[1][2]):
		push_error("Interaction smoke: preview mutated authoritative Posts")
		quit(1)
		return

	var preview: Array = scene.posts.duplicate(true)
	preview[1][1] = false
	preview[1][2] = true
	var preview_shadow := Rules.compute_shadow(preview)
	for r in Rules.BOARD_SIZE:
		for c in Rules.BOARD_SIZE:
			var index := r * Rules.BOARD_SIZE + c
			var rendered := int((scene.live_cells[index] as Control).get_meta("shadow_level", -99))
			if rendered != int(preview_shadow[r][c]):
				push_error("Interaction smoke: LIVE preview mismatch at %d,%d" % [r, c])
				quit(1)
				return

	if not scene._finish_post_drag(target):
		push_error("Interaction smoke: valid drop did not commit")
		quit(1)
		return
	await create_timer(0.18).timeout

	if bool(scene.posts[1][1]) or not bool(scene.posts[1][2]):
		push_error("Interaction smoke: committed Post did not move B2 -> C2")
		quit(1)
		return
	if Rules.count_posts(scene.posts) != 2:
		push_error("Interaction smoke: moving a Post changed total Post count")
		quit(1)
		return

	# Picking up and releasing on the same socket is a cheap, reversible cancel.
	if not scene._begin_post_drag(target):
		push_error("Interaction smoke: could not repick moved Post")
		quit(1)
		return
	if scene._finish_post_drag(target):
		push_error("Interaction smoke: same-socket release should cancel, not commit")
		quit(1)
		return
	if not bool(scene.posts[1][2]) or Rules.count_posts(scene.posts) != 2:
		push_error("Interaction smoke: cancel changed puzzle state")
		quit(1)
		return

	print("Interaction smoke OK: PICK preview is temporary, SLIDE follows sockets, CLICK commits once")
	quit(0)
