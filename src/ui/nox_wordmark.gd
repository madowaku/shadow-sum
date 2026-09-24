extends Control

const N = preload("res://src/ui/nox_theme.gd")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	var fs: int = int(minf(size.y * 1.14, size.x / 4.25))
	var left: Vector2 = N.SERIF.get_string_size("NO", HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var right: Vector2 = N.SERIF.get_string_size("SUM", HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var x_width: float = fs * 0.56
	var total: float = left.x + x_width + right.x
	var baseline: float = (size.y - N.SERIF.get_height(fs)) * 0.5 + N.SERIF.get_ascent(fs)
	var origin: Vector2 = Vector2((size.x - total) * 0.5, baseline)
	draw_string(N.SERIF, origin, "NO", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, N.IVORY)
	var x: float = origin.x + left.x + fs * 0.015
	var y: float = baseline - fs * 0.60
	var w: float = x_width - fs * 0.05
	var h: float = fs * 0.60
	# Two pale ribbons carry translucent shadows. Their shared area is darker.
	var t: float = fs * 0.13
	var first: PackedVector2Array = PackedVector2Array([Vector2(x, y), Vector2(x + t, y), Vector2(x + w, y + h), Vector2(x + w - t, y + h)])
	var second: PackedVector2Array = PackedVector2Array([Vector2(x + w - t, y), Vector2(x + w, y), Vector2(x + t, y + h), Vector2(x, y + h)])
	draw_colored_polygon(first, Color(N.IVORY, 0.92))
	draw_colored_polygon(second, Color(N.IVORY, 0.92))
	var inset: float = t * 0.22
	var shadow_one: PackedVector2Array = PackedVector2Array([Vector2(x + inset, y), Vector2(x + t - inset, y), Vector2(x + w - inset, y + h), Vector2(x + w - t + inset, y + h)])
	var shadow_two: PackedVector2Array = PackedVector2Array([Vector2(x + w - t + inset, y), Vector2(x + w - inset, y), Vector2(x + t - inset, y + h), Vector2(x + inset, y + h)])
	var shadow_ink: Color = Color(0.06, 0.10, 0.15, 0.58)
	draw_colored_polygon(shadow_one, shadow_ink)
	draw_colored_polygon(shadow_two, shadow_ink)
	var mid: Vector2 = Vector2(x + w * 0.5, y + h * 0.5)
	var overlap: PackedVector2Array = PackedVector2Array([mid + Vector2(0, -t * 0.90), mid + Vector2(t * 1.05, 0), mid + Vector2(0, t * 0.90), mid - Vector2(t * 1.05, 0)])
	draw_colored_polygon(overlap, Color(0.04, 0.07, 0.11, 0.60))
	draw_string(N.SERIF, Vector2(origin.x + left.x + x_width, baseline), "SUM", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, N.IVORY)
