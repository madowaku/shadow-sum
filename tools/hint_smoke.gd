extends SceneTree

const Rules = preload("res://src/shadow_rules.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Hint smoke: could not load main scene")
		quit(1)
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	# Stage 003 teaches full shadow = all three sources.
	scene._load_stage(2)
	var before: Array = scene.posts.duplicate(true)
	if scene.hint_button == null or scene.hint_button.disabled:
		push_error("Hint smoke: Stage 003 should expose HINT")
		quit(1)
		return

	scene._on_hint_pressed()
	await create_timer(0.08).timeout
	if scene.hint_button.text != "HINT I":
		push_error("Hint smoke: first whisper did not advance button")
		quit(1)
		return
	if scene.posts != before:
		push_error("Hint smoke: first whisper mutated Posts")
		quit(1)
		return

	scene._on_hint_pressed()
	await create_timer(0.55).timeout
	if scene.hint_button.text != "HINT II" or scene.posts != before:
		push_error("Hint smoke: second whisper changed authoritative state")
		quit(1)
		return

	scene._on_hint_pressed()
	await create_timer(0.12).timeout
	if scene.hint_button.text != "HINT III" or not scene.hint_button.disabled:
		push_error("Hint smoke: third whisper did not reach final state")
		quit(1)
		return
	if scene.posts != before:
		push_error("Hint smoke: final Stage 003 whisper mutated Posts")
		quit(1)
		return

	# RESET forgets hint depth but never campaign progress.
	scene._reset_stage()
	await process_frame
	if scene.whisper_index != 0 or scene.hint_button.text != "HINT ◐":
		push_error("Hint smoke: RESET did not reset whisper depth")
		quit(1)
		return

	# Stage 012 and 013 must have authored reasoning whispers too.
	for stage_idx in [11, 12]:
		scene._load_stage(stage_idx)
		await process_frame
		var stage_before: Array = scene.posts.duplicate(true)
		if scene._current_whispers().size() != 3 or scene.hint_button.disabled:
			push_error("Hint smoke: expected three whispers at stage index %d" % stage_idx)
			quit(1)
			return
		for _i in 3:
			scene._on_hint_pressed()
			await create_timer(0.10).timeout
		if scene.posts != stage_before or Rules.count_posts(scene.posts) != 0:
			push_error("Hint smoke: reasoning whisper mutated stage %d" % stage_idx)
			quit(1)
			return

	print("Hint smoke OK: 003/012/013 whispers advance, reset cleanly, and never mutate Posts")
	quit(0)
