extends SceneTree

const FighterScript := preload("res://scripts/fighter.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _advance_without_input(fighter: Fighter, opponent: Fighter, frames: int) -> void:
	for frame in frames:
		fighter.apply_virtual_input(Vector2.ZERO)
		fighter.simulate(opponent, false)


func _run() -> void:
	var ren := FighterScript.new() as Fighter
	var defender := FighterScript.new() as Fighter
	root.add_child(ren)
	root.add_child(defender)
	ren.setup(0, "REN", Color.CYAN, Vector2(650.0, Fighter.GROUND_Y))
	defender.setup(1, "VEL", Color.RED, Vector2(950.0, Fighter.GROUND_Y))

	ren.pending_projectile = true
	var projectile := ren.take_projectile_request()
	_expect(not projectile.is_empty(), "Azure Pulse must create a projectile request")
	_expect(
		is_equal_approx(absf(float(projectile.velocity.x)), Fighter.REN_PULSE_PROJECTILE_SPEED),
		"Azure Pulse must use the tuned projectile speed"
	)
	_expect(
		absf(float(projectile.velocity.x)) >= 680.0,
		"Azure Pulse projectile must be substantially faster than before"
	)

	var sky_break: Dictionary = Fighter.ATTACKS[&"ren_rise"]
	_expect(int(sky_break.hitstun) == 20, "Sky Break hitstun must be shortened to 20 frames")
	_expect(int(sky_break.knockdown_frames) == 38, "Sky Break knockdown recovery must be shortened")
	defender.receive_attack(sky_break, ren.position.x)
	_advance_without_input(defender, ren, 37)
	_expect(defender.state == &"knockdown", "Sky Break knockdown must last through frame 37")
	_advance_without_input(defender, ren, 1)
	_expect(defender.state == &"idle", "Sky Break defender must recover on frame 38")

	defender.reset_for_round(Vector2(950.0, Fighter.GROUND_Y))
	defender.receive_attack(Fighter.ATTACKS[&"throw"], ren.position.x)
	_advance_without_input(defender, ren, 38)
	_expect(
		defender.state == &"knockdown",
		"other knockdown attacks must retain the default recovery duration"
	)
	_advance_without_input(defender, ren, Fighter.DEFAULT_KNOCKDOWN_RECOVERY_FRAMES - 38)
	_expect(defender.state == &"idle", "default knockdowns must still recover on frame 48")

	if failures.is_empty():
		print("REN_MOVE_TUNING_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
