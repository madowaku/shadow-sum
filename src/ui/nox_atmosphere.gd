extends Control

const Settings = preload("res://src/nox_settings.gd")
var time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	set_process(not Settings.reduced_motion())

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	for index: int in 16:
		var seed_value: float = float(index) * 1.618
		var x: float = fposmod(seed_value * 137.0 + sin(time * 0.14 + index) * 12.0, size.x)
		var y: float = fposmod(seed_value * 191.0 - time * (2.0 + index * 0.11), size.y)
		var opacity: float = 0.08 + 0.08 * sin(time * 0.25 + seed_value)
		draw_circle(Vector2(x, y), 0.8, Color(0.9, 0.82, 0.63, opacity))
