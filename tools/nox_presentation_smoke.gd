extends SceneTree

const Locale = preload("res://src/nox_locale.gd")
var previous_language: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	previous_language = Locale.language()
	Locale.set_language("en")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var width: int = int(OS.get_environment("NOXSUM_WIDTH")) if not OS.get_environment("NOXSUM_WIDTH").is_empty() else 720
	root.size = Vector2i(width, 900)
	var campaign: Control = (load("res://scenes/campaign.tscn") as PackedScene).instantiate()
	root.add_child(campaign)
	await process_frame
	var home: Control = campaign.get_child(0) as Control
	if home.name != "NoxHome" or home.find_children("Trace*", "Button", true, false).size() != 36:
		_fail("NOXSUM home must list all 36 traces")
		return
	await _capture("home_%d" % width)
	home._open_page("GALLERY")
	await _capture("gallery_%d" % width)
	home._close_modal()
	var first: Button = home.find_child("Trace01", true, false) as Button
	first.pressed.emit()
	await create_timer(0.8).timeout
	var game: Control = campaign.get_child(0) as Control
	if not game.nox_campaign or game.stages.size() != 36 or game.stage_index != 0 or game.stages[20].has("review_only"):
		_fail("first trace did not open the 36-stage NOXSUM campaign")
		return
	if not game.title_label.text.begins_with("TRACE 01") or not game.sockets[0].get_child(0).nox_mode:
		_fail("stage copy or NOX board presentation is missing")
		return
	await _capture("stage_01_%d" % width)
	var smoke_save: String = "user://noxsum_presentation_smoke.json"
	game.progress_path = smoke_save
	game.toggle_post(12)
	await create_timer(1.2).timeout
	if not game.stage_solved or not game.status_label.text.contains("TRACE MATCHED"):
		_fail("NOXSUM solve presentation failed")
		return
	await _capture("solved_01_%d" % width)
	game.load_stage(20)
	await process_frame
	if game.stage_index != 20 or not game.title_label.text.begins_with("TRACE 21"):
		_fail("later stages must display NOX story copy")
		return
	await _capture("stage_21_%d" % width)
	game.load_stage(11)
	await process_frame
	if not game.plate_inventory.visible:
		_fail("WALK tray is missing on the mixed-pose trace")
		return
	var walk_press: InputEventMouseButton = InputEventMouseButton.new()
	walk_press.button_index = MOUSE_BUTTON_LEFT
	walk_press.pressed = true
	walk_press.position = game.plate_inventory.size * 0.5
	var walk_release: InputEventMouseButton = InputEventMouseButton.new()
	walk_release.button_index = MOUSE_BUTTON_LEFT
	walk_release.pressed = false
	walk_release.position = game.plate_inventory.get_global_rect().get_center()
	game._start_pointer(walk_press, "post", -3)
	game._input(walk_release)
	if game.selected_post_type != "plate_h":
		_fail("first WALK tap must select its default direction")
		return
	game._start_pointer(walk_press, "post", -3)
	game._input(walk_release)
	if game.selected_post_type != "plate_v" or game.plate_inventory.get_child(0).post_type != "plate_v":
		_fail("second WALK tap must change direction and sprite")
		return
	var home_button: Button = game.find_child("HomeButton", true, false) as Button
	home_button.pressed.emit()
	await process_frame
	home = campaign.get_child(0) as Control
	if home.name != "NoxHome":
		_fail("HOME did not return to the archive")
		return
	var last: Button = home.find_child("Trace36", true, false) as Button
	last.pressed.emit()
	await create_timer(0.8).timeout
	game = campaign.get_child(0) as Control
	if game.stage_index != 35 or not game.title_label.text.begins_with("TRACE 36"):
		_fail("Trace 36 is not reachable from the archive")
		return
	for index: int in 36:
		game.load_stage(index)
		await process_frame
		if game.next_button.get_global_rect().end.y > float(root.size.y) + 1.0:
			_fail("footer outside viewport on trace %02d: %s" % [index + 1, str(game.next_button.get_global_rect())])
			return
		if not game.title_label.text.begins_with("TRACE %02d" % (index + 1)):
			_fail("missing story title on trace %02d" % (index + 1))
			return
	print("NOXSUM_PRESENTATION_OK 36 traces, HOME navigation, WALK direction, NOX board, solve presentation")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(smoke_save))
	var music: Node = root.get_node_or_null("BgmPlaylist")
	if music != null:
		music.music_player.stop()
		music.music_player.stream = null
	await create_timer(0.15).timeout
	campaign.queue_free()
	await process_frame
	Locale.set_language(previous_language)
	quit()

func _capture(name: String) -> void:
	var directory: String = OS.get_environment("NOXSUM_CAPTURE_DIR")
	if directory.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(directory)
	await create_timer(0.8).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(directory.path_join(name + ".png"))
	root.get_texture().get_image().save_jpg(directory.path_join(name + ".jpg"), 0.88)

func _fail(message: String) -> void:
	push_error(message)
	Locale.set_language(previous_language)
	quit(1)
