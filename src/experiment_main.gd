extends Control

const Optics = preload("res://src/experiment_optics.gd")
const Surface = preload("res://src/ui/experiment_surface.gd")
const T = preload("res://src/night_tokens.gd")
const Story = preload("res://src/nox_story.gd")
const NoxSettings = preload("res://src/nox_settings.gd")
const NoxLocale = preload("res://src/nox_locale.gd")
const NoxStageLayout = preload("res://src/ui/nox_stage_layout.gd")
const NoxObservations = preload("res://src/nox_observations.gd")

signal home_requested
const DATA: String = "res://data/grant_experiments_v0_1.json"
const SAVE: String = "user://shadow_sum_grant_experiments_v0_1.json"
const JEV_REVIEW_POOL: String = "res://generated/grant36_candidates.json"
const JEV_REVIEW_SEQUENCE: Array = [
	{"id": "RV01", "slot": "GR28", "variant": "A", "candidate": "three_plate_light_shutter-005"},
	{"id": "RV02", "slot": "GR28", "variant": "B", "candidate": "three_plate_light_shutter-006"},
	{"id": "RV03", "slot": "GR30", "variant": "CHECK", "candidate": "fog_plate_shutter-010"},
	{"id": "RV04", "slot": "GR31", "variant": "A", "candidate": "fog_height_light-007"},
	{"id": "RV05", "slot": "GR31", "variant": "B", "candidate": "fog_height_light-006"},
	{"id": "RV06", "slot": "GR34", "variant": "A", "candidate": "dense_height_plate_shutter-017"},
	{"id": "RV07", "slot": "GR34", "variant": "B", "candidate": "dense_height_plate_shutter-004"},
	{"id": "RV08", "slot": "GR36", "variant": "A", "candidate": "finale-015"},
	{"id": "RV09", "slot": "GR36", "variant": "B", "candidate": "finale-010"}
]
var progress_path: String = SAVE
var cause_light: bool = false
var light_height: bool = false
var flat_plate: bool = false
var grant14_v02: bool = false
var grant20_v03: bool = false
var nox_campaign: bool = false
var compact_nox_layout: bool = false
var initial_stage_index: int = -1
@export var grant36_draft: bool = false
var stage_picker: OptionButton
var jev_review: bool = false
var campaign_id: String = "experiments_v0_1"
var observation_buttons: Array[Button] = []
var stages: Array = []
var stage_index: int = 0
var posts: Array = []
var post_types: Dictionary = {}
var board_mask: PackedByteArray = PackedByteArray()
var shutters: Array = []
var lights: Array = []
var observation_index: int = 0
var completed: Dictionary = {}
var clear_seal: Control
var stage_solved: bool = false
var hint_level: int = 0
var hint_max_level: int = 0
var drag_ghost: Control
var hint_records: Dictionary = {}
var history: Array = []
var motions: Array[Tween] = []
var shadow_motion: Tween
var title_label: Label
var count_label: Label
var observation_label: Label
var status_label: Label
var pose_description_label: Label
var context_preview_key: String = ""
var context_restore_text: String = ""
var nox_chapter_label: Label
var next_button: Button
var back_button: Button
var undo_button: Button
var hint_button: Button
var inventory: Button
var tall_inventory: Button
var plate_inventory: Button
var rail: HBoxContainer
var lamps: Dictionary = {}
var rail_buttons: Array[Button] = []
var sockets: Array[Button] = []
var target_cells: Array[Control] = []
var live_cells: Array[Control] = []
var current_shadow: Array[int] = []
var drag_kind: String = ""
var drag_source: int = -1
var drag_post_type: String = "normal"
var selected_post_type: String = "normal"
var pose_chosen: bool = false
var stage_guide: Control
var finale_overlay: Control
var drag_start: Vector2
var drag_moved: bool = false
var drag_preview: int = -1
var pointer_id: int = -2
var idle_seconds: float = 0.0
var idle_pulsed: bool = false
var elapsed: float = 0.0
var first_action: String = ""
var resets: int = 0
var action_count: int = 0
var sound_player: AudioStreamPlayer

func _ready() -> void:
	var data_path: String = DATA
	if cause_light:
		campaign_id = "cause_light_v0_1"
		data_path = "res://data/cause_light_h01_h06_v0_1.json"
		if progress_path == SAVE:
			progress_path = "user://shadow_sum_cause_light_v0_1.json"
	elif light_height:
		campaign_id = "light_height_v0_1"
		data_path = "res://data/light_height_lc01_tp04_v0_1.json"
		if progress_path == SAVE:
			progress_path = "user://shadow_sum_light_height_v0_1.json"
	elif flat_plate:
		campaign_id = "flat_plate_v0_1"
		data_path = "res://data/flat_plate_p01_p04_v0_1.json"
		if progress_path == SAVE:
			progress_path = "user://shadow_sum_flat_plate_v0_1.json"
	elif grant14_v02:
		campaign_id = "grant14_v0_2"
		data_path = "res://data/grant14_v0_2.json"
		if progress_path == SAVE:
			progress_path = "user://shadow_sum_grant14_v0_2.json"
	elif grant20_v03:
		campaign_id = "grant20_v0_3"
		data_path = "res://data/grant20_v0_3.json"
		if progress_path == SAVE:
			progress_path = "user://shadow_sum_grant20_v0_3.json"
	elif nox_campaign:
		campaign_id = "noxsum_grant36_v1"
		data_path = "res://data/noxsum_grant36_v1.json"
		if progress_path == SAVE:
			progress_path = "user://noxsum_grant36_v1.json"
	elif grant36_draft:
		campaign_id = "grant36_v0_4_draft"
		data_path = "res://data/grant36_v0_4_draft.json"
		if progress_path == SAVE:
			progress_path = "user://shadow_sum_grant36_v0_4_draft.json"
	elif jev_review:
		campaign_id = "jev_review_v0_1"
		if progress_path == SAVE:
			progress_path = "user://shadow_sum_jev_review_v0_1.json"
	if jev_review:
		stages = _build_jev_review_stages()
	else:
		stages = JSON.parse_string(FileAccess.get_file_as_string(data_path))
	_build_ui()
	_load_progress()
	var resume: int = 20 if grant36_draft else 0
	if initial_stage_index >= 0:
		resume = clampi(initial_stage_index, 0, stages.size() - 1)
	while initial_stage_index < 0 and resume < stages.size() - 1 and completed.has(stages[resume]["id"]):
		resume += 1
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var stage_flag: int = args.find("--stage")
	if stage_flag >= 0 and stage_flag + 1 < args.size():
		for index: int in stages.size():
			if stages[index]["id"] == args[stage_flag + 1]:
				resume = index
	load_stage(resume)
	if nox_campaign and completed.is_empty() and not bool(NoxSettings.read_value("tutorial_seen", false)):
		call_deferred("_show_first_guide")

func _build_jev_review_stages() -> Array:
	var raw_pool: Variant = JSON.parse_string(FileAccess.get_file_as_string(JEV_REVIEW_POOL))
	if typeof(raw_pool) != TYPE_DICTIONARY:
		push_error("Jev review pool is missing or invalid: " + JEV_REVIEW_POOL)
		return []
	var pool: Dictionary = raw_pool
	var lookup: Dictionary = {}
	for raw_candidate: Variant in pool.get("candidates", []):
		var candidate: Dictionary = raw_candidate
		lookup[str(candidate.get("id", ""))] = candidate
	var review_stages: Array = []
	for raw_spec: Variant in JEV_REVIEW_SEQUENCE:
		var spec: Dictionary = raw_spec
		var candidate_id: String = str(spec["candidate"])
		if not lookup.has(candidate_id):
			push_error("Jev review candidate missing: " + candidate_id)
			continue
		review_stages.append(_review_stage_from_candidate(spec, lookup[candidate_id]))
	return review_stages

func _review_stage_from_candidate(spec: Dictionary, candidate: Dictionary) -> Dictionary:
	var profile: Dictionary = candidate["profile"]
	var world: Dictionary = candidate["solution"]
	var solution: Array = []
	var solution_post_types: Dictionary = {}
	var solution_tall: Array = []
	for raw_object: Variant in world["objects"]:
		var object: Dictionary = raw_object
		var code: String = str(object["cell"])
		var kind: String = str(object["type"])
		solution.append(code)
		solution_post_types[code] = kind
		if kind == "tall":
			solution_tall.append(code)

	var target: Dictionary = {}
	var complete_shadow: Array = candidate["complete_shadow"]
	var visible_mask: Array = candidate["visible_mask"]
	for index: int in 25:
		if bool(visible_mask[index]):
			var code: String = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
			target[code] = int(complete_shadow[index])

	var light_count: int = int(profile.get("light_count", 0))
	var fixed_lights: Array = profile.get("fixed_lights", []).duplicate()
	var installed_lights: Array = ["TOP", "LEFT", "RIGHT", "BOTTOM"] if light_count > 0 else fixed_lights.duplicate()
	var review_stage: Dictionary = {
		"id": str(spec["id"]),
		"title": "%s / VARIANT %s" % [str(spec["slot"]), str(spec["variant"])],
		"posts": int(profile.get("normal", 0)) + int(profile.get("tall", 0)) + int(profile.get("plate", 0)),
		"normal_posts": int(profile.get("normal", 0)),
		"tall_posts": int(profile.get("tall", 0)),
		"plate_posts": int(profile.get("plate", 0)),
		"installed_lights": installed_lights,
		"solution": solution,
		"solution_post_types": solution_post_types,
		"observations": [{"id": "A", "active_lights": [] if light_count > 0 else fixed_lights.duplicate(), "target": target}],
		"expected_states": int(profile.get("expected_states", 0)),
		"expected_solutions": 1,
		"generator_candidate_id": str(candidate["id"]),
		"generator_profile": profile.duplicate(true),
		"reasoning_signature": str(candidate.get("reasoning_signature", "")),
		"solution_complete_shadow": complete_shadow.duplicate(),
		"review_only": true,
		"review_slot": str(spec["slot"]),
		"review_variant": str(spec["variant"])
	}
	if not solution_tall.is_empty():
		review_stage["solution_tall"] = solution_tall
	if int(profile.get("plate", 0)) > 0:
		review_stage["rotatable_plate"] = true
	if light_count > 0:
		review_stage["free_light_selection"] = true
		review_stage["active_light_count"] = light_count
		review_stage["initial_lights"] = []
		review_stage["solution_lights"] = world["lights"].duplicate()
	if bool(profile.get("shutter", false)):
		review_stage["movable_shutter"] = true
		review_stage["solution_shutter"] = int(world["shutter"])
	var fog_cells: Array = candidate.get("fog_cells", []).duplicate()
	if not fog_cells.is_empty():
		review_stage["fog_cells"] = fog_cells
	return review_stage

func _build_ui() -> void:
	if nox_campaign:
		NoxStageLayout.build(self)
		return
	compact_nox_layout = nox_campaign and get_viewport_rect().size.y <= 820.0
	var background: ColorRect = ColorRect.new()
	background.color = T.BG_BASE
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	theme = Theme.new()
	theme.default_font_size = 12
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = T.BG_BUTTON if state != "hover" else T.BG_PANEL
		style.border_color = T.CYAN if state == "focus" else T.LINE_MEDIUM
		style.set_border_width_all(2 if state == "focus" else 1)
		style.set_corner_radius_all(8)
		if state == "focus":
			style.draw_center = false
		theme.set_stylebox(state, "Button", style)
		theme.set_stylebox(state, "OptionButton", style)
	theme.set_color("font_color", "Button", T.TEXT_SECONDARY)
	theme.set_color("font_color", "OptionButton", T.TEXT_SECONDARY)
	theme.set_color("font_disabled_color", "Button", T.TEXT_MUTED)
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 6 if compact_nox_layout else (8 if cause_light or grant14_v02 or grant20_v03 or grant36_draft or nox_campaign or jev_review else 16))
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 2 if compact_nox_layout else (4 if cause_light or grant14_v02 or grant20_v03 or grant36_draft or nox_campaign or jev_review else 8))
	margin.add_child(column)
	_label(column, "NOXSUM" if nox_campaign else "SHADOW SUM", 25, T.TEXT_PRIMARY)
	var campaign_label: String = "G R A N T   /   E X P E R I M E N T S"
	if cause_light:
		campaign_label = "C A U S E   &   L I G H T"
	elif light_height:
		campaign_label = "L I G H T   &   H E I G H T"
	elif flat_plate:
		campaign_label = "F L A T   P L A T E"
	elif grant14_v02:
		campaign_label = "G R A N T   1 4   /   v 0 . 2"
	elif grant20_v03:
		campaign_label = "G R A N T   2 0   /   v 0 . 3"
	elif nox_campaign:
		campaign_label = "RECONSTRUCT NOX'S NIGHT"
	elif grant36_draft:
		campaign_label = "G R A N T   3 6   /   D R A F T   P L A Y T E S T"
	elif jev_review:
		campaign_label = "D E E P   C A L I B R A T I O N   /   A B"
	_label(column, campaign_label, 10, T.TEXT_MUTED)
	if grant36_draft or nox_campaign:
		var picker_row: HBoxContainer = HBoxContainer.new()
		picker_row.alignment = BoxContainer.ALIGNMENT_CENTER
		picker_row.add_theme_constant_override("separation", 8)
		column.add_child(picker_row)
		_label(picker_row, "TRACE" if nox_campaign else "TEST STAGE", 10, T.TEXT_MUTED)
		stage_picker = OptionButton.new()
		stage_picker.name = "TracePicker" if nox_campaign else "DraftStagePicker"
		stage_picker.custom_minimum_size = Vector2(170, 28 if compact_nox_layout else 32)
		stage_picker.tooltip_text = "Revisit any of NOX's 36 moments." if nox_campaign else "Jump to any draft stage. GR01–GR20 are available for comparison."
		for index: int in stages.size():
			var entry: Dictionary = stages[index]
			stage_picker.add_item("%02d  %s" % [index + 1, Story.title(index)] if nox_campaign else str(entry["id"]) + ("  ·  FOG" if entry.has("fog_cells") else ""))
		stage_picker.item_selected.connect(load_stage)
		picker_row.add_child(stage_picker)
		stage_picker.get_popup().max_size = Vector2i(0, 540)
		if nox_campaign:
			var home_button: Button = _button("HOME", Vector2(64, 28 if compact_nox_layout else 32))
			home_button.name = "HomeButton"
			home_button.pressed.connect(func() -> void: home_requested.emit())
			picker_row.add_child(home_button)
	title_label = _label(column, "", 15, T.GOLD)
	count_label = _label(column, "", 12, T.TEXT_SECONDARY)
	observation_label = _label(column, "", 11, T.TEXT_MUTED)
	if cause_light:
		var observations: HBoxContainer = HBoxContainer.new()
		observations.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(observations)
		for index: int in 2:
			var button: Button = _button("OBSERVATION " + String.chr(65 + index), Vector2(144, 44))
			button.pressed.connect(select_observation.bind(index))
			observations.add_child(button)
			observation_buttons.append(button)
	var screens: HBoxContainer = HBoxContainer.new()
	screens.alignment = BoxContainer.ALIGNMENT_CENTER
	screens.add_theme_constant_override("separation", 16)
	column.add_child(screens)
	var screen_names: Array[String] = ["RECORDED", "RECREATED"]
	if not nox_campaign:
		screen_names = ["TARGET", "CURRENT"]
	for screen_name: String in screen_names:
		var screen_column: VBoxContainer = VBoxContainer.new()
		screens.add_child(screen_column)
		_label(screen_column, screen_name, 10, T.GOLD if screen_name == screen_names[0] else T.CYAN)
		var grid: GridContainer = GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 2)
		grid.add_theme_constant_override("v_separation", 2)
		screen_column.add_child(grid)
		for index: int in 25:
			var holder: Control = Control.new()
			holder.custom_minimum_size = Vector2(22, 22) if compact_nox_layout else (Vector2(26, 26) if cause_light or grant14_v02 or grant20_v03 or grant36_draft or nox_campaign or jev_review else Vector2(28, 28))
			grid.add_child(holder)
			var surface: Control = Surface.new()
			surface.kind = "shadow"
			surface.nox_mode = nox_campaign
			holder.add_child(surface)
			if screen_name == screen_names[0]:
				target_cells.append(surface)
			else:
				live_cells.append(surface)
	var top_center: CenterContainer = CenterContainer.new()
	column.add_child(top_center)
	top_center.add_child(_lamp("TOP"))
	var rail_center: CenterContainer = CenterContainer.new()
	column.add_child(rail_center)
	rail = HBoxContainer.new()
	rail.add_theme_constant_override("separation", 2)
	rail_center.add_child(rail)
	for slot: int in 5:
		var button: Button = _button("", Vector2(46, 36) if compact_nox_layout else Vector2(48, 44))
		button.tooltip_text = "Shutter " + String.chr(65 + slot)
		button.gui_input.connect(_start_pointer.bind("shutter", slot))
		rail.add_child(button)
		var surface: Control = Surface.new()
		surface.kind = "shutter"
		surface.slot_label = String.chr(65 + slot)
		button.add_child(surface)
		rail_buttons.append(button)
	var table: HBoxContainer = HBoxContainer.new()
	table.alignment = BoxContainer.ALIGNMENT_CENTER
	table.add_theme_constant_override("separation", 8)
	column.add_child(table)
	table.add_child(_lamp("LEFT"))
	var board: GridContainer = GridContainer.new()
	board.columns = 5
	board.add_theme_constant_override("h_separation", 2)
	board.add_theme_constant_override("v_separation", 2)
	table.add_child(board)
	for index: int in 25:
		var button: Button = _button("", Vector2(42, 42) if compact_nox_layout else Vector2(48, 48))
		button.tooltip_text = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
		button.gui_input.connect(_start_pointer.bind("post", index))
		board.add_child(button)
		var socket_surface: Control = Surface.new()
		socket_surface.nox_mode = nox_campaign
		button.add_child(socket_surface)
		sockets.append(button)
	table.add_child(_lamp("RIGHT"))
	var bottom_center: CenterContainer = CenterContainer.new()
	column.add_child(bottom_center)
	bottom_center.add_child(_lamp("BOTTOM"))
	_label(column, "RETRACE NOX'S POSITIONS" if nox_campaign else "PLACEMENT BOARD", 10, T.TEXT_MUTED)
	var inventory_center: CenterContainer = CenterContainer.new()
	column.add_child(inventory_center)
	var inventory_row: HBoxContainer = HBoxContainer.new()
	inventory_row.add_theme_constant_override("separation", 10)
	inventory_center.add_child(inventory_row)
	inventory = _button("", Vector2(58, 36) if compact_nox_layout else Vector2(64, 44))
	inventory.tooltip_text = "NOX sitting" if nox_campaign else "Normal Post inventory"
	inventory.gui_input.connect(_start_pointer.bind("post", -1))
	inventory_row.add_child(inventory)
	var inventory_surface: Control = Surface.new()
	inventory_surface.kind = "inventory"
	inventory_surface.nox_mode = nox_campaign
	inventory.add_child(inventory_surface)
	tall_inventory = _button("", Vector2(58, 36) if compact_nox_layout else Vector2(64, 44))
	tall_inventory.tooltip_text = "NOX standing" if nox_campaign else "Tall Post inventory"
	tall_inventory.gui_input.connect(_start_pointer.bind("post", -2))
	inventory_row.add_child(tall_inventory)
	var tall_inventory_surface: Control = Surface.new()
	tall_inventory_surface.kind = "inventory"
	tall_inventory_surface.nox_mode = nox_campaign
	tall_inventory_surface.tall = true
	tall_inventory.add_child(tall_inventory_surface)
	tall_inventory.visible = false
	plate_inventory = _button("", Vector2(58, 36) if compact_nox_layout else Vector2(64, 44))
	plate_inventory.tooltip_text = "NOX walking · tap to turn" if nox_campaign else "Flat Plate inventory"
	plate_inventory.gui_input.connect(_start_pointer.bind("post", -3))
	inventory_row.add_child(plate_inventory)
	var plate_inventory_surface: Control = Surface.new()
	plate_inventory_surface.kind = "inventory"
	plate_inventory_surface.nox_mode = nox_campaign
	plate_inventory_surface.post_type = "plate_v"
	plate_inventory.add_child(plate_inventory_surface)
	plate_inventory.visible = false
	if nox_campaign:
		var memory_panel: PanelContainer = PanelContainer.new()
		memory_panel.name = "NightLog"
		memory_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var memory_style: StyleBoxFlat = StyleBoxFlat.new()
		memory_style.bg_color = T.BG_ELEVATED
		memory_style.border_color = T.LINE_SOFT
		memory_style.set_border_width_all(1)
		memory_style.set_corner_radius_all(12)
		memory_panel.add_theme_stylebox_override("panel", memory_style)
		column.add_child(memory_panel)
		var memory_margin: MarginContainer = MarginContainer.new()
		for side: String in ["left", "right", "top", "bottom"]:
			memory_margin.add_theme_constant_override("margin_" + side, 6 if compact_nox_layout else 10)
		memory_panel.add_child(memory_margin)
		var memory_row: HBoxContainer = HBoxContainer.new()
		memory_row.add_theme_constant_override("separation", 10)
		memory_margin.add_child(memory_row)
		var resting_nox: TextureRect = TextureRect.new()
		resting_nox.name = "RestingNox"
		resting_nox.texture = preload("res://assets/nox/v0.1/board/nox_sleep.png")
		resting_nox.custom_minimum_size = Vector2(58, 46) if compact_nox_layout else Vector2(72, 62)
		resting_nox.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		resting_nox.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		resting_nox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		memory_row.add_child(resting_nox)
		var memory_copy: VBoxContainer = VBoxContainer.new()
		memory_copy.alignment = BoxContainer.ALIGNMENT_CENTER
		memory_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		memory_copy.add_theme_constant_override("separation", 4)
		memory_row.add_child(memory_copy)
		nox_chapter_label = _label(memory_copy, "", 10, T.GOLD)
		nox_chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		status_label = _label(memory_copy, "", 12, T.TEXT_SECONDARY)
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		status_label = _label(column, "", 12, T.TEXT_SECONDARY)
		status_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	status_label.custom_minimum_size.y = 30 if compact_nox_layout else 36
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var footer: HBoxContainer = HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 6)
	column.add_child(footer)
	var footer_size: Vector2 = Vector2(54, 38) if compact_nox_layout else Vector2(56, 44)
	back_button = _button("BACK", footer_size)
	back_button.pressed.connect(func() -> void: load_stage(maxi(0, stage_index - 1)))
	footer.add_child(back_button)
	var reset_button: Button = _button("RESET", footer_size)
	reset_button.pressed.connect(reset_stage)
	footer.add_child(reset_button)
	undo_button = _button("UNDO", footer_size)
	undo_button.pressed.connect(undo_move)
	footer.add_child(undo_button)
	hint_button = _button("CLUE" if nox_campaign else "WHISPER", Vector2(66, 38) if compact_nox_layout else Vector2(76, 44))
	hint_button.pressed.connect(whisper)
	footer.add_child(hint_button)
	next_button = _button("NEXT", footer_size)
	next_button.pressed.connect(next_stage)
	footer.add_child(next_button)
	drag_ghost = Surface.new()
	drag_ghost.kind = "inventory"
	drag_ghost.nox_mode = nox_campaign
	drag_ghost.occupied = true
	drag_ghost.visible = false
	add_child(drag_ghost)
	drag_ghost.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	drag_ghost.size = Vector2(48, 48)
	clear_seal = preload("res://src/ui/clear_seal.gd").new()
	add_child(clear_seal)
	sound_player = AudioStreamPlayer.new()
	add_child(sound_player)

func _label(parent: Node, text_value: String, font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(text_value: String, minimum: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text_value
	button.custom_minimum_size = minimum
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return button

func _lamp(direction: String) -> Button:
	var button: Button = _button("", Vector2(36, 36) if compact_nox_layout else Vector2(44, 44))
	button.tooltip_text = direction
	button.pressed.connect(tap_light.bind(direction))
	var surface: Control = Surface.new()
	surface.kind = "lamp"
	button.add_child(surface)
	lamps[direction] = button
	return button

func stage() -> Dictionary:
	return stages[stage_index]

func load_stage(index: int) -> void:
	_cancel_motions()
	stage_index = clampi(index, 0, stages.size() - 1)
	if stage_picker != null:
		stage_picker.select(stage_index)
	posts.clear()
	post_types.clear()
	board_mask = Optics.board_shape_mask(stage())
	if board_mask.size() != 25:
		push_error("Invalid boardShape mask in " + str(stage().get("id", "unknown stage")))
		board_mask.resize(25)
		board_mask.fill(0)
	for code: String in stage().get("fixed_posts", []):
		var fixed_index: int = Optics.cell(code)
		if fixed_index < 0 or fixed_index >= 25 or not _socket_enabled(fixed_index):
			push_error("Fixed Post has no board socket: " + str(stage().get("id", "unknown stage")) + " " + code)
			continue
		posts.append(fixed_index)
		var fixed_type: String = str(stage().get("fixed_post_types", {}).get(code, "normal"))
		if stage().get("tall", false) or stage().get("fixed_tall_posts", []).has(code):
			fixed_type = "tall"
		post_types[str(fixed_index)] = fixed_type
	shutters = []
	for slot: Variant in stage().get("fixed_shutters", []):
		shutters.append(int(slot))
	if stage().get("movable_shutter", false):
		shutters = [0]
	observation_index = 0
	lights = stage().get("initial_lights", []).duplicate() if stage().get("free_light_selection", false) else stage()["observations"][0]["active_lights"].duplicate()
	selected_post_type = "normal"
	pose_chosen = false
	if stage().get("tall", false) or (int(stage().get("normal_posts", 1)) == 0 and int(stage().get("tall_posts", 0)) > 0):
		selected_post_type = "tall"
	elif int(stage().get("normal_posts", 0)) == 0 and int(stage().get("tall_posts", 0)) == 0 and int(stage().get("plate_posts", 0)) > 0:
		selected_post_type = "plate_h"
	drag_post_type = selected_post_type
	stage_solved = false
	hint_level = 0
	hint_max_level = 0
	drag_ghost.visible = false
	history.clear()
	drag_kind = ""
	pointer_id = -2
	drag_preview = -1
	idle_seconds = 0
	idle_pulsed = false
	elapsed = 0
	first_action = ""
	resets = 0
	action_count = 0
	context_preview_key = ""
	context_restore_text = ""
	status_label.text = ""
	next_button.disabled = true
	_refresh(false)
	if nox_campaign:
		nox_chapter_label.text = ("記録 %02d  /  %s" if NoxLocale.is_japanese() else "PLATE %02d  /  %s") % [stage_index + 1, Story.chapter_name(stage_index, NoxLocale.language())]
		status_label.text = Story.milestone_note(stage_index, NoxLocale.language())
		if status_label.text.is_empty():
			status_label.text = NoxLocale.copy("Observe the record. Let every shadow agree.")
	if lights.has("BOTTOM") and not (nox_campaign and NoxSettings.reduced_motion()):
		var bottom: Control = lamps["BOTTOM"].get_child(0)
		bottom.glow = 0
		var ignition: Tween = create_tween()
		motions.append(ignition)
		ignition.tween_property(bottom, "glow", 1.0, 0.3)

func _cancel_motions() -> void:
	if clear_seal != null:
		clear_seal.reset()
	if finale_overlay != null and finale_overlay.visible:
		finale_overlay.dismiss()
	if status_label != null:
		status_label.add_theme_font_size_override("font_size", 13 if nox_campaign else 12)
		status_label.modulate = Color.WHITE
		status_label.remove_theme_color_override("font_color")
	if next_button != null:
		next_button.scale = Vector2.ONE
		next_button.text = NoxLocale.copy("NEXT") if nox_campaign else "NEXT"
		next_button.remove_theme_color_override("font_color")
	for motion: Tween in motions:
		if motion.is_valid():
			motion.kill()
	motions.clear()
	for control: Control in lamps.values() + sockets + rail_buttons + target_cells + live_cells:
		control.scale = Vector2.ONE
		control.modulate = Color.WHITE
	if inventory != null:
		inventory.modulate = Color.WHITE
	if tall_inventory != null:
		tall_inventory.modulate = Color.WHITE
	if plate_inventory != null:
		plate_inventory.modulate = Color.WHITE

func reset_stage() -> void:
	var previous: Dictionary = {"resets": resets, "elapsed": elapsed, "first": first_action, "actions": action_count, "hint": hint_max_level}
	load_stage(stage_index)
	resets = int(previous["resets"]) + 1
	elapsed = float(previous["elapsed"])
	first_action = previous["first"]
	action_count = previous["actions"]
	hint_max_level = previous["hint"]

func _remember(kind: String) -> void:
	history.append({"posts": posts.duplicate(), "post_types": post_types.duplicate(), "shutters": shutters.duplicate(), "lights": lights.duplicate(), "observation": observation_index, "selected_post_type": selected_post_type})
	if history.size() > 100:
		history.pop_front()
	if first_action.is_empty():
		first_action = kind
	action_count += 1
	idle_seconds = 0

func undo_move() -> void:
	if history.is_empty() or stage_solved:
		return
	var previous: Dictionary = history.pop_back()
	posts = previous["posts"]
	var restored_types: Dictionary = previous.get("post_types", {})
	post_types = restored_types.duplicate()
	shutters = previous["shutters"]
	lights = previous["lights"]
	observation_index = previous["observation"]
	selected_post_type = str(previous.get("selected_post_type", "normal"))
	_refresh()

func tap_light(direction: String) -> void:
	clear_context_preview()
	if stage_solved or (direction == "BOTTOM" and not cause_light and not light_height and not flat_plate and not grant14_v02 and not grant20_v03 and not grant36_draft and not nox_campaign and not jev_review):
		return
	if stage().get("free_light_selection", false):
		if not stage().get("installed_lights", []).has(direction):
			return
		if not lights.has(direction) and stage().has("active_light_count") and lights.size() >= int(stage()["active_light_count"]):
			if nox_campaign:
				status_label.text = NoxLocale.copy("Turn off one light before choosing another.")
				_click(260)
			return
		_remember("Light")
		if lights.has(direction):
			lights.erase(direction)
		else:
			lights.append(direction)
	elif stage().has("active_light_count"):
		if not lights.has(direction):
			return
		_remember("Light")
		lights = stage()["installed_lights"].duplicate()
		lights.erase(direction)
	elif stage().get("light_puzzle", false):
		_remember("Light")
		var was_active: bool = lights.has(direction)
		lights = ["TOP", "LEFT", "RIGHT"]
		if was_active:
			lights.erase(direction)
	elif stage()["observations"].size() > 1:
		var desired: int = -1
		for index: int in stage()["observations"].size():
			if stage()["observations"][index]["active_lights"].has(direction) and not lights.has(direction):
				desired = index
		if desired < 0:
			return
		_remember("Light")
		observation_index = desired
		lights = stage()["observations"][desired]["active_lights"].duplicate()
	else:
		return
	_click(1100)
	_refresh()
	if nox_campaign and not stage_solved:
		status_label.text = NoxLocale.light_description(direction) + " · " + NoxLocale.copy("ON" if lights.has(direction) else "OFF")
	if nox_campaign:
		_pulse_control(lamps[direction])

func select_observation(index: int) -> void:
	if stage_solved or index == observation_index or index < 0 or index >= stage()["observations"].size():
		return
	_remember("Light")
	observation_index = index
	lights = stage()["observations"][index]["active_lights"].duplicate()
	_click(1100)
	_refresh()

func _note_fixed_post_touch() -> void:
	if first_action.is_empty():
		first_action = "Post"
	action_count += 1
	idle_seconds = 0

func _post_type(index: int) -> String:
	return str(post_types.get(str(index), "tall" if stage().get("tall", false) else "normal"))

func _post_category(kind: String) -> String:
	return "plate" if kind.begins_with("plate_") else kind

func _post_limit(kind: String) -> int:
	var category: String = _post_category(kind)
	if stage().has("normal_posts") or stage().has("tall_posts") or stage().has("plate_posts"):
		if category == "tall":
			return int(stage().get("tall_posts", 0))
		if category == "plate":
			return int(stage().get("plate_posts", 0))
		return int(stage().get("normal_posts", 0))
	if stage().get("tall", false):
		return int(stage()["posts"]) if category == "tall" else 0
	return int(stage()["posts"]) if category == "normal" else 0

func _post_count(kind: String) -> int:
	var category: String = _post_category(kind)
	var count: int = 0
	for index: Variant in posts:
		if _post_category(_post_type(int(index))) == category:
			count += 1
	return count

func _can_add_post(kind: String) -> bool:
	return posts.size() < int(stage()["posts"]) and _post_count(kind) < _post_limit(kind)

func _fixed_post_count(kind: String) -> int:
	var category: String = _post_category(kind)
	var count: int = 0
	for index: Variant in posts:
		var post_index: int = int(index)
		if _is_fixed_post(post_index) and _post_category(_post_type(post_index)) == category:
			count += 1
	return count

func _has_movable_inventory(kind: String) -> bool:
	return _post_limit(kind) > _fixed_post_count(kind)

func _inventory_for_type(kind: String) -> Button:
	var category: String = _post_category(kind)
	if category == "tall":
		return tall_inventory
	if category == "plate":
		return plate_inventory
	return inventory

func _is_plate(index: int) -> bool:
	return _post_type(index).begins_with("plate_")

func _is_fixed_post(index: int) -> bool:
	var code: String = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
	return stage().get("fixed_posts", []).has(code)

func _socket_enabled(index: int) -> bool:
	return index >= 0 and index < board_mask.size() and board_mask[index] == 1

func rotate_plate(index: int) -> void:
	if stage_solved or not posts.has(index) or not _is_plate(index) or not stage().get("rotatable_plate", false):
		return
	_remember("Plate")
	post_types[str(index)] = "plate_h" if _post_type(index) == "plate_v" else "plate_v"
	_click(930)
	_refresh()
	if nox_campaign:
		_pulse_control(sockets[index])

func toggle_post(index: int) -> void:
	if stage_solved or index < 0 or index >= 25 or not _socket_enabled(index):
		return
	if _is_fixed_post(index):
		if posts.has(index) and _is_plate(index) and stage().get("rotatable_plate", false):
			rotate_plate(index)
		else:
			_note_fixed_post_touch()
			_click(240)
		return
	if posts.has(index) and _is_plate(index) and stage().get("rotatable_plate", false):
		rotate_plate(index)
		return
	_remember("Post")
	if posts.has(index):
		posts.erase(index)
		post_types.erase(str(index))
	else:
		if not _can_add_post(selected_post_type):
			history.pop_back()
			return
		posts.append(index)
		post_types[str(index)] = selected_post_type
	_click(620)
	_refresh()
	if nox_campaign:
		_pulse_control(sockets[index])

func move_shutter(slot: int, remember: bool = true) -> void:
	if stage_solved or not stage().get("movable_shutter", false) or slot < 0 or slot > 4 or shutters == [slot]:
		return
	if remember:
		_remember("Shutter")
	shutters = [slot]
	_click(850)
	_refresh()
	if nox_campaign:
		_pulse_control(rail_buttons[slot])

func _start_pointer(event: InputEvent, kind: String, index: int) -> void:
	var pressed: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var touch: bool = event is InputEventScreenTouch and event.pressed
	if (not pressed and not touch) or stage_solved or not drag_kind.is_empty():
		return
	clear_context_preview()
	if event is InputEventMouseButton and event.device == -1:
		return
	if kind == "shutter" and not stage().get("movable_shutter", false):
		return
	if kind == "post" and index >= 0 and not _socket_enabled(index):
		return
	if kind == "post" and index >= 0 and _is_fixed_post(index):
		if posts.has(index) and _is_plate(index) and stage().get("rotatable_plate", false):
			rotate_plate(index)
		else:
			_note_fixed_post_touch()
			_click(240)
		return
	var source: Control
	if kind == "shutter":
		source = rail_buttons[index]
	else:
		if index == -3:
			if not _can_add_post("plate_v"):
				return
			if nox_campaign:
				drag_post_type = selected_post_type if selected_post_type.begins_with("plate_") else "plate_h"
			else:
				selected_post_type = "plate_h"
				drag_post_type = "plate_h"
			source = plate_inventory
		elif index == -2:
			if not _can_add_post("tall"):
				return
			selected_post_type = "tall"
			drag_post_type = "tall"
			source = tall_inventory
		elif index == -1:
			var inventory_type: String = "tall" if stage().get("tall", false) else "normal"
			if not _can_add_post(inventory_type):
				return
			selected_post_type = inventory_type
			drag_post_type = inventory_type
			source = inventory
		else:
			drag_post_type = _post_type(index) if posts.has(index) else selected_post_type
			source = sockets[index]
	drag_kind = kind
	drag_source = index
	drag_start = source.get_global_transform() * event.position
	pointer_id = -1 if pressed else (event as InputEventScreenTouch).index
	drag_moved = false
	if kind == "shutter":
		_remember("Shutter")
		move_shutter(index, false)
	accept_event()

func _input(event: InputEvent) -> void:
	if drag_kind.is_empty():
		return
	var point: Vector2
	var released: bool = false
	if pointer_id == -1 and event is InputEventMouseMotion:
		point = event.position
	elif pointer_id == -1 and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		point = event.position
		released = true
	elif event is InputEventScreenDrag and event.index == pointer_id:
		point = event.position
	elif event is InputEventScreenTouch and event.index == pointer_id and not event.pressed:
		point = event.position
		released = true
	else:
		return
	_move_pointer(point)
	if released:
		_finish_pointer(point)
	get_viewport().set_input_as_handled()

func _move_pointer(point: Vector2) -> void:
	drag_moved = drag_moved or point.distance_to(drag_start) > 8
	if drag_kind == "shutter":
		var slot: int = clampi(roundi((point.x - rail_buttons[0].get_global_rect().get_center().x) / (rail_buttons[1].get_global_rect().get_center().x - rail_buttons[0].get_global_rect().get_center().x)), 0, 4)
		move_shutter(slot, false)
	else:
		drag_preview = _nearest_socket(point)
		for index: int in 25:
			sockets[index].get_child(0).highlighted = _socket_enabled(index) and index == drag_preview
		if drag_moved and (posts.has(drag_source) or _can_add_post(drag_post_type)):
			drag_ghost.visible = true
			drag_ghost.tall = drag_post_type == "tall"
			drag_ghost.post_type = drag_post_type
			var center: Vector2 = point - Vector2(0, 18)
			if drag_preview >= 0:
				center = center.lerp(sockets[drag_preview].get_global_rect().get_center() - Vector2(0, 6), 0.38)
			drag_ghost.global_position = center - drag_ghost.size * 0.5
			drag_ghost.queue_redraw()
			if drag_source >= 0:
				sockets[drag_source].modulate.a = 0.42
			if shadow_motion != null and shadow_motion.is_valid():
				shadow_motion.kill()
			var preview: Array = posts.duplicate()
			var types: Dictionary = post_types.duplicate()
			if drag_preview >= 0 and (not posts.has(drag_preview) or drag_preview == drag_source):
				preview.erase(drag_source)
				if drag_source >= 0:
					types.erase(str(drag_source))
				preview.append(drag_preview)
				types[str(drag_preview)] = drag_post_type
			if stage().get("tall", false):
				for index: Variant in preview:
					types[str(index)] = "tall"
			var shadow: Array[int] = Optics.compute_shadow(preview, lights, shutters, types)
			for index: int in 25:
				live_cells[index].value = float(shadow[index])

func _nearest_socket(point: Vector2) -> int:
	var nearest: int = -1
	var distance: float = 36.0
	for index: int in 25:
		if not _socket_enabled(index):
			continue
		var gap: float = sockets[index].get_global_rect().get_center().distance_to(point)
		if gap < distance:
			nearest = index
			distance = gap
	return nearest

func _drop_destination(point: Vector2) -> int:
	for index: int in 25:
		if sockets[index].get_global_rect().has_point(point):
			return index if _socket_enabled(index) else -1
	return _nearest_socket(point)

func _return_dragged_post_to_inventory(point: Vector2) -> bool:
	if drag_source < 0 or not posts.has(drag_source) or _is_fixed_post(drag_source):
		return false
	var target_inventory: Button = _inventory_for_type(drag_post_type)
	if target_inventory == null or not target_inventory.visible or not target_inventory.get_global_rect().has_point(point):
		return false
	_remember("Post")
	posts.erase(drag_source)
	post_types.erase(str(drag_source))
	selected_post_type = drag_post_type
	_click(520)
	return true

func _finish_pointer(point: Vector2) -> void:
	var kind: String = drag_kind
	drag_ghost.visible = false
	drag_kind = ""
	pointer_id = -2
	if kind == "post":
		var destination: int = _drop_destination(point)
		if not drag_moved:
			if drag_source >= 0 and destination == drag_source:
				toggle_post(destination)
			elif drag_source == -3 and nox_campaign:
				selected_post_type = ("plate_h" if selected_post_type == "plate_v" else "plate_v") if pose_chosen else "plate_h"
				pose_chosen = true
				_click(890)
				_refresh()
				if nox_campaign and not stage_solved:
					status_label.text = NoxLocale.pose_description(selected_post_type)
				_pulse_control(plate_inventory)
			elif drag_source < 0:
				selected_post_type = drag_post_type
				pose_chosen = true
				_click(780)
				_refresh()
				if nox_campaign and not stage_solved:
					status_label.text = NoxLocale.pose_description(selected_post_type)
				_pulse_control(plate_inventory if drag_source == -3 else tall_inventory if drag_source == -2 else inventory)
		elif _return_dragged_post_to_inventory(point):
			pass
		elif destination >= 0 and destination != drag_source and not posts.has(destination):
			if posts.has(drag_source) or _can_add_post(drag_post_type):
				_remember("Post")
				if drag_source >= 0:
					posts.erase(drag_source)
					post_types.erase(str(drag_source))
				posts.append(destination)
				post_types[str(destination)] = drag_post_type
				selected_post_type = drag_post_type
				_click(620)
				_refresh()
				if nox_campaign:
					_pulse_control(sockets[destination])
	drag_preview = -1
	for button: Button in sockets:
		button.get_child(0).highlighted = false
		button.modulate = Color.WHITE
	_refresh()

func _refresh(animate: bool = true) -> void:
	if nox_campaign and NoxSettings.reduced_motion():
		animate = false
	if shadow_motion != null and shadow_motion.is_valid():
		shadow_motion.kill()
	var types: Dictionary = post_types.duplicate()
	if stage().get("tall", false):
		for index: Variant in posts:
			types[str(index)] = "tall"
	current_shadow = Optics.compute_shadow(posts, lights, shutters, types)
	var near_shadow: Array[int] = Optics.compute_shadow(posts, lights, shutters)
	var target: Dictionary = stage()["observations"][observation_index]["target"]
	var fog_cells: Array = stage().get("fog_cells", [])
	var motion: Tween = null
	if animate:
		motion = create_tween().set_parallel(true)
		shadow_motion = motion
		motions.append(motion)
	for index: int in 25:
		var code: String = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
		target_cells[index].unknown = fog_cells.has(code)
		target_cells[index].get_parent().tooltip_text = code + (" · " + (NoxLocale.copy("FOG: unobserved, not zero") if nox_campaign else "FOG: unobserved, not zero") if fog_cells.has(code) else " · " + str(int(target.get(code, 0))))
		live_cells[index].unknown = false
		if animate:
			motion.tween_property(target_cells[index], "value", float(target.get(code, 0)), 0.2)
			motion.tween_property(live_cells[index], "value", float(current_shadow[index]), 0.18).set_delay(0.04 if current_shadow[index] > near_shadow[index] else 0.0)
		else:
			target_cells[index].value = float(target.get(code, 0))
			live_cells[index].value = float(current_shadow[index])
		var socket_button: Button = sockets[index]
		var socket_available: bool = _socket_enabled(index)
		socket_button.disabled = not socket_available or stage_solved
		socket_button.mouse_filter = Control.MOUSE_FILTER_STOP if socket_available else Control.MOUSE_FILTER_IGNORE
		var surface: Control = socket_button.get_child(0)
		surface.kind = "socket" if socket_available else "socket_missing"
		surface.occupied = socket_available and posts.has(index)
		surface.post_type = str(types.get(str(index), "normal")) if surface.occupied else "normal"
		surface.tall = surface.occupied and surface.post_type == "tall"
		surface.fixed = _is_fixed_post(index)
	for direction: String in lamps:
		var lamp: Button = lamps[direction]
		var interactive: bool = stage().get("free_light_selection", false) or (stage().get("light_puzzle", false) and (direction != "BOTTOM" or cause_light or light_height))
		if stage().has("active_light_count") and not stage().get("free_light_selection", false):
			interactive = lights.has(direction)
		if stage()["observations"].size() > 1:
			var incidence: int = 0
			for observation: Dictionary in stage()["observations"]:
				incidence += int(observation["active_lights"].has(direction))
			interactive = incidence > 0 and incidence < stage()["observations"].size()
		lamp.disabled = not interactive or stage_solved
		lamp.get_child(0).fixed = not interactive
		lamp.get_child(0).active = lights.has(direction)
		if nox_campaign:
			NoxStageLayout.style_lamp(lamp, interactive and not stage_solved, lights.has(direction))
		lamp.visible = direction != "BOTTOM" or lights.has("BOTTOM")
		if cause_light or light_height or flat_plate or grant14_v02 or grant20_v03 or grant36_draft or nox_campaign or jev_review:
			# Invisible reserved mounts keep the board stationary when a source is absent.
			lamp.visible = true
			var installed: Array = stage().get("installed_lights", stage()["observations"][0]["active_lights"])
			lamp.modulate.a = 1.0 if installed.has(direction) else 0.0
			lamp.mouse_filter = Control.MOUSE_FILTER_STOP if installed.has(direction) else Control.MOUSE_FILTER_IGNORE
			lamp.get_child(0).glow = 1.0
		if direction == "BOTTOM":
			lamp.get_parent().visible = lamp.visible
	rail.get_parent().visible = stage().has("fixed_shutters") or stage().get("movable_shutter", false)
	for slot: int in 5:
		var surface: Control = rail_buttons[slot].get_child(0)
		surface.occupied = shutters.has(slot)
		surface.active = lights.has("TOP")
		surface.highlighted = drag_kind == "shutter" and shutters.has(slot)
		rail_buttons[slot].disabled = not stage().get("movable_shutter", false) or stage_solved
	var has_fixed_posts: bool = stage().has("fixed_posts")
	var mixed_inventory: bool = stage().has("normal_posts") or stage().has("tall_posts") or stage().has("plate_posts")
	if mixed_inventory:
		# Keep movable inventory sockets visible even after a piece is placed so
		# dragging a board piece back to its socket can remove it from the board.
		inventory.visible = _has_movable_inventory("normal")
		tall_inventory.visible = _has_movable_inventory("tall")
		plate_inventory.visible = _has_movable_inventory("plate")
		inventory.get_child(0).occupied = _can_add_post("normal")
		inventory.get_child(0).tall = false
		inventory.get_child(0).post_type = "normal"
		inventory.get_child(0).highlighted = selected_post_type == "normal" and inventory.visible
		tall_inventory.get_child(0).occupied = _can_add_post("tall")
		tall_inventory.get_child(0).post_type = "tall"
		tall_inventory.get_child(0).highlighted = selected_post_type == "tall" and tall_inventory.visible
		plate_inventory.get_child(0).occupied = _can_add_post("plate_v")
		plate_inventory.get_child(0).post_type = (selected_post_type if selected_post_type.begins_with("plate_") else "plate_h") if nox_campaign else "plate_v"
		plate_inventory.get_child(0).highlighted = selected_post_type.begins_with("plate_") and plate_inventory.visible
	else:
		inventory.visible = not has_fixed_posts
		tall_inventory.visible = false
		plate_inventory.visible = false
		inventory.get_child(0).occupied = posts.size() < int(stage()["posts"])
		inventory.get_child(0).tall = stage().get("tall", false)
		inventory.get_child(0).post_type = "tall" if stage().get("tall", false) else "normal"
		inventory.get_child(0).highlighted = false
	inventory.get_parent().visible = inventory.visible or tall_inventory.visible or plate_inventory.visible
	if nox_campaign:
		NoxStageLayout.style_selection(self)
		pose_description_label.visible = inventory.get_parent().visible
		pose_description_label.text = NoxLocale.pose_description(selected_post_type) if pose_description_label.visible else ""
	title_label.text = NoxLocale.trace_heading(stage_index, Story.title(stage_index, NoxLocale.language())) if nox_campaign else "%s  /  %s" % [stage()["id"], stage()["title"]]
	if nox_campaign and mixed_inventory:
		var counts: PackedStringArray = []
		for kind: String in ["normal", "tall", "plate"]:
			if _post_limit(kind) > 0:
				var pose: String = NoxLocale.copy({"normal": "SIT", "tall": "STAND", "plate": "WALK"}[kind])
				counts.append("%s  %d / %d" % [pose, _post_count(kind), _post_limit(kind)])
		count_label.text = "     ·     ".join(counts)
	elif mixed_inventory:
		count_label.text = "N %d/%d  T %d/%d  P %d/%d  ·  %02d/%02d" % [_post_count("normal"), _post_limit("normal"), _post_count("tall"), _post_limit("tall"), _post_count("plate"), _post_limit("plate"), stage_index + 1, stages.size()]
	else:
		count_label.text = "%s %d / %d    ·    %02d / 36" % [NoxLocale.copy("SIT"), posts.size(), int(stage()["posts"]), stage_index + 1] if nox_campaign else "POSTS  %d / %d    ·    %02d / %02d" % [posts.size(), int(stage()["posts"]), stage_index + 1, stages.size()]
	if nox_campaign:
		observation_label.text = NoxLocale.copy("Match both plates. Choose a pose and square.")
		if stage_solved:
			observation_label.text = NoxLocale.copy("Every shadow agrees.")
		elif stage_index == 0:
			if not pose_chosen and posts.is_empty():
				observation_label.text = NoxLocale.copy("① Compare both plates. Choose NOX below.")
			elif posts.is_empty():
				observation_label.text = NoxLocale.copy("② Tap a square to place NOX.")
			else:
				observation_label.text = NoxLocale.copy("③ Match every shade on both plates.")
		if stage().get("free_light_selection", false) and not stage_solved:
			observation_label.text = NoxLocale.light_count(lights.size(), int(stage().get("active_light_count", 0)))
		if not fog_cells.is_empty() and not stage_solved:
			observation_label.text += "    ·    " + NoxLocale.copy("?  UNRECORDED")
	elif light_height or flat_plate or grant14_v02 or grant20_v03 or grant36_draft or nox_campaign or jev_review:
		var light_denominator: String = "FIXED"
		if stage().get("free_light_selection", false):
			light_denominator = str(int(stage()["active_light_count"])) if stage().has("active_light_count") else "?"
		observation_label.text = "LIGHTS  %d / %s" % [lights.size(), light_denominator]
		if jev_review and not stage().get("fog_cells", []).is_empty():
			observation_label.text += "    ·    FOG %d" % stage().get("fog_cells", []).size()
	else:
		observation_label.text = "OBSERVATION  " + str(stage()["observations"][observation_index]["id"])
	if not nox_campaign and not fog_cells.is_empty():
		observation_label.text += "    FOG %d / 25\n? = UNOBSERVED · MATCH THE VISIBLE CELLS" % fog_cells.size()
	if cause_light:
		observation_label.text += "    ACTIVE LIGHTS = %d / %d" % [lights.size(), stage()["installed_lights"].size()]
		for index: int in observation_buttons.size():
			observation_buttons[index].get_parent().visible = stage()["observations"].size() > 1
			observation_buttons[index].disabled = index == observation_index or stage_solved
	back_button.disabled = stage_index == 0
	undo_button.disabled = history.is_empty() or stage_solved
	var hints: Array = NoxObservations.for_stage(stage_index, stage(), NoxLocale.language()) if nox_campaign else stage().get("hints", [])
	hint_button.disabled = stage_solved or hint_level >= mini(3, hints.size())
	hint_button.visible = not nox_campaign or not hints.is_empty()
	hint_button.tooltip_text = "No hints authored for this draft stage." if hints.is_empty() else (NoxLocale.copy("A gentle clue") if nox_campaign else "A gentle clue")
	_check_solve()

func _check_solve() -> void:
	if stage_solved or not drag_kind.is_empty() or not Optics.solved(stage(), posts, shutters, lights, post_types):
		return
	stage_solved = true
	next_button.disabled = true
	undo_button.disabled = true
	hint_button.disabled = true
	# Commit before the presentation: resetting or leaving must never lose a solve.
	completed[stage()["id"]] = true
	hint_records[stage()["id"]] = {"hint": hint_max_level, "first_action": first_action, "solve_seconds": elapsed, "actions": action_count, "resets": resets}
	_save_progress()
	if nox_campaign:
		observation_label.text = NoxLocale.copy("Every shadow agrees.")
	var reduce_motion: bool = nox_campaign and NoxSettings.reduced_motion()
	if not reduce_motion:
		clear_seal.play(target_cells, live_cells)
	status_label.text = ""
	if nox_campaign:
		status_label.add_theme_font_size_override("font_size", 16)
		if reduce_motion:
			status_label.text = NoxLocale.solved(completed.size(), stages.size())
			status_label.add_theme_color_override("font_color", T.GOLD)
			_click(660)
			next_button.text = NoxLocale.copy("HOME" if stage_index == stages.size() - 1 else "NEXT")
			next_button.disabled = false
			next_button.add_theme_color_override("font_color", T.GOLD)
			if stage_index == stages.size() - 1 and completed.size() == stages.size():
				_show_finale()
			return
	var solve_motion: Tween = create_tween()
	motions.append(solve_motion)
	if nox_campaign:
		_click(520)
		solve_motion.tween_interval(0.10)
		solve_motion.tween_callback(func() -> void: _click(660))
		solve_motion.tween_interval(0.10)
		solve_motion.tween_callback(func() -> void: _click(825))
	solve_motion.tween_interval(0.12 if nox_campaign else 0.32)
	solve_motion.tween_callback(func() -> void:
		var final_stage: bool = stage_index == stages.size() - 1
		status_label.text = NoxLocale.solved(completed.size(), stages.size()) if nox_campaign else ("CALIBRATION COMPLETE" if final_stage else "LIGHT KEPT") + "\n%02d / %02d  ·  %s" % [stage_index + 1, stages.size(), "Every shadow in place." if final_stage else "A perfect alignment."]
		status_label.add_theme_color_override("font_color", T.GOLD)
		status_label.modulate.a = 0.0
		if not nox_campaign:
			_click(660))
	solve_motion.tween_property(status_label, "modulate:a", 1.0, 0.28)
	solve_motion.tween_interval(0.25)
	solve_motion.tween_callback(func() -> void:
		next_button.text = (NoxLocale.copy("HOME") if nox_campaign else "REPLAY") if stage_index == stages.size() - 1 else (NoxLocale.copy("NEXT") if nox_campaign else "NEXT")
		next_button.disabled = false
		next_button.add_theme_color_override("font_color", T.GOLD)
		next_button.pivot_offset = next_button.size * 0.5
		next_button.scale = Vector2.ONE * 0.96)
	solve_motion.tween_property(next_button, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if nox_campaign and stage_index == stages.size() - 1 and completed.size() == stages.size():
		solve_motion.tween_interval(0.48)
		solve_motion.tween_callback(_show_finale)

func _pulse_control(control: Control) -> void:
	if not nox_campaign or NoxSettings.reduced_motion() or control == null:
		return
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 0.89
	var pulse: Tween = create_tween()
	motions.append(pulse)
	pulse.tween_property(control, "scale", Vector2.ONE * 1.05, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pulse.tween_property(control, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_first_guide() -> void:
	if is_inside_tree() and stage_guide != null and stage_index == 0 and not stage_solved:
		show_stage_guide()

func show_stage_guide() -> void:
	if stage_guide == null:
		return
	stage_guide.present(NoxLocale.language(), NoxSettings.reduced_motion())

func _show_finale() -> void:
	if finale_overlay != null and is_inside_tree() and stage_solved and stage_index == stages.size() - 1 and completed.size() == stages.size():
		finale_overlay.present(NoxLocale.language(), NoxSettings.reduced_motion())

func next_stage() -> void:
	if next_button.disabled:
		return
	if nox_campaign and stage_index == stages.size() - 1:
		home_requested.emit()
		return
	var first_stage: int = 20 if grant36_draft else 0
	load_stage(first_stage if stage_index == stages.size() - 1 else stage_index + 1)

func whisper() -> void:
	var hints: Array = NoxObservations.for_stage(stage_index, stage(), NoxLocale.language()) if nox_campaign else stage().get("hints", [])
	if stage_solved or hint_level >= mini(3, hints.size()):
		return
	status_label.text = (NoxLocale.copy("OBSERVE ") if nox_campaign else "WHISPER ") + ["I", "II", "III"][hint_level] + "  ·  " + str(hints[hint_level])
	hint_level += 1
	hint_max_level = maxi(hint_max_level, hint_level)
	var surface_name: String = str(stage().get("hint_surface", ""))
	var controls: Array = []
	if surface_name == "cause":
		controls = lamps.values() + rail_buttons
		if hint_level == 2 and stage().has("hint_targets"):
			controls = []
			for code: String in stage()["hint_targets"]:
				controls.append(target_cells[Optics.cell(code)])
	if surface_name == "light" or surface_name == "observation":
		controls = lamps.values()
	elif surface_name == "shutter_slot":
		controls = rail_buttons
	elif surface_name == "socket":
		controls = [inventory, tall_inventory, plate_inventory]
	for control: Control in controls:
		if cause_light and control.modulate.a == 0.0:
			continue
		var pulse: Tween = create_tween()
		motions.append(pulse)
		pulse.tween_property(control, "modulate", Color.WHITE if nox_campaign and NoxSettings.reduced_motion() else Color(1.25, 1.2, 1.08), 0.2)
		pulse.tween_property(control, "modulate", Color.WHITE, 0.5)
	hint_button.disabled = hint_level >= mini(3, hints.size())

func _process(delta: float) -> void:
	if stages.is_empty():
		return
	elapsed += delta
	idle_seconds += delta
	if stage()["id"] == "G02" and idle_seconds > 5 and not idle_pulsed and observation_index == 0 and not stage_solved:
		idle_pulsed = true
		var lamp: Button = lamps["LEFT"]
		lamp.pivot_offset = lamp.size * 0.5
		var pulse: Tween = create_tween()
		motions.append(pulse)
		pulse.tween_property(lamp, "scale", Vector2.ONE * 1.035, 0.35)
		pulse.tween_property(lamp, "scale", Vector2.ONE, 0.35)
	for surface: Control in target_cells + live_cells:
		surface.queue_redraw()
	for button: Button in sockets + rail_buttons + [inventory, tall_inventory, plate_inventory]:
		button.get_child(0).queue_redraw()
	for button: Button in lamps.values():
		button.get_child(0).queue_redraw()
	motions = motions.filter(func(motion: Tween) -> bool: return motion.is_valid())

func _click(frequency: float) -> void:
	var wave: AudioStreamWAV = AudioStreamWAV.new()
	wave.format = AudioStreamWAV.FORMAT_16_BITS
	wave.mix_rate = 22050
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(1324)
	for index: int in 662:
		var envelope: float = pow(1.0 - float(index) / 662.0, 3.0)
		bytes.encode_s16(index * 2, int(sin(TAU * frequency * float(index) / 22050.0) * envelope * 1600))
	wave.data = bytes
	sound_player.stream = wave
	sound_player.play()

func _load_progress() -> void:
	if not FileAccess.file_exists(progress_path):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(progress_path))
	if parsed is Dictionary and parsed.get("campaign", "") == campaign_id:
		for id: String in parsed.get("completed", {}):
			for entry: Dictionary in stages:
				if id == entry["id"]:
					completed[id] = true
		hint_records = parsed.get("playtest", {})

func _save_progress() -> void:
	var file: FileAccess = FileAccess.open(progress_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"campaign": campaign_id, "completed": completed, "playtest": hint_records}, "\t"))

func _exit_tree() -> void:
	_cancel_motions()


func preview_pose(pose: String) -> void:
	_preview_context("pose:" + pose, NoxLocale.pose_description(pose))

func preview_light(direction: String) -> void:
	if not lamps.has(direction) or lamps[direction].disabled:
		return
	_preview_context("light:" + direction, NoxLocale.light_description(direction))

func _preview_context(key: String, message: String) -> void:
	if not nox_campaign or stage_solved or status_label == null:
		return
	if context_preview_key.is_empty():
		context_restore_text = status_label.text
	context_preview_key = key
	status_label.text = message

func clear_context_preview(button: Button = null) -> void:
	if button != null and (button.has_focus() or button.get_global_rect().has_point(button.get_global_mouse_position())):
		return
	if context_preview_key.is_empty():
		return
	context_preview_key = ""
	if status_label != null:
		status_label.text = context_restore_text
	context_restore_text = ""

func toggle_language() -> void:
	if not nox_campaign:
		return
	NoxLocale.toggle()
	sync_stage_language(NoxLocale.language())

func sync_stage_language(_language: String) -> void:
	if not nox_campaign:
		return
	clear_context_preview()
	NoxStageLayout.relocalize(self)
	if stage_guide != null:
		stage_guide.set_language(NoxLocale.language())
	_refresh(false)
	nox_chapter_label.text = ("記録 %02d  /  %s" if NoxLocale.is_japanese() else "PLATE %02d  /  %s") % [stage_index + 1, Story.chapter_name(stage_index, NoxLocale.language())]
	if stage_solved:
		status_label.text = NoxLocale.solved(completed.size(), stages.size())
		next_button.text = NoxLocale.copy("HOME" if stage_index == stages.size() - 1 else "NEXT")
	elif hint_level > 0:
		var hints: Array = NoxObservations.for_stage(stage_index, stage(), NoxLocale.language())
		status_label.text = NoxLocale.copy("OBSERVE ") + ["I", "II", "III"][hint_level - 1] + "  ·  " + str(hints[hint_level - 1])
	else:
		status_label.text = Story.milestone_note(stage_index, NoxLocale.language())
		if status_label.text.is_empty():
			status_label.text = NoxLocale.copy("Observe the record. Let every shadow agree.")
		if pose_chosen:
			status_label.text = NoxLocale.pose_description(selected_post_type)
		next_button.text = NoxLocale.copy("NEXT")
