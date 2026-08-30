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
	game._show_character_select(game.MODE_SOLO)

	game.character_selection[0] = 0
	game._refresh_character_select()
	_expect(game.character_guide_button.text.contains("REN"), "guide button must follow the selected fighter")
	game._show_character_guide()
	_expect(game.character_guide_visible, "guide state must open from character select")
	_expect(game.character_guide_overlay.visible, "guide overlay must be visible when opened")
	_expect(game.character_guide_title_label.text.contains("REN"), "Ren guide must show the fighter name")
	_expect(game.character_guide_features_label.text.contains("万能型") == false, "style belongs in the dedicated style label")
	_expect(game.character_guide_style_label.text.contains("万能型"), "Ren guide must explain his play style")
	_expect(game.character_guide_moves_label.text.contains("蒼波拳"), "Ren guide must show Azure Pulse")
	_expect(game.character_guide_moves_label.text.contains("蒼天衝"), "Ren guide must show Sky Break")
	_expect(game.character_guide_moves_label.text.contains("AZURE ZERO"), "Ren guide must show his super command")

	game._hide_character_guide()
	_expect(not game.character_guide_visible, "guide state must close")
	_expect(not game.character_guide_overlay.visible, "guide overlay must hide when closed")

	game.character_selection[0] = 1
	game._refresh_character_select()
	_expect(game.character_guide_button.text.contains("VEL"), "guide button must update for Vel")
	game._show_character_guide()
	_expect(game.character_guide_title_label.text.contains("VEL"), "Vel guide must show the fighter name")
	_expect(game.character_guide_style_label.text.contains("攻撃型"), "Vel guide must explain his play style")
	_expect(game.character_guide_moves_label.text.contains("影狩り"), "Vel guide must show Shadow Hunt")
	_expect(game.character_guide_moves_label.text.contains("断頭爪"), "Vel guide must show Reaper Dive")
	_expect(game.character_guide_moves_label.text.contains("RED ECLIPSE"), "Vel guide must show his super command")
	await process_frame
	_expect(
		game.character_guide_moves_label.get_minimum_size().y <= game.character_guide_moves_label.size.y,
		"the longer Vel move list must fit inside the guide panel"
	)
	_expect(
		game.character_guide_panel.position.x + game.character_guide_panel.size.x <= game.SCREEN_SIZE.x,
		"guide panel must fit inside the game screen"
	)

	if failures.is_empty():
		print("CHARACTER_GUIDE_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
