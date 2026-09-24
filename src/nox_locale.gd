extends RefCounted

const Settings = preload("res://src/nox_settings.gd")

const JAPANESE: Dictionary = {
	"NOCTURNAL\nOPTICAL ARCHIVE": "夜の光学記録室",
	"SETTINGS": "設定",
	"A  N O C T U R N A L  M Y S T E R Y": "夜の記録を再構成する物語",
	"RECONSTRUCT THE PAST\nFROM THE SHADOWS": "影から、NOXのいた夜を組み立てる。",
	"NOX is gone. The shadows remember.": "NOXはいない。影は覚えている。",
	"P L A Y     ›": "はじめる     ›",
	"C O N T I N U E     ›": "つづきから     ›",
	"V I E W  R E C O R D S     ›": "記録を見直す     ›",
	"36 shadow records await.": "36枚の影の記録が待っている。",
	"ABOUT": "物語",
	"HOW TO PLAY": "遊び方",
	"GALLERY": "記録一覧",
	"OBSERVE.   CONNECT.   UNCOVER.": "観察する。つなげる。見つける。",
	"THE ARCHIVE": "記録室",
	"CLOSE  ×": "閉じる  ×",
	"THE SHADOW ARCHIVE": "影の記録",
	"The archive kept only the shadows.": "記録室に残されたのは影だけ。",
	"NOX was nowhere to be found. In the old Nocturnal Optical Archive, a single plate can hold the shadows of several moments.": "NOXの姿はどこにもなかった。古い夜の光学記録室では、一枚の記録板にいくつもの瞬間の影が残る。",
	"A quiet act of reconstruction": "静かな再構築",
	"Place NOX's traces where the recorded shadows agree. Each pose belongs to the same cat, seen at a different moment. The record reveals where NOX was, but keeps the order of those moments to itself.": "記録された影に合う場所へ、NOXの痕跡を置こう。姿勢が違っても、映っているのは別の瞬間の同じ猫。記録から居場所はわかる。ただし、その順番まではわからない。",
	"36 records. One unanswered question.": "36枚の記録。残るひとつの問い。",
	"Follow the evidence deeper into the archive. What drew NOX into the night?": "資料室の奥へ、証拠を追っていこう。NOXは夜に何を見つけたのだろう。",
	"01  Read the plate": "01  記録板を読む",
	"Compare RECORDED SHADOW with your RECONSTRUCTION. Darker squares hold more overlapping shadows. A question mark is an unrecorded area.": "「記録された影」と「再構築」を比べよう。影が重なるマスほど濃くなる。？は記録されていない場所。",
	"02  Place a NOX trace": "02  NOXの痕跡を置く",
	"Choose a pose, then click a board position, or drag it onto the board. Click a placed SIT or STAND trace to remove it; drag any trace to move it. Drag a WALK trace back to its tray to remove it. Several traces show different moments of the same cat.": "姿勢を選び、盤面の位置をクリックするかドラッグして置こう。置いたSIT・STANDはクリックで外せる。痕跡はドラッグで動かせる。WALKはトレイへ戻すと外れる。複数の痕跡は、同じ猫の別々の瞬間を表す。",
	"03  Observe the light": "03  光を観察する",
	"SIT leaves a nearby trace. STAND reaches farther. WALK has a direction: click WALK or a placed WALK trace to turn it. Available light sources can be switched. SLEEP rests on the rail and blocks the light above its column.": "SITの影は近くに、STANDの影は遠くまで届く。WALKには向きがあり、駒をクリックすると回せる。切り替えられる光源もある。レールで眠るSLEEPは、その列の上からの光を遮る。",
	"04  Let the shadows agree": "04  影を一致させる",
	"Match every recorded square with the available poses and light sources. UNDO takes back one move. RESET clears this reconstruction. OBSERVE offers a clue without placing an answer.": "使える姿勢と光源で、記録されたすべてのマスを一致させよう。「戻す」は一手戻し、「やり直す」は配置を消す。「観察」では答えを置かずに手がかりを読める。",
	"Take your time": "急がなくて大丈夫",
	"There is no timer or penalty. Progress is saved in this browser. Use the GALLERY to revisit any of the 36 records. Escape closes a panel.": "制限時間もペナルティもない。進行はこのブラウザに保存される。記録一覧から36枚のどれでも見直せる。Escキーでパネルを閉じられる。",
	"A quieter room": "静かな記録室",
	"Choose how the archive feels. These preferences are saved on this device.": "表示と音を選べます。設定はこの端末に保存されます。",
	"Sound": "音声",
	"Reduce motion": "動きを抑える",
	"Language": "言語",
	"Made for a moment of attention": "思考を楽しむために",
	"Headphones are optional. Every puzzle can be solved without sound.": "ヘッドホンは任意です。すべての問題は音なしでも解けます。",
	"‹  HOME": "‹  ホーム",
	"RECORDED SHADOW": "記録された影",
	"RECONSTRUCTION": "再構築",
	"WHERE WAS NOX?": "NOXはどこにいた？",
	"BACK": "戻る",
	"RESET": "やり直す",
	"UNDO": "一手戻す",
	"OBSERVE": "観察",
	"NEXT  ›": "次へ  ›",
	"NEXT": "次へ",
	"HOME": "ホーム",
	"SIT": "座る",
	"STAND": "立つ",
	"WALK": "歩く",
	"SLEEP": "眠る",
	"ON": "点灯",
	"OFF": "消灯",
	"SIT · NOX sat here, leaving a nearby shadow.": "座る：NOXがその場所に座っていた痕跡",
	"STAND · A taller shadow reaches farther.": "立つ：より高い影を作る痕跡",
	"WALK · A directional trace. Click to turn.": "歩く：向きのある痕跡。クリックで回せる",
	"SLEEP · Resting on the rail blocks light.": "眠る：レールで光を遮る痕跡",
	"TOP LIGHT · Light from above.": "上の光：上から照らす",
	"LEFT LIGHT · Light from the left.": "左の光：左から照らす",
	"RIGHT LIGHT · Light from the right.": "右の光：右から照らす",
	"BOTTOM LIGHT · Light from below.": "下の光：下から照らす",
	"TOP LIGHT": "上の光",
	"LEFT LIGHT": "左の光",
	"RIGHT LIGHT": "右の光",
	"BOTTOM LIGHT": "下の光",
	"SLEEP · rail ": "眠る · レール ",
	"NOX TRACE · ": "NOXの痕跡 · ",
	" · click to turn": " · クリックで向きを変える",
	"Choose a pose, then a position.": "姿勢を選び、位置を指定しよう。",
	"Match both plates. Choose a pose and square.": "二つの影を比べ、姿勢とマスを選ぼう。",
	"① Compare both plates. Choose NOX below.": "① 二つの影を比べ、下のNOXを選ぼう。",
	"② Tap a square to place NOX.": "② マスをタップしてNOXを置こう。",
	"③ Match every shade on both plates.": "③ 二つの影の濃さをすべて合わせよう。",
	"Every shadow agrees.": "すべての影が一致した。",
	"Turn off one light before choosing another.": "別の光を選ぶ前に、一つ消そう。",
	"?  UNRECORDED": "？ 未記録",
	"A gentle clue": "小さな手がかり",
	"Observe the record. Let every shadow agree.": "記録を観察しよう。すべての影を一致させよう。",
	"FOG: unobserved, not zero": "未観測。影がないとは限らない",
	"TRACE MATCHED": "痕跡が一致した",
	"RECONSTRUCTION COMPLETE": "再構築完了",
	"records reconstructed": "枚の記録を再構築",
	"OBSERVE ": "観察 ",
}

static func language() -> String:
	var stored: String = str(Settings.read_value("language", "en"))
	return "ja" if stored == "ja" else "en"

static func is_japanese() -> bool:
	return language() == "ja"

static func set_language(value: String) -> void:
	Settings.write_value("language", "ja" if value == "ja" else "en")

static func toggle() -> void:
	set_language("en" if is_japanese() else "ja")

static func switch_label() -> String:
	return "EN" if is_japanese() else "日本語"

static func copy(english: String) -> String:
	return str(JAPANESE.get(english, english)) if is_japanese() else english

static func pose_description(pose: String) -> String:
	match pose:
		"tall":
			return copy("STAND · A taller shadow reaches farther.")
		"plate_h", "plate_v":
			return copy("WALK · A directional trace. Click to turn.")
		"sleep":
			return copy("SLEEP · Resting on the rail blocks light.")
		_:
			return copy("SIT · NOX sat here, leaving a nearby shadow.")

static func light_description(direction: String) -> String:
	match direction:
		"LEFT":
			return copy("LEFT LIGHT · Light from the left.")
		"RIGHT":
			return copy("RIGHT LIGHT · Light from the right.")
		"BOTTOM":
			return copy("BOTTOM LIGHT · Light from below.")
		_:
			return copy("TOP LIGHT · Light from above.")

static func progress(count: int) -> String:
	return "%02d / 36  枚を再構築" % count if is_japanese() else "%02d / 36  RECORDS RECONSTRUCTED" % count

static func trace_heading(index: int, title: String) -> String:
	return "記録 %02d  /  %s" % [index + 1, title] if is_japanese() else "TRACE %02d  /  %s" % [index + 1, title]

static func light_count(count: int, maximum: int) -> String:
	return "光源  %d / %d" % [count, maximum] if is_japanese() else "LIGHT SOURCES  %d / %d" % [count, maximum]

static func solved(count: int, maximum: int) -> String:
	var heading: String = copy("RECONSTRUCTION COMPLETE" if count == maximum else "TRACE MATCHED")
	return heading + ("\n%02d / %02d 枚の記録を再構築" if is_japanese() else "\n%02d / %02d records reconstructed") % [count, maximum]

static func bind_text(node: Control, english: String) -> void:
	node.set_meta("nox_english", english)
	if node is Label:
		(node as Label).text = copy(english)
	elif node is Button:
		(node as Button).text = copy(english)

static func bind_tooltip(node: Control, english: String) -> void:
	node.set_meta("nox_tooltip", english)
	node.tooltip_text = copy(english)

static func bind_slot(node: Control, english: String) -> void:
	node.set_meta("nox_slot", english)
	node.set("slot_label", copy(english))
	node.queue_redraw()

static func refresh_bound(root: Node) -> void:
	if root is Control:
		var control: Control = root as Control
		if control.has_meta("nox_english"):
			bind_text(control, str(control.get_meta("nox_english")))
		if control.has_meta("nox_tooltip"):
			bind_tooltip(control, str(control.get_meta("nox_tooltip")))
		if control.has_meta("nox_slot"):
			bind_slot(control, str(control.get_meta("nox_slot")))
	for child: Node in root.get_children():
		refresh_bound(child)