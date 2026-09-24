extends Control
class_name NoxFinaleOverlay

## A quiet full-screen archive milestone for the final reconstructed record.
signal home_requested
signal language_changed(language: String)

const NoxTheme = preload("res://src/ui/nox_theme.gd")
const NoxLocale = preload("res://src/nox_locale.gd")

const GOLD: Color = Color("#c5a476")
const PAPER: Color = Color("#eee7d8")
const MUTED: Color = Color("#a5b2bd")

var _language: String = "en"
var _reduced_motion: bool = false
var _scrim: ColorRect
var _center: CenterContainer
var _panel: PanelContainer
var _caption: Label
var _heading: Label
var _description: Label
var _counter: Label
var _counter_caption: Label
var _closing_line: Label
var _language_button: Button
var _home_button: Button
var _review_button: Button
var _constellation: Constellation
var _motion: Tween


class Constellation extends Control:
	const NODE_GOLD: Color = Color("#c5a476")
	const NODE_PAPER: Color = Color("#eee7d8")
	const NODE_MUTED: Color = Color("#a5b2bd")

	var linked_records: float = 36.0:
		set(value):
			linked_records = clampf(value, 0.0, 36.0)
			queue_redraw()
	var settled_glow: float = 0.0:
		set(value):
			settled_glow = clampf(value, 0.0, 1.0)
			queue_redraw()

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var grid_width: float = minf(size.x - 28.0, 372.0)
		var grid_height: float = minf(size.y - 24.0, 146.0)
		var rect := Rect2((size.x - grid_width) * 0.5, (size.y - grid_height) * 0.5, grid_width, grid_height)
		draw_rect(rect, Color("#111b25", 0.76), true)
		draw_rect(rect, Color(NODE_GOLD, 0.22), false, 1.0, true)

		var points: Array[Vector2] = []
		for index: int in range(36):
			var row: int = floori(float(index) / 6.0)
			var column: int = index % 6
			if row % 2 == 1:
				column = 5 - column
			var x: float = rect.position.x + 18.0 + (grid_width - 36.0) * float(column) / 5.0
			var y: float = rect.position.y + 16.0 + (grid_height - 32.0) * float(row) / 5.0
			points.append(Vector2(x, y))

		var count: float = linked_records
		for index: int in range(35):
			var segment_progress: float = clampf(count - float(index + 1), 0.0, 1.0)
			if segment_progress <= 0.0:
				continue
			var start: Vector2 = points[index]
			var finish: Vector2 = points[index + 1].lerp(points[index], 1.0 - segment_progress)
			draw_line(start, finish, Color(NODE_GOLD, 0.16 + 0.34 * settled_glow), 1.2, true)

		for index: int in range(36):
			var reveal: float = clampf(count - float(index), 0.0, 1.0)
			var point: Vector2 = points[index]
			var base_alpha: float = 0.22 + reveal * 0.7
			if reveal > 0.0:
				draw_circle(point, 7.0 + 3.0 * settled_glow, Color(NODE_GOLD, 0.07 + 0.11 * settled_glow) * reveal)
			draw_circle(point, 3.3, Color(NODE_MUTED, base_alpha * (1.0 - reveal * 0.48)))
			if reveal > 0.0:
				draw_circle(point, 2.1, Color(NODE_PAPER.lerp(NODE_GOLD, 0.7), reveal * (0.78 + 0.22 * settled_glow)))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	NoxTheme.ensure_japanese_font()
	_build_overlay()
	resized.connect(_layout_overlay)
	_layout_overlay()
	hide()


## Show the 36-record finale in the requested language.
func present(language: String, reduced_motion: bool) -> void:
	_language = "ja" if language == "ja" else "en"
	_reduced_motion = reduced_motion
	_refresh_copy()
	if _motion != null and _motion.is_valid():
		_motion.kill()
	show()
	_layout_overlay()
	if _reduced_motion:
		_scrim.modulate.a = 1.0
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
		_constellation.linked_records = 36.0
		_constellation.settled_glow = 0.25
		return

	_scrim.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.97, 0.97)
	_constellation.linked_records = 0.0
	_constellation.settled_glow = 0.0
	call_deferred("_play_arrival")


## Hide the overlay so the reconstructed board can be reviewed again.
func dismiss() -> void:
	if _motion != null and _motion.is_valid():
		_motion.kill()
	hide()


## Update the overlay and shared archive language while it is open.
func set_language(language: String) -> void:
	_language = "ja" if language == "ja" else "en"
	NoxLocale.set_language(_language)
	_refresh_copy()


func _build_overlay() -> void:
	_scrim = ColorRect.new()
	_scrim.name = "FinaleScrim"
	_scrim.color = Color("#07101a", 0.96)
	_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_scrim)
	_scrim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_center = CenterContainer.new()
	_center.name = "FinaleCenter"
	_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_center)
	_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = PanelContainer.new()
	_panel.name = "FinaleCard"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_panel.custom_minimum_size = Vector2(520.0, 620.0)
	_panel.add_theme_stylebox_override("panel", NoxTheme.box(Color("#0b141e", 0.985), Color(GOLD, 0.42), 16, 0))
	_panel.resized.connect(_sync_panel_pivot)
	_center.add_child(_panel)

	var margin: MarginContainer = NoxTheme.margin(_panel, 22)
	var content := VBoxContainer.new()
	content.name = "FinaleContent"
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)
	content.add_child(top_row)
	_caption = NoxTheme.label(top_row, "A QUIET MILESTONE", 10, GOLD)
	_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_language_button = NoxTheme.button("日本語", 36)
	_language_button.custom_minimum_size.x = 72.0
	_language_button.pressed.connect(_toggle_language)
	top_row.add_child(_language_button)

	var divider := ColorRect.new()
	divider.color = Color(GOLD, 0.32)
	divider.custom_minimum_size.y = 1.0
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(divider)

	_heading = NoxTheme.label(content, "36 records, connected.", 28, PAPER, true)
	_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_heading.custom_minimum_size.y = 66.0

	_description = NoxTheme.label(content, "Every shadow agrees with your reconstruction.", 14, MUTED)
	_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_description.custom_minimum_size.y = 38.0

	_constellation = Constellation.new()
	_constellation.name = "LinkedRecords"
	_constellation.custom_minimum_size = Vector2(280.0, 188.0)
	_constellation.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(_constellation)

	_counter = NoxTheme.label(content, "36 / 36", 27, PAPER, true)
	_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_counter_caption = NoxTheme.label(content, "RECORDS RECONSTRUCTED", 9, GOLD)
	_counter_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_closing_line = NoxTheme.label(content, "You found every moment the shadows kept.", 13, PAPER, true)
	_closing_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_closing_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_closing_line.custom_minimum_size.y = 24.0

	var button_row := HBoxContainer.new()
	button_row.name = "FinaleActions"
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 10)
	content.add_child(button_row)
	_home_button = NoxTheme.button("HOME", 50, true)
	_home_button.custom_minimum_size.x = 132.0
	_home_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_home_button.pressed.connect(_request_home)
	button_row.add_child(_home_button)
	_review_button = NoxTheme.button("REVIEW RECORDS", 50)
	_review_button.custom_minimum_size.x = 154.0
	_review_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_review_button.pressed.connect(dismiss)
	button_row.add_child(_review_button)


func _layout_overlay() -> void:
	if _panel == null:
		return
	var viewport_size: Vector2 = get_viewport_rect().size
	var width: float = minf(560.0, maxf(280.0, viewport_size.x - 32.0))
	var height: float = minf(620.0, maxf(500.0, viewport_size.y - 36.0))
	_panel.custom_minimum_size = Vector2(width, height)
	call_deferred("_sync_panel_pivot")


func _sync_panel_pivot() -> void:
	if _panel != null:
		_panel.pivot_offset = _panel.size * 0.5


func _play_arrival() -> void:
	if not is_visible_in_tree() or _reduced_motion:
		return
	_sync_panel_pivot()
	_motion = create_tween()
	_motion.set_parallel(true)
	_motion.tween_property(_scrim, "modulate:a", 1.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion.tween_property(_panel, "modulate:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion.tween_property(_panel, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion.tween_property(_constellation, "linked_records", 36.0, 2.05).set_delay(0.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_motion.chain().tween_property(_constellation, "settled_glow", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_motion.chain().tween_property(_constellation, "settled_glow", 0.25, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _refresh_copy() -> void:
	var japanese: bool = _language == "ja"
	if _caption != null:
		_caption.text = "静かな到達点" if japanese else "A QUIET MILESTONE"
		_heading.text = "36枚の記録が、ひとつにつながった。" if japanese else "36 records, connected."
		_heading.add_theme_font_size_override("font_size", 25 if japanese else 28)
		_description.text = "すべての影が、再構築と一致した。" if japanese else "Every shadow agrees with your reconstruction."
		_counter.text = "36 / 36"
		_counter_caption.text = "枚の記録を再構築" if japanese else "RECORDS RECONSTRUCTED"
		_closing_line.text = "影が残した瞬間を、すべて見つけた。" if japanese else "You found every moment the shadows kept."
		_language_button.text = "EN" if japanese else "日本語"
		_home_button.text = "ホームへ" if japanese else "HOME"
		_review_button.text = "記録を見直す" if japanese else "REVIEW RECORDS"


func _toggle_language() -> void:
	set_language("en" if _language == "ja" else "ja")
	language_changed.emit(_language)


func _request_home() -> void:
	dismiss()
	home_requested.emit()
