extends Control

const N = preload("res://src/ui/nox_theme.gd")
const Surface = preload("res://src/ui/experiment_surface.gd")
const Optics = preload("res://src/experiment_optics.gd")
var rule: String = ""
var language: String = "en"

func _ready() -> void:
	custom_minimum_size = Vector2(0, 134)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(kind: String, locale: String) -> void:
	rule = kind
	language = locale
	queue_redraw()

func _draw() -> void:
	if rule.is_empty():
		return
	var japanese: bool = language == "ja"
	var caption: String = "Example: all four lamps on" if rule == "walk" else "Example: top + left + right lamps on"
	if japanese:
		caption = "例：四方向の光が点灯" if rule == "walk" else "例：上・左・右の光が点灯"
	draw_string(N.BODY, Vector2(0, 13), caption, HORIZONTAL_ALIGNMENT_CENTER, size.x, 11, N.SOFT)
	for example: int in 2:
		var kind: String = "normal"
		var label: String = "SIT"
		var blocked: Array = []
		var active_lights: Array = ["TOP", "LEFT", "RIGHT"]
		if rule == "reach":
			kind = "normal" if example == 0 else "tall"
			label = ("座る" if example == 0 else "立つ") if japanese else ("SIT" if example == 0 else "STAND")
		elif rule == "walk":
			kind = "plate_h" if example == 0 else "plate_v"
			label = ("体：横向き" if example == 0 else "体：縦向き") if japanese else ("BODY: ACROSS" if example == 0 else "BODY: DEPTH")
			active_lights.append("BOTTOM")
		elif rule == "sleep":
			blocked = [] if example == 0 else [2]
			label = ("光が届く" if example == 0 else "眠る猫が遮る") if japanese else ("LIGHT REACHES" if example == 0 else "SLEEP BLOCKS")
		var half: float = size.x * 0.5
		var x: float = half * float(example)
		draw_string(N.BODY, Vector2(x, 32), label, HORIZONTAL_ALIGNMENT_CENTER, half, 11, N.IVORY)
		var texture: Texture2D = Surface.NOX_SIT
		var crop: Rect2 = Rect2(290, 130, 490, 780)
		if kind == "tall":
			texture = Surface.NOX_STAND
			crop = Rect2(260, 85, 500, 860)
		elif kind == "plate_h":
			texture = Surface.NOX_WALK_H
			crop = Rect2(80, 435, 870, 510)
		elif kind == "plate_v":
			texture = Surface.NOX_WALK_V
			crop = Rect2(300, 85, 425, 860)
		var art_size: Vector2 = crop.size * minf(32.0 / crop.size.x, 38.0 / crop.size.y)
		var center: Vector2 = Vector2(x + half * 0.22, 78)
		draw_texture_rect_region(texture, Rect2(center - art_size * 0.5, art_size), crop)
		if rule == "sleep" and example == 1:
			draw_texture_rect_region(Surface.NOX_SLEEP, Rect2(center + Vector2(-16, -34), Vector2(32, 19)), Rect2(150, 285, 760, 555))
			draw_line(center + Vector2(0, -42), center + Vector2(0, -34), N.BRASS, 2)
			draw_line(center + Vector2(-8, -15), center + Vector2(8, -15), N.BRASS, 2)
		draw_string(N.BODY, Vector2(x + half * 0.39, 81), "→", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, N.BRASS)
		var values: Array[int] = Optics.compute_shadow([12], active_lights, blocked, {"12": kind})
		var tile: float = minf(11.0, half * 0.46 / 5.0)
		var origin: Vector2 = Vector2(x + half * 0.53, 48)
		for index: int in 25:
			var rect: Rect2 = Rect2(origin + Vector2(index % 5, floori(float(index) / 5.0)) * tile, Vector2.ONE * (tile - 1))
			draw_rect(rect, Color("#77969e") if values[index] > 0 else Color("#e1e7e8"))
		var footer: String = "影" if japanese else "SHADOW"
		draw_string(N.BODY, Vector2(origin.x, 123), footer, HORIZONTAL_ALIGNMENT_CENTER, tile * 5.0, 10, N.SOFT)
