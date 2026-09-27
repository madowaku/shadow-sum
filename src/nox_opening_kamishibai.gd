extends Control
## Presentation only: no campaign, inventory, progress or hint state is owned here.
signal finished

const N = preload("res://src/ui/nox_theme.gd")
const L = preload("res://src/nox_locale.gd")
const Settings = preload("res://src/nox_settings.gd")
const Surface = preload("res://src/ui/experiment_surface.gd")
const Optics = preload("res://src/experiment_optics.gd")
const Seal = preload("res://src/ui/clear_seal.gd")
const BEATS: Array[Dictionary] = [
	{"id": "archive", "duration": 3.0},
	{"id": "nox", "duration": 3.0},
	{"id": "record", "duration": 3.5},
	{"id": "reconstruct", "duration": 4.0},
	{"id": "match", "duration": 3.0},
	{"id": "enter", "duration": 3.0},
]
const POSES: Array[String] = ["normal", "tall", "plate_h"]
const POSITIONS: Array[int] = [6, 12, 11]
const LIGHTS: Array[String] = ["TOP", "LEFT", "RIGHT"]

var replay: bool = false
var beat_index: int = 0
var elapsed: float = 0.0
var stopped: bool = false
var reduced: bool = false
var last_input_ms: int = -1000
var phase: int = -1
var previous_layer: Control
var layer: Control
var art: TextureRect
var title: Label
var body: Label
var dots: Label
var skip_button: Button
var transition: Tween
var seal: Control
var plates: Array[Control] = []
var portraits: Array[Control] = []
var board: Control
var lamp: Control
var caption: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_sync_viewport()
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	N.ensure_japanese_font()
	Settings.apply_audio()
	reduced = Settings.reduced_motion()
	var background: ColorRect = ColorRect.new()
	background.color = N.INK
	add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer = Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var frame: MarginContainer = N.margin(self, 24)
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column: VBoxContainer = VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(column)
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(header)
	var tag: Label = N.label(header, L.opening("replay"), 12, N.BRASS)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skip_button = N.button(L.opening("skip"), 48)
	skip_button.name = "SkipOpening"
	# Keyboard progression belongs to the Opening; Skip is a pointer-only action.
	skip_button.focus_mode = Control.FOCUS_NONE
	skip_button.pressed.connect(finish)
	header.add_child(skip_button)
	var space: Control = Control.new()
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(space)
	caption = VBoxContainer.new()
	caption.name = "OpeningCaption"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.custom_minimum_size.y = 166
	caption.add_theme_constant_override("separation", 14)
	column.add_child(caption)
	title = N.label(caption, "", 23, N.IVORY, true)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body = N.label(caption, "", 14, N.SOFT)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dots = N.label(column, "", 12, N.BRASS)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint: Label = N.label(column, L.opening("next"), 11, N.SOFT)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_text(self)
	resized.connect(_resize)
	_enter_beat()

func _process(delta: float) -> void:
	if stopped:
		return
	_sync_viewport()
	elapsed += delta
	_animate()
	if elapsed >= float(BEATS[beat_index].duration):
		next_beat()

func _gui_input(event: InputEvent) -> void:
	if stopped:
		return
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		finish()
		return
	var advance: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not event.double_click
	advance = advance or (event is InputEventScreenTouch and event.pressed and not event.double_tap)
	advance = advance or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER])
	if advance:
		accept_event()
		var now: int = Time.get_ticks_msec()
		if now - last_input_ms >= 350:
			last_input_ms = now
			next_beat()

func next_beat() -> void:
	if stopped:
		return
	if beat_index == BEATS.size() - 1:
		finish()
		return
	_exit_beat()
	beat_index += 1
	elapsed = 0.0
	_enter_beat()

func finish() -> void:
	if stopped:
		return
	stopped = true
	_exit_beat()
	if not replay:
		Settings.write_value("opening_seen", true)
	finished.emit()

func _exit_tree() -> void:
	stopped = true
	_exit_beat()

func _exit_beat() -> void:
	if transition != null and transition.is_valid():
		transition.kill()
	transition = null
	if is_instance_valid(previous_layer):
		previous_layer.queue_free()
		previous_layer = null
	if is_instance_valid(seal):
		seal.reset()

func _resize() -> void:
	if not is_instance_valid(layer) or stopped:
		return
	_exit_beat()
	_build_art()
	layer.modulate.a = 1.0
	_animate()

func _enter_beat() -> void:
	var key: String = str(BEATS[beat_index].id)
	title.text = L.opening(key + ".title")
	body.text = L.opening(key + ".body")
	body.visible = not body.text.is_empty()
	var marks: PackedStringArray = []
	for index: int in BEATS.size():
		marks.append("●" if index == beat_index else "○")
	dots.text = "   ".join(marks)
	# Retain the settled frame beneath the incoming frame: no blank-frame flash.
	var outgoing_layer: Control = layer
	previous_layer = outgoing_layer
	layer = Control.new()
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer)
	move_child(layer, previous_layer.get_index() + 1)
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_art()
	layer.modulate.a = 0.0
	transition = create_tween()
	transition.tween_property(layer, "modulate:a", 1.0, 0.12 if reduced else 0.28)
	transition.parallel().tween_property(outgoing_layer, "modulate:a", 0.0, 0.12 if reduced else 0.28)
	transition.tween_callback(func() -> void:
		if is_instance_valid(outgoing_layer):
			outgoing_layer.queue_free()
		if previous_layer == outgoing_layer:
			previous_layer = null)
	_animate()

func _build_art() -> void:
	for child: Node in layer.get_children():
		layer.remove_child(child)
		child.queue_free()
	plates.clear()
	portraits.clear()
	art = null
	board = null
	lamp = null
	seal = null
	phase = -1
	if beat_index != 0:
		var room: TextureRect = TextureRect.new()
		room.texture = preload("res://assets/nox/v0.6/archive_puzzle_window.png")
		room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		room.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		room.modulate = Color(0.35, 0.45, 0.55, 0.12)
		_place(room, Rect2(Vector2.ZERO, size))
	var width: float = size.x - 48.0
	var area: Rect2 = Rect2(24, 100, width, maxf(280, size.y - 350))
	title.add_theme_font_size_override("font_size", 22 if size.x < 500 else 28)
	if beat_index == 0:
		art = TextureRect.new()
		art.texture = preload("res://assets/nox/v0.6/archive_puzzle_window.png")
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_place(art, Rect2(Vector2.ZERO, size))
		var shade: ColorRect = ColorRect.new()
		shade.color = Color(0.02, 0.04, 0.07, 0.92)
		_place(shade, Rect2(0, size.y - 244, size.x, 244))
	elif beat_index == 1:
		var cat_size: float = minf(220, area.size.y * 0.42)
		for pose: String in POSES:
			portraits.append(_portrait(pose, Rect2(Vector2(size.x * 0.5 - cat_size * 0.5, area.position.y + 24), Vector2.ONE * cat_size)))
		lamp = Surface.new()
		lamp.kind = "lamp"
		lamp.fixed = true
		lamp.active = true
		_place(lamp, Rect2(size.x * 0.5 - 20, area.position.y - 16, 40, 40))
		var side: float = minf(width * 0.65, area.size.y * 0.43)
		plates.append(_plate(Rect2(size.x * 0.5 - side * 0.5, area.end.y - side, side, side), L.copy("RECORDED SHADOW")))
	elif beat_index == 2:
		var mini_side: float = minf((width - 24) / 3.0, 130)
		for index: int in 3:
			var x: float = size.x * 0.5 + (index - 1) * (mini_side + 10) - mini_side * 0.5
			portraits.append(_portrait(POSES[index], Rect2(x, area.position.y, mini_side, mini_side)))
			var plate: Control = _plate(Rect2(x, area.position.y + mini_side + 16, mini_side, mini_side), "")
			plate.set_meta("origin", plate.position)
			plates.append(plate)
			_set_plate(plate, _shadow(index + 1, index))
		var side: float = minf(width * 0.64, area.size.y * 0.43)
		plates.append(_plate(Rect2(size.x * 0.5 - side * 0.5, area.end.y - side, side, side), L.copy("RECORDED SHADOW")))
	elif beat_index in [3, 4]:
		var side: float = minf((width - 20) * 0.5, 228)
		for index: int in 2:
			plates.append(_plate(Rect2(size.x * 0.5 + (index - 1) * (side + 10) + 5, area.position.y + 24, side, side), L.copy("RECORDED SHADOW" if index == 0 else "RECONSTRUCTION")))
		_set_plate(plates[0], _shadow(3))
		var board_side: float = minf(width * 0.7, area.size.y - side - 110)
		board = Control.new()
		_place(board, Rect2(size.x * 0.5 - board_side * 0.5, area.position.y + side + 76, board_side, board_side))
		var board_label: Label = N.label(layer, L.copy("WHERE WAS NOX?"), 11, N.BRASS)
		board_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		board_label.position = Vector2(24, board.position.y - 23)
		board_label.size.x = width
		for index: int in 25:
			var cell: Control = Surface.new()
			cell.nox_mode = true
			board.add_child(cell)
			cell.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
			cell.position = Vector2(index % 5, int(index / 5.0)) * board_side / 5
			cell.size = Vector2.ONE * board_side / 5
		for index: int in 3:
			portraits.append(_portrait(POSES[index], Rect2(size.x * 0.5 + (index - 1) * 62 - 25, area.end.y - 46, 50, 50)))
		seal = Seal.new()
		layer.add_child(seal)
	else:
		var wordmark: Control = preload("res://src/ui/nox_wordmark.gd").new()
		_place(wordmark, Rect2(24, area.position.y + area.size.y * 0.3, width, 100))
		var subtitle: Label = N.label(layer, L.copy("RECONSTRUCT THE PAST\nFROM THE SHADOWS"), 13, N.BRASS)
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle.position = Vector2(32, wordmark.position.y + 108)
		subtitle.size.x = size.x - 64
		var trace: Label = N.label(layer, L.opening("trace"), 16, N.IVORY, true)
		trace.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		trace.position = Vector2(24, area.end.y - 50)
		trace.size.x = width
		trace.name = "FirstTrace"
	_style_text(layer)

func _place(node: Control, rect: Rect2) -> void:
	layer.add_child(node)
	node.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _portrait(pose: String, rect: Rect2) -> Control:
	var portrait: TextureRect = TextureRect.new()
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = Surface.NOX_STAND if pose == "tall" else Surface.NOX_WALK_H if pose == "plate_h" else Surface.NOX_SIT
	var helper: Control = Surface.new()
	atlas.region = helper._nox_source(pose)
	helper.free()
	portrait.texture = atlas
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_place(portrait, rect)
	return portrait

func _plate(rect: Rect2, label_text: String) -> Control:
	var plate: Control = Control.new()
	_place(plate, rect)
	var backing: Panel = Panel.new()
	backing.add_theme_stylebox_override("panel", N.box(Color("#14212a"), Color(N.BRASS, 0.5), 3, 0))
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	plate.add_child(backing)
	backing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var cells: Array[Control] = []
	for index: int in 25:
		var cell: Control = Surface.new()
		cell.kind = "shadow"
		cell.nox_mode = true
		plate.add_child(cell)
		cell.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		cell.position = Vector2(index % 5, int(index / 5.0)) * (rect.size.x - 8) / 5 + Vector2(4, 4)
		cell.size = Vector2.ONE * (rect.size.x - 8) / 5
		cells.append(cell)
	plate.set_meta("cells", cells)
	if not label_text.is_empty():
		var label: Label = N.label(plate, label_text, 10 if size.x < 500 else 13, N.BRASS)
		label.position = Vector2(-5, -24)
		label.size = Vector2(rect.size.x + 10, 22)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return plate

func _shadow(count: int, start: int = 0) -> Array[int]:
	var posts: Array = []
	var types: Dictionary = {}
	for index: int in range(start, count):
		posts.append(POSITIONS[index])
		types[str(POSITIONS[index])] = POSES[index]
	return Optics.compute_shadow(posts, LIGHTS, [], types)

func _set_plate(plate: Control, values: Array[int]) -> void:
	var cells: Array = plate.get_meta("cells")
	for index: int in 25:
		cells[index].value = float(values[index])
		cells[index].queue_redraw()

func _animate() -> void:
	if beat_index == 1:
		var pose_index: int = mini(2, int(elapsed / 0.85))
		for index: int in 3:
			portraits[index].visible = index == pose_index
			portraits[index].modulate.a = 1.0 if reduced and elapsed < 2.65 else 0.0 if reduced else clampf((3.0 - elapsed) / 0.5, 0, 1)
		lamp.glow = 1.0 if reduced else 0.65 + 0.35 * sin(fmod(elapsed, 0.85) / 0.85 * PI)
		lamp.queue_redraw()
		_set_plate(plates[0], _shadow(pose_index + 1))
	elif beat_index == 2:
		var count: int = mini(3, int(elapsed / 0.85) + 1)
		_set_plate(plates[3], _shadow(count))
		for index: int in 3:
			var origin: Vector2 = plates[index].get_meta("origin")
			var merge: float = clampf((elapsed - index * 0.85) / 0.7, 0, 1)
			plates[index].position = origin
			plates[index].modulate.a = 1.0 - merge * 0.48
	elif beat_index in [3, 4]:
		var count: int = 3 if beat_index == 4 else clampi(int((elapsed - 0.35) / 1.0), 0, 3)
		_set_plate(plates[1], _shadow(count))
		for index: int in 3:
			var cell: Control = board.get_child(POSITIONS[index])
			cell.occupied = index < count
			cell.post_type = POSES[index]
			cell.queue_redraw()
			portraits[index].modulate.a = 0.25 if index < count else 1.0
		if beat_index == 4 and phase != 4:
			var target: Array[Control] = plates[0].get_meta("cells")
			var live: Array[Control] = plates[1].get_meta("cells")
			seal.play(target, live)
			if reduced:
				seal.motion.kill()
				seal.progress = 1.0
			phase = 4
	elif beat_index == 5:
		var trace: Label = layer.get_node("FirstTrace") as Label
		trace.modulate.a = 1.0 if reduced else clampf((elapsed - 0.7) / 0.8, 0, 1)

func _sync_viewport() -> void:
	var logical: Vector2 = get_viewport_rect().size
	var css: Vector2 = preload("res://src/ui/nox_stage_layout.gd").viewport_css_size(self)
	if css.x <= 0 or css.y <= 0:
		return
	scale = logical / css
	if not size.is_equal_approx(css):
		size = css

func _style_text(node: Node) -> void:
	if node is Label or node is Button:
		# Japanese uses the existing bundled font directly, avoiding thin serif fallback.
		if L.is_japanese():
			node.add_theme_font_override("font", N.JAPANESE)
	for child: Node in node.get_children():
		_style_text(child)
