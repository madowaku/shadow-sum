extends RefCounted

const EN := "en"
const JA := "ja"

const UI := {
	"en": {
		"subtitle": "A QUIET STUDY OF LIGHT",
		"target": "TARGET",
		"live": "YOUR SHADOW",
		"instrument": "PLACE THE POSTS",
		"legend": "Tap to place  ·  Tap again to remove  ·  Drag to move",
		"collection": "%02d / %02d SHADOWS KEPT",
		"posts": "%d / %d POSTS  ·  %s",
		"reset": "RESET",
		"undo": "UNDO",
		"back": "‹  BACK",
		"next": "NEXT  ›",
		"hint": "HINT",
		"language_to_ja": "JP",
		"language_to_en": "EN",
		"sound_on": "Music + SFX on · M to mute",
		"sound_off": "Music + SFX off · M to unmute",
		"mute": "Mute sound",
		"unmute": "Enable sound",
		"help_tooltip": "How to play · ? or F1",
		"undo_tooltip": "Undo the last move · Ctrl+Z",
		"reset_tooltip": "Start this puzzle again · You can undo a reset",
		"back_tooltip": "Previous puzzle",
		"hint_tooltip": "A small nudge, one step at a time",
		"next_tooltip": "Continue to the next shadow",
		"place_post": "Place a post",
		"move_post": "Tap to remove or drag to move",
		"help_kicker": "HOW TO PLAY",
		"help_heading": "Give shape to the light.",
		"help_rule_1_title": "01   Place a post",
		"help_rule_1_body": "Tap an empty socket. Light from above, left and right casts a shadow into the three neighboring cells.",
		"help_rule_2_title": "02   Match the target",
		"help_rule_2_body": "Use every post. Make YOUR SHADOW match each visible TARGET cell. Overlapping shadows become darker.",
		"help_rule_3_title": "03   Leave room for the unknown",
		"help_rule_3_body": "A ? is unobserved, not empty. It can hold any amount of shadow. Clear glass means no shadow.",
		"clear": "CLEAR",
		"keys": "Take your time. Try HINT for a small nudge.\nTab / arrows: focus  ·  Space / Enter: place\nCtrl+Z: undo  ·  M: sound  ·  L: language  ·  ?: help",
		"close_help": "BACK TO THE PUZZLE",
		"close_help_tooltip": "Close help · Escape",
		"switch_to_ja": "日本語に切り替え",
		"switch_to_en": "Switch to English"
	},
	"ja": {
		"subtitle": "光を静かに観察する",
		"target": "ターゲット",
		"live": "あなたの影",
		"instrument": "ポストを配置",
		"legend": "タップで配置  ·  もう一度で解除  ·  ドラッグで移動",
		"collection": "%02d / %02d 個の影を記録",
		"posts": "%d / %d ポスト  ·  %s",
		"reset": "リセット",
		"undo": "戻す",
		"back": "‹  戻る",
		"next": "次へ  ›",
		"hint": "ヒント",
		"language_to_ja": "JP",
		"language_to_en": "EN",
		"sound_on": "BGM + SE ON · Mでミュート",
		"sound_off": "BGM + SE OFF · Mで解除",
		"mute": "サウンドをミュート",
		"unmute": "サウンドを有効化",
		"help_tooltip": "遊び方 · ? または F1",
		"undo_tooltip": "直前の手を戻す · Ctrl+Z",
		"reset_tooltip": "このパズルを最初からやり直す",
		"back_tooltip": "前のパズルへ",
		"hint_tooltip": "一歩ずつ進むための小さなヒント",
		"next_tooltip": "次の影へ進む",
		"place_post": "ポストを配置",
		"move_post": "タップで解除 / ドラッグで移動",
		"help_kicker": "遊び方",
		"help_heading": "光に形を与える。",
		"help_rule_1_title": "01   ポストを置く",
		"help_rule_1_body": "空いたソケットをタップ。上・左・右の光が、隣り合う3つのセルに影を落とします。",
		"help_rule_2_title": "02   ターゲットに合わせる",
		"help_rule_2_body": "すべてのポストを使い、見えているターゲットとあなたの影を一致させます。重なるほど影は濃くなります。",
		"help_rule_3_title": "03   未知の余白を残す",
		"help_rule_3_body": "? は空ではなく未観測です。どんな濃さの影も入りえます。透明なガラスは影がないことを示します。",
		"clear": "透明",
		"keys": "急がずに考えましょう。HINTで小さなヒントを表示できます。\nTab / 矢印: フォーカス  ·  Space / Enter: 配置\nCtrl+Z: 戻す  ·  M: サウンド  ·  L: 言語  ·  ?: 遊び方",
		"close_help": "パズルへ戻る",
		"close_help_tooltip": "遊び方を閉じる · Escape",
		"switch_to_ja": "日本語に切り替え",
		"switch_to_en": "英語に切り替え"
	}
}

const STAGE_TITLES := {
	"FIRST LIGHT": "初めての光",
	"OVERLAP": "重なり",
	"BLACK CORE": "黒い核",
	"FIRST FROST": "最初の霜",
	"CLEAR PATH": "透明な道",
	"AT THE EDGE": "境界線",
	"THREAD": "糸",
	"CROSSCURRENT": "交差する流れ",
	"STILL WATER": "静かな水面",
	"ONE LEFT": "残りひとつ",
	"TWO LEFT": "残りふたつ",
	"DIFFERENCE": "差分",
	"FALSE SHADOW": "偽りの影",
	"TWO DOORS": "ふたつの扉",
	"EXHALE": "息を吐く",
	"AFTERGLOW": "余光",
	"A SMALL DOUBT": "小さな疑い",
	"AFTERIMAGE": "残像"
}

const TIERS := {
	"INTRO": "はじめに",
	"FOG": "霧",
	"LINKS": "つながり",
	"BALANCE": "均衡",
	"DOUBT": "疑い",
	"AFTERGLOW": "余光"
}


const NEXT_LABELS_JA := {
	"NEXT  ›": "次へ  ›",
	"COMPLETE  ◐": "完了  ◐",
	"NEXT SHADOW  ›": "次の影  ›",
	"FINISH  ◐": "終了  ◐"
}

const STATUS_JA := {
	"v0.1 COMPLETE  ◐": "v0.1 完了  ◐",
	"All posts are in use. Tap one to move it.": "ポストはすべて使用中です。ひとつ選んで移動します。",
	"Tap a socket. Watch where its three shadows go.": "ソケットをタップ。3方向に落ちる影を見てみましょう。",
	"Move the post until your shadow matches the target.": "影がターゲットと重なるまでポストを動かします。",
	"All posts placed. Move one to shape the shadow.": "ポストを置き終えました。ひとつ動かして影を整えます。",
	"Shape the observed shadow.": "観測された影を形づくります。",
	"SHADOW COMPLETE": "影の完成",
	"18 SHADOWS KEPT. Thank you for playing.": "18個の影を記録しました。プレイありがとう。",
	"PICKED  ·  slide to another socket": "選択中  ·  別のソケットへスライド",
	"SLIDE  ·  release to click into place": "スライド  ·  離して配置",
	"CLEAR GLASS  =  NO SHADOW": "透明なガラス  =  影なし",
	"FOGGED GLASS  =  SHADOW UNOBSERVED": "曇ったガラス  =  影は未観測",
	"FOGGED  =  UNOBSERVED": "曇り  =  未観測",
	"UNKNOWN  ≠  ZERO": "未知  ≠  0"
}

static func copy(key: String, language: String) -> String:
	var table: Dictionary = UI.get(language, UI[EN])
	return String(table.get(key, key))

static func stage_title(title: String, language: String) -> String:
	if language == JA:
		return String(STAGE_TITLES.get(title, title))
	return title.capitalize()

static func tier_name(tier: String, language: String) -> String:
	if language == JA:
		return String(TIERS.get(tier, tier))
	return tier

static func to_english(raw: String) -> String:
	if STATUS_JA.has(raw):
		return raw
	for english: String in STATUS_JA:
		if STATUS_JA[english] == raw:
			return english
	for english_tier: String in TIERS:
		if raw == String(TIERS[english_tier]) + "の光を解放しました。":
			return english_tier + " LIGHT UNLOCKED"
	return raw

static func next_button(raw: String, language: String) -> String:
	var english := raw
	for key: String in NEXT_LABELS_JA:
		if NEXT_LABELS_JA[key] == raw:
			english = key
			break
	if language == JA:
		return String(NEXT_LABELS_JA.get(english, english))
	return english

static func status(raw: String, language: String) -> String:
	var english := to_english(raw)
	if language == JA:
		if english.ends_with(" LIGHT UNLOCKED"):
			var tier: String = english.trim_suffix(" LIGHT UNLOCKED")
			return String(TIERS.get(tier, tier)) + "の光を解放しました。"
		return String(STATUS_JA.get(english, english))
	return english


