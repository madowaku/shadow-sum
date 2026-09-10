extends "res://src/main.gd"

# SHADOW SUM v0.1.2 ONE MORE TURN Feel Pass
#
# This layer deliberately keeps ShadowRules and stage logic untouched.
# It only adds tactile micro-feedback on top of the deterministic puzzle state.

const FEEL_CYAN := Color("#b7fbff")
const FEEL_GOLD := Color("#ffe0a0")
const FEEL_WHITE := Color("#f3ffff")
const SAMPLE_RATE := 44100

func _toggle_post(r: int, c: int) -> void:
	if stage_solved or stages.is_empty():
		return

	var before_occupied := bool(posts[r][c])
	var before_count := ShadowRules.count_posts(posts)
	var before_shadow := ShadowRules.compute_shadow(posts)

	super._toggle_post(r, c)

	var after_occupied := bool(posts[r][c])
	var after_count := ShadowRules.count_posts(posts)
	if before_occupied == after_occupied and before_count == after_count:
		return

	var adding := after_occupied and not before_occupied
	if adding:
		_play_micro_tone(1180.0, 820.0, 0.045, 0.18, -15.0)
	else:
		_play_micro_tone(620.0, 390.0, 0.055, 0.13, -18.0)

	var after_shadow := ShadowRules.compute_shadow(posts)
	var overlap_cells: Array = []
	var match_cells: Array = []
	var highest_new_level := 0
	var clues: Array = stages[stage_index]["clues"]

	for rr in ShadowRules.BOARD_SIZE:
		for cc in ShadowRules.BOARD_SIZE:
			var before_value := int(before_shadow[rr][cc])
			var after_value := int(after_shadow[rr][cc])
			if before_value == after_value:
				continue

			var index := rr * ShadowRules.BOARD_SIZE + cc
			if adding and after_value > before_value and after_value >= 2:
				overlap_cells.append(index)
				highest_new_level = maxi(highest_new_level, after_value)

			var clue := int(clues[rr][cc])
			if clue > 0 and after_value == clue:
				match_cells.append(index)

	if stage_solved:
		_play_solve_chime()
		return

	if adding and highest_new_level >= 2:
		_delayed_overlap_feedback(highest_new_level, overlap_cells)

	if not match_cells.is_empty():
		_delayed_match_feedback(match_cells)


func _delayed_overlap_feedback(level: int, indices: Array) -> void:
	await get_tree().create_timer(0.085).timeout
	if level >= 3:
		_play_micro_tone(132.0, 92.0, 0.125, 0.24, -10.0)
	else:
		_play_micro_tone(245.0, 185.0, 0.085, 0.19, -13.0)

	for index_value in indices:
		var index := int(index_value)
		if index < 0 or index >= live_cells.size():
			continue
		var cell := live_cells[index] as PanelContainer
		cell.pivot_offset = Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		cell.scale = Vector2(1.0, 0.80 if level >= 3 else 0.88)
		cell.modulate = FEEL_GOLD if level >= 3 else FEEL_CYAN
		var tween := create_tween()
		if level >= 3:
			tween.tween_property(cell, "scale", Vector2(1.075, 1.075), 0.075).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(cell, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			tween.tween_property(cell, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(cell, "modulate", Color.WHITE, 0.20)

	_pulse_all_emitters(FEEL_GOLD if level >= 3 else FEEL_CYAN, 0.16 if level >= 3 else 0.11)


func _delayed_match_feedback(indices: Array) -> void:
	await get_tree().create_timer(0.16).timeout
	if stage_solved:
		return

	for index_value in indices:
		var index := int(index_value)
		if index < 0 or index >= live_cells.size():
			continue
		var cell := live_cells[index] as PanelContainer
		var tween := create_tween()
		tween.tween_property(cell, "modulate", FEEL_WHITE, 0.055)
		tween.tween_property(cell, "modulate", Color.WHITE, 0.13)


func _pulse_all_emitters(color: Color, hold: float) -> void:
	for key in ["N", "W", "E"]:
		if not emitter_labels.has(key):
			continue
		var emitter := emitter_labels[key] as Label
		var tween := create_tween()
		tween.tween_property(emitter, "modulate", color, 0.045)
		tween.tween_interval(hold)
		tween.tween_property(emitter, "modulate", Color.WHITE, 0.16)


func _play_solve_chime() -> void:
	# Three tiny notes mirror the three light emitters without becoming a fanfare.
	_play_micro_tone(440.0, 520.0, 0.11, 0.11, -17.0)
	_play_delayed_tone(0.075, 660.0, 760.0, 0.12, 0.10, -17.0)
	_play_delayed_tone(0.15, 880.0, 1040.0, 0.16, 0.09, -17.0)


func _play_delayed_tone(delay: float, start_hz: float, end_hz: float, duration: float, amplitude: float, volume_db: float) -> void:
	await get_tree().create_timer(delay).timeout
	_play_micro_tone(start_hz, end_hz, duration, amplitude, volume_db)


func _play_micro_tone(start_hz: float, end_hz: float, duration: float, amplitude: float, volume_db: float) -> void:
	var stream := _make_tone_stream(start_hz, end_hz, duration, amplitude)
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()


func _make_tone_stream(start_hz: float, end_hz: float, duration: float, amplitude: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false

	var frame_count := maxi(1, int(duration * float(SAMPLE_RATE)))
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var phase := 0.0

	for i in frame_count:
		var progress := float(i) / float(frame_count)
		var hz := lerpf(start_hz, end_hz, progress)
		phase += TAU * hz / float(SAMPLE_RATE)
		var attack := minf(1.0, progress / 0.055)
		var decay := pow(1.0 - progress, 2.6)
		var sample_f := sin(phase) * amplitude * attack * decay
		var sample := int(clampf(sample_f, -1.0, 1.0) * 32767.0)
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff

	stream.data = bytes
	return stream
