extends Control

# Developer campaigns require explicit arguments; the NOXSUM product uses the final Grant36 campaign.
func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.has("--dev-selector"):
		_show_selector()
		return
	var selected: String = "grant36-v05"
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
	var path: String = "res://scenes/main.tscn" if selected not in ["experiments", "cause-light", "light-height", "flat-plate", "grant14-v02", "grant20-v03", "grant36-v05", "placement-gimmicks"] else "res://scenes/experiments.tscn"
	var campaign: Control = (load(path) as PackedScene).instantiate()
	var requested_stage_index: int = -1
	if get_tree().root.has_meta("shadow_sum_start_stage"):
		requested_stage_index = int(get_tree().root.get_meta("shadow_sum_start_stage"))
		get_tree().root.remove_meta("shadow_sum_start_stage")
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
	elif selected == "grant36-v05":
		campaign.grant36_v05 = true
	elif selected == "placement-gimmicks":
		campaign.placement_gimmicks = true
	if requested_stage_index >= 0 and selected in ["grant20-v03", "grant36-v05"]:
		campaign.set("requested_stage_index", requested_stage_index)
	add_child(campaign)

func _show_selector() -> void:
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column: VBoxContainer = VBoxContainer.new()
	center.add_child(column)
	var labels: Array[String] = ["GRANT18", "G01–G10 EXPERIMENTS", "H01–H06 CAUSE & LIGHT", "LC01–TP04 LIGHT & HEIGHT", "P01–P04 FLAT PLATE", "GRANT14 v0.2", "GRANT20 v0.3", "PP01–PP12 PURE PLACEMENT"]
	var campaigns: Array[String] = ["grant18", "experiments", "cause-light", "light-height", "flat-plate", "grant14-v02", "grant20-v03", "placement-gimmicks"]
	for index: int in labels.size():
		var button: Button = Button.new()
		button.text = labels[index]
		button.custom_minimum_size = Vector2(300, 52)
		button.pressed.connect(_launch.bind(campaigns[index]))
		column.add_child(button)
