extends "res://src/night_skin_main.gd"

const PostVisual = preload("res://src/ui/post_visual.gd")
const SocketVisual = preload("res://src/ui/socket_visual.gd")
const ShadowGlassVisual = preload("res://src/ui/shadow_glass_visual.gd")

# SHADOW SUM v0.1.7b GLASS & METAL
# Material-only layer. Buttons remain the authoritative hit targets; these
# child Controls are mouse-transparent visual surfaces.

var socket_visuals: Array = []
var post_visuals: Array = []
var clue_glass_visuals: Array = []
var live_glass_visuals: Array = []

func _ready() -> void:
	super._ready()
	_apply_glass_metal_skin()
	call_deferred("_apply_glass_metal_skin")

func _apply_post_button_style(button: Button, occupied: bool) -> void:
	# Keep all behavior from the established layer, then hand visual ownership
	# from text/styleboxes to dedicated material Controls.
	super._apply_post_button_style(button, occupied)
	button.text = ""
	button.add_theme_stylebox_override("normal", _transparent_button_style())
	button.add_theme_stylebox_override("hover", _transparent_button_style())
	button.add_theme_stylebox_override("pressed", _transparent_button_style())
	button.add_theme_stylebox_override("disabled", _transparent_button_style())

	var index := post_buttons.find(button)
	if index < 0:
		return
	_ensure_material_slot(button, index)
	var socket := socket_visuals[index] as Control
	var post := post_visuals[index] as Control
	socket.set_state(occupied, bool(socket.get_meta("active", false)))
	post.set_state(occupied, false, occupied)

func _update_clue_cell(cell: PanelContainer, clue: int) -> void:
	super._update_clue_cell(cell, clue)
	var index := clue_cells.find(cell)
	if index < 0:
		return
	var glass := _ensure_glass_visual(cell, true, index)
	glass.set_state(maxi(0, clue), clue < 0, true, index)
	if cell.get_child_count() > 0:
		var label := cell.get_child(0) as Label
		# Keep ? during v0.1.7b. The first-time onboarding pass owns the later
		# transition from symbol to purely frosted unknown glass.
		if clue < 0:
			label.add_theme_color_override("font_color", NightTokens.TEXT_SECONDARY.lightened(0.08))

func _update_live_cell(cell: PanelContainer, value: int) -> void:
	super._update_live_cell(cell, value)
	var index := live_cells.find(cell)
	if index < 0:
		return
	var glass := _ensure_glass_visual(cell, false, index)
	glass.set_state(value, false, false, index + 37)

func _build_drag_ghost() -> void:
	super._build_drag_ghost()
	if drag_ghost == null:
		return
	drag_ghost.add_theme_stylebox_override("panel", _transparent_panel_style())
	for child in drag_ghost.get_children():
		if child is Label:
			(child as Label).visible = false
	var visual := PostVisual.new()
	visual.name = "GhostPostVisual"
	visual.set_state(true, true, false)
	drag_ghost.add_child(visual)

func _apply_drag_socket_readability(target: int) -> void:
	super._apply_drag_socket_readability(target)
	_clear_socket_active_states()
	if target >= 0 and target < socket_visuals.size():
		_set_socket_active(target, true)

func _reset_drag_button_visuals() -> void:
	super._reset_drag_button_visuals()
	_clear_socket_active_states()

func _hide_drag_ghost() -> void:
	super._hide_drag_ghost()
	_clear_socket_active_states()

func _apply_glass_metal_skin() -> void:
	for index in post_buttons.size():
		var button := post_buttons[index] as Button
		_ensure_material_slot(button, index)
		var occupied := _post_is_occupied(index)
		(button.get_node("SocketVisual") as Control).set_state(occupied, false)
		(button.get_node("PostVisual") as Control).set_state(occupied, false, occupied)

	for index in clue_cells.size():
		var clue := int(stages[stage_index]["clues"][index / ShadowRules.BOARD_SIZE][index % ShadowRules.BOARD_SIZE]) if not stages.is_empty() else 0
		var glass := _ensure_glass_visual(clue_cells[index] as PanelContainer, true, index)
		glass.set_state(maxi(0, clue), clue < 0, true, index)
	for index in live_cells.size():
		var glass := _ensure_glass_visual(live_cells[index] as PanelContainer, false, index)
		var r := index / ShadowRules.BOARD_SIZE
		var c := index % ShadowRules.BOARD_SIZE
		var shadow := ShadowRules.compute_shadow(posts)
		glass.set_state(int(shadow[r][c]), false, false, index + 37)

	_apply_instrument_depth()

func _ensure_material_slot(button: Button, index: int) -> void:
	while socket_visuals.size() <= index:
		socket_visuals.append(null)
	while post_visuals.size() <= index:
		post_visuals.append(null)

	var socket := button.get_node_or_null("SocketVisual")
	if socket == null:
		socket = SocketVisual.new()
		socket.name = "SocketVisual"
		button.add_child(socket)
	var post := button.get_node_or_null("PostVisual")
	if post == null:
		post = PostVisual.new()
		post.name = "PostVisual"
		button.add_child(post)

	socket_visuals[index] = socket
	post_visuals[index] = post

	if not button.has_meta("glass_metal_hover_bound"):
		button.set_meta("glass_metal_hover_bound", true)
		button.mouse_entered.connect(_on_socket_hover.bind(index, true))
		button.mouse_exited.connect(_on_socket_hover.bind(index, false))

func _ensure_glass_visual(cell: PanelContainer, target_surface: bool, index: int) -> Control:
	var node_name := "TargetGlassVisual" if target_surface else "LiveGlassVisual"
	var visual := cell.get_node_or_null(node_name)
	if visual == null:
		visual = ShadowGlassVisual.new()
		visual.name = node_name
		cell.add_child(visual)
		# Keep the ? label readable above the material overlay for this pass.
		cell.move_child(visual, 0)

	var store := clue_glass_visuals if target_surface else live_glass_visuals
	while store.size() <= index:
		store.append(null)
	store[index] = visual
	return visual

func _on_socket_hover(index: int, hovering: bool) -> void:
	if drag_active:
		return
	_set_socket_active(index, hovering)

func _set_socket_active(index: int, active: bool) -> void:
	if index < 0 or index >= socket_visuals.size():
		return
	var socket = socket_visuals[index]
	if socket == null:
		return
	socket.set_meta("active", active)
	socket.set_state(_post_is_occupied(index), active)

func _clear_socket_active_states() -> void:
	for index in socket_visuals.size():
		if socket_visuals[index] != null:
			_set_socket_active(index, false)

func _apply_instrument_depth() -> void:
	if get_child_count() < 2:
		return
	var backdrop := get_child(0) as ColorRect
	if backdrop != null:
		backdrop.color = Color("#080A0C")

	var margin := get_child(1) as MarginContainer
	if margin == null or margin.get_child_count() == 0:
		return
	var root := margin.get_child(0) as VBoxContainer
	if root == null or root.get_child_count() < 6:
		return

	var screens := root.get_child(3) as HBoxContainer
	if screens != null:
		for i in screens.get_child_count():
			var column := screens.get_child(i) as VBoxContainer
			if column != null and column.get_child_count() >= 2:
				var frame := column.get_child(1) as PanelContainer
				var border := NightTokens.TARGET_FRAME if i == 0 else NightTokens.LIVE_FRAME
				frame.add_theme_stylebox_override("panel", _material_panel_style(NightTokens.BG_PANEL, border, 10))

	var instrument := root.get_child(5) as VBoxContainer
	if instrument != null and instrument.get_child_count() >= 3:
		var table_row := instrument.get_child(2) as HBoxContainer
		if table_row != null and table_row.get_child_count() >= 3:
			var board_panel := table_row.get_child(1) as PanelContainer
			board_panel.add_theme_stylebox_override("panel", _material_panel_style(NightTokens.BG_ELEVATED, NightTokens.LINE_MEDIUM, 11))

func _material_panel_style(background: Color, border: Color, shadow_size: int) -> StyleBoxFlat:
	var style := _surface_style(background, border, 1, NightTokens.RADIUS_PANEL, shadow_size)
	style.shadow_color = NightTokens.PANEL_SHADOW
	style.shadow_offset = Vector2(0.0, 3.0)
	return style

func _transparent_button_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	return style

func _transparent_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.0)
	style.border_color = Color(0.0, 0.0, 0.0, 0.0)
	return style
