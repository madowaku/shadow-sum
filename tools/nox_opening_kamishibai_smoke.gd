extends SceneTree

const Opening = preload("res://src/nox_opening_kamishibai.gd")
const Home = preload("res://src/nox_home.gd")
const Settings = preload("res://src/nox_settings.gd")
const L = preload("res://src/nox_locale.gd")
var original_settings: String
var had_settings: bool
var progress_before: String
var had_progress: bool
var failures: Array[String] = []
var routed: int = -1

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	had_settings = FileAccess.file_exists(Settings.PATH)
	original_settings = FileAccess.get_file_as_string(Settings.PATH) if had_settings else ""
	had_progress = FileAccess.file_exists(Home.SAVE_PATH)
	progress_before = FileAccess.get_file_as_string(Home.SAVE_PATH) if had_progress else ""
	Settings.write_value("sound", false)
	Settings.write_value("reduced_motion", true)
	Settings.write_value("opening_seen", false)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var total: float = 0.0
	for beat: Dictionary in Opening.BEATS:
		total += float(beat.duration)
	check(total >= 18.0 and total <= 24.0, "duration")
	for language: String in ["ja", "en"]:
		L.set_language(language)
		for beat: Dictionary in Opening.BEATS:
			check(not L.opening(str(beat.id) + ".title").is_empty(), "missing copy")
		for viewport_size: Vector2i in [Vector2i(360, 800), Vector2i(405, 900), Vector2i(720, 900)]:
			root.size = viewport_size
			var opening: Control = Opening.new()
			opening.replay = true
			root.add_child(opening)
			opening.set_process(false)
			await process_frame
			for beat: int in 6:
				opening.elapsed = 2.5
				opening._animate()
				await process_frame
				check(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(opening.skip_button.get_global_rect()), "skip bounds")
				check(opening.skip_button.size.y >= 44, "skip target")
				check(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(opening.caption.get_global_rect()), "caption bounds")
				check(opening.title.get_minimum_size().y <= opening.title.size.y + 1, "title clipping")
				for plate: Control in opening.plates:
					check(Rect2(Vector2.ZERO, Vector2(viewport_size)).encloses(plate.get_global_rect()), "plate bounds")
				if beat == 0:
					check(opening.art.scale == Vector2.ONE, "reduced motion push")
				if beat < 5:
					opening.next_beat()
			opening.finish()
			check(not Settings.read_value("opening_seen", false), "replay changed seen")
			opening.queue_free()
			await process_frame
	var home: Control = Home.new()
	root.add_child(home)
	home.start_requested.connect(func(index: int) -> void: routed = index)
	await process_frame
	home._play()
	var first: Control = home.get_node("NoxOpeningKamishibai")
	check(first != null and not first.replay, "fresh PLAY opening")
	first.set_process(false)
	var skip_click: InputEventMouseButton = InputEventMouseButton.new()
	skip_click.button_index = MOUSE_BUTTON_LEFT
	skip_click.pressed = true
	skip_click.position = first.skip_button.get_global_rect().get_center()
	root.push_input(skip_click, true)
	await process_frame
	skip_click.pressed = false
	root.push_input(skip_click, true)
	await process_frame
	await create_timer(0.25).timeout
	check(routed == 0 and Settings.read_value("opening_seen", false), "skip GR01 and seen")
	home.queue_free()
	await process_frame
	home = Home.new()
	root.add_child(home)
	home.start_requested.connect(func(index: int) -> void: routed = index)
	await process_frame
	routed = -1
	var expected: int = home._resume_index()
	home._play()
	await create_timer(0.25).timeout
	check(routed == expected and home.get_node_or_null("NoxOpeningKamishibai") == null, "seen bypass normal route")
	home.queue_free()
	await process_frame
	Settings.write_value("opening_seen", false)
	home = Home.new()
	root.add_child(home)
	home.start_requested.connect(func(index: int) -> void: routed = index)
	await process_frame
	home._open_page("ABOUT")
	(home.find_child("PrologueButton", true, false) as Button).pressed.emit()
	var replay: Control = home.get_node("NoxOpeningKamishibai")
	replay.finish()
	check(home.modal.visible and not home.entering, "replay returns ABOUT")
	check(not Settings.read_value("opening_seen", false), "replay preserves false seen")
	home._close_modal()
	home._play()
	first = home.get_node("NoxOpeningKamishibai")
	first.set_process(false)
	routed = -1
	for beat: Dictionary in Opening.BEATS:
		first._process(float(beat.duration) + 0.01)
	await create_timer(0.25).timeout
	check(routed == 0 and Settings.read_value("opening_seen", false), "complete GR01 and seen")
	home.queue_free()
	await process_frame
	Settings.write_value("reduced_motion", false)
	var motion: Control = Opening.new()
	motion.replay = true
	root.add_child(motion)
	motion.set_process(false)
	await process_frame
	motion.grab_focus()
	var key: InputEventKey = InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_ENTER
	root.push_input(key, true)
	await process_frame
	check(motion.beat_index == 1, "viewport Enter advances exactly one scene")
	key.pressed = false
	root.push_input(key, true)
	await process_frame
	key.pressed = true
	root.push_input(key, true)
	await process_frame
	check(motion.beat_index == 1, "rapid Enter is debounced")
	key.pressed = false
	root.push_input(key, true)
	await create_timer(0.36).timeout
	var space: InputEventKey = InputEventKey.new()
	space.pressed = true
	space.keycode = KEY_SPACE
	root.push_input(space, true)
	await process_frame
	check(motion.beat_index == 2, "viewport Space advances one scene after debounce")
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(10, 400)
	await create_timer(0.36).timeout
	root.push_input(click, true)
	await process_frame
	check(motion.beat_index == 3, "viewport click advances one scene")
	var touch: InputEventScreenTouch = InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(10, 400)
	await create_timer(0.36).timeout
	root.push_input(touch, true)
	await process_frame
	check(motion.beat_index == 4, "viewport tap advances one scene")
	var escape: InputEventKey = InputEventKey.new()
	escape.pressed = true
	escape.keycode = KEY_ESCAPE
	await create_timer(0.36).timeout
	root.push_input(escape, true)
	await process_frame
	check(motion.stopped, "Escape finishes Opening")
	root.size = Vector2i(360, 800)
	await process_frame
	check(motion.beat_index == 4, "resize state")
	check(AudioServer.is_bus_mute(0), "sound OFF")
	Settings.write_value("sound", true)
	Settings.apply_audio()
	await process_frame
	check(not AudioServer.is_bus_mute(0), "sound ON")
	Settings.write_value("sound", false)
	Settings.apply_audio()
	motion.finish()
	check(motion.transition == null and motion.stopped, "exit cancels timeline")
	motion.queue_free()
	await process_frame
	var tween_probe: Control = Opening.new()
	tween_probe.replay = true
	root.add_child(tween_probe)
	tween_probe.set_process(false)
	await process_frame
	tween_probe.next_beat()
	tween_probe.next_beat()
	var current_layer: Control = tween_probe.layer
	await create_timer(0.36).timeout
	check(tween_probe.beat_index == 2 and tween_probe.layer == current_layer and tween_probe.previous_layer == null, "stale transition callback preserves the current scene")
	tween_probe.finish()
	tween_probe.queue_free()
	await process_frame
	check(FileAccess.file_exists(Home.SAVE_PATH) == had_progress, "progress existence changed")
	if had_progress:
		check(FileAccess.get_file_as_string(Home.SAVE_PATH) == progress_before, "progress changed")
	if had_settings:
		var file: FileAccess = FileAccess.open(Settings.PATH, FileAccess.WRITE)
		file.store_string(original_settings)
		file.close()
	else:
		DirAccess.remove_absolute(Settings.PATH)
	Settings.apply_audio()
	root.get_node("BgmPlaylist").call("set_enabled", false)
	await create_timer(0.1).timeout
	print("OPENING SMOKE: ", "PASS" if failures.is_empty() else str(failures), " | JP/EN, 3 viewports, Enter/Space/click/tap, Escape/Skip, 350ms debounce, tween cleanup, replay/save/audio/motion/resize")
	quit(0 if failures.is_empty() else 1)
