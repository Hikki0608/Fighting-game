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
	var vel := FighterScript.new() as Fighter
	var defender := FighterScript.new() as Fighter
	root.add_child(vel)
	root.add_child(defender)
	vel.setup(0, "VEL", Color.RED, Vector2(650.0, Fighter.GROUND_Y))
	defender.setup(1, "REN", Color.CYAN, Vector2(1500.0, Fighter.GROUND_Y))

	vel.facing = 1
	vel.change_state(&"vel_shadow")
	var shadow_start_x := vel.position.x
	_advance_without_input(vel, defender, Fighter.VEL_SHADOW_END_FRAME)
	var shadow_distance := vel.position.x - shadow_start_x
	_expect(
		shadow_distance >= 240.0,
		"Shadow Hunt must travel at least 240 pixels farther toward the opponent"
	)
	_expect(vel.state == &"idle", "Shadow Hunt must finish on its tuned final frame")

	var pounce: Dictionary = Fighter.ATTACKS[&"vel_pounce"]
	_expect(bool(pounce.knockdown), "Predator Pounce must cause knockdown on hit")
	_expect(
		int(pounce.knockdown_frames) == 44,
		"Predator Pounce must use its dedicated 44-frame knockdown"
	)
	defender.reset_for_round(Vector2(950.0, Fighter.GROUND_Y))
	defender.receive_attack(pounce, vel.position.x)
	_expect(defender.state == &"knockdown", "Predator Pounce must enter knockdown state")
	_advance_without_input(defender, vel, 43)
	_expect(defender.state == &"knockdown", "Predator Pounce knockdown must last through frame 43")
	_advance_without_input(defender, vel, 1)
	_expect(defender.state == &"idle", "Predator Pounce defender must recover on frame 44")

	var dive: Dictionary = Fighter.ATTACKS[&"vel_dive"]
	_expect(int(dive.hitstun) == 20, "Reaper Dive hitstun must be shortened to 20 frames")
	_expect(
		int(dive.knockdown_frames) == 36,
		"Reaper Dive knockdown recovery must be shortened to 36 frames"
	)
	defender.reset_for_round(Vector2(950.0, Fighter.GROUND_Y))
	defender.receive_attack(dive, vel.position.x)
	_advance_without_input(defender, vel, 35)
	_expect(defender.state == &"knockdown", "Reaper Dive knockdown must last through frame 35")
	_advance_without_input(defender, vel, 1)
	_expect(defender.state == &"idle", "Reaper Dive defender must recover on frame 36")

	if failures.is_empty():
		print("VEL_MOVE_TUNING_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
