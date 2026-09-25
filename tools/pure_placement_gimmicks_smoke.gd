extends SceneTree

const Experiment: GDScript = preload("res://src/experiment_main.gd")
const Campaign: GDScript = preload("res://src/campaign_main.gd")
const Optics: GDScript = preload("res://src/experiment_optics.gd")
const DATA: String = "res://data/pure_placement_gimmicks_v0_1.json"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		push_error("PURE PLACEMENT smoke: " + label)

func _stage(stages: Array, id: String) -> Dictionary:
	for raw_stage: Variant in stages:
		var candidate: Dictionary = raw_stage as Dictionary
		if str(candidate.get("id", "")) == id:
			return candidate
	return {}

func _indices(codes: Array) -> Array:
	var result: Array = []
	for raw_code: Variant in codes:
		result.append(Optics.cell(str(raw_code)))
	return result

func _types(posts: Array) -> Dictionary:
	var result: Dictionary = {}
	for raw_index: Variant in posts:
		result[str(int(raw_index))] = "normal"
	return result

func _target_matches(stage: Dictionary, posts: Array) -> bool:
	var observation: Dictionary = stage["observations"][0]
	var live: Array[int] = Optics.compute_stage_shadow(stage, posts, observation["active_lights"], [], _types(posts))
	return Optics.matches(live, observation["target"])

func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	_check(parsed is Array, "data parses as an array")
	if not (parsed is Array):
		quit(1)
		return
	var stages: Array = parsed as Array
	_check(stages.size() == 12, "PP01-PP12 all load")

	for raw_stage: Variant in stages:
		var stage: Dictionary = raw_stage as Dictionary
		var posts: Array = _indices(stage["solution"])
		_check(_target_matches(stage, posts), str(stage["id"]) + " authored solution reproduces target")
		_check(Optics.solved(stage, posts, [], stage["observations"][0]["active_lights"], _types(posts)),
			str(stage["id"]) + " clears through runtime optics")

	var pp01: Dictionary = _stage(stages, "PP01")
	_check(not pp01.is_empty(), "PP01 exists")
	_check(pp01.get("fixed_posts", []) == ["C3"], "PP01 starts with fixed NOX at C3")

	var pp04: Dictionary = _stage(stages, "PP04")
	var pp04_base: Array = pp04["observations"][0]["active_lights"]
	_check(Optics.effective_lights(pp04, [], pp04_base) == ["TOP", "LEFT"], "PP04 switch is idle while empty")
	_check(Optics.effective_lights(pp04, [Optics.cell("C3")], pp04_base) == ["TOP", "LEFT", "RIGHT"],
		"PP04 placement turns RIGHT light on")

	var pp07: Dictionary = _stage(stages, "PP07")
	_check(Optics.apparatus_occupies(pp07, Optics.cell("C2")), "PP07 blocker owns C2")
	_check(not Optics.solved(pp07, [Optics.cell("C2")], [], pp07["observations"][0]["active_lights"], {"7":"normal"}),
		"NOX cannot occupy blocker cell")
	_check(_target_matches(pp07, [Optics.cell("C3")]), "PP07 blocker removes TOP contribution")

	var pp10: Dictionary = _stage(stages, "PP10")
	_check(Optics.apparatus_occupies(pp10, Optics.cell("C2")), "PP10 mirror owns C2")
	_check(_target_matches(pp10, [Optics.cell("D2")]), "PP10 mirror bends TOP light into D2")

	root.size = Vector2i(405, 900)
	var game: Control = Experiment.new()
	game.placement_gimmicks = true
	game.progress_path = "user://pure_placement_smoke_progress.json"
	root.add_child(game)
	await process_frame
	await process_frame
	_check(game.campaign_id == "pure_placement_gimmicks_v0_1", "experiment flag loads isolated campaign")
	_check(game.stages.size() == 12, "runtime UI loads 12 stages")
	game.load_stage(0)
	await process_frame
	_check(game.posts.has(Optics.cell("C3")) and game.sockets[Optics.cell("C3")].get_child(0).fixed,
		"PP01 fixed NOX is present and marked fixed")
	game.load_stage(3)
	await process_frame
	_check(game.sockets[Optics.cell("C3")].get_child(0).switch_marker, "PP04 switch socket is visually marked")
	game.load_stage(6)
	await process_frame
	_check(game.sockets[Optics.cell("C2")].get_child(0).kind == "blocker", "PP07 blocker renders as apparatus")
	game.load_stage(9)
	await process_frame
	_check(game.sockets[Optics.cell("C2")].get_child(0).kind == "mirror", "PP10 mirror renders as apparatus")
	_check(game.sockets[Optics.cell("C2")].get_child(0).mirror_orientation == "\\", "PP10 mirror orientation reaches renderer")
	game.queue_free()
	await process_frame

	var selector: Control = Campaign.new()
	root.add_child(selector)
	await process_frame
	selector.call("_launch", "placement-gimmicks")
	await process_frame
	await process_frame
	_check(selector.get_child_count() == 1, "developer route creates one campaign")
	if selector.get_child_count() == 1:
		var routed: Control = selector.get_child(0) as Control
		_check(bool(routed.get("placement_gimmicks")), "developer route sets placement-gimmicks flag")
		_check(str(routed.get("campaign_id")) == "pure_placement_gimmicks_v0_1", "developer route loads pure placement identity")
	selector.queue_free()

	print("PURE PLACEMENT smoke: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
