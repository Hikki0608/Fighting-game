extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const TRAINING_STAGE_PATH := "res://assets/training_stage.svg"
const EXPECTED_STAGE_WIDTH := 2016
const EXPECTED_STAGE_HEIGHT := 648
const EXPECTED_FLOOR_RAY_COUNT := 29

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var stage_texture := load(TRAINING_STAGE_PATH) as Texture2D
	_expect(stage_texture != null, "training stage texture must load")
	if stage_texture != null:
		_expect(
			stage_texture.get_width() == EXPECTED_STAGE_WIDTH,
			"training stage texture must cover the full 2016 px arena width"
		)
		_expect(
			stage_texture.get_height() == EXPECTED_STAGE_HEIGHT,
			"training stage texture must retain the 648 px screen height"
		)

	var svg_source := FileAccess.get_file_as_string(TRAINING_STAGE_PATH)
	_expect(
		svg_source.contains('id="wall-grid" data-minor-spacing="24" data-major-spacing="72"'),
		"rear-wall major grid must repeat at a uniform 72 px interval"
	)
	_expect(
		svg_source.count("M1008 356L") == EXPECTED_FLOOR_RAY_COUNT,
		"perspective floor rays must cover every 72 px interval across the stage"
	)
	_expect(
		svg_source.contains('id="distance-guides" data-spacing="72"'),
		"distance ticks must repeat uniformly across the full stage"
	)

	var game := MainScript.new() as Node2D
	root.add_child(game)
	game.set("stage_selection", 1)
	game.call("_apply_selected_stage")
	var backgrounds: Array = game.get("arena_backgrounds")
	_expect(backgrounds.size() == 3, "game must retain its three reusable background sprites")
	if backgrounds.size() == 3:
		_expect(
			not backgrounds[0].visible and backgrounds[1].visible and not backgrounds[2].visible,
			"training mode must draw only the single full-width center background"
		)
	game.set("stage_selection", 0)
	game.call("_apply_selected_stage")
	if backgrounds.size() == 3:
		_expect(
			backgrounds[0].visible and backgrounds[1].visible and backgrounds[2].visible,
			"royal colosseum mode must restore all three scrolling background tiles"
		)
	game.queue_free()

	if failures.is_empty():
		print("TRAINING_STAGE_GRID_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
