extends SceneTree

const L = preload("res://src/nox_locale.gd")

var original_language: String = "en"
const SMOKE_SAVE: String = "user://nox_locale_smoke_only.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	original_language = L.language()
	L.set_language("en")
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var width: int = int(OS.get_environment("NOXSUM_WIDTH")) if not OS.get_environment("NOXSUM_WIDTH").is_empty() else 720
	root.size = Vector2i(width, 900)
	var campaign: Control = (load("res://scenes/campaign.tscn") as PackedScene).instantiate()
	root.add_child(campaign)
	await process_frame
	var home: Control = campaign.get_child(0) as Control
	if not (home.find_child("PlayButton", true, false) as Button).text.contains("P L A Y") and not (home.find_child("PlayButton", true, false) as Button).text.contains("C O N T I N U E"):
		_fail("English HOME label missing")
		return
	var switch: Button = home.find_child("LanguageButton", true, false) as Button
	switch.pressed.emit()
	await process_frame
	if L.language() != "ja" or not (home.find_child("SettingsButton", true, false) as Button).text.contains("設定"):
		_fail("HOME language switch did not apply Japanese")
		return
	home._open_page("GALLERY")
	var first: Button = home.find_child("Trace01", true, false) as Button
	if first.text.contains("FIRST EXPOSURE") or not first.tooltip_text.contains("それぞれ"):
		_fail("Japanese archive title or note missing")
		return
	first.pressed.emit()
	await create_timer(0.8).timeout
	var game: Control = campaign.get_child(0) as Control
	if not game.title_label.text.begins_with("記録 01") or not game.nox_chapter_label.text.begins_with("記録 01"):
		_fail("Japanese stage heading missing")
		return
	if not (game.find_child("HomeButton", true, false) as Button).text.contains("ホーム"):
		_fail("Japanese stage controls missing")
		return
	game.whisper()
	if game.hint_level != 1 or not game.status_label.text.contains("観察"):
		_fail("Japanese clue missing")
		return
	game.toggle_language()
	if L.language() != "en" or not game.title_label.text.begins_with("TRACE 01") or game.hint_level != 1 or not game.status_label.text.contains("OBSERVE"):
		_fail("stage switch did not preserve progress and English copy")
		return
	game.toggle_language()
	if L.language() != "ja" or not game.title_label.text.begins_with("記録 01") or game.hint_level != 1:
		_fail("stage switch back to Japanese failed")
		return
	game.progress_path = SMOKE_SAVE
	game.toggle_post(12)
	await create_timer(1.2).timeout
	if not game.stage_solved or not game.status_label.text.contains("痕跡が一致"):
		_fail("Japanese solve feedback missing")
		return
	game.toggle_language()
	if not game.status_label.text.contains("TRACE MATCHED"):
		_fail("solved stage did not relocalize")
		return
	game.toggle_language()
	for index: int in 36:
		game.load_stage(index)
		await process_frame
		if not game.title_label.text.begins_with("記録 %02d" % (index + 1)):
			_fail("Japanese title missing on trace %02d" % (index + 1))
			return
		var title_font: Font = game.title_label.get_theme_font("font")
		var title_size: int = game.title_label.get_theme_font_size("font_size")
		var text_width: float = title_font.get_string_size(game.title_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_size).x
		if text_width > game.title_label.size.x + 1.0 or game.title_label.get_global_rect().end.x > float(root.size.x) + 1.0:
			_fail("Japanese title overflows on trace %02d: text %.1f / label %.1f" % [index + 1, text_width, game.title_label.size.x])
			return
		if game.next_button.get_global_rect().end.y > float(root.size.y) + 1.0:
			_fail("Japanese footer outside viewport on trace %02d: %s" % [index + 1, str(game.next_button.get_global_rect())])
			return
		for clue_index: int in 3:
			game.whisper()
			await process_frame
			if game.hint_level != clue_index + 1 or not game.status_label.text.contains("観察"):
				_fail("Japanese clue did not display on trace %02d, clue %d" % [index + 1, clue_index + 1])
				return
			for english_term: String in ["SIT", "STAND", "WALK", "SLEEP", "TOP"]:
				if game.status_label.text.contains(english_term):
					_fail("Untranslated clue term %s on trace %02d, clue %d" % [english_term, index + 1, clue_index + 1])
					return
			if game.next_button.get_global_rect().end.y > float(root.size.y) + 1.0:
				_fail("Japanese clue overflows footer on trace %02d, clue %d" % [index + 1, clue_index + 1])
				return
	game.home_requested.emit()
	await process_frame
	home = campaign.get_child(0) as Control
	if L.language() != "ja" or not (home.find_child("SettingsButton", true, false) as Button).text.contains("設定"):
		_fail("language did not persist across HOME navigation")
		return
	L.set_language(original_language)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	var music: Node = root.get_node_or_null("BgmPlaylist")
	if music != null:
		music.music_player.stop()
		music.music_player.stream = null
	await create_timer(0.15).timeout
	campaign.queue_free()
	await process_frame
	print("NOXSUM_LOCALE_OK English/Japanese HOME, 36 titles, clue, progress, %d×900 bounds" % width)
	quit()

func _fail(message: String) -> void:
	L.set_language(original_language)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SMOKE_SAVE))
	push_error(message)
	quit(1)
