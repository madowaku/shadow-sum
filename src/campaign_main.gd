extends Control

# NOXSUM is the public Grant entrance. Earlier experiments remain reachable by CLI.
const NoxHome = preload("res://src/nox_home.gd")

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--dev-selector"):
		_show_selector()
		return
	var selected: String = "nox"
	for argument: String in args:
		if argument.begins_with("--campaign="):
			selected = argument.trim_prefix("--campaign=")
	var option: int = args.find("--campaign")
	if option >= 0 and option + 1 < args.size():
		selected = args[option + 1]
	_launch(selected)

func _clear_screen() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()

func _launch(selected: String) -> void:
	if selected == "nox":
		_show_nox_home()
		return
	if selected == "playtest":
		if not OS.is_debug_build():
			_show_nox_home()
			return
		_clear_screen()
		var playtest: Control = (load("res://scenes/experiments.tscn") as PackedScene).instantiate()
		playtest.nox_campaign = true
		playtest.playtest_mode = true
		playtest.initial_stage_index = 0
		add_child(playtest)
		return

	if selected == "blind-v01":
		_clear_screen()
		var blind_campaign: Control = (load("res://scenes/experiments.tscn") as PackedScene).instantiate()
		blind_campaign.nox_campaign = true
		blind_campaign.blind_playtest = true
		blind_campaign.home_requested.connect(_show_nox_home)
		add_child(blind_campaign)
		return

	_clear_screen()

	var path: String = "res://scenes/main.tscn"
	if selected in [
		"experiments",
		"cause-light",
		"light-height",
		"flat-plate",
		"grant14-v02",
		"grant20-v03",
		"grant36-draft",
		"jev-review"
	]:
		path = "res://scenes/experiments.tscn"

	var campaign: Control = (load(path) as PackedScene).instantiate()

	if selected == "cause-light":
		campaign.cause_light = true
	elif selected == "light-height":
		campaign.light_height = true
	elif selected == "flat-plate":
		campaign.flat_plate = true
	elif selected == "grant14-v02":
		campaign.grant14_v02 = true
	elif selected == "grant20-v03":
		campaign.grant20_v03 = true
	elif selected == "grant36-draft":
		campaign.grant36_draft = true
	elif selected == "jev-review":
		campaign.jev_review = true
	elif selected == "variants":
		campaign.stage_path = "res://data/variant_boards_v0_1.json"
		campaign.progress_path = "user://shadow_sum_variants_v0_1.json"

	add_child(campaign)
func _show_nox_home() -> void:
	_clear_screen()
	var home: Control = NoxHome.new()
	home.start_requested.connect(_start_nox_stage)
	add_child(home)

func _start_nox_stage(index: int) -> void:
	_clear_screen()
	var campaign: Control = (load("res://scenes/experiments.tscn") as PackedScene).instantiate()
	campaign.nox_campaign = true
	campaign.initial_stage_index = index
	campaign.home_requested.connect(_show_nox_home)
	add_child(campaign)

func _show_selector() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	center.add_child(column)
	var labels: Array[String] = ["NOXSUM · GRANT 36", "GRANT18", "G01–G10 EXPERIMENTS", "H01–H06 CAUSE & LIGHT", "LC01–TP04 LIGHT & HEIGHT", "P01–P04 FLAT PLATE", "GRANT14 v0.2", "GRANT20 v0.3", "GR21–GR36 DRAFT PLAYTEST", "JEV REVIEW A/B", "VAR01–VAR06 VARIANT BOARDS"]
	var campaigns: Array[String] = ["nox", "grant18", "experiments", "cause-light", "light-height", "flat-plate", "grant14-v02", "grant20-v03", "grant36-draft", "jev-review", "variants"]
	for index: int in labels.size():
		var button: Button = Button.new()
		button.text = labels[index]
		button.custom_minimum_size = Vector2(300, 52)
		button.pressed.connect(_launch.bind(campaigns[index]))
		column.add_child(button)
