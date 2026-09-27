extends RefCounted

const N = preload("res://src/ui/nox_theme.gd")
const Surface = preload("res://src/ui/experiment_surface.gd")
const Story = preload("res://src/nox_story.gd")
const Settings = preload("res://src/nox_settings.gd")
const L = preload("res://src/nox_locale.gd")

static func _browser_viewport_metrics(game: Control) -> Dictionary:
	var logical_size: Vector2 = game.get_viewport_rect().size
	var inner_width: float = logical_size.x
	var inner_height: float = logical_size.y
	var visual_width: float = inner_width
	var visual_height: float = inner_height
	if OS.has_feature("web"):
		var raw_inner_width: Variant = JavaScriptBridge.eval("window.innerWidth", true)
		var raw_inner_height: Variant = JavaScriptBridge.eval("window.innerHeight", true)
		var raw_visual_width: Variant = JavaScriptBridge.eval("window.visualViewport ? window.visualViewport.width : window.innerWidth", true)
		var raw_visual_height: Variant = JavaScriptBridge.eval("window.visualViewport ? window.visualViewport.height : window.innerHeight", true)
		if typeof(raw_inner_width) == TYPE_FLOAT or typeof(raw_inner_width) == TYPE_INT:
			inner_width = float(raw_inner_width)
		if typeof(raw_inner_height) == TYPE_FLOAT or typeof(raw_inner_height) == TYPE_INT:
			inner_height = float(raw_inner_height)
		if typeof(raw_visual_width) == TYPE_FLOAT or typeof(raw_visual_width) == TYPE_INT:
			visual_width = float(raw_visual_width)
		if typeof(raw_visual_height) == TYPE_FLOAT or typeof(raw_visual_height) == TYPE_INT:
			visual_height = float(raw_visual_height)
	return {
		"inner_width": inner_width,
		"inner_height": inner_height,
		"visual_width": visual_width,
		"visual_height": visual_height,
		"css_width": minf(inner_width, visual_width),
		"css_height": visual_height if visual_height > 0.0 else inner_height,
		"logical_size": logical_size
	}

static func viewport_css_width(game: Control) -> float:
	var metrics: Dictionary = _browser_viewport_metrics(game)
	return float(metrics["css_width"])

static func viewport_css_size(game: Control) -> Vector2:
	var metrics: Dictionary = _browser_viewport_metrics(game)
	return Vector2(float(metrics["css_width"]), float(metrics["css_height"]))

static func is_mobile_viewport(game: Control) -> bool:
	return viewport_css_width(game) <= 480.0

static func is_short_mobile_viewport(game: Control) -> bool:
	var metrics: Dictionary = _browser_viewport_metrics(game)
	return float(metrics["css_width"]) <= 480.0 and float(metrics["css_height"]) <= 760.0

static func refresh_browser_layout(game: Control) -> bool:
	if not OS.has_feature("web"):
		return false
	var metrics: Dictionary = _browser_viewport_metrics(game)
	var browser_size: Vector2 = Vector2(float(metrics["css_width"]), float(metrics["css_height"]))
	var logical_size: Vector2 = metrics["logical_size"]
	var previous_size_value: Variant = game.get_meta("noxsum_browser_layout_size", Vector2(-1.0, -1.0))
	var previous_size: Vector2 = previous_size_value if previous_size_value is Vector2 else Vector2(-1.0, -1.0)
	var previous_logical_value: Variant = game.get_meta("noxsum_browser_logical_size", Vector2(-1.0, -1.0))
	var previous_logical: Vector2 = previous_logical_value if previous_logical_value is Vector2 else Vector2(-1.0, -1.0)
	if previous_size.is_equal_approx(browser_size) and previous_logical.is_equal_approx(logical_size):
		return false
	var column: VBoxContainer = game.find_child("ReconstructionLayout", true, false) as VBoxContainer
	if column == null:
		return false
	_responsive(game, column)
	return true

static func build(game: Control) -> void:
	Settings.apply_audio()
	N.ensure_japanese_font()
	var background: ColorRect = ColorRect.new()
	background.color = Color("#111d2a")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var image: TextureRect = TextureRect.new()
	image.texture = preload("res://assets/nox/v0.4/archive_window.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate = Color(0.58, 0.66, 0.74, 0.25)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background_scrim: ColorRect = ColorRect.new()
	background_scrim.color = Color(0.01, 0.03, 0.05, 0.28)
	background_scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(background_scrim)
	background_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.theme = Theme.new()
	game.theme.default_font = N.BODY
	game.theme.default_font_size = 12
	var frame: MarginContainer = N.margin(game, 16)
	frame.name = "StageFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var horizontal: HBoxContainer = HBoxContainer.new()
	horizontal.alignment = BoxContainer.ALIGNMENT_CENTER
	frame.add_child(horizontal)
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "ReconstructionLayout"
	column.add_theme_constant_override("separation", 1)
	horizontal.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	header.name = "StageHeader"
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	var home: Button = N.button(L.copy("‹  HOME"), 44)
	L.bind_text(home, "‹  HOME")
	home.name = "HomeButton"
	home.pressed.connect(func() -> void: game.home_requested.emit())
	header.add_child(home)
	if game.playtest_mode:
		home.hide()
	var language: Button = N.button(L.switch_label(), 44)
	language.name = "LanguageButton"
	language.pressed.connect(game.toggle_language)
	header.add_child(language)
	var logo: Control = preload("res://src/ui/nox_wordmark.gd").new()
	logo.name = "NoxWordmark"
	logo.custom_minimum_size = Vector2(92, 44)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(logo)
	game.stage_picker = OptionButton.new()
	game.stage_picker.name = "TracePicker"
	game.stage_picker.custom_minimum_size = Vector2(82, 44)
	game.stage_picker.add_theme_font_size_override("font_size", 11)
	game.stage_picker.add_theme_stylebox_override("normal", N.box(Color(0.04, 0.08, 0.12, 0.8), Color(N.BRASS, 0.3)))
	for index: int in game.stages.size():
		game.stage_picker.add_item("%02d / 36" % (index + 1))
	game.stage_picker.item_selected.connect(game.load_stage)
	game.stage_picker.get_popup().max_size = Vector2i(0, 520)
	header.add_child(game.stage_picker)
	if game.playtest_mode:
		game.stage_picker.hide()
	game.title_label = N.label(column, "", 25, N.IVORY, true)
	game.title_label.name = "NOXTitle"
	game.title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readable(game.title_label, 3)
	game.count_label = N.label(column, "", 13, N.IVORY)
	game.count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var screens: HBoxContainer = HBoxContainer.new()
	screens.name = "ShadowPlates"
	screens.alignment = BoxContainer.ALIGNMENT_CENTER
	screens.add_theme_constant_override("separation", 20)
	column.add_child(screens)
	for is_record: bool in [true, false]:
		var plate: PanelContainer = PanelContainer.new()
		plate.name = "RecordedPlate" if is_record else "ReconstructionPlate"
		plate.add_theme_stylebox_override("panel", N.box(Color("#1c2e3a"), Color(N.BRASS if is_record else N.SOFT, 0.7), 3, 8))
		screens.add_child(plate)
		var stack: VBoxContainer = VBoxContainer.new()
		stack.add_theme_constant_override("separation", 6)
		plate.add_child(stack)
		var caption_key: String = "RECORDED SHADOW" if is_record else "RECONSTRUCTION"
		var caption: Label = N.label(stack, L.copy(caption_key), 11, N.BRASS if is_record else N.SOFT)
		L.bind_text(caption, caption_key)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var grid_center: CenterContainer = CenterContainer.new()
		grid_center.name = "RecordedGridCenter" if is_record else "ReconstructionGridCenter"
		grid_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stack.add_child(grid_center)
		var grid: GridContainer = GridContainer.new()
		grid.name = "RecordedShadowGrid" if is_record else "ReconstructionShadowGrid"
		grid.columns = 5
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
		grid_center.add_child(grid)
		for index: int in 25:
			var holder: Control = Control.new()
			holder.custom_minimum_size = Vector2(26, 26)
			grid.add_child(holder)
			var surface: Control = Surface.new()
			surface.kind = "shadow"
			surface.nox_mode = true
			holder.add_child(surface)
			if is_record:
				game.target_cells.append(surface)
			else:
				game.live_cells.append(surface)
	game.observation_label = N.label(column, "", 13, N.IVORY)
	game.observation_label.name = "ComparePrompt"
	game.observation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.observation_label.add_theme_stylebox_override("normal", N.box(Color(0.01, 0.04, 0.07, 0.86), Color.TRANSPARENT, 4, 2))
	_readable(game.observation_label)
	var top: CenterContainer = CenterContainer.new()
	top.name = "TopLightWrap"
	column.add_child(top)
	top.add_child(_lamp(game, "TOP"))
	var rail_center: CenterContainer = CenterContainer.new()
	rail_center.name = "RailWrap"
	column.add_child(rail_center)
	game.rail = HBoxContainer.new()
	game.rail.add_theme_constant_override("separation", 2)
	rail_center.add_child(game.rail)
	for slot: int in 5:
		var button: Button = N.button("", 34)
		button.custom_minimum_size.x = 44
		button.tooltip_text = ""
		button.mouse_entered.connect(game.preview_pose.bind("sleep"))
		button.mouse_exited.connect(game.clear_context_preview.bind(button))
		button.focus_entered.connect(game.preview_pose.bind("sleep"))
		button.focus_exited.connect(game.clear_context_preview.bind(button))
		button.set_meta("nox_rail_slot", slot)
		button.gui_input.connect(game._start_pointer.bind("shutter", slot))
		game.rail.add_child(button)
		var surface: Control = Surface.new()
		surface.kind = "shutter"
		surface.nox_mode = true
		surface.slot_label = String.chr(65 + slot)
		button.add_child(surface)
		game.rail_buttons.append(button)
	var table: HBoxContainer = HBoxContainer.new()
	table.name = "BoardRow"
	table.alignment = BoxContainer.ALIGNMENT_CENTER
	table.add_theme_constant_override("separation", 8)
	column.add_child(table)
	table.add_child(_lamp(game, "LEFT"))
	var board: GridContainer = GridContainer.new()
	board.name = "WhereWasNox"
	board.columns = 5
	board.add_theme_constant_override("h_separation", 2)
	board.add_theme_constant_override("v_separation", 2)
	table.add_child(board)
	for index: int in 25:
		var button: Button = N.button("", 44)
		button.custom_minimum_size.x = 44
		button.name = "Socket" + String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
		button.tooltip_text = ""
		button.gui_input.connect(game._start_pointer.bind("post", index))
		board.add_child(button)
		var surface: Control = Surface.new()
		surface.nox_mode = true
		surface.slot_label = button.name.trim_prefix("Socket")
		button.add_child(surface)
		button.mouse_entered.connect(_sync_socket_hover.bind(button, surface))
		button.mouse_exited.connect(_sync_socket_hover.bind(button, surface))
		button.focus_entered.connect(_sync_socket_hover.bind(button, surface))
		button.focus_exited.connect(_sync_socket_hover.bind(button, surface))
		game.sockets.append(button)
	table.add_child(_lamp(game, "RIGHT"))
	var bottom: CenterContainer = CenterContainer.new()
	bottom.name = "BottomLightWrap"
	column.add_child(bottom)
	bottom.add_child(_lamp(game, "BOTTOM"))
	var board_caption: Label = N.label(column, L.copy("WHERE WAS NOX?"), 12, N.BRASS)
	board_caption.name = "BoardCaption"
	L.bind_text(board_caption, "WHERE WAS NOX?")
	board_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_readable(board_caption)
	game.pose_description_label = N.label(column, "", 11, N.IVORY)
	game.pose_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.pose_description_label.custom_minimum_size.y = 18
	game.pose_description_label.add_theme_stylebox_override("normal", N.box(Color(0.01, 0.04, 0.07, 0.76), Color.TRANSPARENT, 4, 1))
	_readable(game.pose_description_label)
	var inventory_center: CenterContainer = CenterContainer.new()
	column.add_child(inventory_center)
	var inventory_row: HBoxContainer = HBoxContainer.new()
	inventory_row.name = "PoseInventoryRow"
	inventory_row.add_theme_constant_override("separation", 12)
	inventory_center.add_child(inventory_row)
	game.inventory = _inventory(game, inventory_row, "SIT", "normal", -1)
	game.tall_inventory = _inventory(game, inventory_row, "STAND", "tall", -2)
	game.plate_inventory = _inventory(game, inventory_row, "WALK", "plate_h", -3)
	var log_trigger: Button = N.button("NIGHT LOG  ›", 44)
	log_trigger.name = "NightLogTrigger"
	log_trigger.visible = false
	log_trigger.pressed.connect(func() -> void: _set_mobile_log(game, true))
	column.add_child(log_trigger)
	game.clear_continue = N.button("", 52, true)
	game.clear_continue.name = "ClearContinue"
	game.clear_continue.add_theme_font_size_override("font_size", 18)
	game.clear_continue.pressed.connect(game.next_stage)
	column.add_child(game.clear_continue)
	game.clear_continue.hide()
	var log_panel: PanelContainer = PanelContainer.new()
	log_panel.name = "NightLog"
	log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_panel.add_theme_stylebox_override("panel", N.box(Color(0.05, 0.08, 0.12, 0.80), Color(N.BRASS, 0.15), 3, 1))
	column.add_child(log_panel)
	var log_column: VBoxContainer = VBoxContainer.new()
	log_column.alignment = BoxContainer.ALIGNMENT_CENTER
	log_column.add_theme_constant_override("separation", 4)
	log_panel.add_child(log_column)
	var log_header: HBoxContainer = HBoxContainer.new()
	log_column.add_child(log_header)
	var log_spacer: Control = Control.new()
	log_spacer.custom_minimum_size.x = 30
	log_header.add_child(log_spacer)
	game.nox_chapter_label = N.label(log_header, "", 9, N.BRASS)
	game.nox_chapter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game.nox_chapter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game.nox_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var guide_button: Button = N.button("?", 26)
	guide_button.name = "StageGuideButton"
	guide_button.custom_minimum_size.x = 30
	guide_button.tooltip_text = L.copy("HOW TO PLAY")
	guide_button.pressed.connect(game.show_stage_guide)
	log_header.add_child(guide_button)
	if game.playtest_mode:
		guide_button.hide()
	game.status_label = N.label(log_column, "", 13, N.IVORY)
	game.status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.status_label.custom_minimum_size.y = 30
	_readable(game.status_label)
	var footer_spacer: Control = Control.new()
	footer_spacer.name = "ActionSpacer"
	footer_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	footer_spacer.visible = false
	column.add_child(footer_spacer)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.name = "ActionBar"
	footer.add_theme_constant_override("separation", 6)
	column.add_child(footer)
	game.back_button = N.button(L.copy("BACK"), 44)
	L.bind_text(game.back_button, "BACK")
	game.back_button.pressed.connect(func() -> void: game.load_stage(maxi(0, game.stage_index - 1)))
	footer.add_child(game.back_button)
	var reset: Button = N.button(L.copy("RESET"), 44)
	L.bind_text(reset, "RESET")
	reset.pressed.connect(game.reset_stage)
	footer.add_child(reset)
	game.undo_button = N.button(L.copy("UNDO"), 44)
	L.bind_text(game.undo_button, "UNDO")
	game.undo_button.pressed.connect(game.undo_move)
	footer.add_child(game.undo_button)
	game.hint_button = N.button("解答を見る" if L.is_japanese() else "REVEAL", 44) if game.playtest_mode else N.button(L.copy("OBSERVE"), 44)
	if game.playtest_mode:
		game.hint_button.name = "PlaytestReveal"
		game.hint_button.pressed.connect(game._reveal_playtest_solution)
	else:
		L.bind_text(game.hint_button, "OBSERVE")
		game.hint_button.pressed.connect(func() -> void:
			game.whisper()
			_set_mobile_log(game, true))
	footer.add_child(game.hint_button)
	game.next_button = N.button(L.copy("NEXT  ›"), 44)
	L.bind_text(game.next_button, "NEXT  ›")
	game.next_button.pressed.connect(game.next_stage)
	footer.add_child(game.next_button)
	for button: Node in footer.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var log_overlay: Control = Control.new()
	log_overlay.name = "NightLogOverlay"
	log_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game.add_child(log_overlay)
	log_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var log_scrim: ColorRect = ColorRect.new()
	log_scrim.color = Color(0.02, 0.04, 0.07, 0.72)
	log_overlay.add_child(log_scrim)
	log_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	log_scrim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_set_mobile_log(game, false))
	var sheet: PanelContainer = PanelContainer.new()
	sheet.name = "NightLogSheet"
	sheet.add_theme_stylebox_override("panel", N.box(Color("#203441"), Color(N.BRASS, 0.72), 10, 14))
	log_overlay.add_child(sheet)
	sheet.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	sheet.offset_left = 8
	sheet.offset_right = -8
	sheet.offset_top = -245
	sheet.offset_bottom = -8
	sheet.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var sheet_column: VBoxContainer = VBoxContainer.new()
	sheet_column.add_theme_constant_override("separation", 8)
	sheet.add_child(sheet_column)
	var sheet_header: HBoxContainer = HBoxContainer.new()
	sheet_column.add_child(sheet_header)
	var sheet_title: Label = N.label(sheet_header, "NIGHT LOG", 15, N.IVORY)
	sheet_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sheet_close: Button = N.button(L.copy("CLOSE  ×"), 44)
	sheet_close.name = "NightLogClose"
	L.bind_text(sheet_close, "CLOSE  ×")
	sheet_close.pressed.connect(func() -> void: _set_mobile_log(game, false))
	sheet_header.add_child(sheet_close)
	var log_host: VBoxContainer = VBoxContainer.new()
	log_host.name = "NightLogHost"
	log_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sheet_column.add_child(log_host)
	log_overlay.hide()
	game.drag_ghost = Surface.new()
	game.drag_ghost.kind = "inventory"
	game.drag_ghost.nox_mode = true
	game.drag_ghost.occupied = true
	game.drag_ghost.visible = false
	game.add_child(game.drag_ghost)
	game.drag_ghost.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	game.drag_ghost.size = Vector2(56, 56)
	game.clear_seal = preload("res://src/ui/clear_seal.gd").new()
	game.add_child(game.clear_seal)
	game.stage_guide = preload("res://src/ui/nox_stage_guide.gd").new()
	game.stage_guide.name = "NoxStageGuide"
	game.add_child(game.stage_guide)
	game.stage_guide.closed.connect(func() -> void: Settings.write_value("tutorial_seen", true))
	game.finale_overlay = preload("res://src/ui/nox_finale_overlay.gd").new()
	game.finale_overlay.name = "NoxFinaleOverlay"
	game.add_child(game.finale_overlay)
	game.finale_overlay.home_requested.connect(func() -> void: game.home_requested.emit())
	game.finale_overlay.language_changed.connect(game.sync_stage_language)
	game.sound_player = AudioStreamPlayer.new()
	game.sound_player.volume_db = Settings.volume_offset_db(Settings.se_volume())
	game.add_child(game.sound_player)
	game.resized.connect(_responsive.bind(game, column))
	_responsive(game, column)
	if not Settings.reduced_motion():
		column.modulate.a = 0.0
		game.create_tween().tween_property(column, "modulate:a", 1.0, 0.4)

static func _lamp(game: Control, direction: String) -> Button:
	var button: Button = N.button("", 36)
	button.name = direction + "Light"
	button.custom_minimum_size.x = 38
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.tooltip_text = ""
	button.pressed.connect(game.tap_light.bind(direction))
	button.mouse_entered.connect(game.preview_light.bind(direction))
	button.mouse_exited.connect(game.clear_context_preview.bind(button))
	button.focus_entered.connect(game.preview_light.bind(direction))
	button.focus_exited.connect(game.clear_context_preview.bind(button))
	var surface: Control = Surface.new()
	surface.kind = "lamp"
	surface.nox_mode = true
	surface.light_direction = direction
	button.add_child(surface)
	game.lamps[direction] = button
	return button

static func _inventory(game: Control, row: HBoxContainer, title: String, type: String, index: int) -> Button:
	var button: Button = N.button("", 60)
	button.name = title + "Inventory"
	button.custom_minimum_size.x = 76
	button.set_meta("nox_inventory_title", title)
	button.set_meta("nox_inventory_turn", type.begins_with("plate"))
	button.tooltip_text = ""
	button.mouse_entered.connect(game.preview_pose.bind(type))
	button.mouse_exited.connect(game.clear_context_preview.bind(button))
	button.focus_entered.connect(game.preview_pose.bind(type))
	button.focus_exited.connect(game.clear_context_preview.bind(button))
	button.gui_input.connect(game._start_pointer.bind("post", index))
	row.add_child(button)
	var surface: Control = Surface.new()
	surface.kind = "inventory"
	surface.nox_mode = true
	surface.post_type = type
	surface.tall = type == "tall"
	L.bind_slot(surface, title)
	button.add_child(surface)
	var badge: PanelContainer = PanelContainer.new()
	badge.name = "CountBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override("panel", N.box(Color("#08131d"), Color(N.BRASS, 0.85), 4, 1))
	button.add_child(badge)
	badge.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	badge.offset_left = 2
	badge.offset_right = -2
	badge.offset_top = 2
	badge.offset_bottom = 18
	var count: Label = N.label(badge, "", 11, N.IVORY)
	count.name = "CountText"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return button

static func update_inventory_counts(game: Control) -> void:
	for entry: Array in [[game.inventory, "normal"], [game.tall_inventory, "tall"], [game.plate_inventory, "plate"]]:
		var button: Button = entry[0]
		var category: String = entry[1]
		var badge: PanelContainer = button.find_child("CountBadge", false, false) as PanelContainer
		var remaining: int = maxi(0, mini(game._post_limit(category) - game._post_count(category), int(game.stage()["posts"]) - game.posts.size()))
		var count: Label = badge.find_child("CountText", false, false) as Label
		count.text = ("残り %d" if L.is_japanese() else "LEFT %d") % remaining
		badge.tooltip_text = "%d / %d" % [remaining, game._post_limit(category)]

static func set_clear_state(game: Control, solved: bool) -> void:
	var mobile: bool = is_mobile_viewport(game)
	var short_mobile: bool = is_short_mobile_viewport(game)
	var trigger: Button = game.find_child("NightLogTrigger", true, false) as Button
	trigger.visible = mobile and not solved
	game.clear_continue.visible = mobile and solved and not game.playtest_mode
	game.clear_continue.text = ("✓  記録クリア   ホームへ  ›" if L.is_japanese() else "✓  TRACE COMPLETE   HOME  ›") if game.stage_index == game.stages.size() - 1 else ("✓  記録クリア   次へ  ›" if L.is_japanese() else "✓  TRACE COMPLETE   NEXT  ›")
	game.clear_continue.custom_minimum_size.y = 44 if short_mobile else 52
	game.clear_continue.add_theme_font_size_override("font_size", 16 if short_mobile else 18)
	game.clear_continue.add_theme_stylebox_override("normal", N.box(Color("#d6b77c"), Color("#f6e6bf"), 8, 4))
	game.clear_continue.add_theme_color_override("font_color", N.INK)
	var next: Button = game.next_button
	if solved:
		var gold: StyleBoxFlat = N.box(Color("#d6b77c"), Color("#f6e6bf"), 6, 0)
		next.add_theme_stylebox_override("normal", gold)
		next.add_theme_stylebox_override("hover", N.box(Color("#f1d69d"), Color.WHITE, 6, 0))
		next.add_theme_stylebox_override("pressed", gold)
		next.add_theme_color_override("font_color", N.INK)
		next.add_theme_font_size_override("font_size", 14 if mobile else 16)
	else:
		var quiet: StyleBoxFlat = N.box(Color(0.04, 0.07, 0.10, 0.80), Color(N.BRASS, 0.22), 4, 0)
		next.add_theme_stylebox_override("normal", quiet)
		next.add_theme_stylebox_override("hover", N.box(Color("#26343e"), N.BRASS, 4, 0))
		next.add_theme_stylebox_override("pressed", quiet)
		next.add_theme_color_override("font_color", N.IVORY)
		next.add_theme_font_size_override("font_size", 11 if mobile else 12)

static func _readable(label: Label, outline: int = 2) -> void:
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.04, 0.98))

static func _sync_socket_hover(button: Button, surface: Control) -> void:
	surface.hovered = button.has_focus() or button.get_global_rect().has_point(button.get_global_mouse_position())
	surface.queue_redraw()

static func style_lamp(button: Button, interactive: bool, lit: bool) -> void:
	var border: Color = Color("#73cde2") if lit else Color("#8ab8c6")
	var normal: StyleBoxFlat = N.box(Color("#142a35") if lit else Color("#14212a"), Color(border, 0.95) if interactive else Color(N.SOFT, 0.22), 5, 0)
	normal.set_border_width_all(2 if interactive else 1)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#244653")
	hover.border_color = Color("#b5eff8")
	var pressed: StyleBoxFlat = hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#0f2430")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if interactive else Control.CURSOR_ARROW

static func style_selection(game: Control) -> void:
	for entry: Array in [[game.inventory, "normal"], [game.tall_inventory, "tall"], [game.plate_inventory, "plate"]]:
		var button: Button = entry[0]
		var category: String = entry[1]
		var selected: bool = button.visible and (game.selected_post_type.begins_with("plate_") if category == "plate" else game.selected_post_type == category)
		var normal: StyleBoxFlat = N.box(Color("#17313f") if selected else Color("#101a23"), Color("#7ed6ed") if selected else Color(N.BRASS, 0.35), 5, 1)
		normal.set_border_width_all(3 if selected else 1)
		var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color("#234859")
		hover.border_color = Color("#b6eff7")
		var pressed: StyleBoxFlat = hover.duplicate() as StyleBoxFlat
		pressed.bg_color = Color("#122f40")
		button.add_theme_stylebox_override("normal", normal)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("disabled", normal)

static func _set_mobile_log(game: Control, open: bool) -> void:
	if not is_mobile_viewport(game):
		return
	var overlay: Control = game.find_child("NightLogOverlay", true, false) as Control
	if overlay == null:
		return
	overlay.visible = open
	if open:
		var close_button: Button = game.find_child("NightLogClose", true, false) as Button
		close_button.grab_focus()


static func close_mobile_log(game: Control) -> void:
	_set_mobile_log(game, false)


static func _responsive(game: Control, column: VBoxContainer) -> void:
	if bool(game.get_meta("noxsum_responsive_in_progress", false)):
		return
	game.set_meta("noxsum_responsive_in_progress", true)
	var metrics: Dictionary = _browser_viewport_metrics(game)
	var logical_size: Vector2 = metrics["logical_size"]
	var css_width: float = float(metrics["css_width"])
	var css_height: float = float(metrics["css_height"])
	var browser_size: Vector2 = Vector2(css_width, css_height)
	var width: float = css_width
	game.set_meta("noxsum_browser_layout_size", browser_size)
	game.set_meta("noxsum_browser_logical_size", logical_size)
	if OS.has_feature("web") and css_width > 0.0 and css_height > 0.0:
		if not bool(game.get_meta("noxsum_web_root_normalized", false)):
			game.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			game.position = Vector2.ZERO
			game.pivot_offset = Vector2.ZERO
			game.set_meta("noxsum_web_root_normalized", true)
		game.size = browser_size
		game.scale = Vector2(logical_size.x / css_width, logical_size.y / css_height)
	var mobile: bool = css_width <= 480.0
	var short_mobile: bool = mobile and css_height <= 760.0
	var trace: String = "inner=%.1f visual=%.1f CSS=%.1fx%.1f Godot=%.1fx%.1f rootScale=%.2fx%.2f mobile=%s shortMobile=%s" % [float(metrics["inner_width"]), float(metrics["visual_width"]), css_width, css_height, logical_size.x, logical_size.y, game.scale.x, game.scale.y, str(mobile), str(short_mobile)]
	if str(game.get_meta("noxsum_viewport_trace", "")) != trace:
		print("[NOXSUM viewport] source=min(window.innerWidth, visualViewport.width); " + trace)
		game.set_meta("noxsum_viewport_trace", trace)
	var frame: MarginContainer = game.find_child("StageFrame", true, false) as MarginContainer
	var edge: int = 4 if short_mobile else 8 if mobile else 16
	var content_width: float = maxf(0.0, width - 2.0 * edge - 1.0) if mobile else minf(600.0, width - 32.0)
	frame.custom_minimum_size = Vector2.ZERO
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left = 0.0
	frame.offset_right = 0.0
	frame.offset_top = 0.0
	frame.offset_bottom = 0.0
	for side: String in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, edge)
	var centered_row: HBoxContainer = frame.get_child(0) as HBoxContainer
	centered_row.custom_minimum_size = Vector2.ZERO
	centered_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centered_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.custom_minimum_size = Vector2(content_width, 0.0)
	column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if mobile else Control.SIZE_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0 if short_mobile else 1 if mobile else 2)
	var header_home: Button = game.find_child("HomeButton", true, false) as Button
	var header_language: Button = game.find_child("LanguageButton", true, false) as Button
	var header_row: HBoxContainer = header_home.get_parent() as HBoxContainer
	header_row.custom_minimum_size.x = 0.0
	header_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_theme_constant_override("separation", 4 if mobile else 8)
	header_home.custom_minimum_size.y = 44
	header_language.custom_minimum_size.y = 44
	game.stage_picker.custom_minimum_size.y = 44
	game.title_label.custom_minimum_size.x = 0.0
	game.title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game.title_label.clip_text = mobile
	game.title_label.add_theme_font_size_override("font_size", 18 if short_mobile else 19 if css_width <= 380.0 else 20 if mobile else 25)
	game.count_label.visible = false
	game.observation_label.custom_minimum_size.x = 0.0
	game.observation_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	game.observation_label.add_theme_font_size_override("font_size", 11 if mobile else 13)
	game.observation_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.observation_label.clip_text = false
	game.pose_description_label.custom_minimum_size.x = 0.0
	game.pose_description_label.add_theme_font_size_override("font_size", 10 if short_mobile else 11 if mobile else 12)
	game.pose_description_label.custom_minimum_size.y = 14 if short_mobile else 18
	var screens: HBoxContainer = game.find_child("ShadowPlates", true, false) as HBoxContainer
	var plate_gap: float = 8.0 if mobile else 20.0
	screens.custom_minimum_size = Vector2(content_width, 0.0) if mobile else Vector2.ZERO
	screens.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	screens.add_theme_constant_override("separation", int(plate_gap))
	var plate_width: float = maxf(0.0, (content_width - plate_gap) * 0.5)
	var plate_inset: float = 2.0 if short_mobile else 3.0 if mobile else 8.0
	var grid_gap: float = 2.0
	var plate_inner_width: float = maxf(0.0, plate_width - plate_inset * 2.0)
	# Reserve vertical room for the SLEEP rail and the solved action row.
	# Keep the plate size stable across traces; lamps/rail/buttons retain 44px targets.
	var shadow_cap: float = 20.0 if mobile and css_width <= 380.0 else 26.0 if mobile else 28.0
	if short_mobile:
		shadow_cap = 18.0
	var shadow: float = minf(shadow_cap, floor(maxf(0.0, plate_inner_width - 4.0 * grid_gap) / 5.0))
	for surface: Control in game.target_cells + game.live_cells:
		surface.get_parent().custom_minimum_size = Vector2(shadow, shadow)
	for plate_name: String in ["RecordedPlate", "ReconstructionPlate"]:
		var plate: PanelContainer = game.find_child(plate_name, true, false) as PanelContainer
		var is_record: bool = plate_name == "RecordedPlate"
		plate.custom_minimum_size = Vector2(plate_width, 0.0) if mobile else Vector2.ZERO
		plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL if mobile else Control.SIZE_FILL
		plate.add_theme_stylebox_override("panel", N.box(Color("#213643"), Color(N.BRASS if is_record else N.SOFT, 0.78), 4, 2 if short_mobile else 3 if mobile else 8))
	var board_lamp_size: float = 44.0 if mobile else 38.0
	var board_cell: float = 46.0
	if mobile:
		var board_gap_budget: float = 2.0 * 8.0 + 4.0 * 2.0
		var cell_limit: float = 36.0 if short_mobile else 44.0 if css_width <= 380.0 else 55.0
		board_cell = clampf(floor((content_width - 2.0 * board_lamp_size - board_gap_budget) / 5.0), 28.0, cell_limit)
	var table: HBoxContainer = game.find_child("BoardRow", true, false) as HBoxContainer
	if table != null:
		table.custom_minimum_size.x = 0.0
		table.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		table.add_theme_constant_override("separation", 8)
	var board: GridContainer = game.find_child("WhereWasNox", true, false) as GridContainer
	board.custom_minimum_size.x = 0.0
	board.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var cell: float = board_cell
	for button: Button in game.sockets:
		button.custom_minimum_size = Vector2(cell, cell)
	for button: Button in game.rail_buttons:
		button.custom_minimum_size = Vector2(cell, 44.0 if mobile else 36.0)
	for direction: String in game.lamps:
		var lamp: Button = game.lamps[direction] as Button
		lamp.custom_minimum_size = Vector2(board_lamp_size, 44.0 if mobile else 36.0)
	var board_caption: Label = game.find_child("BoardCaption", true, false) as Label
	var top: Control = game.find_child("TopLightWrap", true, false) as Control
	var bottom: Control = game.find_child("BottomLightWrap", true, false) as Control
	column.move_child(board_caption, top.get_index() if mobile else bottom.get_index() + 1)
	board_caption.visible = not short_mobile and not (css_width <= 380.0 and game.rail.get_parent().visible)
	board_caption.add_theme_font_size_override("font_size", 11 if short_mobile else 12 if mobile else 10)
	var inventory_row: HBoxContainer = game.find_child("PoseInventoryRow", true, false) as HBoxContainer
	inventory_row.add_theme_constant_override("separation", 6 if short_mobile else 8 if mobile else 12)
	for inventory_button: Button in [game.inventory, game.tall_inventory, game.plate_inventory]:
		inventory_button.custom_minimum_size = Vector2(76.0, 48.0 if short_mobile else 60.0)
	var log_panel: PanelContainer = game.find_child("NightLog", true, false) as PanelContainer
	var trigger: Button = game.find_child("NightLogTrigger", true, false) as Button
	var overlay: Control = game.find_child("NightLogOverlay", true, false) as Control
	var host: VBoxContainer = game.find_child("NightLogHost", true, false) as VBoxContainer
	var spacer: Control = game.find_child("ActionSpacer", true, false) as Control
	var footer: HBoxContainer = game.find_child("ActionBar", true, false) as HBoxContainer
	if mobile:
		if log_panel.get_parent() != host:
			log_panel.reparent(host, false)
		log_panel.size_flags_vertical = Control.SIZE_FILL
		trigger.visible = not game.stage_solved
		game.clear_continue.visible = game.stage_solved and not game.playtest_mode
		spacer.show()
		footer.add_theme_constant_override("separation", 0)
		for action: Button in [game.back_button, footer.get_child(1), game.undo_button, game.hint_button, game.next_button]:
			action.custom_minimum_size.y = 44 if short_mobile else 48
			action.add_theme_font_size_override("font_size", 10 if short_mobile else 11)
			for state: String in ["normal", "hover", "pressed", "disabled"]:
				var style: StyleBoxFlat = action.get_theme_stylebox(state).duplicate() as StyleBoxFlat
				style.content_margin_left = 0
				style.content_margin_right = 0
				action.add_theme_stylebox_override(state, style)
	else:
		if log_panel.get_parent() != column:
			log_panel.reparent(column, false)
		column.move_child(log_panel, footer.get_index())
		log_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		trigger.hide()
		game.clear_continue.hide()
		spacer.hide()
		overlay.hide()
		footer.add_theme_constant_override("separation", 6)
	await game.get_tree().process_frame
	_log_shadow_plate_layout(game, css_width, css_height, logical_size)
	game.set_meta("noxsum_responsive_in_progress", false)


static func _log_shadow_plate_layout(game: Control, css_width: float, css_height: float, logical_size: Vector2) -> void:
	var css_scale: Vector2 = Vector2(css_width / maxf(logical_size.x, 1.0), css_height / maxf(logical_size.y, 1.0))
	for plate_name: String in ["RecordedPlate", "ReconstructionPlate"]:
		var plate: Control = game.find_child(plate_name, true, false) as Control
		var grid_name: String = "RecordedShadowGrid" if plate_name == "RecordedPlate" else "ReconstructionShadowGrid"
		var grid: Control = game.find_child(grid_name, true, false) as Control
		if plate == null or grid == null:
			continue
		var outer_raw: Rect2 = plate.get_global_rect()
		var grid_raw: Rect2 = grid.get_global_rect()
		var outer_css: Rect2 = Rect2(outer_raw.position * css_scale, outer_raw.size * css_scale)
		var grid_css: Rect2 = Rect2(grid_raw.position * css_scale, grid_raw.size * css_scale)
		var left_margin: float = grid_css.position.x - outer_css.position.x
		var right_margin: float = outer_css.end.x - grid_css.end.x
		print("[NOXSUM plate-centering] plate=%s outer_css=(%.2f,%.2f %.2fx%.2f) grid_css=(%.2f,%.2f %.2fx%.2f) left_margin=%.2f right_margin=%.2f abs_delta=%.2f" % [plate_name, outer_css.position.x, outer_css.position.y, outer_css.size.x, outer_css.size.y, grid_css.position.x, grid_css.position.y, grid_css.size.x, grid_css.size.y, left_margin, right_margin, absf(left_margin - right_margin)])


static func relocalize(game: Control) -> void:
	L.refresh_bound(game)
	var guide_button: Button = game.find_child("StageGuideButton", true, false) as Button
	if guide_button != null:
		guide_button.tooltip_text = L.copy("HOW TO PLAY")
	var language: Button = game.find_child("LanguageButton", true, false) as Button
	if language != null:
		language.text = L.switch_label()
	var trigger: Button = game.find_child("NightLogTrigger", true, false) as Button
	if trigger != null:
		trigger.text = "夜の記録  ›" if L.is_japanese() else "NIGHT LOG  ›"
	set_clear_state(game, game.stage_solved)
