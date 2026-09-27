extends RefCounted

# Explain only the rules present on this record. These never inspect its solution.
static func steps(stage: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{"en_title": "Read the two plates", "ja_title": "二つの記録板を比べる", "en": "RECORDED SHADOW is the evidence. RECONSTRUCTION shows the shadows made by your placements. Make every shade agree.", "ja": "「記録された影」が手がかり。「再構築」には、あなたが置いた痕跡の影が映る。すべての濃さを合わせよう。"},
		{"en_title": "Place a trace", "ja_title": "NOXの痕跡を置く", "en": "Choose NOX below, then tap a square. You can also drag. Light casts a shadow on the opposite side of NOX.", "ja": "下のNOXを選び、マスをタップ。ドラッグでも置ける。光と反対側に影ができる。"},
	]
	if stage.get("fixed_posts", []).size() == int(stage.get("posts", 1)):
		result[1] = {"en_title": "Read the known positions", "ja_title": "わかっている位置を使う", "en": "These traces stay in place. Use their shadows to reconstruct the light.", "ja": "この記録の痕跡は固定。その影を手がかりに、光源を復元しよう。"}
		if stage.get("rotatable_plate", false):
			result[1]["en"] = "WALK stays in this position. Tap the cat to change its direction and watch the shadows change."
			result[1]["ja"] = "「歩く」の位置は固定。猫をタップして向きを変え、影の変化を見てみよう。"
	if int(stage.get("posts", 1)) > 1:
		result[0]["en"] += " Darker squares hold overlapping shadows from different moments of the same cat."
		result[0]["ja"] += " 濃いマスには、同じ猫の別々の瞬間の影が重なっている。"
	if stage.get("free_light_selection", false) or stage.get("light_puzzle", false):
		result.append({"en_title": "Reconstruct the light", "ja_title": "光源も復元する", "en": "Tap an available lamp to switch it. If all available light slots are used, turn one off before choosing another.", "ja": "切り替えられる光源をタップ。点灯数が上限なら、ひとつ消してから別の光を選ぼう。"})
	if stage.get("tall", false) or int(stage.get("tall_posts", 0)) > 0:
		result.append({"en_title": "A higher reach", "ja_title": "立つと、遠くまで", "en": "SIT reaches one square from its position. STAND reaches two, including the nearer square. Both follow the active lights.", "ja": "「座る」は隣まで。「立つ」は隣と、その先の二マス目まで影が届く。どちらも点灯中の光に応じる。", "diagram": "reach"})
	if stage.get("rotatable_plate", false) or int(stage.get("plate_posts", 0)) > 0:
		result.append({"en_title": "Body direction / shadow direction", "ja_title": "体の向きと、影の向き", "en": "WALK records shadows across its body, along one axis. Tap a WALK trace to turn it. The lit lamps determine which of those shadows appear.", "ja": "「歩く」の影は、体を横切る一つの軸に記録される。駒をタップして回転。実際の影は点灯中の光で決まる。", "diagram": "walk"})
	if stage.get("movable_shutter", false) or not stage.get("fixed_shutters", []).is_empty():
		result.append({"en_title": "A sleeping cat interrupts the light", "ja_title": "眠る猫が、光を遮る", "en": "SLEEP on the rail blocks TOP light in that column only. Shadows from the other lamps remain. Move SLEEP only when the rail allows it.", "ja": "レールで眠るNOXは、その列の上からの光だけを遮る。ほかの光源の影は残る。動かせるレールでは、眠る位置も選ぼう。", "diagram": "sleep"})
	if not stage.get("fog_cells", []).is_empty():
		result.append({"en_title": "An unrecorded square", "ja_title": "記録されていない場所", "en": "? means unrecorded, not clear glass. Only the visible recorded shades must match.", "ja": "？は未記録。透明なマスとは違う。見えている記録の濃さを合わせよう。"})
	# Put this record's mechanics before the common instructions when reopening help.
	if result.size() > 2:
		var basics: Array[Dictionary] = [result.pop_front(), result.pop_front()]
		result.append_array(basics)
	result.append({"en_title": "Try, watch, undo", "ja_title": "置いて、見て、戻せる", "en": "A brief outline marks the shadows your move changed. UNDO takes back a move. RESET starts this record again.", "ja": "操作で変わった影が、短く縁取られる。「一手戻す」で戻り、「やり直す」でこの記録を初めから試せる。"})
	return result
