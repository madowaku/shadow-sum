extends Control

const T = preload("res://src/night_tokens.gd")

var phase: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()

func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	if w <= 0.0 or h <= 0.0:
		return

	draw_rect(Rect2(Vector2.ZERO, size), T.BG_BASE)

	var grid_step: float = 36.0
	var grid_color := Color(T.LINE_SOFT, 0.34)
	var x: float = fmod(phase * 1.2, grid_step)
	while x < w:
		draw_line(Vector2(x, 0), Vector2(x, h), grid_color, 1.0)
		x += grid_step
	var y: float = fmod(phase * 0.45, grid_step)
	while y < h:
		draw_line(Vector2(0, y), Vector2(w, y), grid_color, 1.0)
		y += grid_step

	_draw_optical_table(w, h)

	var top_fade := Gradient.new()
	top_fade.colors = PackedColorArray([Color(0.02, 0.03, 0.04, 0.0), Color(0.02, 0.03, 0.04, 0.78)])
	var top_tex := GradientTexture1D.new()
	top_tex.gradient = top_fade

	draw_rect(Rect2(0, 0, w, h), Color(0.01, 0.015, 0.02, 0.12))
	draw_rect(Rect2(0, h * 0.42, w, h * 0.58), Color(0.0, 0.0, 0.0, 0.28))

func _draw_optical_table(w: float, h: float) -> void:
	var pulse: float = 0.5 + sin(phase * 0.65) * 0.5
	var source := Vector2(w * 0.10, h * 0.22)
	var prism := Vector2(w * 0.38, h * 0.29)
	var post := Vector2(w * 0.69, h * 0.35)
	var screen_x: float = w * 0.84
	var screen_rect := Rect2(screen_x, h * 0.16, maxf(42.0, w * 0.11), h * 0.31)

	var beam := Color(T.CYAN, 0.18 + pulse * 0.08)
	var beam_hot := Color(T.TEXT_PRIMARY, 0.28 + pulse * 0.08)
	draw_line(source, prism, beam, 7.0, true)
	draw_line(source, prism, beam_hot, 1.5, true)
	draw_line(prism, Vector2(screen_x, h * 0.28), beam, 6.0, true)
	draw_line(prism, Vector2(screen_x, h * 0.28), beam_hot, 1.2, true)

	draw_circle(source, 13.0 + pulse * 2.0, Color(T.CYAN, 0.12))
	draw_circle(source, 4.5, T.TEXT_PRIMARY)
	draw_rect(Rect2(source - Vector2(22, 11), Vector2(18, 22)), T.METAL_SIDE)
	draw_rect(Rect2(source - Vector2(24, 14), Vector2(4, 28)), T.METAL_RIM)

	var prism_points := PackedVector2Array([
		prism + Vector2(-25, 23),
		prism + Vector2(0, -28),
		prism + Vector2(25, 23)
	])
	draw_colored_polygon(prism_points, Color(0.78, 0.9, 0.94, 0.13))
	draw_polyline(PackedVector2Array([
		prism + Vector2(-25, 23),
		prism + Vector2(0, -28),
		prism + Vector2(25, 23),
		prism + Vector2(-25, 23)
	]), Color(T.TEXT_SECONDARY, 0.55), 1.2, true)

	var post_rect := Rect2(post - Vector2(11, 38), Vector2(22, 76))
	draw_rect(post_rect, T.METAL_SIDE)
	draw_rect(Rect2(post_rect.position, Vector2(post_rect.size.x, 5)), T.METAL_TOP)
	draw_line(post + Vector2(-14, 39), post + Vector2(14, 39), Color(T.GOLD_SOFT, 0.55), 2.0)

	draw_rect(screen_rect, Color(T.SHADOW_0, 0.16))
	draw_rect(screen_rect, Color(T.TEXT_SECONDARY, 0.45), false, 1.2)
	var shadow_width: float = screen_rect.size.x * 0.48
	var shadow_rect := Rect2(
		screen_rect.position + Vector2(screen_rect.size.x * 0.24, screen_rect.size.y * 0.28),
		Vector2(shadow_width, screen_rect.size.y * 0.36)
	)
	draw_rect(shadow_rect, Color(0.01, 0.015, 0.02, 0.72))

	var base_y: float = h * 0.44
	draw_line(Vector2(w * 0.05, base_y), Vector2(w * 0.95, base_y), Color(T.LINE_MEDIUM, 0.42), 1.0)
	for marker: int in 8:
		var mx: float = lerpf(w * 0.08, w * 0.92, float(marker) / 7.0)
		draw_line(Vector2(mx, base_y - 4), Vector2(mx, base_y + 4), Color(T.LINE_BRIGHT, 0.42), 1.0)
