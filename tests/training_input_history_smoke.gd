extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const InputHistoryPanelScript := preload("res://scripts/training_input_history_panel.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var directions := [
		Vector2i(-1, -1),
		Vector2i(0, -1),
		Vector2i(1, -1),
		Vector2i(-1, 0),
		Vector2i(1, 0),
		Vector2i(-1, 1),
		Vector2i(0, 1),
		Vector2i(1, 1)
	]
	var history: Array[Dictionary] = []
	for direction in directions:
		var segments: PackedVector2Array = InputHistoryPanelScript.arrow_segments(direction)
		_expect(segments.size() == 6, "each direction icon must use one shaft and two arrowhead lines")
		if segments.size() == 6:
			var travel := segments[1] - segments[0]
			_expect(
				signi(roundi(travel.x)) == signi(direction.x),
				"arrow horizontal direction must match the recorded input"
			)
			_expect(
				signi(roundi(travel.y)) == signi(direction.y),
				"arrow vertical direction must match the recorded input"
			)
		var buttons: Array[String] = []
		if direction == Vector2i(1, 0):
			buttons = ["弱", "SP"]
		history.append({"direction": direction, "buttons": buttons})

	var panel := InputHistoryPanelScript.new() as TrainingInputHistoryPanel
	panel.size = Vector2(244.0, 194.0)
	root.add_child(panel)
	panel.set_history(history)
	await process_frame
	_expect(panel.history_size() == 8, "input history panel must retain all eight direction entries")
	_expect(
		panel.last_rendered_arrow_count == 8,
		"input history panel must draw all eight directions as vector arrows"
	)

	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	_expect(
		not main_source.contains("func _training_direction_text"),
		"training input history must not convert directions into font glyph strings"
	)

	var game := MainScript.new()
	root.add_child(game)
	_expect(
		game.training_input_label is TrainingInputHistoryPanel,
		"training mode must use the vector input-history panel"
	)
	game.queue_free()
	panel.queue_free()

	if failures.is_empty():
		print("TRAINING_INPUT_HISTORY_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
