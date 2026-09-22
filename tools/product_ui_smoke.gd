extends SceneTree

const Rules = preload("res://src/shadow_rules.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("Product UI: " + message)

func _bounds(node: Node, canvas: Rect2) -> void:
	for child: Node in node.get_children():
		if child is Control and child.is_visible_in_tree():
			check(canvas.grow(1.5).encloses(child.get_global_rect()), "outside canvas: %s %s" % [child.name, child.get_global_rect()])
		_bounds(child, canvas)

func _tap(viewport: SubViewport, point: Vector2) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		viewport.push_input(event)
		await process_frame

func _key(viewport: SubViewport, code: Key, control: bool = false) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		event.ctrl_pressed = control
		viewport.push_input(event)
		await process_frame

func _settle() -> void:
	for frame: int in 5:
		await process_frame

func _new(viewport: SubViewport, save_path: String) -> Control:
	var game: Control = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	game.progress_path = save_path
	viewport.add_child(game)
	await _settle()
	return game

func _case(viewport_size: Vector2i) -> void:
	var save_path: String = "user://product_ui_smoke_%d.json" % viewport_size.x
	for suffix: String in ["", ".session.json", ".preferences.cfg"]:
		if FileAccess.file_exists(save_path + suffix):
			DirAccess.remove_absolute(save_path + suffix)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = viewport_size
	root.add_child(viewport)
	var game: Control = await _new(viewport, save_path)
	var ui: Control = game.product_ui
	check(game.audio_manager != null and game.audio_manager.bgm_player != null and game.audio_manager.bgm_player.stream != null, "BGM did not load")
	var bgm_stream: AudioStreamMP3 = game.audio_manager.bgm_player.stream as AudioStreamMP3
	check(bgm_stream != null and bgm_stream.loop, "BGM is not configured to loop")
	_bounds(game, Rect2(Vector2.ZERO, Vector2(viewport_size)))
	for button: Button in ui._background_buttons():
		check(button.size.x >= 44 and button.size.y >= 44, "small touch target: " + str(button.name))
	await _tap(viewport, game.post_buttons[0].get_global_rect().get_center())
	check(game.posts[0][0], "mouse placement failed")
	game.post_buttons[0].grab_focus()
	await _key(viewport, KEY_RIGHT)
	check(viewport.gui_get_focus_owner() == game.post_buttons[1], "right arrow did not select B1")
	await _key(viewport, KEY_DOWN)
	check(viewport.gui_get_focus_owner() == game.post_buttons[6], "down arrow did not select B2")
	var before: Array = game.posts.duplicate(true)
	var history_size: int = game.undo_history.size()
	await _key(viewport, KEY_F1)
	await _settle()
	check(ui.help_overlay.visible and not game.is_processing_input(), "help failed to block raw game input")
	check(viewport.gui_get_focus_owner() == ui.close_button, "help did not receive focus")
	_bounds(ui.help_overlay, Rect2(Vector2.ZERO, Vector2(viewport_size)))
	await _key(viewport, KEY_TAB)
	check(viewport.gui_get_focus_owner() == ui.close_button, "Tab escaped the modal")
	await _tap(viewport, game.post_buttons[0].get_global_rect().get_center())
	await _key(viewport, KEY_Z, true)
	check(game.posts == before and game.undo_history.size() == history_size, "help changed the puzzle underneath")
	await _key(viewport, KEY_ESCAPE)
	check(not ui.help_overlay.visible and game.is_processing_input(), "Escape did not dismiss help")
	check(viewport.gui_get_focus_owner() == game.post_buttons[6], "help did not restore prior focus")
	game.post_buttons[0].grab_focus()
	await _key(viewport, KEY_SPACE)
	check(Rules.count_posts(game.posts) == 0, "Space did not remove the focused post")
	await _key(viewport, KEY_Z, true)
	check(game.posts[0][0], "Ctrl+Z did not undo")
	await _tap(viewport, ui.sound_button.get_global_rect().get_center())
	check(ui.muted and ui.sound_button.text == "OFF", "sound toggle failed")
	check(game.audio_manager.bgm_player.volume_db <= -79.0, "mute did not silence BGM")
	await _tap(viewport, ui.language_button.get_global_rect().get_center())
	check(ui.language_code == "ja" and "初めての光" in game.stage_label.text, "Japanese language toggle failed")
	check(ui.help_kicker.text == "遊び方", "help copy did not switch to Japanese")
	await _key(viewport, KEY_L)
	check(ui.language_code == "en" and "First Light" in game.stage_label.text, "L did not restore English")
	await _key(viewport, KEY_L)
	check(ui.language_code == "ja", "L did not switch back to Japanese")
	await _tap(viewport, game.reset_button.get_global_rect().get_center())
	check(Rules.count_posts(game.posts) == 0, "reset mouse input failed")
	await _tap(viewport, game.post_buttons[12].get_global_rect().get_center())
	check(game.stage_solved and game.next_button.disabled, "solve or NEXT viewing beat changed")
	check(game.next_button.text == "完了  ◐", "Japanese solve-breath label did not appear")
	check(ui.collection_label.text.begins_with("01 / 18"), "collection did not record the clear")
	await create_timer(0.6).timeout
	check(not game.next_button.disabled and game.next_button.text == "次の影  ›", "Japanese NEXT invitation did not appear")
	_bounds(game, Rect2(Vector2.ZERO, Vector2(viewport_size)))
	await _tap(viewport, game.next_button.get_global_rect().get_center())
	check(game.stage_index == 1 and game.stage_label.text.begins_with("02") and game.next_button.text == "次へ  ›", "NEXT navigation failed")
	ui.open_help()
	await _settle()
	await _tap(viewport, ui.close_button.get_global_rect().get_center())
	check(not ui.help_overlay.visible, "help close button failed")
	game.queue_free()
	await _settle()
	game = await _new(viewport, save_path)
	check(game.product_ui.muted and game.product_ui.language_code == "ja" and game.stage_index == 1, "UI preferences or progress did not survive restart")
	await _key(viewport, KEY_L)
	check(game.product_ui.language_code == "en" and "Overlap" in game.stage_label.text, "language preference did not switch after restart")
	await _key(viewport, KEY_M)
	check(not game.product_ui.muted, "M did not restore sound")
	check(game.audio_manager.bgm_player.volume_db > -79.0, "unmute did not restore BGM")
	viewport.queue_free()
	await _settle()
	print("Product UI verified at %s" % viewport_size)

func _run() -> void:
	for viewport_size: Vector2i in [Vector2i(360, 800), Vector2i(390, 844), Vector2i(405, 900), Vector2i(720, 900)]:
		await _case(viewport_size)
	if failures == 0:
		print("Product UI smoke OK: mouse, keyboard, modal isolation, focus restoration, language/sound persistence, solve/NEXT and four layouts")
	quit(0 if failures == 0 else 1)


