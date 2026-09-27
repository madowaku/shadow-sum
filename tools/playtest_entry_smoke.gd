extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var expected: String = "PT-001"
	var stage_flag: int = args.find("--stage")
	if stage_flag >= 0 and stage_flag + 1 < args.size():
		expected = args[stage_flag + 1]
	var viewport: SubViewport = SubViewport.new()
	viewport.size = Vector2i(405, 900)
	root.add_child(viewport)
	var campaign: Control = (load("res://scenes/campaign.tscn") as PackedScene).instantiate()
	viewport.add_child(campaign)
	await process_frame
	var game: Control = campaign.find_child("Experiments", true, false) as Control
	if game == null or not game.playtest_mode or game.stage()["id"] != expected:
		push_error("Playtest CLI entry failed: expected " + expected)
		quit(1)
		return
	if game.find_child("HomeButton", true, false).visible:
		push_error("Playtest entry exposed HOME")
		quit(1)
		return
	print("PLAYTEST_ENTRY_OK " + expected)
	quit(0)
