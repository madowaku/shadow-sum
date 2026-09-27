extends SceneTree

const Experiment: GDScript = preload("res://src/experiment_main.gd")
const Campaign: GDScript = preload("res://src/campaign_main.gd")
const Optics: GDScript = preload("res://src/experiment_optics.gd")
const DATA: String = "res://data/gimmick_probe_v0_3.json"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		push_error("GIMMICK PROBE smoke: " + label)

func _typed_solution(stage: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var declared: Dictionary = stage.get("solution_post_types", {})
	for raw_code: Variant in stage.get("solution", []):
		var code: String = str(raw_code)
		result[str(Optics.cell(code))] = str(declared.get(code, "normal"))
	return result

func _solution_posts(stage: Dictionary) -> Array:
	var result: Array = []
	for raw_code: Variant in stage.get("solution", []):
		result.append(Optics.cell(str(raw_code)))
	return result

func _run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	_check(parsed is Array, "probe data parses")
	if not (parsed is Array):
		quit(1)
		return
	var stages: Array = parsed as Array
	_check(stages.size() == 4, "four probes load")

	for raw_stage: Variant in stages:
		var stage: Dictionary = raw_stage as Dictionary
		var posts: Array = _solution_posts(stage)
		var types: Dictionary = _typed_solution(stage)
		var lights: Array = stage["observations"][0]["active_lights"]
		_check(Optics.solved(stage, posts, [], lights, types), str(stage["id"]) + " authored solution clears in Godot optics")

	root.size = Vector2i(405, 900)
	var game: Control = Experiment.new()
	game.gimmick_probes = true
	game.progress_path = "user://noxsum_gimmick_probe_smoke.json"
	root.add_child(game)
	await process_frame
	await process_frame
	_check(game.campaign_id == "gimmick_probe_v0_3", "isolated probe campaign loads")
	_check(game.stages.size() == 4, "runtime has four probes")

	game.load_stage(0)
	await process_frame
	_check(game.plate_inventory.visible, "LAN-01 lantern inventory is visible")
	_check(game.plate_inventory.get_child(0).post_type == "lantern", "utility inventory renders as lantern")

	game.load_stage(1)
	await process_frame
	game.selected_post_type = "lantern"
	game.toggle_post(Optics.cell("D3"))
	game.selected_post_type = "normal"
	game.toggle_post(Optics.cell("D2"))
	await process_frame
	_check(game.stage_solved, "LAN-02 solves through live placement")

	game.load_stage(2)
	await process_frame
	var mirror_index: int = Optics.cell("C3")
	_check(game.post_types[str(mirror_index)] == "mirror_slash", "MIR-01 starts slash")
	game.rotate_mirror(mirror_index)
	_check(game.post_types[str(mirror_index)] == "mirror_backslash", "fixed mirror rotates on demand")
	game.rotate_mirror(mirror_index)
	_check(game.post_types[str(mirror_index)] == "mirror_slash", "mirror rotates back")

	game.load_stage(3)
	await process_frame
	game.selected_post_type = "normal"
	game.toggle_post(Optics.cell("E4"))
	await process_frame
	_check(not game.stage_solved, "MIR-02 E4 alone leaves slash orientation wrong")
	game.rotate_mirror(mirror_index)
	await process_frame
	_check(game.stage_solved, "MIR-02 ZERO clue resolves mirror orientation")

	game.queue_free()
	await process_frame

	var selector: Control = Campaign.new()
	root.add_child(selector)
	await process_frame
	selector.call("_launch", "gimmick-probes")
	await process_frame
	await process_frame
	_check(selector.get_child_count() == 1, "developer route creates one probe campaign")
	if selector.get_child_count() == 1:
		var routed: Control = selector.get_child(0) as Control
		_check(bool(routed.get("gimmick_probes")), "developer route sets probe flag")
		_check(str(routed.get("campaign_id")) == "gimmick_probe_v0_3", "developer route loads probe identity")
	selector.queue_free()

	print("GIMMICK PROBE smoke: %d failures" % failures.size())
	quit(1 if not failures.is_empty() else 0)
