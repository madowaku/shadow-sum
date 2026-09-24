extends RefCounted

const N = preload("res://src/ui/nox_theme.gd")
const Surface = preload("res://src/ui/experiment_surface.gd")
const Story = preload("res://src/nox_story.gd")
const Settings = preload("res://src/nox_settings.gd")
const L = preload("res://src/nox_locale.gd")

static func build(game: Control) -> void:
	Settings.apply_audio()
	N.ensure_japanese_font()
	var background: ColorRect = ColorRect.new()
	background.color = N.INK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var image: TextureRect = TextureRect.new()
	image.texture = preload("res://assets/nox/v0.4/archive_window.png")
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.modulate = Color(0.40, 0.48, 0.62, 0.15)
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game.add_child(image)
	image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.theme = Theme.new()
	game.theme.default_font = N.BODY
	game.theme.default_font_size = 12
	var frame: MarginContainer = N.margin(game, 16)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var horizontal: HBoxContainer = HBoxContainer.new()
	horizontal.alignment = BoxContainer.ALIGNMENT_CENTER
	frame.add_child(horizontal)
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "ReconstructionLayout"
	column.add_theme_constant_override("separation", 1)
	horizontal.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	column.add_child(header)
	var home: Button = N.button(L.copy("‹  HOME"), 40)
	L.bind_text(home, "‹  HOME")
	home.name = "HomeButton"
	home.pressed.connect(func() -> void: game.home_requested.emit())
	header.add_child(home)
	var language: Button = N.button(L.switch_label(), 40)
	language.name = "LanguageButton"
	language.pressed.connect(game.toggle_language)
	header.add_child(language)
	var logo: Control = preload("res://src/ui/nox_wordmark.gd").new()
	logo.custom_minimum_size = Vector2(130, 40)
	logo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(logo)
	game.stage_picker = OptionButton.new()
	game.stage_picker.name = "TracePicker"
	game.stage_picker.custom_minimum_size = Vector2(88, 40)
	game.stage_picker.add_theme_font_size_override("font_size", 11)
	game.stage_picker.add_theme_stylebox_override("normal", N.box(Color(0.04, 0.08, 0.12, 0.8), Color(N.BRASS, 0.3)))
	for index: int in game.stages.size():
		game.stage_picker.add_item("%02d / 36" % (index + 1))
	game.stage_picker.item_selected.connect(game.load_stage)
	game.stage_picker.get_popup().max_size = Vector2i(0, 520)
	header.add_child(game.stage_picker)
	game.title_label = N.label(column, "", 25, N.IVORY, true)
	game.title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.count_label = N.label(column, "", 13, N.IVORY)
	game.count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var screens: HBoxContainer = HBoxContainer.new()
	screens.alignment = BoxContainer.ALIGNMENT_CENTER
	screens.add_theme_constant_override("separation", 20)
	column.add_child(screens)
	for is_record: bool in [true, false]:
		var plate: PanelContainer = PanelContainer.new()
		plate.add_theme_stylebox_override("panel", N.box(Color("#15222d"), Color(N.BRASS if is_record else N.SOFT, 0.5), 3, 8))
		screens.add_child(plate)
		var stack: VBoxContainer = VBoxContainer.new()
		stack.add_theme_constant_override("separation", 6)
		plate.add_child(stack)
		var caption_key: String = "RECORDED SHADOW" if is_record else "RECONSTRUCTION"
		var caption: Label = N.label(stack, L.copy(caption_key), 11, N.BRASS if is_record else N.SOFT)
		L.bind_text(caption, caption_key)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var grid: GridContainer = GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
		stack.add_child(grid)
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
	game.observation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var top: CenterContainer = CenterContainer.new()
	column.add_child(top)
	top.add_child(_lamp(game, "TOP"))
	var rail_center: CenterContainer = CenterContainer.new()
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
	column.add_child(bottom)
	bottom.add_child(_lamp(game, "BOTTOM"))
	var board_caption: Label = N.label(column, L.copy("WHERE WAS NOX?"), 10, N.BRASS)
	L.bind_text(board_caption, "WHERE WAS NOX?")
	board_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.pose_description_label = N.label(column, "", 11, N.SOFT)
	game.pose_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.pose_description_label.custom_minimum_size.y = 15
	var inventory_center: CenterContainer = CenterContainer.new()
	column.add_child(inventory_center)
	var inventory_row: HBoxContainer = HBoxContainer.new()
	inventory_row.add_theme_constant_override("separation", 12)
	inventory_center.add_child(inventory_row)
	game.inventory = _inventory(game, inventory_row, "SIT", "normal", -1)
	game.tall_inventory = _inventory(game, inventory_row, "STAND", "tall", -2)
	game.plate_inventory = _inventory(game, inventory_row, "WALK", "plate_h", -3)
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
	game.status_label = N.label(log_column, "", 13, N.IVORY)
	game.status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game.status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game.status_label.custom_minimum_size.y = 30
	var footer: HBoxContainer = HBoxContainer.new()
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
	game.hint_button = N.button(L.copy("OBSERVE"), 44)
	L.bind_text(game.hint_button, "OBSERVE")
	game.hint_button.pressed.connect(game.whisper)
	footer.add_child(game.hint_button)
	game.next_button = N.button(L.copy("NEXT  ›"), 44)
	L.bind_text(game.next_button, "NEXT  ›")
	game.next_button.pressed.connect(game.next_stage)
	footer.add_child(game.next_button)
	for button: Node in footer.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	game.add_child(game.sound_player)
	game.resized.connect(_responsive.bind(game, column))
	_responsive(game, column)
	if not Settings.reduced_motion():
		column.modulate.a = 0.0
		game.create_tween().tween_property(column, "modulate:a", 1.0, 0.4)

static func _lamp(game: Control, direction: String) -> Button:
	var button: Button = N.button("", 36)
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
	return button

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

static func _responsive(game: Control, column: VBoxContainer) -> void:
	var width: float = game.get_viewport_rect().size.x
	var wide: bool = width >= 540
	column.custom_minimum_size.x = minf(600, width - 32)
	var cell: float = 46.0 if wide else 44.0
	var shadow: float = 28.0 if wide else 26.0
	for button: Button in game.sockets:
		button.custom_minimum_size = Vector2(cell, cell)
	for button: Button in game.rail_buttons:
		button.custom_minimum_size.x = cell
	for surface: Control in game.target_cells + game.live_cells:
		surface.get_parent().custom_minimum_size = Vector2(shadow, shadow)


static func relocalize(game: Control) -> void:
	L.refresh_bound(game)
	var guide_button: Button = game.find_child("StageGuideButton", true, false) as Button
	if guide_button != null:
		guide_button.tooltip_text = L.copy("HOW TO PLAY")
	var language: Button = game.find_child("LanguageButton", true, false) as Button
	if language != null:
		language.text = L.switch_label()
