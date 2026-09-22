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

static func solved(stage: Dictionary, posts: Array, shutters: Array, lights: Array) -> bool:
	if posts.size() != int(stage["posts"]):
		return false
	if stage.get("movable_shutter", false) and shutters.size() != 1:
		return false
	if stage.get("light_puzzle", false) and lights.size() != int(stage.get("active_light_count", 2)):
		return false
	var types: Dictionary = {}
	if stage.get("tall", false):
		for index: Variant in posts:
			types[str(index)] = "tall"
	for observation: Dictionary in stage["observations"]:
		var active: Array = lights if stage.get("light_puzzle", false) else observation["active_lights"]
		if not matches(compute_shadow(posts, active, shutters, types), observation["target"]):
			return false
	return true
