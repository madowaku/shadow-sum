extends SceneTree

const Rules = preload("res://src/shadow_rules.gd")

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Magnetic smoke: could not load main scene")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	# Stage 002 gives us room to move one occupied Post around without solving.
	scene._load_stage(1)
	scene._toggle_post(0, 0) # A1
	scene._toggle_post(1, 1) # B2
	await create_timer(0.12).timeout

	var source := 1 * Rules.BOARD_SIZE + 1 # B2
	var target := 1 * Rules.BOARD_SIZE + 4 # E2, right edge gives a clean outside hit area.
	if not scene._begin_post_drag(source):
		push_error("Magnetic smoke: could not begin drag")
		quit(1)
		return

	var target_button := scene.post_buttons[target] as Button
	var target_rect := target_button.get_global_rect()
	var target_center := target_rect.position + target_rect.size * 0.5
	var magnetic_point := target_center + Vector2(target_rect.size.x * 0.5 + 5.0, 0.0)

	# The pointer is deliberately outside the visual socket, but still inside the
	# tuned magnetic capture radius.
	if target_rect.has_point(magnetic_point):
		push_error("Magnetic smoke: test point unexpectedly landed inside socket")
		quit(1)
		return
	if scene._drag_target_at(magnetic_point) != target:
		push_error("Magnetic smoke: near-miss did not magnetically acquire E2")
		quit(1)
		return

	scene._pointer_move(magnetic_point)
	await process_frame
	if scene.drag_target_index != target:
		push_error("Magnetic smoke: pointer move did not switch snapped target")
		quit(1)
		return

	if scene.drag_ghost == null or not scene.drag_ghost.visible:
		push_error("Magnetic smoke: lifted ghost is not visible")
		quit(1)
		return
	var ghost_center := scene.drag_ghost.position + scene.drag_ghost.size * 0.5
	if ghost_center.y >= magnetic_point.y - 5.0:
		push_error("Magnetic smoke: ghost was not visibly lifted above pointer")
		quit(1)
		return

	# Preview remains temporary until CLICK/release.
	if not bool(scene.posts[1][1]) or bool(scene.posts[1][4]):
		push_error("Magnetic smoke: snapped preview mutated authoritative state")
		quit(1)
		return

	if not scene._finish_post_drag(target):
		push_error("Magnetic smoke: snapped release did not commit")
		quit(1)
		return
	await create_timer(0.16).timeout

	if bool(scene.posts[1][1]) or not bool(scene.posts[1][4]):
		push_error("Magnetic smoke: committed move did not land on E2")
		quit(1)
		return
	if Rules.count_posts(scene.posts) != 2:
		push_error("Magnetic smoke: snap changed total Post count")
		quit(1)
		return

	print("Magnetic smoke OK: near-miss snaps, ghost lifts, preview stays temporary, release commits once")
	quit(0)
