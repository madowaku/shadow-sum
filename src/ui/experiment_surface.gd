extends Control

const T = preload("res://src/night_tokens.gd")
const NOX_SIT: Texture2D = preload("res://assets/nox/nox_sit.svg")
const NOX_STAND: Texture2D = preload("res://assets/nox/nox_stand.svg")
const NOX_SLEEP: Texture2D = preload("res://assets/nox/nox_sleep.svg")
var slot_label: String = ""
var kind: String = "socket"
var value: float = 0.0
var occupied: bool = false
var tall: bool = false
var post_type: String = "normal"
var fixed: bool = false
var highlighted: bool = false
var active: bool = false
var glow: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	if kind == "shadow":
		var shade: Color = T.SHADOW_0.lerp(T.SHADOW_3, clampf(value / 3.0, 0.0, 1.0))
		draw_style_box(_style(shade, T.LINE_SOFT, 4), Rect2(Vector2.ONE, size - Vector2.ONE * 2))
		draw_line(Vector2(5, 4), Vector2(size.x - 5, 4), Color(1, 1, 1, 0.16))
		if value > 3.0:
			draw_string(ThemeDB.fallback_font, Vector2(6, size.y - 6), str(roundi(value)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, T.TEXT_PRIMARY)
	elif kind == "socket" or kind == "inventory":
		draw_circle(center, minf(size.x, size.y) * 0.32, T.SOCKET_INNER)
		draw_arc(center, minf(size.x, size.y) * 0.32, 0, TAU, 40, T.CYAN if highlighted else T.SOCKET_RIM, 1.5, true)
		if occupied:
			if post_type.begins_with("plate_"):
				var horizontal: bool = post_type == "plate_h"
				var plate_size: Vector2 = Vector2(30, 7) if horizontal else Vector2(7, 30)
				var plate_rect: Rect2 = Rect2(center - plate_size * 0.5, plate_size)
				draw_style_box(_style(T.METAL_SIDE_DARK, T.METAL_RIM, 2), plate_rect)
				if horizontal:
					draw_line(Vector2(plate_rect.position.x + 4, center.y - 1), Vector2(plate_rect.end.x - 4, center.y - 1), T.METAL_TOP, 1.0)
				else:
					draw_line(Vector2(center.x - 1, plate_rect.position.y + 4), Vector2(center.x - 1, plate_rect.end.y - 4), T.METAL_TOP, 1.0)
			else:
				var cat_texture: Texture2D = NOX_STAND if tall else NOX_SIT
				var cat_size: Vector2 = Vector2(36, 46) if tall else Vector2(40, 40)
				var cat_rect := Rect2(center - cat_size * 0.5 + Vector2(0, 1 if tall else 2), cat_size)
				var cat_alpha: float = 1.0 if kind == "inventory" else 0.82
				if highlighted:
					draw_circle(center, 21, Color(T.CYAN, 0.10))
				draw_texture_rect(cat_texture, cat_rect, false, Color(1, 1, 1, cat_alpha))
			if fixed:
				for sign_value: int in [-1, 1]:
					draw_circle(center + Vector2(sign_value * 15, 10), 2, T.METAL_RIM)
	elif kind == "lamp":
		if active:
			draw_circle(center, 18, Color(T.CYAN, 0.08 * glow))
			draw_circle(center, 13, Color(T.CYAN, 0.13 * glow))
		draw_circle(center, 8, T.METAL_SIDE)
		draw_circle(center, 5, T.CYAN.lerp(T.METAL_TOP, 1.0 - glow) if active else T.METAL_TOP)
		if not fixed:
			draw_arc(center, 16, -0.8, 0.8, 16, T.TEXT_SECONDARY, 1.5, true)
		else:
			draw_circle(center + Vector2(14, 14), 1.5, T.TEXT_MUTED)
	elif kind == "shutter":
		center.y += 6
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 4, 12), slot_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, T.TEXT_MUTED)
		draw_line(Vector2(0, center.y), Vector2(size.x, center.y), T.METAL_RIM, 2)
		if active:
			draw_line(Vector2(center.x, 0), Vector2(center.x, center.y if occupied else size.y), Color(T.CYAN, 0.22), 5)
		if occupied:
			var sleep_size := Vector2(38, 23)
			var sleep_rect := Rect2(center - sleep_size * 0.5 - Vector2(0, 4 if highlighted else 1), sleep_size)
			if highlighted:
				draw_circle(center - Vector2(0, 1), 21, Color(T.CYAN, 0.10))
			draw_texture_rect(NOX_SLEEP, sleep_rect, false, Color(1, 1, 1, 0.90))

func _style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style
