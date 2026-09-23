extends SceneTree

const Optics: GDScript = preload("res://src/experiment_optics.gd")
const PRODUCT_SAVE: String = "user://shadow_sum_grant36_v0_5.json"
const SPOT_CHECKS: Array[String] = ["GR01", "GR22", "GR23", "GR27", "GR28", "GR29", "GR32", "GR34", "GR35", "GR36"]

var failures: Array[String] = []
var original_save_exists: bool = false
var original_save_bytes: PackedByteArray = PackedByteArray()

func _initialize() -> void:
    if OS.get_cmdline_user_args().has("--sync-dev-route"):
        call_deferred("_run_dev_route")
    else:
        call_deferred("_run")

func _run_dev_route() -> void:
    root.size = Vector2i(405, 900)
    change_scene_to_file("res://scenes/home.tscn")
    await create_timer(0.25).timeout
    await process_frame
    var campaign: Control = current_scene as Control
    _check(campaign != null and campaign.get_child_count() > 0, "developer route opens campaign")
    if campaign != null and campaign.get_child_count() > 0:
        var game: Control = campaign.get_child(0) as Control
        _check(game.campaign_id == "grant36-v05" and game.stage()["id"] == "GR28",
            "developer --campaign / --stage route opens final GR28")
    print("NOXSUM developer route smoke: %d failures" % failures.size())
    quit(1 if not failures.is_empty() else 0)

func _check(condition: bool, label: String) -> void:
    if not condition:
        failures.append(label)
        push_error("NOXSUM final sync: " + label)

func _find_button(node: Node, label: String) -> Button:
    if node is Button and (node as Button).text == label:
        return node as Button
    for child: Node in node.get_children():
        var found: Button = _find_button(child, label)
        if found != null:
            return found
    return null

func _find_scroll(node: Node) -> ScrollContainer:
    if node is ScrollContainer:
        return node as ScrollContainer
    for child: Node in node.get_children():
        var found: ScrollContainer = _find_scroll(child)
        if found != null:
            return found
    return null

func _tap(control: Control) -> void:
    var point: Vector2 = root.get_final_transform() * control.get_global_rect().get_center()
    var down := InputEventMouseButton.new()
    down.button_index = MOUSE_BUTTON_LEFT
    down.position = point
    down.pressed = true
    root.push_input(down)
    var up := InputEventMouseButton.new()
    up.button_index = MOUSE_BUTTON_LEFT
    up.position = point
    up.pressed = false
    root.push_input(up)
    await process_frame

func _bounds(node: Node, viewport: Rect2, context: String) -> void:
    for child: Node in node.get_children():
        if child is Control and (child as Control).is_visible_in_tree():
            var control := child as Control
            _check(viewport.grow(2.0).encloses(control.get_global_rect()),
                context + ": out of bounds " + str(control.name) + " " + str(control.get_global_rect()))
        _bounds(child, viewport, context)

func _stage_index(game: Control, stage_id: String) -> int:
    for index: int in game.stages.size():
        if game.stages[index]["id"] == stage_id:
            return index
    return -1

func _check_stage(game: Control, stage_id: String, dimensions: Vector2i) -> void:
    var index: int = _stage_index(game, stage_id)
    _check(index >= 0, stage_id + " exists")
    if index < 0:
        return
    game.load_stage(index)
    await process_frame
    await process_frame
    var record: Dictionary = game.stage()
    _check(game.title_label.text.contains(str(record["title"])), stage_id + " header matches final data")
    _check(game.board_mask == Optics.board_shape_mask(record), stage_id + " board mask matches final data")
    var installed: Array = record.get("installed_lights", record["observations"][0]["active_lights"])
    for direction: String in ["TOP", "LEFT", "RIGHT", "BOTTOM"]:
        var lamp: Button = game.lamps[direction]
        _check(lamp.visible, stage_id + " reserved light mount remains in layout " + direction)
        if installed.has(direction):
            _check(lamp.modulate.a > 0.9, stage_id + " installed light visible " + direction)
        else:
            _check(lamp.modulate.a < 0.1, stage_id + " absent light mount is transparent " + direction)
            if record.get("free_light_selection", false):
                _check(not lamp.disabled, stage_id + " selectable light enabled " + direction)
            elif record["observations"].size() == 1:
                _check(lamp.disabled, stage_id + " fixed light locked " + direction)
    _check(game.rail.get_parent().visible == (record.has("fixed_shutters") or record.get("movable_shutter", false)),
        stage_id + " shutter rail follows final data")
    _bounds(game, root.get_visible_rect(), stage_id + " " + str(dimensions))

func _finish() -> void:
    var save_path: String = ProjectSettings.globalize_path(PRODUCT_SAVE)
    if original_save_exists:
        var restored: FileAccess = FileAccess.open(PRODUCT_SAVE, FileAccess.WRITE)
        if restored != null:
            restored.store_buffer(original_save_bytes)
            restored.close()
    elif FileAccess.file_exists(PRODUCT_SAVE):
        DirAccess.remove_absolute(save_path)
    print("NOXSUM Grant36 final sync smoke: %d failures" % failures.size())
    quit(1 if not failures.is_empty() else 0)

func _run() -> void:
    original_save_exists = FileAccess.file_exists(PRODUCT_SAVE)
    if original_save_exists:
        original_save_bytes = FileAccess.get_file_as_bytes(PRODUCT_SAVE)
        DirAccess.remove_absolute(ProjectSettings.globalize_path(PRODUCT_SAVE))
    root.size = Vector2i(360, 800)
    var launch_error: Error = change_scene_to_file("res://scenes/home.tscn")
    _check(launch_error == OK, "HOME scene opens")
    await scene_changed
    await process_frame
    var home: Control = current_scene as Control
    _check(home != null and home.stages.size() == 36 and home._completed_count() == 0, "fresh HOME recognizes 36 unsolved stages")
    _check(home.find_child("Title", true, false).text == "NOXSUM", "NOXSUM HOME title remains")
    _bounds(home, root.get_visible_rect(), "HOME 360x800")
    home._open_level_select()
    await process_frame
    var scroll: ScrollContainer = _find_scroll(home.level_overlay)
    var select_28: Button = _find_button(home.level_overlay, "28/36")
    _check(scroll != null and select_28 != null and _find_button(home.level_overlay, "36/36") != null,
        "HOME offers all 36 stages")
    if scroll != null:
        _check(not scroll.get_h_scroll_bar().visible, "stage select has no horizontal clipping")
    if scroll == null or select_28 == null:
        _finish()
        return
    scroll.scroll_vertical = 1000
    await process_frame
    await process_frame
    _check(scroll.get_global_rect().has_point(select_28.get_global_rect().get_center()),
        "GR28 stage-select button can scroll into view")
    await _tap(select_28)
    await create_timer(0.6).timeout
    await process_frame
    var campaign: Control = current_scene as Control
    _check(campaign != null and campaign.get_child_count() > 0, "HOME opens campaign scene")
    if campaign == null or campaign.get_child_count() == 0:
        _finish()
        return
    var game: Control = campaign.get_child(0) as Control
    _check(game.campaign_id == "grant36-v05" and game.stage()["id"] == "GR28",
        "HOME stage-select opens final GR28")
    var gr28: Dictionary = game.stage()
    _check(gr28["title"] == "PLATE IN THE GAP", "GR28 sentinel title")
    _check(gr28["boardShape"]["mask"] == ["10101", "11111", "00100", "11111", "10101"],
        "GR28 sentinel mask")
    _check(not gr28.get("free_light_selection", false) and not gr28.get("movable_shutter", false),
        "GR28 excludes old light/shutter variant")
    _check(game.lights == ["TOP", "LEFT", "RIGHT", "BOTTOM"] and not game.plate_inventory.disabled,
        "GR28 has four fixed lights and Plate control")

    for dimensions: Vector2i in [Vector2i(360, 800), Vector2i(405, 900), Vector2i(720, 900)]:
        root.size = dimensions
        await process_frame
        for stage_id: String in SPOT_CHECKS:
            await _check_stage(game, stage_id, dimensions)
        for stage_id: String in ["GR22", "GR23", "GR27", "GR31"]:
            game.load_stage(_stage_index(game, stage_id))
            await process_frame
            var bottom: Button = game.lamps["BOTTOM"]
            _check(bottom.visible and bottom.modulate.a > 0.9 and not bottom.disabled,
                stage_id + " BOTTOM visible and interactive at " + str(dimensions))
            _check(not game.lights.has("BOTTOM"), stage_id + " BOTTOM starts inactive")
            await _tap(bottom)
            _check(game.lights.has("BOTTOM"), stage_id + " BOTTOM mouse click turns on")
            await _tap(bottom)
            _check(not game.lights.has("BOTTOM"), stage_id + " BOTTOM mouse click turns off")
        game.load_stage(_stage_index(game, "GR29"))
        await process_frame
        var fog_cell: String = str(game.stage()["fog_cells"][0])
        _check(game.target_cells[Optics.cell(fog_cell)].unknown, "GR29 FOG appears unknown")
        var missing: int = -1
        for index: int in 25:
            if game.board_mask[index] == 0:
                missing = index
                break
        _check(missing >= 0 and game.sockets[missing].get_child(0).kind == "socket_missing",
            "GR29 missing socket differs from FOG")

    game.load_stage(0)
    await process_frame
    await _tap(game.sockets[Optics.cell("C3")])
    _check(game.stage_solved and game.completed.has("GR01"), "GR01 mouse solve saves final campaign progress")
    game._go_home()
    await create_timer(0.2).timeout
    await process_frame
    home = current_scene as Control
    _check(home != null and home.stages.size() == 36 and home.find_child("Title", true, false).text == "NOXSUM",
        "return HOME preserves NOXSUM and 36-stage collection")
    _check(home.completed.has("GR01") and home._resume_index() == 1 and home.continue_info.text.contains("GR02"),
        "HOME immediately shares gameplay progress and resumes GR02")
    change_scene_to_file("res://scenes/home.tscn")
    await scene_changed
    await process_frame
    home = current_scene as Control
    _check(home.completed.has("GR01") and home._resume_index() == 1,
        "HOME progress persists after restart")
    _finish()
