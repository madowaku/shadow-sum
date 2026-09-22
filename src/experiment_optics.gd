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
		var reach: int = 2 if post_types.get(str(index), "normal") == "tall" else 1
		for light: String in active_lights:
			if light == "TOP" and shutters.has(origin.x):
				continue
			for distance: int in range(1, reach + 1):
				var target: Vector2i = origin + (DIRECTIONS[light] as Vector2i) * distance
				if target.x >= 0 and target.x < 5 and target.y >= 0 and target.y < 5:
					result[target.y * 5 + target.x] += 1
	return result

static func matches(shadow: Array, target: Dictionary) -> bool:
	for index: int in 25:
		var code: String = String.chr(65 + index % 5) + str(int(index / 5.0) + 1)
		if shadow[index] != int(target.get(code, 0)):
			return false
	return true

static func solved(stage: Dictionary, posts: Array, shutters: Array, lights: Array, post_types: Dictionary = {}) -> bool:
	if posts.size() != int(stage["posts"]):
		return false
	if stage.get("movable_shutter", false) and shutters.size() != 1:
		return false
	if stage.get("light_puzzle", false) and stage.has("active_light_count") and lights.size() != int(stage["active_light_count"]):
		return false
	if stage.get("free_light_selection", false) and lights.is_empty():
		return false
	var types: Dictionary = post_types.duplicate()
	if stage.get("tall", false):
		for index: Variant in posts:
			types[str(index)] = "tall"
	if stage.has("normal_posts") or stage.has("tall_posts"):
		var normal_count: int = 0
		var tall_count: int = 0
		for index: Variant in posts:
			if types.get(str(index), "normal") == "tall":
				tall_count += 1
			else:
				normal_count += 1
		if normal_count != int(stage.get("normal_posts", 0)) or tall_count != int(stage.get("tall_posts", 0)):
			return false
	for observation: Dictionary in stage["observations"]:
		var use_live_lights: bool = stage.get("light_puzzle", false) or stage.get("free_light_selection", false)
		var active: Array = lights if use_live_lights else observation["active_lights"]
		if not matches(compute_shadow(posts, active, shutters, types), observation["target"]):
			return false
	return true
