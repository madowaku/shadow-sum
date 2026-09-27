extends RefCounted

# Stage-specific story clues for the authored NOXSUM deck.
const INTRO: Array = [
	["One SIT trace explains all three marks.", "Follow the three shadows back to a common position.", "Their common origin lies between the three directions."],
	["A darker square can hold more than one moment.", "Which two SIT traces could both contribute to B3?", "Use the single shadows to locate those two traces."],
	["Clear glass is evidence, too.", "Every NOX trace must explain shadows without adding unwanted ones.", "Both layouts explain the marked squares. Which one also leaves D5 clear?"],
	["Look at the light below the board.", "SIT behaves the same way. The illumination has changed.", "Follow the fourth shadow back toward NOX."],
	["NOX's position is known. Reconstruct the light.", "Each recorded mark points away from its source.", "Choose only the sources needed by these two directions."],
	["Position and light can be inferred together.", "The double mark in the middle needs two opposing contributions.", "The absence of vertical shadows constrains both lights and positions."],
	["The TOP light is on, but one column behaves differently.", "A sleeping NOX blocks one path of light along the rail.", "Sideways shadows survive in that column."],
	["Separate the positions from the blocked light.", "The side shadows locate SIT traces even with SLEEP on the rail.", "Place SLEEP to explain the missing downward shadow."],
	["NOX changed posture.", "Follow one direction beyond the nearest square.", "STAND reaches farther than SIT."],
	["Two poses answer the same light differently.", "Which trace must reach the distant squares?", "The darker C4 holds a contribution from both STAND and SIT."],
	["A WALK trace can stay in place and change direction.", "WALK leaves shadows along one axis.", "Turn WALK and observe which pair of shadows remains."],
	["SIT answers every lit direction. WALK answers one axis.", "The full cross locates SIT.", "Use the remaining pair and overlap to infer WALK's direction."],
	["Missing shadows can have different causes.", "Use the fixed SIT trace to infer which lights are on.", "WALK's direction explains the remaining absence."],
	["The light pair and the poses constrain each other.", "A shadow reaching two squares belongs to STAND.", "The horizontal pattern reveals the two active lights."],
	["One absence belongs to SLEEP. Another belongs to WALK's direction.", "Use SIT to read the blocked TOP light.", "Infer WALK's direction from the sideways shadows."],
	["Two WALK traces can face different directions.", "Each opposite pair of shadows has its own midpoint.", "The upper WALK trace answers sideways; the lower answers vertically."],
	["Long reach and directional reach are different clues.", "The long horizontal span belongs to STAND.", "The remaining vertical pair identifies WALK and its direction."],
	["A switched-off light and SLEEP leave different absences.", "Read the full plate to find which light is off.", "Use the missing TOP shadow in one column to place SLEEP."],
	["Three poses leave three kinds of evidence.", "Locate the long reach and the full nearby cross.", "The remaining marks must fit WALK's direction."],
	["Separate the causes you have learned to read.", "STAND changes reach. SLEEP blocks a column. WALK changes direction.", "Use those pose clues to reconstruct the three active lights."]
]

const INTRO_JA: Array = [
	["「座る」の影ひとつで、三つの印を説明できます。", "三つの影をたどり、共通する位置を探しましょう。", "三方向のあいだに、影の出発点があります。"],
	["濃いマスには、複数の場面の影が重なっていることがあります。", "B3に重なる可能性がある、二つの「座る」の影はどれでしょう？", "単独で現れる影を手がかりに、二つの位置を探しましょう。"],
	["透明なガラスも手がかりになります。", "NOXの影をすべて説明し、余分な影が生じないようにしましょう。", "印のあるマスが一致する配置は二通り。D5を透明なままにできるのは、どちらでしょう？"],
	["盤面の下にある光源に注目しましょう。", "「座る」の影は同じ形です。変わったのは照明です。", "四つ目の影をたどり、NOXの位置を考えましょう。"],
	["NOXの位置はわかっています。光源を復元しましょう。", "記録された印は、それぞれ光源とは反対側に伸びています。", "この二方向を説明するために必要な光源だけを選びましょう。"],
	["位置と光源は、同時に推理できます。", "中央の二重の印には、向かい合う二方向からの影が必要です。", "縦方向の影がないことから、光源と位置の両方を絞りましょう。"],
	["上の光は点灯していますが、ある列だけ様子が違います。", "眠っているNOXがレール沿いの光路をひとつ遮ります。", "その列には横向きの影が残ります。"],
	["位置と遮られた光を分けて考えましょう。", "レール上に「眠る」がいても、横向きの影から「座る」の位置を特定できます。", "下向きの影が欠ける理由を説明できるよう、「眠る」の位置を置きましょう。"],
	["NOXの姿勢が変わりました。", "ひとつの向きに、隣のマスを越えて伸びる影を探しましょう。", "「立つ」の影は「座る」より遠くまで届きます。"],
	["二つの姿勢は、同じ照明でも異なる影を残します。", "遠くのマスまで届くのは、どちらの影でしょう？", "濃いC4には、「立つ」と「座る」の両方の影が重なっています。"],
	["「歩く」の影は位置を保ったまま、向きを変えることがあります。", "「歩く」は一つの軸に沿って影を残します。", "「歩く」の向きを変え、どちらの一組の影が残るか見てみましょう。"],
	["「座る」の影は点灯中の全方向に伸びます。「歩く」の影は一つの軸に沿います。", "交差する十字の影から「座る」の位置がわかります。", "残る一組の影とその重なりから、「歩く」の向きを考えましょう。"],
	["影がない理由はひとつとは限りません。", "位置の決まった「座る」の影から、どの光が点灯しているかを読み取りましょう。", "残った空白は、「歩く」の向きで説明できるか考えましょう。"],
	["点灯している光と姿勢の両方で候補を絞れます。", "二マス先まで伸びる影は「立つ」によるものです。", "横方向の並びから、点灯中の二つの光がわかります。"],
	["ひとつの空白は「眠る」、もうひとつは「歩く」の向きによるものです。", "「座る」の影を使って、遮られた上の光を読み取りましょう。", "横向きの影から、「歩く」の向きを推理しましょう。"],
	["二つの「歩く」の影は、別々の向きを向いていることがあります。", "反対向きの影の各組には、それぞれの中点があります。", "上側の「歩く」は横方向、下側は縦方向の影で確かめましょう。"],
	["遠くまで届く影と、向きで決まる影は別の手がかりです。", "横に長く伸びる影は「立つ」のものです。", "残る縦方向の二つの影から、「歩く」と向きを特定しましょう。"],
	["消灯した光と「眠る」では、欠ける影が異なります。", "盤面全体から、消えている光を見つけましょう。", "ある列で上の影がないことから、「眠る」の位置を探しましょう。"],
	["三つの姿勢が、異なる手がかりを残します。", "長く伸びる影と、近くの十字全体から位置を探しましょう。", "残った印が「歩く」の向きに合うか確認しましょう。"],
	["読み取ってきた原因を切り分けましょう。", "「立つ」は影の長さを変えます。「眠る」は一列を遮ります。「歩く」は向きを変えます。", "姿勢の手がかりから、点灯している三つの光を復元しましょう。"]
]

static func for_stage(index: int, stage: Dictionary, language: String = "en") -> Array:
	if index < INTRO.size():
		return INTRO_JA[index] if language == "ja" else INTRO[index]
	if language == "ja":
		var result_ja: Array = ["空白も影と同じように、丁寧に読み取りましょう。"]
		if not stage.get("fog_cells", []).is_empty():
			result_ja[0] = "？は未記録のマスです。見えているマスを使って候補を絞りましょう。"
		if stage.get("movable_shutter", false):
			result_ja.append("「眠る」が上からの光を遮った影と、「歩く」の向きや消灯で消えた影を区別しましょう。")
		elif int(stage.get("tall_posts", 0)) > 0:
			result_ja.append("まず遠くまで届く影から「立つ」の位置を探し、その後で近くの重なりを確かめましょう。")
		else:
			result_ja.append("反対向きの影を結ぶと、NOXの位置候補がわかります。その後、重なりを照合しましょう。")
		result_ja.append("原因をひとつずつ変えましょう。変更するたびに、盤面全体の記録を確認します。")
		return result_ja
	var result: Array = ["Read the empty recorded squares as carefully as the dark ones."]
	if not stage.get("fog_cells", []).is_empty():
		result[0] = "A question mark is unrecorded. Constrain the reconstruction using the visible squares."
	if stage.get("movable_shutter", false):
		result.append("Separate a missing TOP shadow caused by SLEEP from absences caused by WALK or an unlit source.")
	elif int(stage.get("tall_posts", 0)) > 0:
		result.append("Read the farthest shadows to locate STAND before checking the nearby overlap.")
	else:
		result.append("Pair opposite shadows around possible NOX positions, then compare their overlap.")
	result.append("Change one cause at a time. Check the entire recorded plate after each change.")
	return result
