extends "res://src/hint_main.gd"

const NightTokens = preload("res://src/night_tokens.gd")

# v0.1.7a STATIC SKIN
# Presentation-only layer. Puzzle rules, stage data, input, progress and hints
# remain owned by the layers below this script.

var night_display_font: Font
var night_instrument_font: Font
var night_body_font: Font


func _ready() -> void:
	night_display_font = NightTokens.display_font()
	night_instrument_font = NightTokens.instrument_font()
	night_body_font = NightTokens.body_font()
	super._ready()
	_apply_night_static_skin()
	call_deferred("_apply_night_static_skin")


func _apply_responsive_layout() -> void:
	super._apply_responsive_layout()
	_apply_night_typography()
	_apply_night_footer_skin()


func _shadow_style(value: int, hidden: bool, is_target: bool) -> StyleBoxFlat:
	var background := NightTokens.SHADOW_UNKNOWN
	var border := NightTokens.SHADOW_UNKNOWN_BORDER
	var border_width := 1
	if not hidden:
		match value:
			0:
				background = NightTokens.SHADOW_0
			1:
				background = NightTokens.SHADOW_1
			2:
				background = NightTokens.SHADOW_2
			3:
				background = NightTokens.SHADOW_3
			_:
				background = NightTokens.SHADOW_UNKNOWN
		border = NightTokens.TARGET_FRAME if is_target else NightTokens.LIVE_FRAME
	else:
		border_width = 2
	return _panel_style(background, border, border_width, NightTokens.RADIUS_CELL)


func _apply_post_button_style(button: Button, occupied: bool) -> void:
	button.add_theme_font_override("font", night_instrument_font)
	button.add_theme_color_override("font_disabled_color", NightTokens.TEXT_MUTED.darkened(0.35))
	if occupied:
		button.text = "●"
		button.add_theme_color_override("font_color", NightTokens.POST_TOP)
		button.add_theme_color_override("font_hover_color", NightTokens.TEXT_PRIMARY)
		button.add_theme_font_size_override("font_size", 27)
		button.add_theme_stylebox_override("normal", _surface_style(NightTokens.POST_BODY, NightTokens.POST_RING, 2, NightTokens.RADIUS_SOCKET, 4))
		button.add_theme_stylebox_override("hover", _surface_style(NightTokens.POST_BODY.lightened(0.05), NightTokens.GOLD_SOFT, 2, NightTokens.RADIUS_SOCKET, 6))
		button.add_theme_stylebox_override("pressed", _surface_style(NightTokens.POST_BODY.darkened(0.06), NightTokens.GOLD, 2, NightTokens.RADIUS_SOCKET, 2))
		button.add_theme_stylebox_override("disabled", _surface_style(NightTokens.POST_BODY, NightTokens.POST_RING.darkened(0.20), 1, NightTokens.RADIUS_SOCKET, 2))
	else:
		button.text = "·"
		button.add_theme_color_override("font_color", NightTokens.LINE_BRIGHT)
		button.add_theme_color_override("font_hover_color", NightTokens.CYAN)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_stylebox_override("normal", _surface_style(NightTokens.BG_SOCKET, NightTokens.LINE_SOFT, 1, NightTokens.RADIUS_SOCKET, 1))
		button.add_theme_stylebox_override("hover", _surface_style(NightTokens.BG_SOCKET.lightened(0.035), NightTokens.CYAN_SOFT.darkened(0.18), 1, NightTokens.RADIUS_SOCKET, 3))
		button.add_theme_stylebox_override("pressed", _surface_style(NightTokens.BG_SOCKET.lightened(0.055), NightTokens.CYAN_SOFT, 2, NightTokens.RADIUS_SOCKET, 2))
		button.add_theme_stylebox_override("disabled", _surface_style(NightTokens.BG_SOCKET.darkened(0.08), NightTokens.LINE_SOFT.darkened(0.20), 1, NightTokens.RADIUS_SOCKET, 0))


func _style_footer_button(button: Button, primary: bool) -> void:
	button.custom_minimum_size = Vector2(78, 34) if compact_layout else Vector2(104, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_override("font", night_instrument_font)
	button.add_theme_font_size_override("font_size", 10 if compact_layout else 12)
	var border := NightTokens.GOLD_SOFT if primary else NightTokens.LINE_MEDIUM
	var text_color := NightTokens.GOLD if primary else NightTokens.TEXT_PRIMARY
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", NightTokens.TEXT_PRIMARY if primary else NightTokens.CYAN)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_color_override("font_disabled_color", NightTokens.TEXT_MUTED.darkened(0.30))
	button.add_theme_stylebox_override("normal", _surface_style(NightTokens.BG_BUTTON, border, 1, NightTokens.RADIUS_BUTTON, 2))
	button.add_theme_stylebox_override("hover", _surface_style(NightTokens.BG_BUTTON.lightened(0.035), border.lightened(0.08), 1, NightTokens.RADIUS_BUTTON, 4))
	button.add_theme_stylebox_override("pressed", _surface_style(NightTokens.BG_BUTTON.darkened(0.05), border, 2, NightTokens.RADIUS_BUTTON, 1))
	button.add_theme_stylebox_override("disabled", _surface_style(NightTokens.BG_BUTTON.darkened(0.16), NightTokens.LINE_SOFT.darkened(0.18), 1, NightTokens.RADIUS_BUTTON, 0))


func _apply_night_static_skin() -> void:
	if get_child_count() < 2:
		return
	var backdrop := get_child(0) as ColorRect
	if backdrop != null:
		backdrop.color = NightTokens.BG_BASE

	var margin := get_child(1) as MarginContainer
	if margin == null or margin.get_child_count() == 0:
		return
	var root := margin.get_child(0) as VBoxContainer
	if root == null or root.get_child_count() < 9:
		return

	_apply_night_typography()
	_apply_night_screens(root.get_child(3) as HBoxContainer)
	_apply_night_instrument(root.get_child(5) as VBoxContainer)
	_apply_night_footer_skin()

	for cell_value in clue_cells:
		var cell := cell_value as PanelContainer
		if cell.get_child_count() > 0:
			var label := cell.get_child(0) as Label
			label.add_theme_font_override("font", night_instrument_font)
			label.add_theme_color_override("font_color", NightTokens.TEXT_SECONDARY)
	for cell_value in live_cells:
		var cell := cell_value as PanelContainer
		if cell.get_child_count() > 0:
			var label := cell.get_child(0) as Label
			label.add_theme_font_override("font", night_instrument_font)

	_update_all()


func _apply_night_typography() -> void:
	if get_child_count() < 2:
		return
	var margin := get_child(1) as MarginContainer
	if margin == null or margin.get_child_count() == 0:
		return
	var root := margin.get_child(0) as VBoxContainer
	if root == null or root.get_child_count() < 9:
		return

	var title := root.get_child(0) as Label
	var stage := root.get_child(1) as Label
	var counter := root.get_child(2) as Label
	var status := root.get_child(6) as Label
	var legend := root.get_child(8) as Label

	title.add_theme_font_override("font", night_display_font)
	title.add_theme_color_override("font_color", NightTokens.TEXT_PRIMARY)
	title.add_theme_font_size_override("font_size", NightTokens.TITLE_COMPACT if compact_layout else NightTokens.TITLE_DESKTOP)

	stage.add_theme_font_override("font", night_instrument_font)
	stage.add_theme_color_override("font_color", NightTokens.GOLD_SOFT)
	stage.add_theme_font_size_override("font_size", NightTokens.STAGE_COMPACT if compact_layout else NightTokens.STAGE_DESKTOP)

	counter.add_theme_font_override("font", night_instrument_font)
	counter.add_theme_color_override("font_color", NightTokens.TEXT_MUTED)
	counter.add_theme_font_size_override("font_size", NightTokens.COUNTER_COMPACT if compact_layout else NightTokens.COUNTER_DESKTOP)

	status.add_theme_font_override("font", night_body_font)
	if not stage_solved:
		status.add_theme_color_override("font_color", NightTokens.TEXT_SECONDARY)
	status.add_theme_font_size_override("font_size", NightTokens.STATUS_COMPACT if compact_layout else NightTokens.STATUS_DESKTOP)

	legend.add_theme_font_override("font", night_instrument_font)
	legend.add_theme_color_override("font_color", NightTokens.TEXT_MUTED.darkened(0.12))
	legend.add_theme_font_size_override("font_size", NightTokens.MICRO_COMPACT if compact_layout else NightTokens.MICRO_DESKTOP)


func _apply_night_screens(screens: HBoxContainer) -> void:
	if screens == null:
		return
	for index in screens.get_child_count():
		var column := screens.get_child(index) as VBoxContainer
		if column == null or column.get_child_count() < 2:
			continue
		var label := column.get_child(0) as Label
		label.add_theme_font_override("font", night_instrument_font)
		label.add_theme_color_override("font_color", NightTokens.GOLD_SOFT if index == 0 else NightTokens.CYAN_SOFT)
		var frame := column.get_child(1) as PanelContainer
		var border := NightTokens.TARGET_FRAME if index == 0 else NightTokens.LIVE_FRAME
		frame.add_theme_stylebox_override("panel", _surface_style(NightTokens.BG_PANEL, border, 1, NightTokens.RADIUS_PANEL, 7))


func _apply_night_instrument(instrument: VBoxContainer) -> void:
	if instrument == null or instrument.get_child_count() < 4:
		return
	var north := instrument.get_child(0) as Label
	var arrow := instrument.get_child(1) as Label
	var table_row := instrument.get_child(2) as HBoxContainer
	var caption := instrument.get_child(3) as Label

	for label_value in [north, arrow, caption]:
		var label := label_value as Label
		label.add_theme_font_override("font", night_instrument_font)
		label.add_theme_color_override("font_color", NightTokens.TEXT_MUTED)

	if table_row.get_child_count() >= 3:
		var west := table_row.get_child(0) as Label
		var board_panel := table_row.get_child(1) as PanelContainer
		var east := table_row.get_child(2) as Label
		for emitter_value in [west, east]:
			var emitter := emitter_value as Label
			emitter.add_theme_font_override("font", night_instrument_font)
			emitter.add_theme_color_override("font_color", NightTokens.CYAN_SOFT)
		north.add_theme_color_override("font_color", NightTokens.CYAN_SOFT)
		board_panel.add_theme_stylebox_override("panel", _surface_style(NightTokens.BG_ELEVATED, NightTokens.LINE_SOFT, 1, NightTokens.RADIUS_PANEL, 8))


func _apply_night_footer_skin() -> void:
	if next_button == null or next_button.get_parent() == null:
		return
	var footer := next_button.get_parent() as HBoxContainer
	if footer == null:
		return
	for child in footer.get_children():
		if not (child is Button):
			continue
		var button := child as Button
		if button == next_button:
			_style_footer_button(button, true)
		elif button.name == "HintButton":
			_style_footer_button(button, false)
			button.add_theme_color_override("font_color", NightTokens.CYAN)
			button.add_theme_color_override("font_hover_color", NightTokens.TEXT_PRIMARY)
			button.add_theme_stylebox_override("normal", _surface_style(NightTokens.BG_BUTTON, NightTokens.CYAN_SOFT.darkened(0.22), 1, NightTokens.RADIUS_BUTTON, 2))
			button.add_theme_stylebox_override("hover", _surface_style(NightTokens.BG_BUTTON.lightened(0.035), NightTokens.CYAN_SOFT, 1, NightTokens.RADIUS_BUTTON, 4))
		else:
			_style_footer_button(button, false)


func _surface_style(background: Color, border: Color, border_width: int, radius: int, shadow_size: int) -> StyleBoxFlat:
	var style := _panel_style(background, border, border_width, radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.28)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 2)
	style.content_margin_left = 6.0
	style.content_margin_right = 6.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style
