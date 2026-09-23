extends Control

# Explicit developer selector; this Grant20 branch boots the current candidate by default.
func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--dev-selector"):
		_show_selector()
		return
	var selected: String = "grant20-v03"
	for argument: String in args:
		if argument.begins_with("--campaign="):
			selected = argument.trim_prefix("--campaign=")
	var option: int = args.find("--campaign")
	if option >= 0 and option + 1 < args.size():
		selected = args[option + 1]
	_launch(selected)

func _launch(selected: String) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	var path: String = "res://scenes/main.tscn" if selected not in ["experiments", "cause-light", "light-height", "flat-plate", "grant14-v02", "grant20-v03", "jev-review", "grant36-v05"] else "res://scenes/experiments.tscn"
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
	elif selected == "jev-review":
		campaign.jev_review = true
	elif selected == "grant36-v05":
		campaign.grant36_v05 = true
	add_child(campaign)

func _show_selector() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	center.add_child(column)
	var labels: Array[String] = ["GRANT18", "G01–G10 EXPERIMENTS", "H01–H06 CAUSE & LIGHT", "LC01–TP04 LIGHT & HEIGHT", "P01–P04 FLAT PLATE", "GRANT14 v0.2", "GRANT20 v0.3", "JEV REVIEW A/B"]
	var campaigns: Array[String] = ["grant18", "experiments", "cause-light", "light-height", "flat-plate", "grant14-v02", "grant20-v03", "jev-review"]
	for index: int in labels.size():
		var button: Button = Button.new()
		button.text = labels[index]
		button.custom_minimum_size = Vector2(300, 52)
		button.pressed.connect(_launch.bind(campaigns[index]))
		column.add_child(button)
