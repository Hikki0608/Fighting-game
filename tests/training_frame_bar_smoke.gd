extends SceneTree

const FighterScript := preload("res://scripts/fighter.gd")
const FrameBarScript := preload("res://scripts/training_frame_bar.gd")
const MainScript := preload("res://scripts/main.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var p1 = FighterScript.new()
	var p2 = FighterScript.new()
	root.add_child(p1)
	root.add_child(p2)
	p1.setup(0, "REN", Color("2cccf4"), Vector2(430.0, FighterScript.GROUND_Y))
	p2.setup(1, "VEL", Color("ff4f86"), Vector2(720.0, FighterScript.GROUND_Y))

	var frame_bar = FrameBarScript.new()
	frame_bar.size = Vector2(1040.0, 132.0)
	frame_bar.visible = true
	root.add_child(frame_bar)

	p1.state = &"light"
	p1.state_frame = 1
	frame_bar.record_frame([p1, p2], false)
	_expect(frame_bar.latest_phase(0) == &"startup", "attack startup must render in the startup phase")
	p1.state_frame = 5
	frame_bar.record_frame([p1, p2], false)
	_expect(frame_bar.latest_phase(0) == &"active", "active hit frames must render in the active phase")
	p1.state_frame = 8
	frame_bar.record_frame([p1, p2], false)
	_expect(frame_bar.latest_phase(0) == &"recovery", "post-active frames must render in recovery")
	frame_bar.record_frame([p1, p2], true)
	_expect(frame_bar.latest_phase(0) == &"hitstop", "global hitstop must take priority in the timeline")

	p1.state = &"forward_step"
	p1.state_frame = 1
	p2.state = &"hitstun"
	p2.state_frame = 1
	frame_bar.record_frame([p1, p2], false)
	_expect(frame_bar.latest_phase(0) == &"movement", "steps must render as movement frames")
	_expect(frame_bar.latest_phase(1) == &"hitstun", "damage reactions must render as hitstun")
	_expect(
		frame_bar.last_action_summaries[0].contains("立ち弱"),
		"the bar must retain the latest move summary"
	)

	p1.state = &"forward_step"
	p2.state = &"hitstun"
	for frame_index in FrameBarScript.MAX_FRAMES + 10:
		p1.state_frame = frame_index
		p2.state_frame = frame_index
		frame_bar.record_frame([p1, p2], false)
	_expect(frame_bar.history_size(0) == FrameBarScript.MAX_FRAMES, "P1 history must stay at 72 frames")
	_expect(frame_bar.history_size(1) == FrameBarScript.MAX_FRAMES, "P2 history must stay at 72 frames")
	await process_frame
	_expect(
		frame_bar.last_drawn_cell_count == FrameBarScript.MAX_FRAMES * 2,
		"both full frame rows must be rendered"
	)
	_expect(frame_bar.last_drawn_run_labels > 0, "continuous frame runs must display their duration")

	var game := MainScript.new()
	root.add_child(game)
	game.game_mode = game.MODE_TRAINING
	game._set_training_live_data_visible(true)
	_expect(game.training_frame_bar.visible, "key 1 live data must reveal the training frame bar")
	_expect(game.fighters[0].debug_boxes, "live data must continue to reveal hitboxes")
	game._set_training_live_data_visible(false)
	_expect(not game.training_frame_bar.visible, "live data toggle must hide the training frame bar")
	_expect(not game.fighters[0].debug_boxes, "live data toggle must hide hitboxes")

	if failures.is_empty():
		print("TRAINING_FRAME_BAR_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
