class_name CpuController
extends RefCounted

const CLOSE_RANGE := 92.0
const MID_RANGE := 190.0
const FAR_RANGE := 330.0

var rng := RandomNumberGenerator.new()
var decision_frames := 0
var guard_frames := 0
var attack_cooldown := 0
var move_axis := 0.0
var decision_buttons := {
	"light": false,
	"heavy": false,
	"special": false,
	"throw": false
}
var output_intent := {
	"axis": Vector2.ZERO,
	"buttons": {}
}


func _init() -> void:
	rng.randomize()
	output_intent.buttons = decision_buttons


func reset() -> void:
	decision_frames = 0
	guard_frames = 0
	attack_cooldown = 0
	move_axis = 0.0


func build_intent(cpu: Fighter, opponent: Fighter) -> Dictionary:
	var buttons := decision_buttons
	_reset_buttons()
	attack_cooldown = maxi(0, attack_cooldown - 1)

	var delta_x := opponent.position.x - cpu.position.x
	var distance := absf(delta_x)
	var toward := 1.0 if delta_x >= 0.0 else -1.0
	var away := -toward

	if cpu.state == &"vel_shadow":
		if cpu.state_frame >= 10 and cpu.state_frame <= 20 and attack_cooldown <= 0 and rng.randf() < 0.24:
			buttons.heavy = true
			attack_cooldown = 30
		return _intent(Vector2.ZERO, buttons)

	if _cannot_choose_action(cpu):
		move_axis = 0.0
		return _intent(Vector2.ZERO, buttons)

	if not cpu.is_on_ground():
		move_axis = toward
		if attack_cooldown <= 0 and distance < MID_RANGE and rng.randf() < 0.075:
			var air_roll := rng.randf()
			if air_roll < 0.34:
				buttons.special = true
			elif air_roll < 0.72:
				buttons.light = true
			else:
				buttons.heavy = true
			attack_cooldown = 22
		return _intent(Vector2(move_axis, 0.0), buttons)

	if not opponent.is_on_ground() and distance < MID_RANGE and attack_cooldown <= 0 and rng.randf() < 0.34:
		buttons.special = true
		attack_cooldown = rng.randi_range(28, 42)
		return _intent(Vector2(0.0, 1.0), buttons)

	if _opponent_is_threatening(opponent, distance):
		if opponent.state == &"throw" and rng.randf() < 0.42:
			decision_frames = 12
			move_axis = away
			return _intent(Vector2(away, -1.0), buttons)
		if rng.randf() < 0.72:
			guard_frames = rng.randi_range(10, 20)

	if guard_frames > 0:
		guard_frames -= 1
		move_axis = away
		return _intent(Vector2(away, 0.0), buttons)

	if decision_frames > 0:
		decision_frames -= 1
		return _intent(Vector2(move_axis, 0.0), buttons)

	if attack_cooldown > 0:
		move_axis = away if distance < CLOSE_RANGE else toward
		decision_frames = rng.randi_range(5, 11)
		return _intent(Vector2(move_axis, 0.0), buttons)

	var roll := rng.randf()
	move_axis = 0.0

	if cpu.meter >= Fighter.MAX_METER and distance < MID_RANGE and roll < 0.18:
		buttons.light = true
		buttons.heavy = true
		attack_cooldown = 52
		return _intent(Vector2.ZERO, buttons)

	if distance > FAR_RANGE:
		if cpu.character_id == &"ren" and roll < 0.34:
			buttons.special = true
			attack_cooldown = rng.randi_range(30, 44)
			return _intent(Vector2.ZERO, buttons)
		move_axis = toward
		decision_frames = rng.randi_range(18, 32)
		if roll < 0.12:
			return _intent(Vector2(toward, -1.0), buttons)
		return _intent(Vector2(toward, 0.0), buttons)

	if distance > MID_RANGE:
		if cpu.character_id == &"ren" and roll < 0.26:
			buttons.special = true
			attack_cooldown = rng.randi_range(28, 42)
		elif roll < 0.62:
			move_axis = toward
			decision_frames = rng.randi_range(10, 22)
		elif roll < 0.84:
			buttons.special = true
			move_axis = toward
			attack_cooldown = rng.randi_range(25, 40)
		else:
			move_axis = away
			decision_frames = rng.randi_range(7, 14)
		return _intent(Vector2(move_axis, 0.0), buttons)

	if distance > CLOSE_RANGE:
		if roll < 0.28:
			buttons.light = true
		elif roll < 0.52:
			buttons.heavy = true
			if rng.randf() < 0.34:
				move_axis = toward
		elif roll < 0.76:
			buttons.special = true
			if cpu.character_id == &"ren" or rng.randf() < 0.70:
				move_axis = toward
		elif roll < 0.88:
			move_axis = toward
			decision_frames = rng.randi_range(5, 10)
		else:
			move_axis = away
			guard_frames = rng.randi_range(8, 15)
	else:
		if roll < 0.20:
			buttons.throw = true
			if rng.randf() < 0.32:
				move_axis = away
		elif roll < 0.47:
			buttons.light = true
		elif roll < 0.68:
			buttons.heavy = true
			if rng.randf() < 0.38:
				move_axis = toward
		elif roll < 0.90:
			buttons.special = true
			if cpu.character_id == &"vel" and rng.randf() < 0.22:
				move_axis = away
			elif rng.randf() < 0.46:
				move_axis = toward
		else:
			move_axis = away
			guard_frames = rng.randi_range(9, 18)

	if buttons.light or buttons.heavy or buttons.special or buttons.throw:
		attack_cooldown = rng.randi_range(18, 34)
	return _intent(Vector2(move_axis, 0.0), buttons)


func _cannot_choose_action(cpu: Fighter) -> bool:
	return (
		cpu.state == &"hitstun"
		or cpu.state == &"blockstun"
		or cpu.state == &"knockdown"
		or cpu.state == &"vel_shadow"
		or cpu.is_attacking()
	)


func _opponent_is_threatening(opponent: Fighter, distance: float) -> bool:
	if not opponent.is_attacking():
		return false
	var attack := opponent.current_attack()
	if bool(attack.get("projectile", false)):
		return false
	var warning_frame := maxi(1, int(attack.startup) - 3)
	return opponent.state_frame >= warning_frame and distance <= float(attack.range) + 62.0


func _reset_buttons() -> void:
	for button_name in decision_buttons:
		decision_buttons[button_name] = false


func _intent(axis: Vector2, buttons: Dictionary) -> Dictionary:
	output_intent.axis = axis
	output_intent.buttons = buttons
	return output_intent
