extends RefCounted

# SHADOW SUM v0.1.7 MONOCHROME NIGHT
# Static design tokens for the nocturnal optical-instrument skin.

const BG_BASE := Color("#090B0D")
const BG_ELEVATED := Color("#11151A")
const BG_PANEL := Color("#151A20")
const BG_SOCKET := Color("#0E1216")
const BG_BUTTON := Color("#12171C")

const LINE_SOFT := Color("#27303A")
const LINE_MEDIUM := Color("#33404A")
const LINE_BRIGHT := Color("#445460")

const TEXT_PRIMARY := Color("#EEF2F4")
const TEXT_SECONDARY := Color("#A9B3BA")
const TEXT_MUTED := Color("#7F8B94")

const GOLD := Color("#D6B16B")
const GOLD_SOFT := Color("#B89B66")
const CYAN := Color("#8FCFD6")
const CYAN_SOFT := Color("#6EAAB2")
const RED := Color("#B56B6B")

const TARGET_FRAME := Color("#50483A")
const LIVE_FRAME := Color("#344950")

const SHADOW_0 := Color("#DDE4E5")
const SHADOW_1 := Color("#AAB4B8")
const SHADOW_2 := Color("#727E84")
const SHADOW_3 := Color("#353D43")
const SHADOW_UNKNOWN := Color("#5A656C")
const SHADOW_UNKNOWN_BORDER := Color("#7A858B")

# GLASS & METAL v0.1.7b
# These are material accents layered over the readable v0.1.7a values. The
# four shadow levels above remain the semantic source of contrast.
const GLASS_HIGHLIGHT := Color(1.0, 1.0, 1.0, 0.11)
const GLASS_LOWLIGHT := Color(0.0, 0.0, 0.0, 0.14)
const GLASS_FOG := Color(0.78, 0.84, 0.87, 0.10)
const GLASS_GRAIN := Color(1.0, 1.0, 1.0, 0.045)
const GLASS_TARGET_WARM := Color(0.86, 0.74, 0.54, 0.055)
const GLASS_LIVE_COOL := Color(0.56, 0.82, 0.86, 0.050)

const METAL_TOP := Color("#56616A")
const METAL_TOP_INNER := Color("#3E474F")
const METAL_SIDE := Color("#20272D")
const METAL_SIDE_DARK := Color("#151B20")
const METAL_RIM := Color("#697781")
const METAL_SPECULAR := Color(1.0, 1.0, 1.0, 0.22)

const SOCKET_INNER := Color("#090D10")
const SOCKET_INNER_BOTTOM := Color("#0D1216")
const SOCKET_RIM := Color("#2C3740")
const SOCKET_RIM_INNER := Color("#182027")
const SOCKET_ACTIVE := Color("#6EAAB2")
const SOCKET_SETTLED := Color("#8E774D")
const PANEL_SHADOW := Color(0.0, 0.0, 0.0, 0.32)

# Legacy names retained while the material layer migrates visual ownership.
const POST_TOP := Color("#C9C2B7")
const POST_BODY := Color("#171C21")
const POST_RING := Color("#746347")

const RADIUS_CELL := 8
const RADIUS_PANEL := 14
const RADIUS_SOCKET := 10
const RADIUS_BUTTON := 16

const TITLE_DESKTOP := 29
const TITLE_COMPACT := 25
const STAGE_DESKTOP := 14
const STAGE_COMPACT := 12
const COUNTER_DESKTOP := 12
const COUNTER_COMPACT := 10
const STATUS_DESKTOP := 14
const STATUS_COMPACT := 12
const MICRO_DESKTOP := 10
const MICRO_COMPACT := 9

static func display_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Cormorant Garamond", "Georgia", "serif"])
	font.font_weight = 500
	font.allow_system_fallback = true
	return font

static func instrument_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["IBM Plex Mono", "Consolas", "monospace"])
	font.font_weight = 500
	font.allow_system_fallback = true
	return font

static func body_font() -> Font:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Zen Kaku Gothic New", "Yu Gothic UI", "Meiryo", "sans-serif"])
	font.font_weight = 400
	font.allow_system_fallback = true
	return font
