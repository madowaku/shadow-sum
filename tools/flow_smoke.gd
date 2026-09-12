extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Flow smoke: could not load main scene")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame

	scene._load_stage(0)
	scene._toggle_post(2, 2) # C3 solves FIRST LIGHT.
	await process_frame

	if not scene.stage_solved:
		push_error("Flow smoke: Stage 001 did not solve")
		quit(1)
		return
	if not scene.next_button.disabled:
		push_error("Flow smoke: NEXT should pause during the solve breath")
		quit(1)
		return
	if scene.next_button.text != "COMPLETE  ◐":
		push_error("Flow smoke: solve breath label did not appear")
		quit(1)
		return

	await create_timer(0.52).timeout
	if scene.next_button.disabled:
		push_error("Flow smoke: NEXT did not unlock after solve breath")
		quit(1)
		return
	if scene.next_button.text != "NEXT SHADOW  ›":
		push_error("Flow smoke: NEXT invitation text is wrong: %s" % scene.next_button.text)
		quit(1)
		return

	scene._next_stage()
	await process_frame
	if scene.stage_index != 1 or scene.stage_solved:
		push_error("Flow smoke: NEXT did not advance cleanly to Stage 002")
		quit(1)
		return
	if scene.next_button.text != "NEXT  ›" or not scene.next_button.disabled:
		push_error("Flow smoke: new stage did not restore resting NEXT state")
		quit(1)
		return

	print("Flow smoke OK: solve breath shows complete shadow, NEXT invites once, next stage resets cleanly")
	quit(0)
