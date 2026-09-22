extends Control

# The game owns moves, hints, saves and the delayed NEXT transition.
const T = preload("res://src/night_tokens.gd")
const Rules = preload("res://src/shadow_rules.gd")
const L = preload("res://src/ui/localization.gd")

var game: Control
var column: VBoxContainer
var sound_button: Button
var language_button: Button
var help_button: Button
var help_overlay: Panel
var help_card: PanelContainer
var close_button: Button
var collection: Control
var collection_label: Label
var subtitle_label: Label
var target_label: Label
var live_label: Label
var instrument_caption: Label
var legend_label: Label
var help_kicker: Label
var help_heading: Label
var help_rule_titles: Array[Label] = []
var help_rule_bodies: Array[Label] = []
var help_swatches: Array[Label] = []
var help_keys: Label
var language_code: String = L.EN
var last_status_source: String = ""
var muted: bool = false
var previous_focus: Control
var saved_focus_modes: Dictionary = {}

func _ready() -> void:
	name = "ProductUI"
	game = get_parent() as Control
	set_as_top_level(true)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	column = game.get_child(1).get_child(0) as VBoxContainer
	game.get_child(1).name = "GameFrame"
	column.name = "GameColumn"
	var heading: Label = column.get_child(0) as Label
	heading.name = "GameTitle"
	subtitle_label = _label("", 10, T.TEXT_MUTED)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_child(subtitle_label)
	subtitle_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	subtitle_label.offset_top = -14
	subtitle_label.offset_bottom = 0
	sound_button = _utility_button("SFX", "")
	sound_button.name = "SoundButton"
	sound_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	sound_button.offset_left = 0
	sound_button.offset_right = 44
	heading.add_child(sound_button)
	sound_button.pressed.connect(_toggle_sound)
	language_button = _utility_button("", "")
	language_button.name = "LanguageButton"
	language_button.custom_minimum_size = Vector2(44, 44)
	language_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	language_button.offset_left = 48
	language_button.offset_right = 92
	heading.add_child(language_button)
	language_button.pressed.connect(_toggle_language)
	help_button = _utility_button("?", "")
	help_button.name = "HelpButton"
	help_button.add_theme_font_size_override("font_size", 20)
	heading.add_child(help_button)
	help_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	help_button.offset_left = -44
	help_button.offset_right = 0
	help_button.pressed.connect(open_help)
	collection = Control.new()
	collection.name = "Collection"
	collection.custom_minimum_size.y = 32
	collection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(collection)
	collection_label = _label("", 10, T.TEXT_MUTED)
	collection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	collection.add_child(collection_label)
	collection_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	collection.draw.connect(_draw_collection)
	_build_help()
	for index: int in game.post_buttons.size():
		var button: Button = game.post_buttons[index]
		button.name = "Socket" + String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
		button.mouse_entered.connect(_refresh_socket_focus.bind(index))
		button.mouse_exited.connect(_refresh_socket_focus.bind(index))
		button.focus_entered.connect(_refresh_socket_focus.bind(index))
		button.focus_exited.connect(_refresh_socket_focus.bind(index))
	for index: int in game.post_buttons.size():
		var button: Button = game.post_buttons[index]
		var neighbors: Array[int] = [index - 1 if index % 5 > 0 else index, index - 5 if index >= 5 else index, index + 1 if index % 5 < 4 else index, index + 5 if index < 20 else index]
		for side: int in 4:
			button.set_focus_neighbor(side, button.get_path_to(game.post_buttons[neighbors[side]]))
	_load_preferences()
	reflow()
	call_deferred("reflow")

func _label(copy: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = copy
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _utility_button(copy: String, tooltip: String) -> Button:
	var button: Button = Button.new()
	button.text = copy
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(44, 44)
	button.add_theme_font_override("font", T.instrument_font())
	button.add_theme_font_size_override("font_size", 12)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button

func _box(background: Color, border: Color, radius: int = 10) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style

func _focus_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = _box(Color.TRANSPARENT, T.CYAN)
	style.draw_center = false
	style.set_border_width_all(2)
	return style

func style_controls() -> void:
	for button: Button in [game.back_button, game.reset_button, game.undo_button, game.hint_button, game.next_button, sound_button, language_button, help_button, close_button]:
		if button == null:
			continue
		button.focus_mode = Control.FOCUS_NONE if help_overlay.visible and button != close_button else Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var primary: bool = button == game.next_button or button == close_button
		var accent: Color = T.GOLD if primary else (T.CYAN if button == game.hint_button else T.TEXT_SECONDARY)
		button.add_theme_stylebox_override("normal", _box(Color("242321") if primary else T.BG_BUTTON, T.GOLD_SOFT if primary else T.LINE_MEDIUM))
		button.add_theme_stylebox_override("hover", _box(Color("353027") if primary else Color("202b32"), accent))
		button.add_theme_stylebox_override("pressed", _box(T.BG_BASE, accent))
		button.add_theme_stylebox_override("disabled", _box(Color("10151a"), T.LINE_SOFT))
		button.add_theme_stylebox_override("focus", _focus_style())
		button.add_theme_color_override("font_color", accent)
		button.add_theme_color_override("font_hover_color", T.TEXT_PRIMARY)
		button.add_theme_color_override("font_pressed_color", T.TEXT_PRIMARY)
		button.add_theme_color_override("font_disabled_color", Color("657079"))
	for button: Button in game.post_buttons:
		button.focus_mode = Control.FOCUS_NONE if help_overlay.visible else Control.FOCUS_ALL
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("focus", _focus_style())
	game.undo_button.tooltip_text = L.copy("undo_tooltip", language_code)
	game.reset_button.tooltip_text = L.copy("reset_tooltip", language_code)
	game.back_button.tooltip_text = L.copy("back_tooltip", language_code)
	game.hint_button.tooltip_text = L.copy("hint_tooltip", language_code)
	game.next_button.tooltip_text = L.copy("next_tooltip", language_code)

func reflow() -> void:
	var compact: bool = game.compact_layout
	var available: Vector2 = get_viewport_rect().size
	var margin: MarginContainer = game.get_child(1) as MarginContainer
	var short_screen: bool = compact and available.y < 880
	var inset: int = (8 if available.x < 380 else 10) if compact else maxi(24, int((available.x - 640) * 0.5))
	game._set_margins(margin, inset, inset, 12 if short_screen or not compact else 20, 12 if short_screen or not compact else 20)
	column.add_theme_constant_override("separation", (5 if short_screen else 8) if compact else 4)
	var title: Label = column.get_child(0) as Label
	title.custom_minimum_size.y = (54 if short_screen else 58) if compact else 52
	title.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	title.add_theme_font_size_override("font_size", 27 if compact else 32)
	game.stage_label.custom_minimum_size.y = 24 if compact else 20
	game.stage_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game.stage_label.add_theme_font_size_override("font_size", 14)
	game.stage_label.add_theme_color_override("font_color", T.GOLD)
	game.counter_label.custom_minimum_size.y = 22 if compact else 18
	game.counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game.counter_label.add_theme_font_size_override("font_size", 12)
	game.counter_label.add_theme_color_override("font_color", T.TEXT_SECONDARY)
	var screens: HBoxContainer = column.get_child(3) as HBoxContainer
	if compact:
		var cell_size: float = minf(32, floorf((available.x - inset * 2 - 8 - 56) / 10))
		for cell: Control in game.clue_cells + game.live_cells:
			cell.custom_minimum_size = Vector2(cell_size, cell_size)
	for index: int in 2:
		var screen_title: Label = screens.get_child(index).get_child(0) as Label
		screen_title.text = L.copy("target", language_code) if index == 0 else L.copy("live", language_code)
		screen_title.add_theme_font_size_override("font_size", 12)
	var air: Control = column.get_child(4) as Control
	air.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var instrument: VBoxContainer = column.get_child(5) as VBoxContainer
	var arrow: Label = instrument.get_child(1) as Label
	arrow.visible = not short_screen
	if available.x < 380:
		for emitter: Label in [instrument.get_child(2).get_child(0), instrument.get_child(2).get_child(2)]:
			emitter.custom_minimum_size.x = 28
	instrument_caption = instrument.get_child(3) as Label
	instrument_caption.text = L.copy("instrument", language_code)
	instrument_caption.add_theme_font_size_override("font_size", 11)
	game.status_label.custom_minimum_size.y = 42 if compact else 32
	game.status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.status_label.add_theme_font_size_override("font_size", 13 if compact else 14)
	var footer: HBoxContainer = game.next_button.get_parent() as HBoxContainer
	var gap: int = (4 if available.x < 380 else 6) if compact else 8
	footer.add_theme_constant_override("separation", gap)
	var next_width: int = (104 if available.x < 380 else 110) if compact else 134
	var language_shrink: int = 2 if compact and language_code == L.JA else 0
	var secondary_width: int = mini(58, int((available.x - inset * 2 - next_width - gap * 4) / 4)) - language_shrink if compact else 90
	for button: Button in footer.get_children():
		button.custom_minimum_size = Vector2(secondary_width, 46 if compact else 44)
		button.add_theme_font_size_override("font_size", 10 if compact else 12)
	game.next_button.custom_minimum_size.x = next_width
	legend_label = column.get_child(8) as Label
	legend_label.text = L.copy("legend", language_code)
	legend_label.custom_minimum_size.y = 18
	legend_label.add_theme_font_override("font", T.body_font())
	legend_label.add_theme_font_size_override("font_size", 11)
	legend_label.add_theme_color_override("font_color", T.TEXT_SECONDARY)
	collection.custom_minimum_size.y = 24 if short_screen else (30 if compact else 26)
	help_card.custom_minimum_size.x = minf(420, available.x - 40)
	style_controls()
	refresh()

func refresh() -> void:
	if game.stages.is_empty():
		return
	last_status_source = L.to_english(game.status_label.text)
	_apply_language()
	collection.queue_redraw()

func _process(_delta: float) -> void:
	if game == null or game.status_label == null:
		return
	var raw: String = game.status_label.text
	var source: String = L.to_english(raw)
	var localized: String = L.status(source, language_code)
	if source != last_status_source or raw != localized:
		last_status_source = source
		game.status_label.text = localized
	var next_localized: String = L.next_button(game.next_button.text, language_code)
	if game.next_button.text != next_localized:
		game.next_button.text = next_localized

func _apply_language() -> void:
	if game == null or game.stages.is_empty():
		return
	var stage: Dictionary = game.stages[game.stage_index]
	var stage_title: String = L.stage_title(String(stage["title"]), language_code)
	var tier_name: String = L.tier_name(String(stage["tier"]), language_code)
	subtitle_label.text = L.copy("subtitle", language_code)
	game.stage_label.text = "%02d  /  %s" % [int(stage["id"]), stage_title]
	var placed: int = Rules.count_posts(game.posts)
	game.counter_label.text = L.copy("posts", language_code) % [placed, int(stage["posts"]), tier_name]
	collection_label.text = L.copy("collection", language_code) % [game.completed_stage_ids.size(), game.stages.size()]
	var screens: HBoxContainer = column.get_child(3) as HBoxContainer
	for index: int in 2:
		var screen_title: Label = screens.get_child(index).get_child(0) as Label
		screen_title.text = L.copy("target", language_code) if index == 0 else L.copy("live", language_code)
	instrument_caption.text = L.copy("instrument", language_code)
	legend_label.text = L.copy("legend", language_code)
	game.undo_button.text = L.copy("undo", language_code)
	game.reset_button.text = L.copy("reset", language_code)
	game.back_button.text = L.copy("back", language_code)
	game.next_button.text = L.next_button(game.next_button.text, language_code)
	var hint_text: String = game.hint_button.text
	if language_code == L.JA and hint_text.begins_with("HINT"):
		hint_text = "ヒント" + hint_text.substr(4)
	elif language_code == L.EN and hint_text.begins_with("ヒント"):
		hint_text = "HINT" + hint_text.substr(3)
	game.hint_button.text = hint_text if not hint_text.is_empty() else L.copy("hint", language_code)
	language_button.text = L.copy("language_to_ja", language_code) if language_code == L.EN else L.copy("language_to_en", language_code)
	language_button.tooltip_text = L.copy("switch_to_ja", language_code) if language_code == L.EN else L.copy("switch_to_en", language_code)
	help_button.tooltip_text = L.copy("help_tooltip", language_code)
	game.undo_button.tooltip_text = L.copy("undo_tooltip", language_code)
	game.reset_button.tooltip_text = L.copy("reset_tooltip", language_code)
	game.back_button.tooltip_text = L.copy("back_tooltip", language_code)
	game.hint_button.tooltip_text = L.copy("hint_tooltip", language_code)
	game.next_button.tooltip_text = L.copy("next_tooltip", language_code)
	game.status_label.text = L.status(last_status_source, language_code)
	game.status_label.add_theme_font_size_override("font_size", 12 if game.compact_layout and language_code == L.JA else (13 if game.compact_layout else 14))
	if help_kicker != null:
		help_kicker.text = L.copy("help_kicker", language_code)
		help_heading.text = L.copy("help_heading", language_code)
		var rule_title_keys: Array[String] = ["help_rule_1_title", "help_rule_2_title", "help_rule_3_title"]
		var rule_body_keys: Array[String] = ["help_rule_1_body", "help_rule_2_body", "help_rule_3_body"]
		for index: int in help_rule_titles.size():
			help_rule_titles[index].text = L.copy(rule_title_keys[index], language_code)
			help_rule_bodies[index].text = L.copy(rule_body_keys[index], language_code)
		var swatch_names: Array[String] = [L.copy("clear", language_code), "1", "2", "3", "?"]
		for index: int in help_swatches.size():
			help_swatches[index].text = swatch_names[index]
		help_keys.text = L.copy("keys", language_code)
		close_button.text = L.copy("close_help", language_code)
		close_button.tooltip_text = L.copy("close_help_tooltip", language_code)
	_refresh_sound()
	for index: int in game.post_buttons.size():
		var button: Button = game.post_buttons[index]
		var occupied: bool = game.posts[int(index / 5.0)][index % 5]
		var action_copy: String = L.copy("move_post", language_code) if occupied else L.copy("place_post", language_code)
		button.tooltip_text = "%s%d · %s" % [String.chr(65 + index % 5), int(index / 5.0) + 1, action_copy]

func _draw_collection() -> void:
	var track_width: float = minf(320, collection.size.x)
	var start: float = (collection.size.x - track_width) * 0.5
	var count: int = game.stages.size()
	if count == 0:
		return
	var segment: float = (track_width - (count - 1) * 4) / count
	for index: int in count:
		var completed: bool = game.completed_stage_ids.has(int(game.stages[index]["id"]))
		var color: Color = T.GOLD if completed else (T.CYAN_SOFT if index == game.stage_index else T.LINE_SOFT)
		collection.draw_rect(Rect2(start + index * (segment + 4), collection.size.y - 4, segment, 2), color)

func _refresh_socket_focus(index: int) -> void:
	if game.drag_active:
		return
	var button: Button = game.post_buttons[index]
	game._set_socket_active(index, not button.disabled and (button.has_focus() or button.is_hovered()))

func _build_help() -> void:
	help_overlay = Panel.new()
	help_overlay.name = "HelpOverlay"
	help_overlay.add_theme_stylebox_override("panel", _box(Color(0.02, 0.03, 0.04, 0.96), Color.TRANSPARENT, 0))
	help_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_overlay.hide()
	add_child(help_overlay)
	var center: CenterContainer = CenterContainer.new()
	center.name = "HelpCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	help_overlay.add_child(center)
	help_card = PanelContainer.new()
	help_card.name = "HelpCard"
	var surface: StyleBoxFlat = _box(T.BG_ELEVATED, T.LINE_BRIGHT, 18)
	for edge: int in 4:
		surface.set_content_margin(edge, 24)
	help_card.add_theme_stylebox_override("panel", surface)
	center.add_child(help_card)
	var content: VBoxContainer = VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 18)
	help_card.add_child(content)
	help_kicker = _label("", 11, T.GOLD)
	content.add_child(help_kicker)
	help_heading = _label("", 28, T.TEXT_PRIMARY)
	help_heading.add_theme_font_override("font", T.display_font())
	help_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(help_heading)
	for index: int in 3:
		var group: VBoxContainer = VBoxContainer.new()
		group.add_theme_constant_override("separation", 6)
		content.add_child(group)
		var rule_title: Label = _label("", 14, T.TEXT_PRIMARY)
		group.add_child(rule_title)
		help_rule_titles.append(rule_title)
		var explanation: Label = _label("", 14, T.TEXT_SECONDARY)
		explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		group.add_child(explanation)
		help_rule_bodies.append(explanation)
	var swatches: HBoxContainer = HBoxContainer.new()
	swatches.add_theme_constant_override("separation", 8)
	content.add_child(swatches)
	var colors: Array[Color] = [T.SHADOW_0, T.SHADOW_1, T.SHADOW_2, T.SHADOW_3, T.SHADOW_UNKNOWN]
	for index: int in 5:
		var swatch: VBoxContainer = VBoxContainer.new()
		swatch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		swatches.add_child(swatch)
		var glass: Panel = Panel.new()
		glass.custom_minimum_size.y = 28
		glass.add_theme_stylebox_override("panel", _box(colors[index], T.LINE_BRIGHT, 5))
		glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.add_child(glass)
		var value: Label = _label("", 11, T.TEXT_SECONDARY)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		swatch.add_child(value)
		help_swatches.append(value)
	help_keys = _label("", 12, T.TEXT_MUTED)
	help_keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(help_keys)
	close_button = _utility_button("", "")
	close_button.name = "CloseHelp"
	close_button.custom_minimum_size.y = 48
	close_button.pressed.connect(close_help)
	content.add_child(close_button)

func open_help() -> void:
	if help_overlay.visible:
		return
	if game.drag_active:
		game._finish_post_drag(game.drag_source_index)
	game._clear_drag_state()
	previous_focus = get_viewport().gui_get_focus_owner()
	saved_focus_modes.clear()
	for button: Button in _background_buttons():
		saved_focus_modes[button] = button.focus_mode
		button.focus_mode = Control.FOCUS_NONE
	game.set_process_input(false)
	help_overlay.show()
	close_button.grab_focus()

func close_help() -> void:
	help_overlay.hide()
	game.set_process_input(true)
	for button: Button in saved_focus_modes:
		if is_instance_valid(button):
			button.focus_mode = saved_focus_modes[button]
	saved_focus_modes.clear()
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree() and not (previous_focus is BaseButton and previous_focus.disabled):
		previous_focus.grab_focus()
	else:
		help_button.grab_focus()

func _background_buttons() -> Array[Button]:
	var buttons: Array[Button] = [game.back_button, game.reset_button, game.undo_button, game.hint_button, game.next_button, sound_button, language_button, help_button]
	for button: Button in game.post_buttons:
		buttons.append(button)
	return buttons

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key: InputEventKey = event as InputEventKey
	if help_overlay.visible:
		if key.keycode in [KEY_ESCAPE, KEY_F1]:
			close_help()
		get_viewport().set_input_as_handled()
		return
	if key.keycode == KEY_F1 or (key.keycode == KEY_SLASH and key.shift_pressed) or key.unicode == 63:
		open_help()
	elif key.keycode == KEY_Z and (key.ctrl_pressed or key.meta_pressed):
		game._undo_move()
	elif key.keycode == KEY_M:
		_toggle_sound()
	elif key.keycode == KEY_L:
		_toggle_language()
	else:
		return
	get_viewport().set_input_as_handled()

func _toggle_sound() -> void:
	muted = not muted
	_refresh_sound()
	if muted:
		for child: Node in game.get_children():
			if child is AudioStreamPlayer:
				child.queue_free()
	_save_preferences()

func _toggle_language() -> void:
	language_code = L.JA if language_code == L.EN else L.EN
	reflow()
	_save_preferences()

func _save_preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value("audio", "muted", muted)
	config.set_value("ui", "language", language_code)
	if config.save(game.progress_path + ".preferences.cfg") != OK:
		push_warning("Could not save UI preferences")

func _load_preferences() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(game.progress_path + ".preferences.cfg") == OK:
		muted = config.get_value("audio", "muted", false) == true
		var saved_language: String = String(config.get_value("ui", "language", L.EN))
		language_code = L.JA if saved_language == L.JA else L.EN
	_refresh_sound()

func _refresh_sound() -> void:
	sound_button.text = "OFF" if muted else "SFX"
	sound_button.tooltip_text = L.copy("sound_off", language_code) if muted else L.copy("sound_on", language_code)
	sound_button.accessibility_name = L.copy("unmute", language_code) if muted else L.copy("mute", language_code)
