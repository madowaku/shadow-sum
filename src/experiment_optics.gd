extends RefCounted

enum LightDir { TOP, LEFT, RIGHT, BOTTOM }
const DIRECTIONS: Dictionary = {"TOP": Vector2i(0, 1), "LEFT": Vector2i(1, 0), "RIGHT": Vector2i(-1, 0), "BOTTOM": Vector2i(0, -1)}

static func cell(code: String) -> int:
	return (int(code.substr(1)) - 1) * 5 + code.unicode_at(0) - 65

static func compute_shadow(posts: Array, active_lights: Array, shutters: Array = [], post_types: Dictionary = {}) -> Array[int]:
	var result: Array[int] = []
	result.resize(25)
	result.fill(0)
	for raw: Variant in posts:
		var index: int = int(raw)
		var origin: Vector2i = Vector2i(index % 5, int(index / 5.0))
		var post_type: String = str(post_types.get(str(index), "normal"))
		var reach: int = 2 if post_type == "tall" else 1
		for light: String in active_lights:
			if post_type == "plate_v" and light not in ["LEFT", "RIGHT"]:
				continue
			if post_type == "plate_h" and light not in ["TOP", "BOTTOM"]:
				continue
			if light == "TOP" and shutters.has(origin.x):
				continue
			for distance: int in range(1, reach + 1):
				var target: Vector2i = origin + (DIRECTIONS[light] as Vector2i) * distance
				if target.x >= 0 and target.x < 5 and target.y >= 0 and target.y < 5:
					result[target.y * 5 + target.x] += 1
	return result

static func effective_lights(stage: Dictionary, posts: Array, base_lights: Array) -> Array:
	var active: Array = base_lights.duplicate()
	var occupied: Dictionary = {}
	for raw_index: Variant in posts:
		occupied[str(int(raw_index))] = true
	for raw_switch: Variant in stage.get("placement_switches", []):
		if typeof(raw_switch) != TYPE_DICTIONARY:
			continue
		var switch_data: Dictionary = raw_switch as Dictionary
		var switch_index: int = cell(str(switch_data.get("cell", "")))
		if not occupied.has(str(switch_index)):
			continue
		for raw_direction: Variant in switch_data.get("off", []):
			active.erase(str(raw_direction))
		for raw_direction: Variant in switch_data.get("on", []):
			var direction: String = str(raw_direction)
			if not active.has(direction):
				active.append(direction)
	var ordered: Array = []
	for direction: String in ["TOP", "LEFT", "RIGHT", "BOTTOM"]:
		if active.has(direction):
			ordered.append(direction)
	return ordered

static func apparatus_occupies(stage: Dictionary, index: int) -> bool:
	for raw_code: Variant in stage.get("blockers", []):
		if cell(str(raw_code)) == index:
			return true
	var mirror_data: Variant = stage.get("mirrors", {})
	if typeof(mirror_data) == TYPE_DICTIONARY:
		for raw_code: Variant in (mirror_data as Dictionary).keys():
			if cell(str(raw_code)) == index:
				return true
	return false

static func _reflect(direction: Vector2i, orientation: String) -> Vector2i:
	if orientation == "/":
		return Vector2i(-direction.y, -direction.x)
	return Vector2i(direction.y, direction.x)

static func _edge_start(light: String, lane: int) -> Vector2i:
	match light:
		"TOP":
			return Vector2i(lane, 0)
		"BOTTOM":
			return Vector2i(lane, 4)
		"LEFT":
			return Vector2i(0, lane)
		"RIGHT":
			return Vector2i(4, lane)
	return Vector2i(-1, -1)

static func _compute_beam_shadow(stage: Dictionary, posts: Array, active_lights: Array, shutters: Array, post_types: Dictionary) -> Array[int]:
	var result: Array[int] = []
	result.resize(25)
	result.fill(0)
	var occupied: Dictionary = {}
	for raw_index: Variant in posts:
		occupied[str(int(raw_index))] = true
	var blockers: Dictionary = {}
	for raw_code: Variant in stage.get("blockers", []):
		blockers[str(cell(str(raw_code)))] = true
	var mirrors: Dictionary = {}
	var raw_mirrors: Variant = stage.get("mirrors", {})
	if typeof(raw_mirrors) == TYPE_DICTIONARY:
		for raw_code: Variant in (raw_mirrors as Dictionary).keys():
			mirrors[str(cell(str(raw_code)))] = str((raw_mirrors as Dictionary)[raw_code])
	for raw_light: Variant in active_lights:
		var light: String = str(raw_light)
		if not DIRECTIONS.has(light):
			continue
		for lane: int in 5:
			if light == "TOP" and shutters.has(lane):
				continue
			var direction: Vector2i = DIRECTIONS[light] as Vector2i
			var position: Vector2i = _edge_start(light, lane)
			var visited: Dictionary = {}
			while position.x >= 0 and position.x < 5 and position.y >= 0 and position.y < 5:
				var state_key: String = "%d:%d:%d:%d" % [position.x, position.y, direction.x, direction.y]
				if visited.has(state_key):
					break
				visited[state_key] = true
				var index: int = position.y * 5 + position.x
				if blockers.has(str(index)):
					break
				if mirrors.has(str(index)):
					direction = _reflect(direction, str(mirrors[str(index)]))
					position += direction
					continue
				if occupied.has(str(index)):
					var post_type: String = str(post_types.get(str(index), "normal"))
					var can_cast: bool = true
					if post_type == "plate_v" and direction.x == 0:
						can_cast = false
					elif post_type == "plate_h" and direction.y == 0:
						can_cast = false
					if can_cast:
						var reach: int = 2 if post_type == "tall" else 1
						for distance: int in range(1, reach + 1):
							var target: Vector2i = position + direction * distance
							if target.x >= 0 and target.x < 5 and target.y >= 0 and target.y < 5:
								result[target.y * 5 + target.x] += 1
				position += direction
	return result

static func compute_stage_shadow(stage: Dictionary, posts: Array, base_lights: Array, shutters: Array = [], post_types: Dictionary = {}) -> Array[int]:
	var active: Array = effective_lights(stage, posts, base_lights)
	if stage.has("blockers") or stage.has("mirrors"):
		return _compute_beam_shadow(stage, posts, active, shutters, post_types)
	return compute_shadow(posts, active, shutters, post_types)

static func matches(shadow: Array, target: Dictionary, ignored_cells: Array = []) -> bool:
	for index: int in 25:
		var code: String = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
		if ignored_cells.has(code):
			continue
		if shadow[index] != int(target.get(code, 0)):
			return false
	return true

static func board_shape_mask(stage: Dictionary) -> PackedByteArray:
	var result: PackedByteArray = PackedByteArray()
	result.resize(25)
	result.fill(1)
	if not stage.has("boardShape"):
		return result
	var board_shape: Variant = stage["boardShape"]
	if typeof(board_shape) != TYPE_DICTIONARY:
		return PackedByteArray()
	var raw_mask: Variant = (board_shape as Dictionary).get("mask", null)
	if typeof(raw_mask) != TYPE_ARRAY or (raw_mask as Array).size() != 5:
		return PackedByteArray()
	for row_index: int in 5:
		var row_value: Variant = (raw_mask as Array)[row_index]
		if typeof(row_value) != TYPE_STRING:
			return PackedByteArray()
		var row: String = str(row_value)
		if row.length() != 5:
			return PackedByteArray()
		for column: int in 5:
			var token: String = row.substr(column, 1)
			if token != "0" and token != "1":
				return PackedByteArray()
			result[row_index * 5 + column] = 1 if token == "1" else 0
	return result

static func valid_post_type(post_type: String) -> bool:
	return post_type in ["normal", "tall", "plate_v", "plate_h"]

static func exact_typed_inventory(stage: Dictionary, posts: Array, post_types: Dictionary) -> bool:
	var has_typed_inventory: bool = stage.has("normal_posts") or stage.has("tall_posts") or stage.has("plate_posts")
	if not has_typed_inventory:
		return true
	var expected_normal: int = int(stage.get("normal_posts", 0))
	var expected_tall: int = int(stage.get("tall_posts", 0))
	var expected_plate: int = int(stage.get("plate_posts", 0))
	if expected_normal + expected_tall + expected_plate != int(stage["posts"]):
		return false
	var normal_count: int = 0
	var tall_count: int = 0
	var plate_count: int = 0
	var seen: Dictionary = {}
	for raw_index: Variant in posts:
		var key: String = str(int(raw_index))
		if seen.has(key) or not post_types.has(key):
			return false
		seen[key] = true
		var post_type: String = str(post_types[key])
		match post_type:
			"normal":
				normal_count += 1
			"tall":
				tall_count += 1
			"plate_v", "plate_h":
				plate_count += 1
			_:
				return false
	for raw_key: Variant in post_types.keys():
		if not seen.has(str(raw_key)):
			return false
	return normal_count == expected_normal and tall_count == expected_tall and plate_count == expected_plate

static func solved(stage: Dictionary, posts: Array, shutters: Array, lights: Array, post_types: Dictionary = {}) -> bool:
	if posts.size() != int(stage["posts"]):
		return false
	var allowed_sockets: PackedByteArray = board_shape_mask(stage)
	if allowed_sockets.size() != 25:
		return false
	var seen_positions: Dictionary = {}
	for raw_index: Variant in posts:
		var post_index: int = int(raw_index)
		if post_index < 0 or post_index >= 25 or allowed_sockets[post_index] == 0 or seen_positions.has(str(post_index)):
			return false
		if apparatus_occupies(stage, post_index):
			return false
		seen_positions[str(post_index)] = true
	if stage.get("movable_shutter", false) and shutters.size() != 1:
		return false
	if (stage.get("light_puzzle", false) or stage.get("free_light_selection", false)) and stage.has("active_light_count") and lights.size() != int(stage["active_light_count"]):
		return false
	if stage.get("free_light_selection", false) and lights.is_empty():
		return false
	var types: Dictionary = post_types.duplicate()
	if stage.get("tall", false):
		for index: Variant in posts:
			types[str(index)] = "tall"
	for index: Variant in posts:
		var post_type: String = str(types.get(str(index), "normal"))
		if not valid_post_type(post_type):
			return false
	if not exact_typed_inventory(stage, posts, types):
		return false
	for observation: Dictionary in stage["observations"]:
		var use_live_lights: bool = stage.get("light_puzzle", false) or stage.get("free_light_selection", false)
		var base_active: Array = lights if use_live_lights else observation["active_lights"]
		if not matches(compute_stage_shadow(stage, posts, base_active, shutters, types), observation["target"], stage.get("fog_cells", [])):
			return false
	return true
