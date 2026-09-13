extends Control

const NightTokens = preload("res://src/night_tokens.gd")

var value := 0
var hidden := false
var is_target := false
var cell_seed := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

func set_state(new_value: int, is_hidden: bool, target_surface: bool, seed_value: int) -> void:
	value = new_value
	hidden = is_hidden
	is_target = target_surface
	cell_seed = seed_value
	queue_redraw()

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return

	var inner := Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0))
	var tint := NightTokens.GLASS_TARGET_WARM if is_target else NightTokens.GLASS_LIVE_COOL
	draw_rect(inner, tint)

	# Glass catches a little room light at the top and loses it near the bottom.
	var left := 5.0
	var right := size.x - 5.0
	draw_line(Vector2(left, 4.0), Vector2(right, 4.0), NightTokens.GLASS_HIGHLIGHT, 1.0, true)
	draw_line(Vector2(left, size.y - 4.0), Vector2(right, size.y - 4.0), NightTokens.GLASS_LOWLIGHT, 1.0, true)

	# Fixed grain prevents flat vector cells without creating restless animation.
	var grain_count := 2 if value <= 1 else 3
	if hidden:
		grain_count = 5
	for i in grain_count:
		var p := _grain_point(i)
		draw_circle(p, 0.65, NightTokens.GLASS_GRAIN)

	if hidden:
		# Three translucent fog bands say “unobservable” without implying zero.
		var fog := NightTokens.GLASS_FOG
		draw_line(Vector2(6.0, size.y * 0.38), Vector2(size.x - 7.0, size.y * 0.30), fog, 2.0, true)
		draw_line(Vector2(5.0, size.y * 0.52), Vector2(size.x - 5.0, size.y * 0.48), Color(fog, fog.a * 0.85), 2.4, true)
		draw_line(Vector2(7.0, size.y * 0.67), Vector2(size.x - 8.0, size.y * 0.61), Color(fog, fog.a * 0.65), 1.7, true)

func _grain_point(index: int) -> Vector2:
	var x_seed := (cell_seed * 17 + index * 29 + (11 if is_target else 23)) % 97
	var y_seed := (cell_seed * 31 + index * 19 + (7 if hidden else 13)) % 89
	var x := 6.0 + (size.x - 12.0) * float(x_seed) / 96.0
	var y := 7.0 + (size.y - 14.0) * float(y_seed) / 88.0
	return Vector2(x, y)
