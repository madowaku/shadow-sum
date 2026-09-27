extends RefCounted

const SERIF: Font = preload("res://assets/fonts/Display.tres")
const BODY: Font = preload("res://assets/fonts/Body.tres")
const JAPANESE: Font = preload("res://assets/fonts/NotoSansJP-VF.ttf")
const INK: Color = Color("#090f18")
const IVORY: Color = Color("#eee7d8")
const SOFT: Color = Color("#cbd6dd")
const BRASS: Color = Color("#dfc08d")

static func label(parent: Node, value: String, font_size: int = 12, color: Color = IVORY, serif: bool = false) -> Label:
	var node: Label = Label.new()
	node.text = value
	node.add_theme_font_override("font", SERIF if serif else BODY)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func box(fill: Color, border: Color, radius: int = 4, inset: int = 8) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = inset
	style.content_margin_right = inset
	style.content_margin_top = inset
	style.content_margin_bottom = inset
	return style

static func button(value: String, height: float = 44.0, primary: bool = false) -> Button:
	var node: Button = Button.new()
	node.text = value
	node.custom_minimum_size.y = height
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", SERIF if primary else BODY)
	node.add_theme_font_size_override("font_size", 25 if primary else 12)
	node.add_theme_color_override("font_color", IVORY)
	node.add_theme_color_override("font_hover_color", Color.WHITE)
	node.add_theme_color_override("font_disabled_color", Color("#64717e"))
	var normal: StyleBoxFlat = box(Color(0.04, 0.07, 0.10, 0.80), Color(BRASS, 0.65 if primary else 0.22), 18 if primary else 4, 10)
	node.add_theme_stylebox_override("normal", normal)
	var hover: StyleBoxFlat = normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#26343e")
	hover.border_color = BRASS
	node.add_theme_stylebox_override("hover", hover)
	var pressed: StyleBoxFlat = hover.duplicate() as StyleBoxFlat
	pressed.bg_color = INK
	node.add_theme_stylebox_override("pressed", pressed)
	node.add_theme_stylebox_override("disabled", normal)
	var focus: StyleBoxFlat = box(Color.TRANSPARENT, IVORY, 4, 0)
	focus.draw_center = false
	focus.set_border_width_all(2)
	node.add_theme_stylebox_override("focus", focus)
	return node

static func margin(parent: Node, amount: int) -> MarginContainer:
	var node: MarginContainer = MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		node.add_theme_constant_override("margin_" + side, amount)
	parent.add_child(node)
	return node

static func ensure_japanese_font() -> void:
	var fonts: Array[Font] = [JAPANESE]
	var serif: Font = SERIF
	var body: Font = BODY
	serif.fallbacks = fonts
	body.fallbacks = fonts