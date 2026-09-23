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
		var active: Array = lights if use_live_lights else observation["active_lights"]
		if not matches(compute_shadow(posts, active, shutters, types), observation["target"], stage.get("fog_cells", [])):
			return false
	return true
