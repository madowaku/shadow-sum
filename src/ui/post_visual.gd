extends Control

const NightTokens = preload("res://src/night_tokens.gd")
const POST_TEXTURE_PATH: String = "res://assets/materials/post/occupied.png"
const POST_GHOST_TEXTURE_PATH: String = "res://assets/materials/post/ghost.png"

var post_texture: Texture2D
var ghost_texture: Texture2D
var occupied := false
var ghost := false
var settled := false

func _ready() -> void:
	post_texture = load(POST_TEXTURE_PATH) as Texture2D
	ghost_texture = load(POST_GHOST_TEXTURE_PATH) as Texture2D
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()

var seat_tween: Tween
var seat_scale: float = 1.0:
	set(next):
		seat_scale = next
		queue_redraw()
var seat_lift: float = 0.0:
	set(next):
		seat_lift = next
		queue_redraw()
var seat_glint: float = 0.0:
	set(next):
		seat_glint = next
		queue_redraw()

func cancel_motion() -> void:
	if seat_tween != null and seat_tween.is_valid():
		seat_tween.kill()
	seat_tween = null
	seat_scale = 1.0
	seat_lift = 0.0
	seat_glint = 0.0

func mechanical_seat() -> void:
	cancel_motion()
	if not occupied or ghost:
		return
	seat_scale = 0.94
	seat_lift = -2.0
	seat_glint = 0.18
	seat_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	seat_tween.tween_property(self, "seat_scale", 1.018, 0.07)
	seat_tween.parallel().tween_property(self, "seat_lift", 0.0, 0.10)
	seat_tween.tween_property(self, "seat_scale", 1.0, 0.07)
	seat_tween.parallel().tween_property(self, "seat_glint", 0.0, 0.07)

func set_state(is_occupied: bool, is_ghost := false, is_settled := false) -> void:
	if not is_occupied:
		cancel_motion()
	occupied = is_occupied
	ghost = is_ghost
	settled = is_settled
	visible = occupied
	queue_redraw()

func _draw() -> void:
	if not occupied:
		return

	draw_set_transform(size * 0.5 + Vector2(0.0, seat_lift), 0.0, Vector2.ONE * seat_scale)
	var center := Vector2.ZERO
	var scale_factor := minf(size.x, size.y) / 48.0
	var body_width := 22.0 * scale_factor
	var body_height := 23.0 * scale_factor
	var top_height := 6.0 * scale_factor
	var left := center.x - body_width * 0.5
	var top_y := center.y - body_height * 0.5
	var bottom_y := center.y + body_height * 0.5

	# A quiet contact shadow makes the part sit inside the socket rather than
	# read as a state icon floating on a button.
	_draw_ellipse(Vector2(center.x, bottom_y + 3.0 * scale_factor), Vector2(body_width * 0.62, top_height * 0.72), Color(0.0, 0.0, 0.0, 0.34))

	var texture_to_draw: Texture2D = ghost_texture if ghost and ghost_texture != null else post_texture
	if texture_to_draw != null:
		var sprite_size: float = minf(size.x, size.y) * 0.76
		var sprite_rect: Rect2 = Rect2(Vector2(-sprite_size * 0.5, -sprite_size * 0.5), Vector2(sprite_size, sprite_size))
		var texture_tint: Color = Color(0.80, 0.96, 1.0, 0.84) if ghost else Color.WHITE
		draw_texture_rect(texture_to_draw, sprite_rect, false, texture_tint)
		if settled:
			_draw_ellipse(Vector2(center.x, sprite_size * 0.40), Vector2(sprite_size * 0.30, sprite_size * 0.08), Color(NightTokens.GOLD_SOFT, 0.20), false, maxf(1.0, scale_factor))
		return

	var side_points := PackedVector2Array([
		Vector2(left, top_y),
		Vector2(left + body_width, top_y),
		Vector2(left + body_width, bottom_y),
		Vector2(left, bottom_y),
	])
	draw_colored_polygon(side_points, NightTokens.METAL_SIDE)

	# Slightly darker lower face gives the tiny cylinder enough volume even at
	# compact 48 px socket size.
	var lower_rect := Rect2(left, center.y, body_width, body_height * 0.5)
	draw_rect(lower_rect, NightTokens.METAL_SIDE_DARK)
	_draw_ellipse(Vector2(center.x, bottom_y), Vector2(body_width * 0.5, top_height * 0.5), NightTokens.METAL_SIDE_DARK)

	_draw_ellipse(Vector2(center.x, top_y), Vector2(body_width * 0.5, top_height * 0.5), NightTokens.METAL_RIM)
	_draw_ellipse(Vector2(center.x, top_y + 0.8 * scale_factor), Vector2(body_width * 0.42, top_height * 0.38), NightTokens.METAL_TOP)
	_draw_ellipse(Vector2(center.x - 2.0 * scale_factor, top_y - 0.2 * scale_factor), Vector2(body_width * 0.22, top_height * 0.14), NightTokens.METAL_SPECULAR.lightened(seat_glint))

	if settled:
		_draw_ellipse(Vector2(center.x, bottom_y + 0.5 * scale_factor), Vector2(body_width * 0.60, top_height * 0.78), Color(NightTokens.GOLD_SOFT, 0.20), false, maxf(1.0, scale_factor))
	if ghost:
		_draw_ellipse(Vector2(center.x, top_y), Vector2(body_width * 0.58, top_height * 0.66), Color(NightTokens.CYAN, 0.24), false, maxf(1.0, scale_factor))

func _draw_ellipse(center: Vector2, radii: Vector2, color: Color, filled := true, width := 1.0) -> void:
	var points := PackedVector2Array()
	var segments := 28
	for i in segments:
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	if filled:
		draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		draw_polyline(points, color, width, true)
