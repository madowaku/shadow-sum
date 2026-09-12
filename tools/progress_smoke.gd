extends SceneTree

const TEST_PROGRESS_PATH := "user://progress_smoke_v0_1.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if FileAccess.file_exists(TEST_PROGRESS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PROGRESS_PATH))

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		push_error("Progress smoke: could not load main scene")
		quit(1)
		return

	var first := packed.instantiate()
	first.progress_path = TEST_PROGRESS_PATH
	root.add_child(first)
	await process_frame
	await process_frame
	await process_frame

	if first.stage_index != 0 or first.completed_stage_ids.size() != 0:
		push_error("Progress smoke: fresh profile did not start at Stage 001")
		quit(1)
		return

	# Stage 001: C3.
	first._toggle_post(2, 2)
	await create_timer(0.12).timeout
	if not first.completed_stage_ids.has(1) or not FileAccess.file_exists(TEST_PROGRESS_PATH):
		push_error("Progress smoke: Stage 001 clear was not persisted")
		quit(1)
		return

	first.queue_free()
	await process_frame

	# A new instance must resume at the first unsolved puzzle, Stage 002.
	var second := packed.instantiate()
	second.progress_path = TEST_PROGRESS_PATH
	root.add_child(second)
	await process_frame
	await process_frame
	await process_frame

	if second.stage_index != 1 or not second.completed_stage_ids.has(1):
		push_error("Progress smoke: restart did not resume at Stage 002")
		quit(1)
		return
	if second.back_button == null or second.back_button.disabled:
		push_error("Progress smoke: completed history was not replayable via BACK")
		quit(1)
		return

	# Stage 002: B2, C3.
	second._toggle_post(1, 1)
	second._toggle_post(2, 2)
	await create_timer(0.12).timeout
	if not second.completed_stage_ids.has(2):
		push_error("Progress smoke: Stage 002 clear missing")
		quit(1)
		return

	# Stage 003: C2, B3, D3. Clearing it should light EASY.
	second._load_stage(2)
	second._toggle_post(1, 2)
	second._toggle_post(2, 1)
	second._toggle_post(2, 3)
	await create_timer(0.30).timeout

	if not second.completed_stage_ids.has(3):
		push_error("Progress smoke: Stage 003 clear missing")
		quit(1)
		return
	if second._unlocked_tier_count() < 2 or second._highest_unlocked_stage_index() != 3:
		push_error("Progress smoke: EASY did not unlock after Intro trio")
		quit(1)
		return

	second.queue_free()
	await process_frame

	var third := packed.instantiate()
	third.progress_path = TEST_PROGRESS_PATH
	root.add_child(third)
	await process_frame
	await process_frame
	await process_frame

	if third.stage_index != 3:
		push_error("Progress smoke: second restart did not resume at Stage 004")
		quit(1)
		return
	if third.completed_stage_ids.size() != 3:
		push_error("Progress smoke: expected exactly three stored clears")
		quit(1)
		return

	# BACK reaches completed Stage 003, and NEXT can return through cleared history.
	third._go_previous_stage()
	if third.stage_index != 2 or third.next_button.disabled:
		push_error("Progress smoke: replay navigation did not expose cleared Stage 003")
		quit(1)
		return
	third._next_stage()
	if third.stage_index != 3:
		push_error("Progress smoke: NEXT did not return from replay to Stage 004")
		quit(1)
		return

	third.queue_free()
	await process_frame
	if FileAccess.file_exists(TEST_PROGRESS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PROGRESS_PATH))

	print("Progress smoke OK: clear saves, restart resumes, tiers unlock, cleared stages replay")
	quit(0)
