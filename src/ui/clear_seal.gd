extends Control
## A quiet, input-transparent seal over the two matched shadow panels.
const T = preload("res://src/night_tokens.gd")
var panels: Array = []
var progress: float = 0.0:
	set(value):
		progress = value
		queue_redraw()
var motion: Tween

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hide()

func play(target: Array[Control], live: Array[Control]) -> void:
	reset()
	panels = [target, live]
	show()
	motion = create_tween()
	motion.tween_property(self, "progress", 1.0, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func reset() -> void:
	if motion != null and motion.is_valid():
		motion.kill()
	progress = 0.0
	hide()

func _draw() -> void:
	for cells: Array in panels:
		var rect: Rect2 = cells[0].get_global_rect()
		for cell: Control in cells:
			rect = rect.merge(cell.get_global_rect())
		rect.position -= global_position
		rect = rect.grow(4.0)
		var alpha: float = sin(progress * PI) * 0.45
		for spread: int in range(3, 13, 3):
			draw_rect(rect.grow(float(spread)), Color(T.GOLD, alpha * 0.13), false, 2.0)
		draw_rect(rect, Color(T.GOLD, progress * 0.72), false, 1.0)
		if progress < 1.0:
			var sweep_y: float = rect.position.y + rect.size.y * progress
			draw_line(Vector2(rect.position.x, sweep_y), Vector2(rect.end.x, sweep_y), Color(T.GOLD, alpha), 2.0, true)
		var length: float = 8.0 * progress
		for corner: Vector2 in [rect.position, rect.end]:
			var sign_value: float = 1.0 if corner == rect.position else -1.0
			draw_line(corner, corner + Vector2(length * sign_value, 0), Color(T.GOLD, progress), 2.0, true)
			draw_line(corner, corner + Vector2(0, length * sign_value), Color(T.GOLD, progress), 2.0, true)
