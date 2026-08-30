extends SceneTree

const MainScript := preload("res://scripts/main.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _prepare_round(game: Node, p1_health: int, p2_health: int, frames_left: int) -> void:
	game.phase = &"fight"
	game.game_mode = &"solo"
	game.round_frames = frames_left
	game.fighters[0].health = p1_health
	game.fighters[1].health = p2_health
	game.announcement = ""
	game.announcement_sub = ""
	game._reset_combo_display()


func _run() -> void:
	var game := MainScript.new()
	root.add_child(game)
	for label in game.combo_labels:
		label.visible = true

	game.phase = &"fight"
	game._show_player_callout(0, "BACK THROW", 60)
	game._update_ui()
	_expect(game.player_callout_labels[0].text == "BACK THROW", "P1 callout must appear on the left")
	_expect(game.player_callout_labels[1].text.is_empty(), "P1 callout must not appear on the right")
	_expect(
		game.player_callout_labels[0].position.x < game.SCREEN_SIZE.x * 0.5,
		"P1 callout label must stay on the left half"
	)

	game._reset_combo_display()
	game.phase = &"fight"
	game._show_player_callout(1, "RED ECLIPSE", 60)
	game._update_ui()
	_expect(game.player_callout_labels[0].text.is_empty(), "P2 callout must not appear on the left")
	_expect(game.player_callout_labels[1].text == "RED ECLIPSE", "P2 callout must appear on the right")
	_expect(
		game.player_callout_labels[1].position.x > game.SCREEN_SIZE.x * 0.5,
		"P2 callout label must stay on the right half"
	)

	game.wins = [0, 0]
	_prepare_round(game, 500, 0, 120)
	game._finish_round()
	game._update_ui()
	_expect(game.announcement == "K.O.", "K.O. must remain in the center announcement")
	_expect(
		game.player_callout_labels[0].text == "%s TAKES THE ROUND" % game.fighters[0].fighter_name,
		"round winner text must appear on the winner's left side"
	)
	_expect(game.player_callout_labels[1].text.is_empty(), "losing side must not show the round winner text")

	game.wins = [0, 0]
	_prepare_round(game, 0, 500, 0)
	game._finish_round()
	game._update_ui()
	_expect(game.announcement.is_empty(), "TIME UP must not replace the centered K.O. slot")
	_expect(game.player_callout_labels[0].text.is_empty(), "timeout winner text must not use the losing side")
	_expect(
		game.player_callout_labels[1].text.begins_with("TIME UP"),
		"timeout result must appear on the winner's right side"
	)

	game.wins = [1, 0]
	_prepare_round(game, 500, 0, 120)
	game._finish_round()
	game._update_ui()
	_expect(game.announcement == "K.O.", "final-round K.O. must remain centered")
	_expect(
		game.player_callout_labels[0].text == "%s WINS" % game.fighters[0].fighter_name,
		"match winner text must remain on the winning player's side"
	)

	if failures.is_empty():
		print("PLAYER_CALLOUT_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
