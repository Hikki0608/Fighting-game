extends SceneTree

const MainScript := preload("res://scripts/main.gd")
const SpriteAlphaBoundsScript := preload("res://scripts/sprite_alpha_bounds.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var expected_value_count := (
		SpriteAlphaBoundsScript.SHEETS_PER_CHARACTER
		* SpriteAlphaBoundsScript.ROWS_PER_SHEET
		* SpriteAlphaBoundsScript.COLUMNS_PER_ROW
		* SpriteAlphaBoundsScript.VALUES_PER_FRAME
	)
	_expect(
		SpriteAlphaBoundsScript.REN_BOUNDS.size() == expected_value_count,
		"Ren sprite bounds must contain four values for all 125 frames"
	)
	_expect(
		SpriteAlphaBoundsScript.VEL_BOUNDS.size() == expected_value_count,
		"Vel sprite bounds must contain four values for all 125 frames"
	)
	for character_id in [&"ren", &"vel"]:
		for sheet_index in SpriteAlphaBoundsScript.SHEETS_PER_CHARACTER:
			for row_index in SpriteAlphaBoundsScript.ROWS_PER_SHEET:
				for column_index in SpriteAlphaBoundsScript.COLUMNS_PER_ROW:
					var frame_bounds := SpriteAlphaBoundsScript.rect_for(
						character_id,
						Vector3i(sheet_index, column_index, row_index)
					)
					_expect(
						frame_bounds.has_area(),
						"every authored sprite frame must have valid alpha bounds"
					)
	var repaired_ren_frame := SpriteAlphaBoundsScript.rect_for(&"ren", Vector3i(4, 1, 3))
	_expect(
		repaired_ren_frame == Rect2(61.0, 132.0, 195.0, 83.0),
		"Ren knockdown frame two must retain its complete generated bounds"
	)
	_expect(
		not SpriteAlphaBoundsScript.rect_for(&"ren", Vector3i(5, 0, 0)).has_area(),
		"out-of-range sprite coordinates must return an empty safe fallback"
	)

	var game := MainScript.new()
	root.add_child(game)
	var ren: Fighter = game.fighters[0]
	var vel: Fighter = game.fighters[1]

	ren.position = Vector2(500.0, Fighter.GROUND_Y)
	ren.state = &"idle"
	ren.state_frame = 0
	ren.motion_tick = 0
	ren.landing_frames = 0
	ren.sprite_transition_frames = 0
	ren.facing = 1
	var ren_standing_right := ren.hurt_rect()
	_expect(ren_standing_right.has_area(), "Ren's standing sprite must have a hurtbox")
	_expect(
		ren_standing_right.get_center().x > ren.position.x + 25.0,
		"Ren's hurtbox must follow the visible forward-offset stance"
	)
	var legacy_back_edge := ren.position.x - Fighter.HURTBOX_WIDTH * 0.5 + 4.0
	_expect(
		not ren_standing_right.has_point(Vector2(legacy_back_edge, ren_standing_right.get_center().y)),
		"empty space behind Ren must no longer count as part of his hurtbox"
	)

	ren.facing = -1
	var ren_standing_left := ren.hurt_rect()
	_expect(
		ren_standing_left.get_center().x < ren.position.x - 25.0,
		"Ren's hurtbox must mirror when he turns around"
	)
	_expect(
		absf(ren_standing_right.size.x - ren_standing_left.size.x) < 1.0,
		"turning around must preserve the hurtbox size"
	)

	ren.facing = 1
	ren.state = &"crouch"
	ren.motion_tick = 0
	var ren_crouching := ren.hurt_rect()
	_expect(
		ren_crouching.size.y < ren_standing_right.size.y * 0.8,
		"a crouching pose must have a visibly shorter hurtbox"
	)
	ren.state = &"jump"
	ren.velocity = Vector2.ZERO
	var ren_jump_tuck := ren.hurt_rect()
	_expect(
		ren_jump_tuck.size.y < ren_standing_right.size.y * 0.75,
		"the tucked jump pose must not keep the full standing hurtbox"
	)

	vel.position = Vector2(800.0, Fighter.GROUND_Y)
	vel.state = &"idle"
	vel.state_frame = 0
	vel.motion_tick = 0
	vel.landing_frames = 0
	vel.sprite_transition_frames = 0
	vel.facing = 1
	var vel_standing := vel.hurt_rect()
	_expect(vel_standing.has_area(), "Vel's standing sprite must have a hurtbox")
	_expect(
		absf(vel_standing.get_center().x - vel.position.x) < 8.0,
		"Vel's centered stance must keep a centered hurtbox"
	)

	if failures.is_empty():
		print("HURTBOX_GEOMETRY_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
