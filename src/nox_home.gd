extends Control

signal start_requested(stage_index: int)

const N = preload("res://src/ui/nox_theme.gd")
const Story = preload("res://src/nox_story.gd")
const Settings = preload("res://src/nox_settings.gd")
const L = preload("res://src/nox_locale.gd")
const Wordmark = preload("res://src/ui/nox_wordmark.gd")
const SAVE_PATH: String = "user://noxsum_grant36_v1.json"
const CAMPAIGN_ID: String = "noxsum_grant36_v1"
const STAGE_COUNT: int = 36
const BACKGROUND: Texture2D = preload("res://assets/nox/v0.6/archive_puzzle_window.png")

var completed: Dictionary = {}
var continue_button: Button
var progress_label: Label
var sound_button: Button
var modal: Control
var modal_body: VBoxContainer
var modal_title: Label
var modal_scroll: ScrollContainer
var archive: VBoxContainer
var masthead: Label
var wordmark: Control
var subtitle: Label
var entering: bool = false
var return_focus: Control

func _ready() -> void:
	name = "NoxHome"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Settings.apply_audio()
	N.ensure_japanese_font()
	_load_progress()
	_build_ui()
	resized.connect(_responsive)
	_responsive()
	if not Settings.reduced_motion():
		modulate.a = 0.0
		create_tween().tween_property(self, "modulate:a", 1.0, 0.65)

func _load_progress() -> void:
	completed.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary and parsed.get("campaign", "") == CAMPAIGN_ID:
		var saved: Variant = parsed.get("completed", {})
		if saved is Dictionary:
			for index: int in STAGE_COUNT:
				var id: String = "GR%02d" % (index + 1)
				if saved.has(id):
					completed[id] = true

func _resume_index() -> int:
	for index: int in STAGE_COUNT:
		if not completed.has("GR%02d" % (index + 1)):
			return index
	return STAGE_COUNT - 1

func _build_ui() -> void:
	var background: TextureRect = TextureRect.new()
	background.texture = BACKGROUND
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient: Gradient = Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.16, 0.40, 0.64, 0.79, 1.0])
	gradient.colors = PackedColorArray([Color(0.01, 0.03, 0.06, 0.40), Color(0.01, 0.03, 0.06, 0.30), Color(0.01, 0.03, 0.06, 0.16), Color.TRANSPARENT, Color(0.02, 0.03, 0.05, 0.32), Color(0.01, 0.02, 0.03, 0.78)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var shade: TextureRect = TextureRect.new()
	shade.texture = texture
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(preload("res://src/ui/nox_atmosphere.gd").new())

	var top: MarginContainer = N.margin(self, 24)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	var top_row: HBoxContainer = HBoxContainer.new()
	top.add_child(top_row)
	masthead = N.label(top_row, L.copy("NOCTURNAL\nOPTICAL ARCHIVE"), 10, N.IVORY)
	masthead.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_readable(masthead)
	sound_button = N.button("", 44)
	sound_button.name = "SoundButton"
	sound_button.custom_minimum_size.x = 74
	sound_button.add_theme_font_size_override("font_size", 10)
	sound_button.pressed.connect(_toggle_sound)
	top_row.add_child(sound_button)
	_refresh_sound_button()
	var language: Button = N.button(L.switch_label(), 44)
	language.name = "LanguageButton"
	language.pressed.connect(_switch_language)
	top_row.add_child(language)
	var settings: Button = N.button(L.copy("SETTINGS"), 44)
	settings.name = "SettingsButton"
	settings.pressed.connect(_open_settings)
	top_row.add_child(settings)

	var title_area: MarginContainer = N.margin(self, 20)
	title_area.anchor_top = 0.06
	title_area.anchor_bottom = 0.38
	title_area.anchor_right = 1.0
	var title_column: VBoxContainer = VBoxContainer.new()
	title_column.alignment = BoxContainer.ALIGNMENT_CENTER
	title_column.add_theme_constant_override("separation", 10)
	title_area.add_child(title_column)
	var edition: Label = N.label(title_column, L.copy("A  N O C T U R N A L  M Y S T E R Y"), 11, N.BRASS)
	edition.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readable(edition)
	wordmark = Wordmark.new()
	wordmark.custom_minimum_size.y = 110
	title_column.add_child(wordmark)
	subtitle = N.label(title_column, L.copy("RECONSTRUCT THE PAST\nFROM THE SHADOWS"), 11)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_constant_override("line_spacing", 5)
	_readable(subtitle, 3)
	var tag: Label = N.label(title_column, L.copy("NOX is gone. The shadows remember."), 20, N.IVORY, true)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.add_theme_constant_override("outline_size", 4)
	tag.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.96))

	var bottom: MarginContainer = N.margin(self, 24)
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.anchor_right = 1.0
	bottom.offset_top = -228
	bottom.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var bottom_column: VBoxContainer = VBoxContainer.new()
	bottom_column.add_theme_constant_override("separation", 12)
	bottom.add_child(bottom_column)
	var play_center: CenterContainer = CenterContainer.new()
	bottom_column.add_child(play_center)
	var action_key: String = "P L A Y     ›" if completed.is_empty() else "V I E W  R E C O R D S     ›" if completed.size() == STAGE_COUNT else "C O N T I N U E     ›"
	continue_button = N.button(L.copy(action_key), 58, true)
	continue_button.name = "PlayButton"
	continue_button.custom_minimum_size.x = 280
	continue_button.pressed.connect(func() -> void:
		if completed.size() == STAGE_COUNT:
			_open_page("GALLERY")
		else:
			_play())
	play_center.add_child(continue_button)
	progress_label = N.label(bottom_column, L.copy("36 shadow records await.") if completed.is_empty() else L.progress(completed.size()), 11, N.SOFT)
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readable(progress_label)
	var nav: HBoxContainer = HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 8)
	bottom_column.add_child(nav)
	for item: String in ["ABOUT", "HOW TO PLAY", "GALLERY"]:
		var button: Button = N.button(L.copy(item), 44)
		button.name = item.to_pascal_case() + "Button"
		button.pressed.connect(_open_page.bind(item))
		nav.add_child(button)
	var footer: Label = N.label(bottom_column, L.copy("OBSERVE.   CONNECT.   UNCOVER."), 9, N.BRASS)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readable(footer)
	_build_modal()

func _build_modal() -> void:
	modal = Control.new()
	modal.name = "ArchiveOverlay"
	add_child(modal)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scrim: ColorRect = ColorRect.new()
	scrim.color = Color(0.01, 0.02, 0.04, 0.87)
	modal.add_child(scrim)
	scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame: MarginContainer = N.margin(modal, 20)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", N.box(Color("#101a25"), Color(N.BRASS, 0.5), 6, 18))
	frame.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	column.add_child(header)
	modal_title = N.label(header, L.copy("THE ARCHIVE"), 28, N.IVORY, true)
	modal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var close: Button = N.button(L.copy("CLOSE  ×"), 44)
	close.name = "CloseOverlay"
	close.pressed.connect(_close_modal)
	header.add_child(close)
	modal_scroll = ScrollContainer.new()
	modal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(modal_scroll)
	modal_body = VBoxContainer.new()
	modal_body.add_theme_constant_override("separation", 20)
	modal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	modal_scroll.add_child(modal_body)
	archive = VBoxContainer.new()
	archive.name = "MemoryArchive"
	archive.add_theme_constant_override("separation", 20)
	modal_body.add_child(archive)
	for chapter_index: int in 6:
		_build_chapter(archive, chapter_index)
	modal.hide()

func _build_chapter(parent: VBoxContainer, chapter_index: int) -> void:
	var heading: Label = N.label(parent, "%02d  /  %s" % [chapter_index + 1, Story.chapter_name(chapter_index * 6, L.language())], 19, N.IVORY, true)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var note: Label = N.label(parent, Story.chapter_note(chapter_index * 6, L.language()), 12, N.SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_to_group("NoxArchiveGrid")
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	parent.add_child(grid)
	for offset: int in 6:
		var index: int = chapter_index * 6 + offset
		var cleared: bool = completed.has("GR%02d" % (index + 1))
		var button: Button = N.button("%02d  %s\n%s" % [index + 1, "✓" if cleared else "·", Story.title(index, L.language())], 70)
		button.name = "Trace%02d" % (index + 1)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 11)
		button.clip_text = true
		button.tooltip_text = Story.title(index, L.language()) + "\n" + Story.note(index, L.language())
		button.pressed.connect(_enter.bind(index))
		grid.add_child(button)

func _prepare_page(title: String) -> void:
	return_focus = get_viewport().gui_get_focus_owner()
	for child: Node in modal_body.get_children():
		if child != archive:
			modal_body.remove_child(child)
			child.queue_free()
	archive.hide()
	modal_title.text = title
	modal_scroll.scroll_vertical = 0
	modal.show()
	(modal.find_child("CloseOverlay", true, false) as Button).grab_focus()

func _paragraph(title: String, body: String) -> void:
	var section: VBoxContainer = VBoxContainer.new()
	section.add_theme_constant_override("separation", 8)
	modal_body.add_child(section)
	var heading: Label = N.label(section, L.copy(title), 23, N.BRASS, true)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var text: Label = N.label(section, L.copy(body), 14, N.IVORY)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_constant_override("line_spacing", 5)

func _open_page(page: String) -> void:
	if entering:
		return
	_prepare_page(L.copy(page))
	if page == "GALLERY":
		modal_title.text = L.copy("THE SHADOW ARCHIVE")
		archive.show()
	elif page == "ABOUT":
		var prologue: Button = N.button(L.opening("replay"), 48)
		prologue.name = "PrologueButton"
		prologue.pressed.connect(_open_prologue.bind(true))
		modal_body.add_child(prologue)
		_paragraph("The archive kept only the shadows.", "NOX was nowhere to be found. In the old Nocturnal Optical Archive, a single plate can hold the shadows of several moments.")
		_paragraph("A quiet act of reconstruction", "Place NOX's traces where the recorded shadows agree. Each pose belongs to the same cat, seen at a different moment. The record reveals where NOX was, but keeps the order of those moments to itself.")
		_paragraph("36 records. One unanswered question.", "Follow the evidence deeper into the archive. What drew NOX into the night?")
	else:
		_paragraph("01  Read the plate", "Compare RECORDED SHADOW with your RECONSTRUCTION. Darker squares hold more overlapping shadows. A question mark is an unrecorded area.")
		_paragraph("02  Place a NOX trace", "Choose a pose, then click a board position, or drag it onto the board. Click a placed SIT or STAND trace to remove it; drag any trace to move it. Drag a WALK trace back to its tray to remove it. Several traces show different moments of the same cat.")
		_paragraph("03  Observe the light", "SIT leaves a nearby trace. STAND reaches farther. WALK has a direction: click WALK or a placed WALK trace to turn it. Available light sources can be switched. SLEEP rests on the rail and blocks the light above its column.")
		_paragraph("04  Let the shadows agree", "Match every recorded square with the available poses and light sources. UNDO takes back one move. RESET clears this reconstruction. OBSERVE offers a clue without placing an answer.")
		_paragraph("Take your time", "There is no timer or penalty. Progress is saved in this browser. Use the GALLERY to revisit any of the 36 records. Escape closes a panel.")

func _open_settings() -> void:
	_prepare_page(L.copy("SETTINGS"))
	_paragraph("A quieter room", "Choose how the archive feels. These preferences are saved on this device.")
	var sound: CheckButton = CheckButton.new()
	sound.name = "SoundToggle"
	sound.text = L.copy("Sound")
	sound.button_pressed = Settings.sound_enabled()
	sound.custom_minimum_size.y = 52
	sound.add_theme_font_override("font", N.BODY)
	sound.toggled.connect(_set_sound)
	modal_body.add_child(sound)
	_add_volume_slider("BGM", "bgm_volume", Settings.bgm_volume())
	_add_volume_slider("SE", "se_volume", Settings.se_volume())
	var motion: CheckButton = CheckButton.new()
	motion.name = "MotionToggle"
	motion.text = L.copy("Reduce motion")
	motion.button_pressed = Settings.reduced_motion()
	motion.custom_minimum_size.y = 52
	motion.add_theme_font_override("font", N.BODY)
	motion.toggled.connect(func(enabled: bool) -> void:
		Settings.write_value("reduced_motion", enabled)
		for child: Node in get_children():
			if child.get_script() == preload("res://src/ui/nox_atmosphere.gd"):
				child.set_process(not enabled))
	modal_body.add_child(motion)
	var language: Button = N.button(L.copy("Language") + ": " + ("日本語" if L.is_japanese() else "English") + "  ›", 52)
	language.name = "LanguageToggle"
	language.pressed.connect(func() -> void: _switch_language(true))
	modal_body.add_child(language)
	_paragraph("Made for a moment of attention", "Headphones are optional. Every puzzle can be solved without sound.")

func _add_volume_slider(title: String, key: String, current: float) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = title + "VolumeRow"
	row.add_theme_constant_override("separation", 10)
	modal_body.add_child(row)
	var caption: Label = N.label(row, title, 14, N.IVORY)
	caption.custom_minimum_size.x = 42
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var slider: HSlider = HSlider.new()
	slider.name = title + "VolumeSlider"
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 5.0
	slider.value = current
	slider.custom_minimum_size.y = 44
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.tooltip_text = title + " volume"
	row.add_child(slider)
	var amount: Label = N.label(row, "%d%%" % roundi(current), 13, N.IVORY)
	amount.name = title + "VolumeValue"
	amount.custom_minimum_size.x = 48
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slider.value_changed.connect(func(value: float) -> void:
		Settings.write_value(key, value)
		Settings.apply_audio()
		amount.text = "%d%%" % roundi(value))

func _set_sound(enabled: bool) -> void:
	Settings.write_value("sound", enabled)
	Settings.apply_audio()
	_refresh_sound_button()

func _toggle_sound() -> void:
	_set_sound(not Settings.sound_enabled())

func _refresh_sound_button() -> void:
	if sound_button == null:
		return
	sound_button.text = ("音 ON" if Settings.sound_enabled() else "音 OFF") if L.is_japanese() else ("SOUND ON" if Settings.sound_enabled() else "SOUND OFF")
	sound_button.tooltip_text = L.copy("Sound")
	sound_button.accessibility_name = sound_button.text
	var active: bool = Settings.sound_enabled()
	sound_button.add_theme_stylebox_override("normal", N.box(Color("#173440") if active else Color(0.04, 0.07, 0.10, 0.88), Color("#8dd9e7") if active else Color(N.BRASS, 0.35), 4, 6))

func _readable(label: Label, outline: int = 2) -> void:
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.95))

func _switch_language(reopen_settings: bool = false) -> void:
	L.toggle()
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_build_ui()
	_responsive()
	if reopen_settings:
		_open_settings()

func _close_modal() -> void:
	modal.hide()
	if is_instance_valid(return_focus):
		return_focus.grab_focus()

func _unhandled_key_input(event: InputEvent) -> void:
	if entering:
		return
	if event.is_action_pressed("ui_cancel") and modal.visible:
		_close_modal()
		get_viewport().set_input_as_handled()

func _responsive() -> void:
	if wordmark == null:
		return
	wordmark.custom_minimum_size.y = clampf(size.x * 0.18, 70, 114)
	continue_button.custom_minimum_size.x = minf(316, size.x - 40)
	continue_button.custom_minimum_size.y = 64 if size.x <= 480 else 58
	subtitle.add_theme_font_size_override("font_size", 13 if size.x <= 480 else 14)
	masthead.add_theme_font_size_override("font_size", 9 if size.x < 500 else 11)
	for grid: Node in get_tree().get_nodes_in_group("NoxArchiveGrid"):
		grid.columns = 2 if size.x < 500 else 3

func _enter(index: int) -> void:
	if entering:
		return
	entering = true
	var fade: ColorRect = ColorRect.new()
	fade.color = N.INK
	fade.modulate.a = 0.0
	add_child(fade)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var transition: Tween = create_tween()
	transition.tween_property(fade, "modulate:a", 1.0, 0.05 if Settings.reduced_motion() else 0.65).set_trans(Tween.TRANS_SINE)
	transition.tween_callback(func() -> void: start_requested.emit(index))

func _play() -> void:
	if entering:
		return
	if not bool(Settings.read_value("opening_seen", false)):
		_open_prologue(false)
	else:
		_enter(_resume_index())

func _open_prologue(is_replay: bool) -> void:
	if entering:
		return
	entering = true
	var opening: Control = (preload("res://scenes/nox_opening_kamishibai.tscn") as PackedScene).instantiate()
	opening.replay = is_replay
	opening.finished.connect(func() -> void:
		entering = false
		if not is_replay:
			_enter(0)
		else:
			remove_child(opening)
			opening.queue_free()
			var replay_button: Button = modal.find_child("PrologueButton", true, false) as Button
			if replay_button != null:
				replay_button.grab_focus())
	add_child(opening)
