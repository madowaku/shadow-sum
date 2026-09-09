class_name ShadowRules
extends RefCounted

const BOARD_SIZE := 5

static func make_empty_posts() -> Array:
	var posts: Array = []
	for _r in BOARD_SIZE:
		var row: Array = []
		for _c in BOARD_SIZE:
			row.append(false)
		posts.append(row)
	return posts

static func compute_shadow(posts: Array) -> Array:
	var shadow: Array = []
	for r in BOARD_SIZE:
		var row: Array = []
		for c in BOARD_SIZE:
			var value := 0
			if r > 0 and posts[r - 1][c]:
				value += 1
			if c > 0 and posts[r][c - 1]:
				value += 1
			if c < BOARD_SIZE - 1 and posts[r][c + 1]:
				value += 1
			row.append(value)
		shadow.append(row)
	return shadow

static func count_posts(posts: Array) -> int:
	var total := 0
	for row in posts:
		for occupied in row:
			if occupied:
				total += 1
	return total

static func matches_visible_clues(shadow: Array, clues: Array) -> bool:
	for r in BOARD_SIZE:
		for c in BOARD_SIZE:
			var clue: int = int(clues[r][c])
			if clue >= 0 and int(shadow[r][c]) != clue:
				return false
	return true

static func glyph(value: int) -> String:
	match value:
		0:
			return "·"
		1:
			return "░"
		2:
			return "▒"
		3:
			return "▓"
		_:
			return "?"
