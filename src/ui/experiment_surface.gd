extends Control

const N = preload("res://src/ui/nox_theme.gd")
const NOX_SLEEP: Texture2D = preload("res://assets/nox/v0.1/board/nox_sleep.png")
const T = preload("res://src/night_tokens.gd")
const NOX_SIT: Texture2D = preload("res://assets/nox/v0.1/board/nox_sit.png")
const NOX_STAND: Texture2D = preload("res://assets/nox/v0.1/board/nox_stand.png")
const NOX_WALK_H: Texture2D = preload("res://assets/nox/v0.1/board/nox_walk.png")
const NOX_WALK_V: Texture2D = preload("res://assets/nox/v0.1/board/nox_walk_v.png")
var slot_label: String = ""
var kind: String = "socket"
var nox_mode: bool = false
var value: float = 0.0
var occupied: bool = false
var tall: bool = false
var post_type: String = "normal"
var fixed: bool = false
var highlighted: bool = false
var active: bool = false
var unknown: bool = false
var glow: float = 1.0
var hovered: bool = false
var light_direction: String = "TOP"
var change_remaining: float = 0.0
var feedback_reduced_motion: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var center: Vector2 = size * 0.5
	if kind == "shadow":
		if unknown:
			draw_style_box(_style(T.BG_PANEL, T.LINE_SOFT, 4), Rect2(Vector2.ONE, size - Vector2.ONE * 2))
			for offset: int in range(-int(size.y), int(size.x), 7):
				draw_line(Vector2(offset, size.y - 3), Vector2(offset + size.y, 3), Color(T.TEXT_MUTED, 0.16), 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(size.x * 0.5 - 4, size.y * 0.5 + 5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, N.IVORY if nox_mode else T.TEXT_MUTED)
		else:
			var shade: Color = T.SHADOW_0.lerp(T.SHADOW_3, clampf(value / 3.0, 0.0, 1.0))
			draw_style_box(_style(shade, T.LINE_SOFT, 4), Rect2(Vector2.ONE, size - Vector2.ONE * 2))
			draw_line(Vector2(5, 4), Vector2(size.x - 5, 4), Color(1, 1, 1, 0.16))
			if value > 3.0:
				draw_string(ThemeDB.fallback_font, Vector2(6, size.y - 6), str(roundi(value)), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, T.TEXT_PRIMARY)
		if nox_mode and change_remaining > 0.0:
			var opacity: float = 1.0 if feedback_reduced_motion else minf(1.0, change_remaining * 4.0)
			# This marks an action's effect, regardless of whether it matches the target.
			draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(N.BRASS, opacity), false, 2.0)
	elif kind == "socket_missing":
		var plug_rect: Rect2 = Rect2(Vector2(5, 5), size - Vector2(10, 10))
		draw_style_box(_style(T.METAL_SIDE_DARK, T.LINE_SOFT, 3), plug_rect)
		var muted: Color = Color(T.METAL_RIM, 0.55)
		draw_line(center + Vector2(-5, -5), center + Vector2(5, 5), muted, 1.0)
		draw_line(center + Vector2(-5, 5), center + Vector2(5, -5), muted, 1.0)
		for offset: Vector2 in [Vector2(8, 8), Vector2(size.x - 8, 8), Vector2(8, size.y - 8), Vector2(size.x - 8, size.y - 8)]:
			draw_circle(offset, 1.3, T.METAL_RIM)
	elif kind == "socket" or kind == "inventory":
		if nox_mode and kind == "inventory":
			center.y += 8
			draw_string(N.BODY, Vector2(0, size.y - 4), slot_label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, N.IVORY)
		draw_circle(center, minf(size.x, size.y) * 0.32, T.SOCKET_INNER)
		draw_arc(center, minf(size.x, size.y) * 0.32, 0, TAU, 40, T.CYAN if highlighted else Color("#8fb5c1") if nox_mode else T.SOCKET_RIM, 2.3 if nox_mode else 1.5, true)
		if occupied and nox_mode:
			var portrait: Texture2D = NOX_SIT
			if post_type == "tall":
				portrait = NOX_STAND
			elif post_type == "plate_h":
				portrait = NOX_WALK_H
			elif post_type == "plate_v":
				portrait = NOX_WALK_V
			var art_size: float = minf(size.x, size.y) + (6.0 if kind == "socket" else -24.0)
			var art_center: Vector2 = center
			if kind == "inventory" and post_type == "tall":
				art_size *= 1.02
				art_center.y += 3
			if kind == "socket" and post_type == "tall":
				art_size *= 1.35
				art_center.y -= 10.0
			var source: Rect2 = _nox_source(post_type)
			var art_height: float = art_size
			var art_width: float = art_height * source.size.x / source.size.y
			if art_width > art_size:
				art_width = art_size
				art_height = art_width * source.size.y / source.size.x
			draw_texture_rect_region(portrait, Rect2(art_center - Vector2(art_width, art_height) * 0.5, Vector2(art_width, art_height)), source)
			if fixed:
				draw_circle(center + Vector2(15, 14), 2, T.GOLD_SOFT)
		elif occupied:
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
				var height: float = 30.0 if tall else 17.0
				var top: Vector2 = center - Vector2(0, height * 0.5)
				draw_rect(Rect2(top - Vector2(9, 0), Vector2(18, height)), T.METAL_SIDE)
				draw_line(top + Vector2(-8, 0), top + Vector2(-8, height), T.METAL_RIM, 1.0)
				draw_set_transform(top, 0, Vector2(1, 0.38))
				draw_circle(Vector2.ZERO, 9, T.METAL_RIM)
				draw_circle(Vector2.ZERO, 7, T.METAL_TOP)
				draw_set_transform(Vector2.ZERO)
			if fixed:
				for sign_value: int in [-1, 1]:
					draw_circle(center + Vector2(sign_value * 15, 10), 2, T.METAL_RIM)
		if nox_mode and kind == "socket":
			draw_string(N.BODY, Vector2(4, 10), slot_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, N.IVORY if hovered else Color(N.SOFT, 0.78))
	elif kind == "lamp":
		var lamp_center: Vector2 = center + (Vector2(0, -6) if nox_mode and not fixed else Vector2.ZERO)
		if active:
			draw_circle(lamp_center, 15, Color(T.CYAN, 0.09 * glow))
			draw_circle(lamp_center, 10, Color(T.CYAN, 0.17 * glow))
		draw_circle(lamp_center, 7, T.METAL_SIDE)
		draw_circle(lamp_center, 4.5, T.CYAN.lerp(T.METAL_TOP, 1.0 - glow) if active else T.METAL_TOP)
		if not fixed:
			var inward: Vector2 = Vector2.DOWN
			match light_direction:
				"BOTTOM": inward = Vector2.UP
				"LEFT": inward = Vector2.RIGHT
				"RIGHT": inward = Vector2.LEFT
			var arc_color: Color = Color("#8bdef0") if active else Color("#afc8d3")
			draw_arc(lamp_center, 10, inward.angle() - 0.67, inward.angle() + 0.67, 14, arc_color, 1.8, true)
			var tip: Vector2 = lamp_center + inward * 11
			var tangent: Vector2 = Vector2(-inward.y, inward.x)
			draw_line(tip - inward * 3 + tangent * 3, tip, arc_color, 1.5, true)
			draw_line(tip - inward * 3 - tangent * 3, tip, arc_color, 1.5, true)
			if nox_mode:
				draw_string(N.BODY, Vector2(0, size.y - 2), "ON" if active else "OFF", HORIZONTAL_ALIGNMENT_CENTER, size.x, 10, arc_color)
		else:
			draw_circle(lamp_center + Vector2(11, 10), 1.5, T.TEXT_MUTED)
	elif kind == "shutter":
		if nox_mode:
			draw_line(Vector2(0, size.y - 6), Vector2(size.x, size.y - 6), N.BRASS.darkened(0.6), 1)
			if active:
				var ray_end: float = size.y * 0.36 if occupied else size.y - 2.0
				draw_line(Vector2(center.x, 0), Vector2(center.x, ray_end), Color(N.BRASS, 0.75), 2.0, true)
				if occupied:
					draw_line(Vector2(center.x - 7, ray_end), Vector2(center.x + 7, ray_end), N.BRASS, 2.0, true)
				else:
					draw_line(Vector2(center.x - 3, ray_end - 4), Vector2(center.x, ray_end), N.BRASS, 1.5, true)
					draw_line(Vector2(center.x + 3, ray_end - 4), Vector2(center.x, ray_end), N.BRASS, 1.5, true)
			if occupied:
				draw_texture_rect_region(NOX_SLEEP, Rect2(Vector2(2, 1), Vector2(size.x - 4, size.y - 4)), Rect2(150, 285, 760, 555))
			else:
				draw_string(N.BODY, Vector2(0, size.y - 11), slot_label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 9, N.SOFT)
			return
		center.y += 6
		draw_string(ThemeDB.fallback_font, Vector2(center.x - 4, 12), slot_label, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, T.TEXT_MUTED)
		draw_line(Vector2(0, center.y), Vector2(size.x, center.y), T.METAL_RIM, 2)
		if active:
			draw_line(Vector2(center.x, 0), Vector2(center.x, center.y if occupied else size.y), Color(T.CYAN, 0.22), 5)
		if occupied:
			draw_style_box(_style(T.METAL_SIDE_DARK, T.METAL_RIM, 2), Rect2(center - Vector2(16, 6 if highlighted else 3), Vector2(32, 10)))
			draw_line(center + Vector2(-10, 1), center + Vector2(10, 1), T.METAL_TOP, 1)

func _style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style

func _nox_source(pose: String) -> Rect2:
	match pose:
		"tall":
			return Rect2(260, 85, 500, 860)
		"plate_h":
			return Rect2(80, 435, 870, 510)
		"plate_v":
			return Rect2(300, 85, 425, 860)
		_:
			return Rect2(290, 130, 490, 780)
