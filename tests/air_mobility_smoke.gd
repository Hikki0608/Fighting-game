extends SceneTree

const FighterScript := preload("res://scripts/fighter.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _advance(
	fighter: Fighter,
	opponent: Fighter,
	axis: Vector2,
	buttons: Dictionary = {}
) -> void:
	fighter.apply_virtual_input(axis, buttons)
	fighter.simulate(opponent, true)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run() -> void:
	var p1 := FighterScript.new() as Fighter
	var p2 := FighterScript.new() as Fighter
	root.add_child(p1)
	root.add_child(p2)
	p1.setup(0, "REN", Color.CYAN, Vector2(650.0, Fighter.GROUND_Y))
	p2.setup(1, "VEL", Color.RED, Vector2(1400.0, Fighter.GROUND_Y))

	_expect(
		Fighter.AIR_MOVE_SPEED >= Fighter.FORWARD_WALK_SPEED * 1.45,
		"air movement must be substantially faster than forward walking"
	)
	var jump_start := p1.position.x
	_advance(p1, p2, Vector2(1.0, -1.0))
	for frame in 29:
		_advance(p1, p2, Vector2(1.0, 0.0))
	_expect(p1.state == &"jump", "the mobility check must remain airborne")
	_expect(
		p1.position.x - jump_start > 225.0,
		"holding forward in the air must cover substantially more ground"
	)
	_advance(p1, p2, Vector2(-1.0, 0.0))
	_expect(
		is_equal_approx(p1.velocity.x, -Fighter.AIR_MOVE_SPEED),
		"neutral jumps must respond immediately to an aerial direction change"
	)

	p1.reset_for_round(Vector2(650.0, Fighter.GROUND_Y))
	_advance(p1, p2, Vector2(1.0, -1.0))
	_advance(p1, p2, Vector2(1.0, 0.0), {"light": true})
	_expect(p1.state == &"jump_light", "light attack must start during the jump")
	for frame in 8:
		_advance(p1, p2, Vector2(-1.0, 0.0))
	_expect(
		p1.velocity.x < -100.0,
		"air attacks must retain strong directional control"
	)

	if failures.is_empty():
		print("AIR_MOBILITY_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
