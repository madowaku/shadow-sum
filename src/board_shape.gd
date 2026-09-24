extends RefCounted

# Placement only. ShadowRules intentionally has no dependency on this class.
const SIZE: int = 5
const FULL: int = (1 << (SIZE * SIZE)) - 1
var enabled_bits: int = FULL
var enabled_count: int = SIZE * SIZE

static func validation_error(stage: Dictionary) -> String:
	if not stage.has("boardShape"):
		return ""
	var shape: Variant = stage["boardShape"]
	if not shape is Dictionary:
		return "boardShape must be an object"
	if shape.get("type") != "mask":
		return "boardShape.type must be mask"
	for dimension: String in ["width", "height"]:
		var value: Variant = shape.get(dimension)
		if not (value is int or value is float) or value != SIZE:
			return "boardShape.%s must be 5" % dimension
	var mask: Variant = shape.get("mask")
	if not mask is Array or mask.size() != SIZE:
		return "boardShape.mask must contain five rows"
	var count: int = 0
	for row: Variant in mask:
		if not row is String or row.length() != SIZE:
			return "boardShape.mask rows must be five-character strings"
		for character: String in row:
			if character not in ["0", "1"]:
				return "boardShape.mask accepts only 0 and 1"
			count += int(character == "1")
	if count == 0:
		return "boardShape must enable at least one socket"
	if int(stage.get("posts", 0)) > count:
		return "Post count exceeds enabled socket count"
	return ""

func load_stage(stage: Dictionary, diagnose: bool = true) -> bool:
	# Reset first, including when moving from a variant to an old stage.
	enabled_bits = FULL
	enabled_count = SIZE * SIZE
	var error: String = validation_error(stage)
	if not error.is_empty():
		if diagnose:
			push_warning("Stage %s: %s; using full board" % [str(stage.get("id", "?")), error])
		return false
	if not stage.has("boardShape"):
		return true
	enabled_bits = 0
	enabled_count = 0
	var mask: Array = stage["boardShape"]["mask"]
	for row: int in SIZE:
		for column: int in SIZE:
			if mask[row][column] == "1":
				enabled_bits |= 1 << (row * SIZE + column)
				enabled_count += 1
	return true

func is_socket_enabled(row: int, column: int) -> bool:
	return row >= 0 and row < SIZE and column >= 0 and column < SIZE and (enabled_bits & (1 << (row * SIZE + column))) != 0

func get_enabled_socket_count() -> int:
	return enabled_count

func filter_posts(board: Array, diagnose: bool = true) -> Array:
	# Call after the existing save schema/type validation.
	var filtered: Array = board.duplicate(true)
	for row: int in SIZE:
		for column: int in SIZE:
			if filtered[row][column] and not is_socket_enabled(row, column):
				filtered[row][column] = false
				if diagnose:
					push_warning("Ignored restored Post at disabled socket (%d, %d)" % [row, column])
	return filtered
