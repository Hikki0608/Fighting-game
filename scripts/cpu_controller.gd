class_name CpuController
extends RefCounted

const CLOSE_RANGE := 92.0
const POKE_RANGE := 155.0
const MID_RANGE := 235.0
const FAR_RANGE := 360.0
const CORNER_SPACE := 105.0
const THREAT_PADDING := 78.0
const THREAT_REACTION_MIN_FRAMES := 2
const THREAT_REACTION_MAX_FRAMES := 7
const NORMAL_DEFENSE_CHANCE := 0.64
const PROJECTILE_DEFENSE_CHANCE := 0.68
const THROW_DEFENSE_CHANCE := 0.56
const SUPER_DEFENSE_CHANCE := 0.76
const BLOCK_READ_ACCURACY := 0.86

var rng := RandomNumberGenerator.new()
var decision_frames := 0
var guard_frames := 0
var attack_cooldown := 0
var jump_cooldown := 0
var decision_axis := Vector2.ZERO
var guard_axis := Vector2.ZERO
var combo_source_state: StringName = &""
var was_attacking := false
var last_tactic: StringName = &"idle"
var tracked_threat_state: StringName = &""
var threat_reaction_frames := -1
var threat_will_defend := false
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
	jump_cooldown = 0
	decision_axis = Vector2.ZERO
	guard_axis = Vector2.ZERO
	combo_source_state = &""
	was_attacking = false
	last_tactic = &"idle"
	_clear_tracked_threat()
	_reset_buttons()


func set_seed(value: int) -> void:
	rng.seed = value


func build_intent(cpu: Fighter, opponent: Fighter) -> Dictionary:
	var buttons := decision_buttons
	_reset_buttons()
	attack_cooldown = maxi(0, attack_cooldown - 1)
	jump_cooldown = maxi(0, jump_cooldown - 1)

	var delta_x := opponent.position.x - cpu.position.x
	var distance := absf(delta_x)
	var toward := 1.0 if delta_x >= 0.0 else -1.0
	var away := -toward
	_refresh_threat_observation(opponent)

	if cpu.state == &"vel_shadow":
		return _vel_shadow_intent(cpu, buttons)

	if cpu.is_attacking():
		was_attacking = true
		return _attack_followup_intent(cpu, toward, buttons)
	if was_attacking:
		was_attacking = false
		attack_cooldown = maxi(attack_cooldown, rng.randi_range(14, 26))
		decision_frames = 0
	combo_source_state = &""

	if _cannot_choose_action(cpu):
		last_tactic = &"disabled"
		return _intent(Vector2.ZERO, buttons)

	if not cpu.is_on_ground():
		return _air_intent(cpu, distance, toward, away, buttons)

	if guard_frames > 0:
		guard_frames -= 1
		last_tactic = &"guard_hold"
		return _intent(guard_axis, buttons)

	if _opponent_is_threatening(opponent, distance) and _should_defend_threat(opponent):
		return _defensive_intent(cpu, opponent, distance, toward, away, buttons)

	if (
		not opponent.is_on_ground()
		and distance < POKE_RANGE + 24.0
		and attack_cooldown <= 0
		and rng.randf() < 0.48
	):
		return _anti_air_intent(buttons)

	if decision_frames > 0:
		decision_frames -= 1
		return _intent(decision_axis, buttons)

	if attack_cooldown > 0:
		return _cooldown_movement(cpu, distance, toward, away, buttons)

	return _ground_tactic(cpu, opponent, distance, toward, away, buttons)


func _vel_shadow_intent(cpu: Fighter, buttons: Dictionary) -> Dictionary:
	last_tactic = &"vel_shadow"
	if (
		cpu.state_frame >= 10
		and cpu.state_frame <= 20
		and attack_cooldown <= 0
		and rng.randf() < 0.28
	):
		buttons.heavy = true
		attack_cooldown = 30
		last_tactic = &"vel_shadow_followup"
	return _intent(Vector2.ZERO, buttons)


func _attack_followup_intent(cpu: Fighter, toward: float, buttons: Dictionary) -> Dictionary:
	last_tactic = &"attack_recovery"
	if not cpu.attack_has_connected or combo_source_state == cpu.state:
		return _intent(Vector2.ZERO, buttons)

	var attack := cpu.current_attack()
	if cpu.state_frame < int(attack.get("startup", 1)):
		return _intent(Vector2.ZERO, buttons)

	combo_source_state = cpu.state
	var roll := rng.randf()
	if (
		cpu.meter >= Fighter.MAX_METER
		and not bool(attack.get("super", false))
		and roll < 0.24
	):
		buttons.light = true
		buttons.heavy = true
		attack_cooldown = 46
		last_tactic = &"super_cancel"
	elif (cpu.state == &"light" or cpu.state == &"crouch_light") and roll < 0.66:
		buttons.heavy = true
		attack_cooldown = 24
		last_tactic = &"light_to_heavy"
	elif (
		cpu.state == &"heavy"
		or cpu.state == &"forward_heavy"
		or cpu.state == &"crouch_heavy"
	) and roll < 0.48:
		buttons.special = true
		attack_cooldown = 30
		last_tactic = &"heavy_to_special"
		return _intent(Vector2(toward, 0.0), buttons)
	return _intent(Vector2.ZERO, buttons)


func _air_intent(
	cpu: Fighter,
	distance: float,
	toward: float,
	away: float,
	buttons: Dictionary
) -> Dictionary:
	var air_axis := 0.0
	if distance > POKE_RANGE:
		air_axis = toward
	elif distance < CLOSE_RANGE * 0.72:
		air_axis = away

	last_tactic = &"air_control"
	if attack_cooldown <= 0 and distance < MID_RANGE and rng.randf() < 0.11:
		var air_roll := rng.randf()
		if air_roll < 0.30:
			buttons.special = true
			last_tactic = &"air_special"
		elif air_roll < 0.68:
			buttons.light = true
			last_tactic = &"air_light"
		else:
			buttons.heavy = true
			last_tactic = &"air_heavy"
		attack_cooldown = rng.randi_range(20, 30)
	return _intent(Vector2(air_axis, 0.0), buttons)


func _defensive_intent(
	cpu: Fighter,
	opponent: Fighter,
	distance: float,
	toward: float,
	away: float,
	buttons: Dictionary
) -> Dictionary:
	var attack := opponent.current_attack()
	var is_throw := bool(attack.get("grab", false)) or bool(attack.get("unblockable", false))
	if is_throw:
		if jump_cooldown <= 0 and rng.randf() < 0.76:
			var jump_direction := away
			if _space_in_direction(cpu, away) < CORNER_SPACE:
				jump_direction = toward
			jump_cooldown = rng.randi_range(42, 58)
			last_tactic = &"throw_escape_jump"
			return _intent(Vector2(jump_direction, -1.0), buttons)
		last_tactic = &"throw_escape_retreat"
		return _hold_decision(Vector2(away, 0.0), 5, 9, last_tactic, buttons)

	if bool(attack.get("projectile", false)):
		if jump_cooldown <= 0 and distance > POKE_RANGE and rng.randf() < 0.30:
			jump_cooldown = rng.randi_range(46, 62)
			last_tactic = &"projectile_jump"
			return _intent(Vector2(toward, -1.0), buttons)
		var travel_frames := clampi(ceili(distance / 8.5) + 10, 18, 55)
		return _start_guard(away, false, travel_frames, &"projectile_guard", buttons)

	var block_type: StringName = attack.get("block_type", &"mid")
	var crouching := false
	if block_type == &"low":
		crouching = rng.randf() < BLOCK_READ_ACCURACY
	elif block_type == &"overhead":
		crouching = rng.randf() >= BLOCK_READ_ACCURACY
	else:
		crouching = rng.randf() < 0.44
	return _start_guard(
		away,
		crouching,
		rng.randi_range(10, 19),
		&"crouch_guard" if crouching else &"stand_guard",
		buttons
	)


func _anti_air_intent(buttons: Dictionary) -> Dictionary:
	if rng.randf() < 0.56:
		buttons.heavy = true
		last_tactic = &"anti_air_heavy"
	else:
		buttons.special = true
		last_tactic = &"anti_air_special"
	attack_cooldown = rng.randi_range(28, 40)
	return _intent(Vector2(0.0, 1.0), buttons)


func _cooldown_movement(
	cpu: Fighter,
	distance: float,
	toward: float,
	away: float,
	buttons: Dictionary
) -> Dictionary:
	var roll := rng.randf()
	var cornered := _space_in_direction(cpu, away) < CORNER_SPACE
	if distance < CLOSE_RANGE:
		if roll < 0.46:
			if cornered:
				return _start_guard(away, false, rng.randi_range(7, 12), &"corner_guard", buttons)
			return _hold_decision(Vector2(away, 0.0), 5, 10, &"retreat", buttons)
		if roll < 0.69:
			return _hold_decision(Vector2.ZERO, 4, 9, &"close_patience", buttons)
		if roll < 0.86:
			return _start_guard(away, true, rng.randi_range(6, 11), &"crouch_guard", buttons)
		return _hold_decision(Vector2(toward, 0.0), 3, 6, &"micro_advance", buttons)

	if distance > MID_RANGE:
		if roll < 0.52:
			return _hold_decision(Vector2(toward, 0.0), 7, 14, &"approach", buttons)
		if roll < 0.80:
			return _hold_decision(Vector2.ZERO, 5, 11, &"far_patience", buttons)
		if not cornered:
			return _hold_decision(Vector2(away, 0.0), 4, 8, &"space_reset", buttons)
		return _hold_decision(Vector2.ZERO, 4, 8, &"corner_patience", buttons)

	if roll < 0.28:
		return _hold_decision(Vector2(toward, 0.0), 4, 8, &"micro_advance", buttons)
	if roll < 0.58 and not cornered:
		return _hold_decision(Vector2(away, 0.0), 4, 9, &"shimmy", buttons)
	if roll < 0.82:
		return _hold_decision(Vector2.ZERO, 5, 11, &"footsies_pause", buttons)
	return _start_guard(away, true, rng.randi_range(6, 11), &"crouch_guard", buttons)


func _ground_tactic(
	cpu: Fighter,
	opponent: Fighter,
	distance: float,
	toward: float,
	away: float,
	buttons: Dictionary
) -> Dictionary:
	var roll := rng.randf()
	var cornered := _space_in_direction(cpu, away) < CORNER_SPACE
	var needs_comeback := cpu.health + 180 < opponent.health

	if cpu.meter >= Fighter.MAX_METER and distance < MID_RANGE and roll < (0.20 if needs_comeback else 0.13):
		buttons.light = true
		buttons.heavy = true
		attack_cooldown = 50
		last_tactic = &"super"
		return _intent(Vector2.ZERO, buttons)

	if distance > FAR_RANGE:
		if cpu.character_id == &"ren" and roll < 0.30:
			buttons.special = true
			attack_cooldown = rng.randi_range(34, 48)
			last_tactic = &"projectile"
			return _intent(Vector2.ZERO, buttons)
		if roll < (0.70 if cpu.character_id == &"ren" else 0.58):
			return _hold_decision(Vector2(toward, 0.0), 8, 16, &"approach", buttons)
		if roll < 0.81 and jump_cooldown <= 0:
			jump_cooldown = rng.randi_range(48, 66)
			last_tactic = &"forward_jump"
			return _intent(Vector2(toward, -1.0), buttons)
		if roll < 0.93:
			return _hold_decision(Vector2.ZERO, 7, 14, &"far_patience", buttons)
		return _hold_decision(Vector2(0.0, 1.0), 5, 10, &"far_crouch", buttons)

	if distance > MID_RANGE:
		if cpu.character_id == &"ren" and roll < 0.18:
			buttons.special = true
			attack_cooldown = rng.randi_range(30, 44)
			last_tactic = &"projectile"
			return _intent(Vector2.ZERO, buttons)
		if roll < 0.36:
			buttons.special = true
			attack_cooldown = rng.randi_range(28, 42)
			last_tactic = &"advancing_special"
			return _intent(Vector2(toward, 0.0), buttons)
		if roll < 0.59:
			return _hold_decision(Vector2(toward, 0.0), 6, 13, &"approach", buttons)
		if roll < 0.74 and not cornered:
			return _hold_decision(Vector2(away, 0.0), 5, 10, &"space_reset", buttons)
		if roll < 0.87:
			return _hold_decision(Vector2.ZERO, 6, 13, &"footsies_pause", buttons)
		if roll < 0.94:
			return _hold_decision(Vector2(0.0, 1.0), 5, 10, &"crouch_feint", buttons)
		if jump_cooldown <= 0:
			jump_cooldown = rng.randi_range(48, 66)
			last_tactic = &"forward_jump"
			return _intent(Vector2(toward, -1.0), buttons)
		return _hold_decision(Vector2.ZERO, 5, 9, &"footsies_pause", buttons)

	if distance > POKE_RANGE:
		if roll < 0.17:
			buttons.heavy = true
			attack_cooldown = rng.randi_range(24, 35)
			last_tactic = &"overhead"
			return _intent(Vector2(toward, 0.0), buttons)
		if roll < 0.34:
			buttons.special = true
			attack_cooldown = rng.randi_range(26, 38)
			last_tactic = &"advancing_special"
			return _intent(Vector2(toward, 0.0), buttons)
		if roll < 0.49:
			return _hold_decision(Vector2(toward, 0.0), 4, 8, &"micro_advance", buttons)
		if roll < 0.66 and not cornered:
			return _hold_decision(Vector2(away, 0.0), 4, 9, &"shimmy", buttons)
		if roll < 0.80:
			return _hold_decision(Vector2.ZERO, 4, 9, &"footsies_pause", buttons)
		if roll < 0.88:
			return _start_guard(away, true, rng.randi_range(6, 11), &"crouch_guard", buttons)
		if jump_cooldown <= 0:
			jump_cooldown = rng.randi_range(40, 56)
			last_tactic = &"forward_jump"
			return _intent(Vector2(toward, -1.0), buttons)
		return _hold_decision(Vector2.ZERO, 4, 8, &"footsies_pause", buttons)

	if distance > CLOSE_RANGE:
		if roll < 0.19:
			buttons.light = true
			attack_cooldown = rng.randi_range(18, 28)
			last_tactic = &"poke_light"
			return _intent(Vector2.ZERO, buttons)
		if roll < 0.36:
			buttons.heavy = true
			attack_cooldown = rng.randi_range(24, 36)
			last_tactic = &"poke_heavy"
			return _intent(Vector2(toward if rng.randf() < 0.52 else 0.0, 0.0), buttons)
		if roll < 0.51:
			buttons.special = true
			attack_cooldown = rng.randi_range(25, 38)
			last_tactic = &"close_special"
			return _intent(Vector2(toward if rng.randf() < 0.62 else 0.0, 0.0), buttons)
		if roll < 0.67 and not cornered:
			return _hold_decision(Vector2(away, 0.0), 4, 8, &"shimmy", buttons)
		if roll < 0.79:
			return _hold_decision(Vector2.ZERO, 4, 8, &"close_patience", buttons)
		if roll < 0.87:
			return _start_guard(away, rng.randf() < 0.55, rng.randi_range(7, 13), &"guard_feint", buttons)
		if jump_cooldown <= 0:
			jump_cooldown = rng.randi_range(40, 56)
			last_tactic = &"neutral_jump"
			return _intent(Vector2(0.0, -1.0), buttons)
		return _hold_decision(Vector2.ZERO, 3, 7, &"close_patience", buttons)

	if roll < 0.16:
		buttons.throw = true
		var throw_axis := away if rng.randf() < 0.36 else 0.0
		attack_cooldown = rng.randi_range(26, 38)
		last_tactic = &"back_throw" if throw_axis != 0.0 else &"throw"
		return _intent(Vector2(throw_axis, 0.0), buttons)
	if roll < 0.38:
		buttons.light = true
		var crouch_light := rng.randf() < 0.38
		attack_cooldown = rng.randi_range(18, 28)
		last_tactic = &"crouch_light" if crouch_light else &"light"
		return _intent(Vector2(0.0, 1.0 if crouch_light else 0.0), buttons)
	if roll < 0.57:
		buttons.heavy = true
		var heavy_axis := Vector2(toward, 0.0) if rng.randf() < 0.54 else Vector2(0.0, 1.0)
		attack_cooldown = rng.randi_range(25, 38)
		last_tactic = &"overhead" if heavy_axis.x != 0.0 else &"anti_air_heavy"
		return _intent(heavy_axis, buttons)
	if roll < 0.72:
		buttons.special = true
		var special_roll := rng.randf()
		var special_axis := Vector2.ZERO
		if special_roll < 0.48:
			special_axis.x = toward
		elif special_roll < 0.72:
			special_axis.y = 1.0
		elif cpu.character_id == &"vel":
			special_axis.x = away
		attack_cooldown = rng.randi_range(27, 40)
		last_tactic = &"close_special"
		return _intent(special_axis, buttons)
	if roll < 0.84:
		return _start_guard(away, rng.randf() < 0.56, rng.randi_range(8, 15), &"close_guard", buttons)
	if roll < 0.96 and jump_cooldown <= 0:
		var jump_axis := away if not cornered else toward
		jump_cooldown = rng.randi_range(40, 56)
		last_tactic = &"escape_jump"
		return _intent(Vector2(jump_axis, -1.0), buttons)
	return _hold_decision(Vector2.ZERO, 4, 8, &"close_patience", buttons)


func _cannot_choose_action(cpu: Fighter) -> bool:
	return (
		cpu.state == &"hitstun"
		or cpu.state == &"blockstun"
		or cpu.state == &"knockdown"
		or cpu.state == &"forward_step"
		or cpu.state == &"back_step"
		or cpu.state == &"vel_shadow"
	)


func _opponent_is_threatening(opponent: Fighter, distance: float) -> bool:
	if not opponent.is_attacking():
		return false
	var attack := opponent.current_attack()
	var startup := int(attack.get("startup", 1))
	var active := int(attack.get("active", 1))
	if bool(attack.get("projectile", false)):
		var projectile_frame := int(attack.get("projectile_frame", startup))
		return (
			opponent.state_frame >= maxi(1, projectile_frame - 4)
			and opponent.state_frame <= projectile_frame + 2
			and distance <= FAR_RANGE + 140.0
		)
	var warning_frame := maxi(1, startup - 4)
	return (
		opponent.state_frame >= warning_frame
		and opponent.state_frame <= startup + active + 2
		and distance <= float(attack.get("range", 0.0)) + THREAT_PADDING
	)


func _refresh_threat_observation(opponent: Fighter) -> void:
	if not opponent.is_attacking():
		_clear_tracked_threat()
		return
	if tracked_threat_state == opponent.state:
		return
	tracked_threat_state = opponent.state
	threat_reaction_frames = -1
	threat_will_defend = false


func _clear_tracked_threat() -> void:
	tracked_threat_state = &""
	threat_reaction_frames = -1
	threat_will_defend = false


func _should_defend_threat(opponent: Fighter) -> bool:
	# Commit to one read per attack. A failed read stays failed until the
	# opponent starts a different action, preventing frame-by-frame rerolls from
	# turning a fallible reaction chance into near-perfect defense.
	if threat_reaction_frames < 0:
		threat_reaction_frames = rng.randi_range(
			THREAT_REACTION_MIN_FRAMES,
			THREAT_REACTION_MAX_FRAMES
		)
		threat_will_defend = rng.randf() < _threat_defense_chance(opponent.current_attack())
	if threat_reaction_frames > 0:
		threat_reaction_frames -= 1
		return false
	return threat_will_defend


func _threat_defense_chance(attack: Dictionary) -> float:
	if bool(attack.get("grab", false)) or bool(attack.get("unblockable", false)):
		return THROW_DEFENSE_CHANCE
	if bool(attack.get("projectile", false)):
		return PROJECTILE_DEFENSE_CHANCE
	if bool(attack.get("super", false)):
		return SUPER_DEFENSE_CHANCE
	return NORMAL_DEFENSE_CHANCE


func _space_in_direction(cpu: Fighter, direction: float) -> float:
	if direction < 0.0:
		return cpu.position.x - (Fighter.ARENA_LEFT + Fighter.BODY_WIDTH * 0.5)
	return (Fighter.ARENA_RIGHT - Fighter.BODY_WIDTH * 0.5) - cpu.position.x


func _start_guard(
	away: float,
	crouching: bool,
	frames: int,
	tactic: StringName,
	buttons: Dictionary
) -> Dictionary:
	guard_axis = Vector2(away, 1.0 if crouching else 0.0)
	guard_frames = maxi(0, frames - 1)
	last_tactic = tactic
	return _intent(guard_axis, buttons)


func _hold_decision(
	axis: Vector2,
	minimum_frames: int,
	maximum_frames: int,
	tactic: StringName,
	buttons: Dictionary
) -> Dictionary:
	decision_axis = axis
	decision_frames = maxi(0, rng.randi_range(minimum_frames, maximum_frames) - 1)
	last_tactic = tactic
	return _intent(decision_axis, buttons)


func _reset_buttons() -> void:
	for button_name in decision_buttons:
		decision_buttons[button_name] = false


func _intent(axis: Vector2, buttons: Dictionary) -> Dictionary:
	output_intent.axis = axis
	output_intent.buttons = buttons
	return output_intent
