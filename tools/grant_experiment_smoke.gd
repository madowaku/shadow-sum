extends SceneTree

const Experiment = preload("res://src/experiment_main.gd")
const Optics = preload("res://src/experiment_optics.gd")
var failures: int = 0
var game: Control

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Experiments: " + message)

func _bounds(node: Node, canvas: Rect2) -> void:
	for child: Node in node.get_children():
		if child is Control and child.is_visible_in_tree():
			check(canvas.grow(1).encloses(child.get_global_rect()), "offscreen " + str(child.get_path()) + " " + str(child.get_global_rect()) + " canvas=" + str(canvas))
		_bounds(child, canvas)

func _press(point: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = true
	root.push_input(event)

func _release(point: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.pressed = false
	root.push_input(event)

func _tap(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	_press(point)
	_release(point)

func _drag(source: Control, destination: Control) -> void:
	_press(source.get_global_rect().get_center())
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = destination.get_global_rect().get_center()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(event)
	_release(event.position)

func _touch(control: Control) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = 0
	event.position = control.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event)
	event = event.duplicate()
	event.pressed = false
	root.push_input(event)

func _run() -> void:
	var grant_path: String = "user://shadow_sum_grant18_progress_v1.json"
	var before: String = FileAccess.get_file_as_string(grant_path) if FileAccess.file_exists(grant_path) else "<absent>"
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	root.size = Vector2i(405, 900)
	game = Experiment.new()
	game.progress_path = "user://grant_experiments_smoke_only.json"
	if FileAccess.file_exists(game.progress_path):
		DirAccess.remove_absolute(game.progress_path)
	game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(game)
	await process_frame
	await process_frame
	check(game.lights == ["TOP", "LEFT"], "G01 initial lamps")
	_tap(game.sockets[12])
	check(game.stage_solved, "G01 click C3 solves")
	check(game.next_button.disabled, "NEXT breath missing")
	var old: Array = game.motions.duplicate()
	game.reset_stage()
	for motion: Tween in old:
		check(not motion.is_valid(), "reset retained tween")
	await create_timer(0.95).timeout
	check(not game.stage_solved and game.next_button.disabled and not game.completed.has("G01"), "stale solve callback")
	_touch(game.sockets[12])
	check(game.stage_solved, "touch C3 solves")
	game.load_stage(1)
	await process_frame
	_drag(game.inventory, game.sockets[6])
	check(game.posts == [6], "inventory drag")
	var world: Array = game.posts.duplicate()
	_tap(game.lamps["LEFT"])
	check(game.observation_index == 1 and game.posts == world, "lamp tap preserves world")
	_touch(game.lamps["TOP"])
	check(game.observation_index == 0, "touch lamp changes observation")
	_drag(game.sockets[6], game.sockets[7])
	check(game.posts == [7], "Post move magnetic snap")
	game.undo_move()
	check(game.posts == [6], "undo Post move")
	game.load_stage(2)
	game.toggle_post(0)
	game.tap_light("RIGHT")
	check(game.posts == [0] and game.observation_index == 1, "G03 world retained")
	game.load_stage(3)
	game.toggle_post(12)
	check(game.current_shadow[17] == 0 and game.current_shadow[11] == 1 and game.current_shadow[13] == 1, "shutter must suppress TOP only")
	game.load_stage(4)
	game.toggle_post(12)
	check(game.current_shadow[7] == 1, "BOTTOM upward")
	game.load_stage(5)
	game.toggle_post(12)
	check(game.current_shadow[10] == 1 and game.current_shadow[22] == 1, "Tall distance two")
	game.load_stage(6)
	game.toggle_post(12)
	check(game.posts == [12, 18], "fixed Posts changed")
	game.tap_light("RIGHT")
	check(game.stage_solved, "RIGHT OFF solves")
	game.load_stage(7)
	await process_frame
	await process_frame
	_drag(game.rail_buttons[0], game.rail_buttons[2])
	check(game.shutters == [2] and not game.stage_solved, "rail drag snap")
	_touch(game.rail_buttons[3])
	check(game.shutters == [3] and game.current_shadow[23] == 0 and game.stage_solved, "rail touch/live recompute")
	game.load_stage(8)
	game.toggle_post(7)
	game.toggle_post(18)
	check(not game.stage_solved, "G09 wrong shutter accepted")
	game.move_shutter(2)
	check(game.stage_solved, "G09 exact state")
	game.load_stage(9)
	game.toggle_post(8)
	game.move_shutter(1)
	world = game.posts.duplicate()
	game.tap_light("RIGHT")
	check(game.posts == world and game.shutters == [1], "G10 switch preserved Posts/shutter")
	# A-only false solutions must never clear.
	var rejected: int = 0
	for first: int in 25:
		for second: int in range(first + 1, 25):
			for slot: int in 5:
				var candidate: Array = [first, second]
				if Optics.matches(Optics.compute_shadow(candidate, ["TOP", "LEFT"], [slot]), game.stage()["observations"][0]["target"]):
					if not Optics.solved(game.stage(), candidate, [slot], ["TOP", "LEFT"]):
						rejected += 1
	check(rejected == 4, "G10 all-observation clear guard")
	game.reset_stage()
	check(game.posts.is_empty() and game.shutters == [0] and game.observation_index == 0, "RESET optics")
	for dimensions: Vector2i in [Vector2i(405, 900), Vector2i(676, 900), Vector2i(720, 900)]:
		root.size = dimensions
		for stage_number: int in 10:
			game.load_stage(stage_number)
			await process_frame
			await process_frame
			_bounds(game, Rect2(Vector2.ZERO, Vector2(dimensions)))
			var hitboxes: Array = game.sockets + game.rail_buttons + game.lamps.values() + [game.back_button, game.next_button, game.hint_button, game.undo_button, game.inventory]
			for a: int in hitboxes.size():
				var control: Control = hitboxes[a]
				if not control.is_visible_in_tree():
					continue
				check(control.size.x >= 44 and control.size.y >= 44, "small touch target")
				for b: int in range(a + 1, hitboxes.size()):
					if hitboxes[b].is_visible_in_tree():
						check(not control.get_global_rect().intersects(hitboxes[b].get_global_rect()), "overlapping input regions")
	game.completed.clear()
	for stage_number: int in 10:
		game.load_stage(stage_number)
		if not game.stage().has("fixed_posts"):
			for code: String in game.stage()["solution"]:
				game.toggle_post(Optics.cell(code))
		if game.stage().get("movable_shutter", false):
			game.move_shutter(int(game.stage()["solution_shutter"]))
		if game.stage().get("light_puzzle", false):
			game.tap_light("RIGHT")
		check(game.stage_solved, "solve " + str(stage_number + 1))
		check(game.next_button.disabled, "early NEXT")
		await create_timer(0.96).timeout
		check(not game.next_button.disabled and game.completed.has(game.stage()["id"]), "solve timing/save")
		old = game.motions.duplicate()
		game.next_stage()
		if stage_number < 9:
			for motion: Tween in old:
				check(not motion.is_valid(), "NEXT retained old tween")
	check(game.completed.size() == 10, "ten completions")
	check(game.status_label.text.begins_with("10 EXPERIMENTS"), "ending")
	var after: String = FileAccess.get_file_as_string(grant_path) if FileAccess.file_exists(grant_path) else "<absent>"
	check(before == after, "Grant18 save touched")
	game.load_stage(9)
	var hint_posts: Array = game.posts.duplicate()
	for index: int in 3:
		game.whisper()
	check(game.posts == hint_posts and game.hint_level == 3 and not game.stage_solved, "WHISPER mutated world")
	game.reset_stage()
	await create_timer(0.8).timeout
	check(game.status_label.text.is_empty(), "stale hint")
	DirAccess.remove_absolute(game.progress_path)
	game.queue_free()
	await process_frame
	print("Grant experiments smoke: %d failures" % failures)
	quit(1 if failures else 0)
