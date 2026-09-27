extends SceneTree

const Optics = preload("res://src/experiment_optics.gd")

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error("Playtest smoke: " + message)

func _run() -> void:
	for path: String in ["user://noxsum_playtest_smoke.json", "user://noxsum_playtest_smoke_results.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(405, 900)
	root.add_child(viewport)
	var scene: Control = (load("res://scenes/experiments.tscn") as PackedScene).instantiate()
	scene.nox_campaign = true
	scene.playtest_mode = true
	scene.initial_stage_index = 0
	scene.progress_path = "user://noxsum_playtest_smoke.json"
	scene.playtest_results_path = "user://noxsum_playtest_smoke_results.json"
	viewport.add_child(scene)
	await process_frame
	check(scene.campaign_id == "noxsum_playtest_v0_1", "wrong campaign")
	check(scene.progress_path != "user://noxsum_grant36_v1.json", "Grant save collision")
	check(scene.stages.size() == 40, "did not load all 40 questions")
	check(scene.stage()["id"] == "PT-001", "did not start PT-001")
	check(scene.title_label.text == "PT-001", "blind title leaked metadata")
	check(scene.stage_picker != null and not scene.stage_picker.visible, "blind mode exposed stage picker")
	for index: int in 40:
		scene.load_stage(index)
		check(scene.stage()["id"] == "PT-%03d" % (index + 1), "stage order at " + str(index))
	scene.load_stage(0)
	scene._reveal_playtest_solution()
	check(scene.playtest_revealed and scene.stage_solved, "reveal did not show solution")
	check(scene.posts.size() == scene.stage()["solution"].size(), "reveal post count")
	scene._show_reveal_review()
	check(scene.playtest_review != null and scene.playtest_review.visible, "reaction UI absent")
	if scene.playtest_review != null:
		scene.playtest_review._select_reaction("NARUHODO")
		scene.playtest_review._submit()
	check(scene.stage()["id"] == "PT-002", "rating did not advance")
	check(scene.playtest_results.has("PT-001"), "rating did not save")
	if scene.playtest_results.has("PT-001"):
		check(scene.playtest_results["PT-001"]["reveal_reaction"] == "NARUHODO", "reaction missing")
	check(FileAccess.file_exists(scene.playtest_results_path), "result file absent")
	var solution: Array = scene.stage()["solution"]
	scene.posts.clear()
	scene.post_types.clear()
	var types: Dictionary = scene.stage().get("solution_post_types", {})
	for raw_code: Variant in solution:
		var code: String = str(raw_code)
		var cell_index: int = Optics.cell(code)
		scene.posts.append(cell_index)
		scene.post_types[str(cell_index)] = str(types.get(code, "normal"))
	scene._check_solve()
	check(scene.stage_solved and not scene.playtest_revealed, "normal solution did not clear")
	scene._show_playtest_review()
	await process_frame
	var review_panel: PanelContainer = scene.playtest_review.find_child("PlaytestPanel", true, false) as PanelContainer
	check(Rect2(Vector2.ZERO, Vector2(405, 900)).grow(1.0).encloses(review_panel.get_global_rect()), "405px rating panel overflow")
	for key: String in ["flow_feel", "aha", "frustration", "want_next"]:
		scene.playtest_review._select_score(key, 4)
	scene.playtest_review._submit()
	check(scene.stage()["id"] == "PT-003", "solved rating did not advance")
	check(scene.playtest_results["PT-002"]["flow_feel"] == 4, "solved rating missing")
	scene.load_stage(39)
	scene._reveal_playtest_solution()
	scene._show_reveal_review()
	scene.playtest_review._select_reaction("FLAT")
	scene.playtest_review._submit()
	check(scene.playtest_review.visible, "final save location absent")
	check(scene.playtest_review.find_child("PlaytestResultsPath", true, false) != null, "final path field absent")
	scene.queue_free()
	await process_frame
	var grant: Control = (load("res://scenes/experiments.tscn") as PackedScene).instantiate()
	grant.nox_campaign = true
	grant.progress_path = "user://noxsum_grant36_smoke.json"
	viewport.add_child(grant)
	await process_frame
	check(grant.stages.size() == 36 and grant.stage()["id"] == "GR01", "Grant36 regression")
	check(grant.playtest_review == null, "Grant36 contains playtest UI")
	grant.queue_free()
	await process_frame
	var wide_viewport: SubViewport = SubViewport.new()
	wide_viewport.size = Vector2i(720, 900)
	root.add_child(wide_viewport)
	var wide: Control = (load("res://scenes/experiments.tscn") as PackedScene).instantiate()
	wide.nox_campaign = true
	wide.playtest_mode = true
	wide.progress_path = "user://noxsum_playtest_smoke.json"
	wide.playtest_results_path = "user://noxsum_playtest_smoke_results.json"
	wide_viewport.add_child(wide)
	wide.playtest_review.present_solved("PT-001")
	await process_frame
	var wide_panel: PanelContainer = wide.playtest_review.find_child("PlaytestPanel", true, false) as PanelContainer
	check(Rect2(Vector2.ZERO, Vector2(720, 900)).grow(1.0).encloses(wide_panel.get_global_rect()), "720px rating panel overflow")
	wide.queue_free()
	await process_frame
	for path: String in ["user://noxsum_playtest_smoke.json", "user://noxsum_playtest_smoke_results.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	print("PLAYTEST_SMOKE_OK" if failures == 0 else "PLAYTEST_SMOKE_FAILED: " + str(failures))
	quit(0 if failures == 0 else 1)
