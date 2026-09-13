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

	var script := scene.get_script() as Script
	if script == null or script.resource_path != "res://src/night_skin_main.gd":
		_fail("main scene is not using night_skin_main.gd")
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

	var first_post := scene.post_buttons[0] as Button
	scene._apply_post_button_style(first_post, true)
	if first_post.text != "●":
		_fail("occupied Post lost its physical marker")
		return
	var post_style := first_post.get_theme_stylebox("normal") as StyleBoxFlat
	if post_style == null or post_style.bg_color == NightTokens.GOLD:
		_fail("occupied Post should be dark metal, not a gold tile")
		return

	var margin := scene.get_child(1) as MarginContainer
	var root_box := margin.get_child(0) as VBoxContainer
	var title := root_box.get_child(0) as Label
	if not (title.get_theme_font("font") is SystemFont):
		_fail("display SystemFont was not installed")
		return

	var footer := scene.next_button.get_parent() as HBoxContainer
	if footer == null or footer.get_child_count() != 4:
		_fail("night footer must preserve BACK / RESET / HINT / NEXT")
		return

	# Static skin must not touch puzzle state.
	scene._load_stage(2)
	var before: Array = scene.posts.duplicate(true)
	scene._apply_night_static_skin()
	if scene.posts != before:
		_fail("presentation skin mutated authoritative Posts")
		return

	print("Night skin smoke OK: tokens, glass, metal Posts, typography and four-button footer are presentation-only")
	quit(0)
