extends SceneTree

const CampaignScene = preload("res://scenes/campaign.tscn")
const Settings = preload("res://src/nox_settings.gd")

var failures: Array[String] = []
var screenshots: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _screenshot_directory() -> String:
	var profile: String = OS.get_environment("USERPROFILE")
	var pictures: String = profile.path_join("Pictures")
	var screenshots_dir: String = pictures.path_join("Screenshots")
	if DirAccess.dir_exists_absolute(screenshots_dir):
		return screenshots_dir
	if DirAccess.dir_exists_absolute(pictures):
		return pictures
	return profile

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	var path: String = _screenshot_directory().path_join("noxsum-fresh-" + name + ".png")
	var image: Image = root.get_texture().get_image()
	_check(image != null and image.get_width() > 0 and image.get_height() > 0, "rendered frame " + name)
	if image == null:
		return
	var save_result: Error = image.save_png(path)
	_check(save_result == OK, "save screenshot " + name)
	if save_result == OK:
		screenshots.append(path)

func _send_key(keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame

func _run() -> void:
	root.size = Vector2i(720, 900)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	Settings.write_value("sound", false)
	Settings.write_value("reduced_motion", true)
	Settings.write_value("opening_seen", false)
	var app: Control = CampaignScene.instantiate() as Control
	root.add_child(app)
	await process_frame
	var home: Control = app.get_node_or_null("NoxHome") as Control
	_check(home != null, "fresh launch reaches HOME")
	if home == null:
		quit(1)
		return
	await process_frame
	await process_frame
	var play_button: Button = home.find_child("PlayButton", true, false) as Button
	_check(play_button != null, "HOME Play button exists")
	if play_button == null:
		quit(1)
		return
	var play_click: InputEventMouseButton = InputEventMouseButton.new()
	play_click.button_index = MOUSE_BUTTON_LEFT
	play_click.pressed = true
	play_click.position = play_button.get_global_rect().get_center()
	root.push_input(play_click, true)
	await process_frame
	play_click.pressed = false
	root.push_input(play_click, true)
	await process_frame
	var opening: Control = home.get_node_or_null("NoxOpeningKamishibai") as Control
	_check(opening != null and not opening.replay, "first PLAY opens the first-time Opening")
	if opening == null:
		quit(1)
		return
	opening.set_process(false)
	opening.grab_focus()
	for scene_index: int in 6:
		_check(opening.beat_index == scene_index and not opening.stopped, "Opening Scene%02d before Enter" % (scene_index + 1))
		await _capture("opening-scene%02d" % (scene_index + 1))
		await create_timer(0.36).timeout
		await _send_key(KEY_ENTER)
		if scene_index < 5:
			_check(opening.beat_index == scene_index + 1 and not opening.stopped, "one Enter reaches only Scene%02d" % (scene_index + 2))
			await create_timer(0.36).timeout
	await create_timer(0.85).timeout
	var campaign: Control = app.get_child(0) as Control if app.get_child_count() > 0 else null
	_check(campaign != null and campaign.get("nox_campaign") == true and campaign.get("initial_stage_index") == 0, "Scene06 Enter routes to GR01")
	await _capture("gr01")
	for path: String in screenshots:
		print("SCREENSHOT: ", path)
	print("OPENING INPUT VERIFY: ", "PASS" if failures.is_empty() else str(failures), " | fresh APPDATA, HOME → PLAY, Enter ×6, GR01")
	quit(0 if failures.is_empty() else 1)
