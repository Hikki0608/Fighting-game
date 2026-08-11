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


func _init() -> void:
	rng.randomize()


func reset() -> void:
	decision_frames = 0
	guard_frames = 0
	attack_cooldown = 0
	move_axis = 0.0


func build_intent(cpu: Fighter, opponent: Fighter) -> Dictionary:
	var buttons := _empty_buttons()
	attack_cooldown = maxi(0, attack_cooldown - 1)

	var delta_x := opponent.position.x - cpu.position.x
	var distance := absf(delta_x)
	var toward := 1.0 if delta_x >= 0.0 else -1.0
	var away := -toward

	if _cannot_choose_action(cpu):
		move_axis = 0.0
		return _intent(Vector2.ZERO, buttons)

	if not cpu.is_on_ground():
		move_axis = toward
		if attack_cooldown <= 0 and rng.randf() < 0.055:
			buttons.light = true
			attack_cooldown = 22
		return _intent(Vector2(move_axis, 0.0), buttons)

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

	if distance > FAR_RANGE:
		move_axis = toward
		decision_frames = rng.randi_range(18, 32)
		if roll < 0.14:
			return _intent(Vector2(toward, -1.0), buttons)
		return _intent(Vector2(toward, 0.0), buttons)

	if distance > MID_RANGE:
		if roll < 0.66:
			move_axis = toward
			decision_frames = rng.randi_range(10, 22)
		elif roll < 0.80:
			buttons.special = true
			attack_cooldown = rng.randi_range(25, 40)
		else:
			move_axis = away
			decision_frames = rng.randi_range(7, 14)
		return _intent(Vector2(move_axis, 0.0), buttons)

	if distance > CLOSE_RANGE:
		if roll < 0.34:
			buttons.light = true
		elif roll < 0.58:
			buttons.heavy = true
		elif roll < 0.76:
			buttons.special = true
		elif roll < 0.88:
			move_axis = toward
			decision_frames = rng.randi_range(5, 10)
		else:
			move_axis = away
			guard_frames = rng.randi_range(8, 15)
	else:
		if roll < 0.24:
			buttons.throw = true
		elif roll < 0.55:
			buttons.light = true
		elif roll < 0.76:
			buttons.heavy = true
		elif roll < 0.88:
			buttons.special = true
		else:
			move_axis = away
			guard_frames = rng.randi_range(9, 18)

	if buttons.light or buttons.heavy or buttons.special or buttons.throw:
		attack_cooldown = rng.randi_range(18, 34)
	return _intent(Vector2(move_axis, 0.0), buttons)


func _cannot_choose_action(cpu: Fighter) -> bool:
	return cpu.state == &"hitstun" or cpu.state == &"blockstun" or cpu.state == &"knockdown" or Fighter.ATTACKS.has(cpu.state)


func _opponent_is_threatening(opponent: Fighter, distance: float) -> bool:
	if not Fighter.ATTACKS.has(opponent.state):
		return false
	var attack: Dictionary = Fighter.ATTACKS[opponent.state]
	var warning_frame := maxi(1, int(attack.startup) - 3)
	return opponent.state_frame >= warning_frame and distance <= float(attack.range) + 62.0


func _empty_buttons() -> Dictionary:
	return {
		"light": false,
		"heavy": false,
		"special": false,
		"throw": false
	}


func _intent(axis: Vector2, buttons: Dictionary) -> Dictionary:
	return {"axis": axis, "buttons": buttons}
