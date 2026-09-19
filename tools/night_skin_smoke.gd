extends SceneTree

const NightTokens = preload("res://src/night_tokens.gd")

func _initialize() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("Night skin smoke: %s" % message)
	quit(1)

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("could not load main scene")
		return

	var scene := packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await process_frame

	# Night Skin is now a presentation contract inherited by later material
	# layers. Do not pin the top-level scene script to night_skin_main.gd.
	if not scene.has_method("_apply_night_static_skin"):
		_fail("main scene no longer inherits the night skin contract")
		return

	var backdrop := scene.get_child(0) as ColorRect
	if backdrop == null or backdrop.color != NightTokens.BG_BASE:
		_fail("night background token was not applied")
		return

	var clear_style := scene._shadow_style(0, false, true) as StyleBoxFlat
	var unknown_style := scene._shadow_style(0, true, true) as StyleBoxFlat
	if clear_style == null or clear_style.bg_color != NightTokens.SHADOW_0:
		_fail("clear glass token was not applied")
		return
	if unknown_style == null or unknown_style.bg_color != NightTokens.SHADOW_UNKNOWN:
		_fail("unknown fog token was not applied")
		return
	if unknown_style.bg_color == clear_style.bg_color or unknown_style.border_width_left < 2:
		_fail("unknown cells are not visually distinct from observed zero")
		return

	var margin := scene.get_child(1) as MarginContainer
	var root_box := margin.get_child(0) as VBoxContainer
	var title := root_box.get_child(0) as Label
	if not (title.get_theme_font("font") is SystemFont):
		_fail("display SystemFont was not installed")
		return

	var footer := scene.next_button.get_parent() as HBoxContainer
	if footer == null or footer.get_child_count() != 5:
		_fail("night footer must preserve BACK / RESET / UNDO / HINT / NEXT")
		return

	var expected: Array = [scene.back_button, scene.reset_button, scene.undo_button, scene.hint_button, scene.next_button]
	for index: int in expected.size():
		if footer.get_child(index) != expected[index]:
			_fail("footer control order changed")
			return

	# Static skin must not touch puzzle state, even when a later material layer
	# owns the actual Post/Socket drawing.
	scene._load_stage(2)
	var before: Array = scene.posts.duplicate(true)
	scene._apply_night_static_skin()
	if scene.posts != before:
		_fail("presentation skin mutated authoritative Posts")
		return

	print("Night skin smoke OK: tokens, glass states, typography and five-button footer survive later presentation layers")
	quit(0)
