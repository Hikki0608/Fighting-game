extends SceneTree

const FighterScript := preload("res://scripts/fighter.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _advance(fighter: Fighter, opponent: Fighter, axis: Vector2) -> void:
	fighter.apply_virtual_input(axis)
	fighter.simulate(opponent, true)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _double_tap(fighter: Fighter, opponent: Fighter, direction: float) -> void:
	_advance(fighter, opponent, Vector2(direction, 0.0))
	_advance(fighter, opponent, Vector2.ZERO)
	_advance(fighter, opponent, Vector2(direction, 0.0))


func _run() -> void:
	var p1 := FighterScript.new() as Fighter
	var p2 := FighterScript.new() as Fighter
	root.add_child(p1)
	root.add_child(p2)
	p1.setup(0, "REN", Color.CYAN, Vector2(650.0, Fighter.GROUND_Y))
	p2.setup(1, "VEL", Color.RED, Vector2(1300.0, Fighter.GROUND_Y))

	var forward_start := p1.position.x
	_double_tap(p1, p2, 1.0)
	_expect(p1.state == &"forward_step", "double-tapping toward the opponent must start forward_step")
	for frame in Fighter.FORWARD_STEP_DURATION_FRAMES + 1:
		_advance(p1, p2, Vector2.ZERO)
	_expect(p1.state == &"idle", "forward_step must return to idle")
	_expect(p1.position.x - forward_start > 100.0, "forward_step must cover useful ground")

	p1.reset_for_round(Vector2(650.0, Fighter.GROUND_Y))
	var back_start := p1.position.x
	_double_tap(p1, p2, -1.0)
	_expect(p1.state == &"back_step", "double-tapping away from the opponent must start back_step")
	for frame in Fighter.BACK_STEP_DURATION_FRAMES + 1:
		_advance(p1, p2, Vector2.ZERO)
	_expect(p1.state == &"idle", "back_step must return to idle")
	_expect(back_start - p1.position.x > 100.0, "back_step must create useful distance")

	p1.reset_for_round(Vector2(650.0, Fighter.GROUND_Y))
	_advance(p1, p2, Vector2(1.0, 0.0))
	for frame in 24:
		_advance(p1, p2, Vector2(1.0, 0.0))
	_expect(p1.state == &"walk", "holding a direction must not retrigger a step")

	p1.reset_for_round(Vector2(650.0, Fighter.GROUND_Y))
	_advance(p1, p2, Vector2(1.0, 0.0))
	for frame in Fighter.DOUBLE_TAP_WINDOW_FRAMES + 2:
		_advance(p1, p2, Vector2.ZERO)
	_advance(p1, p2, Vector2(1.0, 0.0))
	_expect(p1.state == &"walk", "a late second tap must remain ordinary walking")

	# Forward and back are relative to the opponent, not fixed screen directions.
	p1.reset_for_round(Vector2(1350.0, Fighter.GROUND_Y))
	p2.reset_for_round(Vector2(650.0, Fighter.GROUND_Y))
	p1.facing = -1
	_double_tap(p1, p2, -1.0)
	_expect(p1.state == &"forward_step", "screen-left must be forward when the opponent is on the left")

	if failures.is_empty():
		print("STEP_INPUT_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
