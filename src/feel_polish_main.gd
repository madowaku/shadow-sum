extends "res://src/feel_main.gd"

# SHADOW SUM v0.1.2b Feel Tuning + 360x800 Polish
#
# This layer keeps the puzzle rules frozen and focuses on two things:
# 1. shadow cells should feel as though ink/light is settling rather than snapping,
# 2. the full instrument should remain comfortably usable at 360x800.

const COMPACT_BREAKPOINT_W := 560.0
const COMPACT_SCREEN_CELL := 32.0
const COMPACT_POST_CELL := 48.0
const LIQUID_SETTLE_TIME := 0.18

var compact_layout := false


func _ready() -> void:
	super._ready()
	_apply_responsive_layout()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _load_stage(index: int) -> void:
	# A new stage should appear cleanly instead of morphing from the previous answer.
	for cell_value in live_cells:
		var cell := cell_value as PanelContainer
		cell.set_meta("shadow_level", -1)
	super._load_stage(index)


func _update_live_cell(cell: PanelContainer, value: int) -> void:
	var label := cell.get_child(0) as Label
	label.text = ""

	var previous := int(cell.get_meta("shadow_level", -1))
	if previous < 0:
		cell.add_theme_stylebox_override("panel", _shadow_style(value, false, false))
		cell.set_meta("shadow_level", value)
		return

	if previous == value:
		return

	# Tween the StyleBox itself. This makes the shadow density seep into the cell
	# instead of swapping the entire tile colour in one frame.
	var style := _shadow_style(previous, false, false)
	var target := _shadow_style(value, false, false)
	cell.add_theme_stylebox_override("panel", style)
	cell.set_meta("shadow_level", value)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(style, "bg_color", target.bg_color, LIQUID_SETTLE_TIME)
	tween.parallel().tween_property(style, "border_color", target.border_color, LIQUID_SETTLE_TIME)

	# A tiny breathing motion is enough to make density changes feel organic.
	cell.pivot_offset = cell.size * 0.5
	if value > previous:
		cell.scale = Vector2(0.985, 0.985)
	else:
		cell.scale = Vector2(1.015, 1.015)
	var settle := create_tween()
	settle.tween_property(cell, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_viewport_size_changed() -> void:
	call_deferred("_apply_responsive_layout")


func _apply_responsive_layout() -> void:
	if get_child_count() < 2:
		return

	# With canvas_items + expand, the visible rect is the correct logical canvas
	# to design against. A 360x800 window maps to 405x900 logical units.
	var viewport_size := get_viewport().get_visible_rect().size
	var should_compact := viewport_size.x <= COMPACT_BREAKPOINT_W
	compact_layout = should_compact

	var margin := get_child(1) as MarginContainer
	if margin == null or margin.get_child_count() == 0:
		return
	var root_box := margin.get_child(0) as VBoxContainer
	if root_box == null or root_box.get_child_count() < 9:
		return

	if should_compact:
		_set_margins(margin, 10, 10, 9, 8)
		root_box.add_theme_constant_override("separation", 6)
	else:
		_set_margins(margin, 28, 28, 20, 18)
		root_box.add_theme_constant_override("separation", 10)

	var title := root_box.get_child(0) as Label
	var stage := root_box.get_child(1) as Label
	var counter := root_box.get_child(2) as Label
	var screens := root_box.get_child(3) as HBoxContainer
	var instrument := root_box.get_child(5) as VBoxContainer
	var status := root_box.get_child(6) as Label
	var footer := root_box.get_child(7) as HBoxContainer
	var legend := root_box.get_child(8) as Label

	if should_compact:
		title.add_theme_font_size_override("font_size", 22)
		stage.add_theme_font_size_override("font_size", 13)
		counter.add_theme_font_size_override("font_size", 11)
		status.add_theme_font_size_override("font_size", 12)
		status.custom_minimum_size.y = 24
		legend.add_theme_font_size_override("font_size", 9)
		legend.text = "LIGHT   →   SHADOW   →   DEEPER   →   FULL"
	else:
		title.add_theme_font_size_override("font_size", 29)
		stage.add_theme_font_size_override("font_size", 16)
		counter.add_theme_font_size_override("font_size", 13)
		status.add_theme_font_size_override("font_size", 15)
		status.custom_minimum_size.y = 28
		legend.add_theme_font_size_override("font_size", 11)
		legend.text = "bright  →  light shadow  →  double  →  full shadow"

	_apply_screen_layout(screens, should_compact)
	_apply_instrument_layout(instrument, should_compact)

	footer.add_theme_constant_override("separation", 8 if should_compact else 12)
	for child in footer.get_children():
		if child is Button:
			var button := child as Button
			button.custom_minimum_size = Vector2(104, 34) if should_compact else Vector2(118, 38)

	# Let container layout settle before recentering pivots used by feel tweens.
	call_deferred("_refresh_animation_pivots")


func _apply_screen_layout(screens: HBoxContainer, compact: bool) -> void:
	screens.add_theme_constant_override("separation", 8 if compact else 24)
	var size_value := COMPACT_SCREEN_CELL if compact else CELL_SIZE
	var cell_font := 14 if compact else 19

	for cell_value in clue_cells:
		var cell := cell_value as PanelContainer
		cell.custom_minimum_size = Vector2(size_value, size_value)
		var label := cell.get_child(0) as Label
		label.add_theme_font_size_override("font_size", cell_font)
	for cell_value in live_cells:
		var cell := cell_value as PanelContainer
		cell.custom_minimum_size = Vector2(size_value, size_value)
		var label := cell.get_child(0) as Label
		label.add_theme_font_size_override("font_size", cell_font)

	for index in screens.get_child_count():
		var column := screens.get_child(index) as VBoxContainer
		if column == null or column.get_child_count() < 2:
			continue
		column.add_theme_constant_override("separation", 3 if compact else 5)
		var screen_title := column.get_child(0) as Label
		screen_title.add_theme_font_size_override("font_size", 10 if compact else 12)
		if compact:
			screen_title.text = "TARGET" if index == 0 else "LIVE"
		else:
			screen_title.text = "TARGET" if index == 0 else "LIVE SHADOW"

		var frame := column.get_child(1) as PanelContainer
		if frame == null or frame.get_child_count() == 0:
			continue
		var frame_margin := frame.get_child(0) as MarginContainer
		_set_margins(frame_margin, 4 if compact else 8, 4 if compact else 8, 4 if compact else 8, 4 if compact else 8)
		if frame_margin.get_child_count() > 0:
			var grid := frame_margin.get_child(0) as GridContainer
			grid.add_theme_constant_override("h_separation", 2 if compact else 3)
			grid.add_theme_constant_override("v_separation", 2 if compact else 3)


func _apply_instrument_layout(instrument: VBoxContainer, compact: bool) -> void:
	instrument.add_theme_constant_override("separation", 3 if compact else 5)
	if instrument.get_child_count() < 4:
		return

	var north := instrument.get_child(0) as Label
	var arrow := instrument.get_child(1) as Label
	var table_row := instrument.get_child(2) as HBoxContainer
	var caption := instrument.get_child(3) as Label

	north.custom_minimum_size = Vector2(50, 28) if compact else Vector2(64, 42)
	north.add_theme_font_size_override("font_size", 10 if compact else 12)
	arrow.add_theme_font_size_override("font_size", 14 if compact else 18)
	caption.add_theme_font_size_override("font_size", 9 if compact else 11)
	table_row.add_theme_constant_override("separation", 4 if compact else 12)

	if table_row.get_child_count() >= 3:
		var west := table_row.get_child(0) as Label
		var board_panel := table_row.get_child(1) as PanelContainer
		var east := table_row.get_child(2) as Label
		for emitter in [west, east]:
			emitter.custom_minimum_size = Vector2(34, 34) if compact else Vector2(64, 42)
			emitter.add_theme_font_size_override("font_size", 9 if compact else 12)

		if board_panel.get_child_count() > 0:
			var board_margin := board_panel.get_child(0) as MarginContainer
			_set_margins(board_margin, 5 if compact else 10, 5 if compact else 10, 5 if compact else 10, 5 if compact else 10)
			if board_margin.get_child_count() > 0:
				var grid := board_margin.get_child(0) as GridContainer
				grid.add_theme_constant_override("h_separation", 3 if compact else 4)
				grid.add_theme_constant_override("v_separation", 3 if compact else 4)

	var post_size := COMPACT_POST_CELL if compact else POST_CELL_SIZE
	for button_value in post_buttons:
		var button := button_value as Button
		button.custom_minimum_size = Vector2(post_size, post_size)


func _refresh_animation_pivots() -> void:
	for cell_value in live_cells:
		var cell := cell_value as PanelContainer
		cell.pivot_offset = cell.size * 0.5
	for button_value in post_buttons:
		var button := button_value as Button
		button.pivot_offset = button.size * 0.5


func _set_margins(container: MarginContainer, left: int, right: int, top: int, bottom: int) -> void:
	container.add_theme_constant_override("margin_left", left)
	container.add_theme_constant_override("margin_right", right)
	container.add_theme_constant_override("margin_top", top)
	container.add_theme_constant_override("margin_bottom", bottom)
