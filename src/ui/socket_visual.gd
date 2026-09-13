extends Control

const NightTokens = preload("res://src/night_tokens.gd")

var occupied := false
var active := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func set_state(is_occupied: bool, is_active := false) -> void:
	occupied = is_occupied
	active = is_active
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0))
	var outer := StyleBoxFlat.new()
	outer.bg_color = NightTokens.SOCKET_INNER_BOTTOM
	outer.border_color = NightTokens.SOCKET_ACTIVE if active else (NightTokens.SOCKET_SETTLED if occupied else NightTokens.SOCKET_RIM)
	outer.set_border_width_all(2 if active else 1)
	outer.set_corner_radius_all(NightTokens.RADIUS_SOCKET)
	outer.shadow_color = Color(0.0, 0.0, 0.0, 0.30)
	outer.shadow_size = 3
	outer.shadow_offset = Vector2(0.0, 2.0)
	draw_style_box(outer, rect)

	var inset := rect.grow(-4.0)
	var inner := StyleBoxFlat.new()
	inner.bg_color = NightTokens.SOCKET_INNER
	inner.border_color = NightTokens.SOCKET_RIM_INNER
	inner.set_border_width_all(1)
	inner.set_corner_radius_all(maxi(4, NightTokens.RADIUS_SOCKET - 3))
	draw_style_box(inner, inset)

	# This tiny bore is intentionally geometry, not a text dot.
	var center := size * 0.5
	var bore_color := NightTokens.SOCKET_ACTIVE if active else NightTokens.LINE_BRIGHT.darkened(0.12)
	draw_circle(center, 1.6 if size.x < 50.0 else 1.9, bore_color)

	if active:
		draw_arc(center, minf(size.x, size.y) * 0.32, 0.0, TAU, 32, Color(NightTokens.CYAN, 0.22), 1.0, true)
