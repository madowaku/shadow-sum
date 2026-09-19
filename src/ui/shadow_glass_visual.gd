extends Control

const NightTokens = preload("res://src/night_tokens.gd")

var value := 0
# Avoid Control.hidden (native signal); this is authored clue state.
var clue_hidden: bool = false
var is_target := false
var cell_seed := 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

var motion_enabled: bool = false
var immediate_updates: bool = true
var preview_updates: bool = false
var ink_tween: Tween
var display_level: float = 0.0:
	set(next):
		display_level = next
		queue_redraw()
var fog_amount: float = 0.0:
	set(next):
		fog_amount = next
		queue_redraw()
var glint: float = 0.0:
	set(next):
		glint = next
		queue_redraw()
var revealed: bool = false
var initialized: bool = false
var last_preview: bool = false

func cancel_motion() -> void:
	if ink_tween != null and ink_tween.is_valid():
		ink_tween.kill()
	ink_tween = null
	glint = 0.0

func set_state(new_value: int, is_hidden: bool, target_surface: bool, seed_value: int) -> void:
	var unchanged: bool = initialized and value == new_value and clue_hidden == is_hidden and last_preview == preview_updates
	value = new_value
	clue_hidden = is_hidden
	is_target = target_surface
	cell_seed = seed_value
	if not initialized or immediate_updates or not motion_enabled:
		cancel_motion()
		display_level = float(value)
		fog_amount = 1.0 if clue_hidden else 0.0
		revealed = false
	elif not unchanged:
		cancel_motion()
		revealed = false
		var durations: Array[float] = [0.18, 0.18, 0.20, 0.23]
		var duration: float = 0.15 if float(value) < display_level else durations[clampi(value, 0, 3)]
		if preview_updates:
			duration = 0.09
		ink_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		ink_tween.tween_property(self, "display_level", float(value), duration)
		ink_tween.tween_property(self, "fog_amount", 1.0 if clue_hidden else 0.0, duration)
	last_preview = preview_updates
	initialized = true
	queue_redraw()

func reveal_density(level: int, delay: float) -> void:
	cancel_motion()
	value = level
	revealed = true
	ink_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	ink_tween.tween_interval(delay)
	ink_tween.tween_property(self, "display_level", float(level), 0.18)
	ink_tween.parallel().tween_property(self, "fog_amount", 0.0, 0.18)
	ink_tween.tween_property(self, "glint", 0.16, 0.02)
	ink_tween.tween_property(self, "glint", 0.0, 0.03)

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return

	var inner := Rect2(Vector2(2.0, 2.0), size - Vector2(4.0, 4.0))
	var tint := NightTokens.GLASS_TARGET_WARM if is_target else NightTokens.GLASS_LIVE_COOL
	draw_rect(inner, tint)
	if motion_enabled:
		var level: float = clampf(display_level, 0.0, 3.0)
		var lower: int = mini(int(level), 2)
		var alphas: Array[float] = [0.0, 0.035, 0.075, 0.120]
		var ink_alpha: float = lerpf(alphas[lower], alphas[lower + 1], level - float(lower))
		# Inset ink keeps the reflection at the glass surface stationary.
		draw_rect(inner.grow(-2.0), Color(0.015, 0.019, 0.023, ink_alpha))
		if revealed:
			draw_rect(inner, Color(NightTokens.SHADOW_UNKNOWN, fog_amount))
		if glint > 0.0:
			draw_line(Vector2(5.0, 5.0), Vector2(size.x - 5.0, 5.0), Color(NightTokens.GOLD_SOFT, glint), 1.0)

	# Glass catches a little room light at the top and loses it near the bottom.
	var left := 5.0
	var right := size.x - 5.0
	draw_line(Vector2(left, 4.0), Vector2(right, 4.0), NightTokens.GLASS_HIGHLIGHT, 1.0, true)
	draw_line(Vector2(left, size.y - 4.0), Vector2(right, size.y - 4.0), NightTokens.GLASS_LOWLIGHT, 1.0, true)

	# Fixed grain prevents flat vector cells without creating restless animation.
	var grain_count := 3
	if clue_hidden:
		grain_count = 5
	for i in grain_count:
		var p := _grain_point(i)
		draw_circle(p, 0.65, NightTokens.GLASS_GRAIN)

	if clue_hidden:
		# Three translucent fog bands say “unobservable” without implying zero.
		var fog: Color = Color(NightTokens.GLASS_FOG, NightTokens.GLASS_FOG.a * fog_amount)
		draw_line(Vector2(6.0, size.y * 0.38), Vector2(size.x - 7.0, size.y * 0.30), fog, 2.0, true)
		draw_line(Vector2(5.0, size.y * 0.52), Vector2(size.x - 5.0, size.y * 0.48), Color(fog, fog.a * 0.85), 2.4, true)
		draw_line(Vector2(7.0, size.y * 0.67), Vector2(size.x - 8.0, size.y * 0.61), Color(fog, fog.a * 0.65), 1.7, true)

func _grain_point(index: int) -> Vector2:
	var x_seed := (cell_seed * 17 + index * 29 + (11 if is_target else 23)) % 97
	var y_seed := (cell_seed * 31 + index * 19 + (7 if clue_hidden else 13)) % 89
	var x := 6.0 + (size.x - 12.0) * float(x_seed) / 96.0
	var y := 7.0 + (size.y - 14.0) * float(y_seed) / 88.0
	return Vector2(x, y)
