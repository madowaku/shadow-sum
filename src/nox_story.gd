extends RefCounted

# Display-only copy for the 36 validated Grant puzzles. Keep puzzle rules in data.
# These descriptions identify evidence on a plate; they do not establish time order.
const CHAPTERS: Array[String] = [
	"FIRST OBSERVATIONS",
	"LIGHT & INTERRUPTION",
	"HEIGHT & DIRECTION",
	"READING THE PLATE",
	"LAYERED RECORDS",
	"THE LAST PLATES"
]

const CHAPTER_NOTES: Array[String] = [
	"Read each recorded mark against the places the plate leaves clear.",
	"Light paths and an ordinary sleeping cat can change what reaches the plate.",
	"SIT, STAND, and WALK leave distinct optical signatures.",
	"Compare absence, overlap, and direction across the record.",
	"Several ordinary causes can leave a dense shadow.",
	"The final records preserve only what the plate can show."
]

const TITLES: Array[String] = [
	"FIRST EXPOSURE", "OVERLAP", "CLEAR GLASS", "FOURTH SOURCE", "TWO SOURCES", "LIGHT & POSITION",
	"SLEEPING PLACE", "THE OCCLUDED RAY", "A HIGHER REACH", "MIXED SILHOUETTES", "WALKING DIRECTION", "CROSSING SHADOWS",
	"LIGHT OR EDGE", "HEIGHT IN GLASS", "PLATE & SLEEP", "TWO AXES", "REACH & EDGE", "LIGHT THROUGH A GAP",
	"THREE SILHOUETTES", "RECONSTRUCTION", "BLOCKED REACH", "WHICH DIRECTION", "LOCAL OR SHARED", "SHAPE OF THE SILENCE",
	"THE LONG WAY THROUGH", "BEYOND THE RAIL", "ANGLE OF LIGHT", "PLATE IN THE GAP", "VEILED SOCKETS", "PARTIAL CROSS",
	"UNSEEN POSITION", "THE LAST OPEN AXIS", "FOUR SILHOUETTES", "FOUR CAUSES AGREE", "DENSE BOARD SYNTHESIS", "THE SHAPED FINALE"
]

const STAGE_NOTES: Array[String] = [
	"Trace each mark back to a possible position.",
	"Where the record is darker, more than one shadow may overlap.",
	"Clear glass is part of the evidence.",
	"Compare the directions of the four light sources.",
	"Choose the illumination that accounts for the recorded marks.",
	"Position and light can be read together.",
	"A sleeping NOX can interrupt a beam by resting near the optical rail.",
	"Use the visible marks and absences to place the interruption.",
	"STAND reaches farther than SIT.",
	"Different silhouettes leave different lengths of shadow.",
	"WALK records a direction as well as a position.",
	"Crossing shadows can share the same plate.",
	"Consider both the light source and the edge of the plate.",
	"Height changes which marks a position can explain.",
	"The optical rail and NOX's pose both affect the record.",
	"Read each axis without assuming a path between positions.",
	"A long reach can be limited by an edge.",
	"A gap in the record can reveal an interrupted beam.",
	"Three silhouettes may belong to separate moments of the same NOX.",
	"Test each proposed position against the complete plate.",
	"An interrupted beam can hide a longer shadow.",
	"Direction and illumination can produce similar marks.",
	"Compare a local interruption with the full light pattern.",
	"Read the open and missing sockets together with every recorded shade.",
	"Follow the long trace through the narrow open axis, checking both its reach and the board edge.",
	"The record beyond the interrupted axis still carries evidence.",
	"Light direction and pose must agree with the plate.",
	"Use the plate in the gap to distinguish a pose from the direction that made its shadow.",
	"Treat the veiled sockets as evidence: a missing place on the board is not an empty recorded square.",
	"A partial crossing can still constrain the whole record.",
	"An unseen position may be ruled out by its expected shadow.",
	"Only one axis remains open; trace each possible cause through the complete record.",
	"Four silhouettes can still describe the same individual across moments.",
	"Combine the learned causes and check that all four fixed directions explain every recorded cell.",
	"Synthesize the poses, light directions, and board shape against the densest record yet.",
	"The four lights stay fixed. Read every overlap and absence against the shaped board before placing the final traces."
]

const CHAPTERS_JA: Array[String] = [
	"最初の観察",
	"光と遮り",
	"高さと向き",
	"盤面を読む",
	"重なり合う記録",
	"最後の盤面"
]

const CHAPTER_NOTES_JA: Array[String] = [
	"記録された印と、盤面に残された空白を照らし合わせましょう。",
	"光の道筋や、眠っている猫が、盤面に届く光を変えることがあります。",
	"「座る」、「立つ」、「歩く」は、それぞれ異なる影の形を残します。",
	"記録全体から、欠けた印、重なり、向きを比べましょう。",
	"濃い影を生む原因は、ひとつとは限りません。",
	"最後の記録に残されているのは、盤面が示すものだけです。"
]

const TITLES_JA: Array[String] = [
	"最初の記録", "重なり", "透明なガラス", "第四の光源", "二つの光源", "光と位置",
	"眠る場所", "遮られた光線", "高みへ伸びる影", "混ざり合うシルエット", "歩く向き", "交差する影",
	"光か、盤の縁か", "ガラスに映る高さ", "盤面と眠り", "二つの軸", "伸びと縁", "すき間を通る光",
	"三つのシルエット", "痕跡の再構成", "遮りの向こうの影", "どちら向きか", "局所か、共通か", "静寂のかたち",
	"長い道筋", "レールの向こう", "光の角度", "すき間の記録板", "覆われたソケット", "不完全な交差",
	"見えない位置", "最後に残る軸", "四つのシルエット", "四つの原因が一致する", "高密度盤面の総合", "変形盤面の終章"
]

const STAGE_NOTES_JA: Array[String] = [
	"それぞれの印から、あり得る位置をたどってみましょう。",
	"記録が濃い場所では、複数の影が重なっているかもしれません。",
	"透明なガラスも手がかりの一部です。",
	"四つの光源の向きを比べてみましょう。",
	"記録された印を説明できる照明を選びましょう。",
	"位置と光は、あわせて読み解けます。",
	"眠っているNOXが、光学レールの近くで休み、光路を遮ることがあります。",
	"見えている印と空白を使い、遮りの位置を考えましょう。",
	"「立つ」の影は「座る」より遠くまで届きます。",
	"シルエットが違えば、影の長さも異なります。",
	"「歩く」は位置だけでなく、向きも記録します。",
	"複数の影が同じ盤面で交差することがあります。",
	"光源と盤面の縁の両方を考えてみましょう。",
	"高さによって、その位置で説明できる印が変わります。",
	"光学レールとNOXの姿勢が、どちらも記録に影響します。",
	"位置間の経路を仮定せず、それぞれの軸を読みましょう。",
	"長く伸びる影も、盤面の縁で途切れることがあります。",
	"記録のすき間から、遮られた光路がわかることがあります。",
	"三つのシルエットは、同じNOXの別々の場面かもしれません。",
	"提案した位置を、盤面全体に照らして確かめましょう。",
	"遮られた光路の奥に、もっと長い影が隠れているかもしれません。",
	"向きと照明によって、似た印が生まれることがあります。",
	"一か所での遮りか、盤面全体に共通する光のパターンかを比べましょう。",
	"開いているマスと欠けたマスを、記録されたすべての影とあわせて読みましょう。",
	"細い軸を通る長い痕跡を、伸びる距離と盤面の縁の両方から確かめましょう。",
	"遮られた軸の向こうにも、手がかりは残っています。",
	"光の向きと姿勢の両方を、盤面の記録に合わせましょう。",
	"すき間の記録板を使い、姿勢と影を生んだ向きを見分けましょう。",
	"覆われたマスも手がかりです。盤面にない場所と、記録にない影を混同しないでください。",
	"交差が途中まででも、盤面全体を読み解く手がかりになります。",
	"見えない位置も、そこにあるはずの影から候補を絞れます。",
	"最後に開いた軸をたどり、盤面全体の記録で原因を確かめましょう。",
	"四つのシルエットは、同じ個体の異なる場面を表しているかもしれません。",
	"学んだ原因を組み合わせ、固定された四方向の光で記録全体を説明しましょう。",
	"姿勢、光の向き、盤面の形を、最も濃く重なる記録に照らして統合しましょう。",
	"四つの光源は固定です。最後の痕跡を置く前に、変形盤面の重なりと空白を読み切りましょう。"
]

static func chapter(index: int) -> int:
	return clampi(int(floorf(float(index) / 6.0)), 0, 5)

static func chapter_name(index: int, language: String = "en") -> String:
	return (CHAPTERS_JA if language == "ja" else CHAPTERS)[chapter(index)]

static func chapter_note(index: int, language: String = "en") -> String:
	return (CHAPTER_NOTES_JA if language == "ja" else CHAPTER_NOTES)[chapter(index)]

static func title(index: int, language: String = "en") -> String:
	var safe_index := clampi(index, 0, TITLES.size() - 1)
	return (TITLES_JA if language == "ja" else TITLES)[safe_index]

static func note(index: int, language: String = "en") -> String:
	var safe_index := clampi(index, 0, STAGE_NOTES.size() - 1)
	return (STAGE_NOTES_JA if language == "ja" else STAGE_NOTES)[safe_index]

# Sparse narrative appears at the opening, mechanic introductions, chapter turns,
# and the last plate. Empty text means there is no story interlude for this trace.
static func milestone_note(index: int, language: String = "en") -> String:
	match index:
		0:
			return "アーカイブに残っていたのは、影だけ。\nNOXの姿はどこにもなかった。" if language == "ja" else "The archive kept only the shadows.\nNOX was nowhere to be found."
		1:
			return "二つの場面が、ひとつの濃い痕跡を残すことがあります。" if language == "ja" else "Two moments can leave one darker trace."
		3:
			return "灯りもまた記録の一部。\n光の向きは、影に残されています。" if language == "ja" else "The lamps are part of the record, too.\nTheir directions remain in the shadows."
		6:
			return "消えた影にも、ごくありふれた理由があるかもしれません。" if language == "ja" else "Some missing shadows have very ordinary explanations."
		8:
			return "記録のどこかに、より高いものを見ようと立ち上がったNOXの姿があります。" if language == "ja" else "Somewhere in these records, NOX stood to see something higher."
		10:
			return "影にも、向きが残ることがあります。" if language == "ja" else "A shadow can remember direction, too."
		12:
			return "高さと向きによって、同じ光の見え方が変わります。" if language == "ja" else "Height and direction reshape the same play of light."
		18:
			return "ひとつの盤面に、複数の場面が重なることがあります。" if language == "ja" else "Several moments can share one plate."
		24:
			return "何がないかも、影と同じくらい多くを伝えます。" if language == "ja" else "Absence can carry as much information as a shadow."
		30:
			return "どの記録も、アーカイブの奥へと続いています。" if language == "ja" else "Every record points deeper into the archive."
		35:
			return "四つの光源は、この変形盤面のまわりに固定されています。\n最後の痕跡を置く前に、影の重なりと空白を読み切りましょう。" if language == "ja" else "The four lights stay fixed around this shaped plate.\nRead every overlap and absence before deciding where the last traces belong."
		_:
			return ""