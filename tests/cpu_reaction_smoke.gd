extends SceneTree

const FighterScript := preload("res://scripts/fighter.gd")
const CpuControllerScript := preload("res://scripts/cpu_controller.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _run_projectile_read(seed_value: int, cpu: Fighter, opponent: Fighter) -> Dictionary:
	var controller := CpuControllerScript.new() as CpuController
	controller.set_seed(seed_value)
	cpu.reset_for_round(Vector2(950.0, Fighter.GROUND_Y))
	opponent.reset_for_round(Vector2(650.0, Fighter.GROUND_Y))
	opponent.change_state(&"ren_pulse")
	opponent.state_frame = 9

	var defended := false
	var defended_on_first_frame := false
	for frame in 7:
		controller.build_intent(cpu, opponent)
		var chose_projectile_defense := controller.last_tactic in [
			&"projectile_jump",
			&"projectile_guard"
		]
		if frame == 0 and chose_projectile_defense:
			defended_on_first_frame = true
		defended = defended or chose_projectile_defense
		opponent.state_frame += 1
	return {
		"defended": defended,
		"defended_on_first_frame": defended_on_first_frame
	}


func _run() -> void:
	var cpu := FighterScript.new() as Fighter
	var opponent := FighterScript.new() as Fighter
	root.add_child(cpu)
	root.add_child(opponent)
	cpu.setup(1, "VEL", Color.RED, Vector2(950.0, Fighter.GROUND_Y))
	opponent.setup(0, "REN", Color.CYAN, Vector2(650.0, Fighter.GROUND_Y))

	var defended_reads := 0
	var missed_reads := 0
	for seed_value in 128:
		var result := _run_projectile_read(seed_value, cpu, opponent)
		_expect(
			not bool(result.defended_on_first_frame),
			"CPU defense must include a visible reaction delay"
		)
		if bool(result.defended):
			defended_reads += 1
		else:
			missed_reads += 1

	_expect(defended_reads > 0, "CPU must still recognize and defend some projectile threats")
	_expect(missed_reads > 0, "CPU must sometimes fail to defend a projectile threat")
	_expect(
		defended_reads < 112,
		"CPU projectile defense must not approach certainty across repeated attacks"
	)

	if failures.is_empty():
		print("CPU_REACTION_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
