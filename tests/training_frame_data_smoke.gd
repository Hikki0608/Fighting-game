extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const FrameDataPanelScript := preload("res://scripts/training_frame_data_panel.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _find_row(rows: Array[Dictionary], state: StringName) -> Dictionary:
	for row in rows:
		if StringName(row.get("state", &"")) == state:
			return row
	return {}


func _run() -> void:
	var ren_rows: Array[Dictionary] = FrameDataPanelScript.build_rows(&"ren")
	var vel_rows: Array[Dictionary] = FrameDataPanelScript.build_rows(&"vel")
	_expect(ren_rows.size() == 13, "Ren table must contain eight common and five unique moves")
	_expect(vel_rows.size() == 14, "Vel table must contain eight common and six unique moves")

	var light := _find_row(ren_rows, &"light")
	_expect(int(light.get("startup", -1)) == 4, "standing light startup must come from gameplay data")
	_expect(str(light.get("active", "")) == "5-7", "standing light active range must use gameplay frames")
	_expect(int(light.get("recovery", -1)) == 8, "standing light recovery must come from gameplay data")
	_expect(str(light.get("hit_advantage", "")) == "+5", "standing light hit advantage must be calculated")
	_expect(str(light.get("block_advantage", "")) == "-2", "standing light block advantage must be calculated")

	var ren_pulse := _find_row(ren_rows, &"ren_pulse")
	_expect(str(ren_pulse.get("active", "")) == "飛び道具", "Azure Pulse must identify its projectile active period")
	_expect(str(ren_pulse.get("hit_advantage", "")) == "可変", "projectile hit advantage must be marked variable")
	_expect(str(ren_pulse.get("block_advantage", "")) == "可変", "projectile guard advantage must be marked variable")
	var ren_rise := _find_row(ren_rows, &"ren_rise")
	_expect(str(ren_rise.get("hit_advantage", "")) == "DOWN", "Sky Break must identify knockdown on hit")

	var vel_rake := _find_row(vel_rows, &"vel_rake")
	_expect(str(vel_rake.get("active", "")) == "7, 11, 15", "Crimson Rake must list all three hit frames")
	_expect(str(vel_rake.get("hit_advantage", "")) == "+1", "Crimson Rake must use its final-hit hitstun")
	_expect(str(vel_rake.get("block_advantage", "")) == "-7", "Crimson Rake must use its final-hit blockstun")
	var vel_shadow := _find_row(vel_rows, &"vel_shadow")
	_expect(str(vel_shadow.get("active", "")) == "移動", "Shadow Hunt must be identified as movement")
	var vel_super := _find_row(vel_rows, &"vel_super")
	_expect(str(vel_super.get("hit_advantage", "")) == "DOWN", "Red Eclipse must identify knockdown on hit")
	_expect(str(vel_super.get("block_advantage", "")) == "—", "unblockable Red Eclipse must not show guard advantage")

	var panel = FrameDataPanelScript.new()
	panel.size = Vector2(1104.0, 612.0)
	root.add_child(panel)
	panel.set_character(&"vel")
	await process_frame
	_expect(panel.last_drawn_row_count == 14, "Vel table must render all frame-data rows")
	_expect(panel.last_table_bottom < panel.size.y, "frame-data table must fit inside the panel")

	var game := MainScript.new()
	root.add_child(game)
	game.game_mode = game.MODE_TRAINING
	game.phase = &"fight"
	game._show_training_frame_data()
	_expect(game.training_frame_data_visible, "training mode must open the frame-data table")
	_expect(game.training_frame_data_layer.visible, "frame-data canvas must be visible while open")
	game._set_training_frame_data_character(&"vel")
	_expect(game.training_frame_data_panel.character_id == &"vel", "training table must switch to Vel")
	game._hide_training_frame_data()
	_expect(not game.training_frame_data_visible, "frame-data table must close cleanly")
	_expect(not game.training_frame_data_layer.visible, "frame-data canvas must hide after closing")

	if failures.is_empty():
		print("TRAINING_FRAME_DATA_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
