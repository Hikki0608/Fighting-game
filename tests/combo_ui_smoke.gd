extends SceneTree

const MainScript := preload("res://scripts/main.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var game := MainScript.new()
	root.add_child(game)
	game.phase = &"fight"
	for combo_label in game.combo_labels:
		combo_label.visible = true

	game.fighters[1].combo_received = 4
	game.fighters[0].combo_received = 0
	game._update_ui()
	_expect(game.combo_labels[0].text == "4 HIT COMBO", "P1 combo count must use the left label")
	_expect(game.combo_labels[1].text.is_empty(), "P2 combo label must stay empty during a P1 combo")
	_expect(game.combo_labels[0].position.x < game.SCREEN_SIZE.x * 0.5, "P1 combo label must be on the left")
	_expect(
		game.combo_labels[0].horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT,
		"P1 combo text must align toward the left edge"
	)

	game.fighters[1].combo_received = 0
	game.fighters[0].combo_received = 3
	game._update_ui()
	_expect(game.combo_labels[0].text == "4 HIT COMBO", "P1 combo label must remain visible after recovery")
	_expect(game.combo_labels[1].text == "3 HIT COMBO", "P2 combo count must use the right label")
	_expect(game.combo_labels[1].position.x > game.SCREEN_SIZE.x * 0.5, "P2 combo label must be on the right")
	_expect(
		game.combo_labels[1].horizontal_alignment == HORIZONTAL_ALIGNMENT_RIGHT,
		"P2 combo text must align toward the right edge"
	)

	game.fighters[0].combo_received = 0
	for _frame in game.COMBO_DISPLAY_HOLD_FRAMES:
		game._update_ui()
	_expect(game.combo_labels[1].text == "3 HIT COMBO", "P2 combo label must hold for two seconds")
	game._update_ui()
	_expect(game.combo_labels[1].text.is_empty(), "P2 combo label must clear after its hold time")

	if failures.is_empty():
		print("COMBO_UI_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
