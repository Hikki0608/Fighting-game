class_name Fighter
extends Node2D

const GROUND_Y := 558.0
const ARENA_LEFT := 76.0
const ARENA_RIGHT := 1076.0
const GRAVITY := 2350.0
const WALK_SPEED := 275.0
const JUMP_SPEED := -850.0
const BODY_WIDTH := 58.0
const BODY_HEIGHT := 126.0
const CROUCH_HEIGHT := 82.0

const ATTACKS := {
	&"light": {
		"startup": 4, "active": 3, "recovery": 9,
		"damage": 48, "chip": 0, "hitstun": 15, "blockstun": 9,
		"range": 78.0, "height": 52.0, "push": 15.0,
		"hitstop": 7, "label": "LIGHT"
	},
	&"heavy": {
		"startup": 9, "active": 4, "recovery": 18,
		"damage": 92, "chip": 0, "hitstun": 23, "blockstun": 13,
		"range": 112.0, "height": 70.0, "push": 30.0,
		"hitstop": 11, "label": "HEAVY"
	},
	&"special": {
		"startup": 8, "active": 7, "recovery": 24,
		"damage": 118, "chip": 12, "hitstun": 28, "blockstun": 17,
		"range": 132.0, "height": 84.0, "push": 46.0,
		"hitstop": 13, "label": "BREAK EDGE"
	},
	&"throw": {
		"startup": 5, "active": 2, "recovery": 24,
		"damage": 135, "chip": 0, "hitstun": 32, "blockstun": 0,
		"range": 56.0, "height": 96.0, "push": 72.0,
		"hitstop": 15, "label": "THROW", "unblockable": true,
		"knockdown": true, "launch_y": -330.0, "bottom_offset": 8.0
	},
	&"jump_light": {
		"startup": 5, "active": 5, "recovery": 10,
		"damage": 58, "chip": 0, "hitstun": 17, "blockstun": 10,
		"range": 82.0, "height": 72.0, "push": 18.0,
		"hitstop": 8, "label": "JUMP LIGHT", "airborne": true,
		"bottom_offset": -4.0
	},
	&"jump_heavy": {
		"startup": 9, "active": 6, "recovery": 17,
		"damage": 104, "chip": 0, "hitstun": 25, "blockstun": 14,
		"range": 104.0, "height": 92.0, "push": 34.0,
		"hitstop": 12, "label": "JUMP HEAVY", "airborne": true,
		"bottom_offset": -12.0
	}
}

var player_id := 0
var fighter_name := "PLAYER 1"
var body_color := Color("4ed8ff")
var accent_color := Color("e9fbff")
var health := 1000
var facing := 1
var velocity := Vector2.ZERO
var state: StringName = &"idle"
var state_frame := 0
var attack_connected := false
var intent := {
	"axis": Vector2.ZERO,
	"buttons": {},
	"pressed": {}
}
var previous_buttons := {
	"light": false,
	"heavy": false,
	"special": false,
	"throw": false
}
var sampled_buttons := {
	"light": false,
	"heavy": false,
	"special": false,
	"throw": false
}
var input_history: Array[Vector2] = []
var debug_boxes := false
var combo_received := 0
var last_hit_result := ""
var throw_backwards := false
var air_attack_used := false
var last_visual_state: StringName = &""
var last_visual_frame := -1
var last_visual_facing := 0
var last_visual_height := -1
var last_visual_back_throw := false
var last_visual_debug := false
var last_visual_attack_active := false


func setup(id: int, display_name: String, color: Color, spawn_position: Vector2) -> void:
	player_id = id
	fighter_name = display_name
	body_color = color
	accent_color = color.lightened(0.55)
	position = spawn_position
	facing = 1 if player_id == 0 else -1
	reset_for_round(spawn_position)


func reset_for_round(spawn_position: Vector2) -> void:
	position = spawn_position
	health = 1000
	velocity = Vector2.ZERO
	state = &"idle"
	state_frame = 0
	attack_connected = false
	combo_received = 0
	last_hit_result = ""
	throw_backwards = false
	air_attack_used = false
	previous_buttons = {
		"light": false,
		"heavy": false,
		"special": false,
		"throw": false
	}
	intent = {
		"axis": Vector2.ZERO,
		"buttons": previous_buttons.duplicate(),
		"pressed": previous_buttons.duplicate()
	}
	input_history.clear()
	_invalidate_visual_cache()
	_queue_visual_redraw_if_needed()


func capture_input() -> void:
	var axis := Vector2.ZERO
	var buttons := sampled_buttons
	_reset_sampled_buttons()

	if player_id == 0:
		axis.x = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
		axis.y = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
		buttons.light = Input.is_physical_key_pressed(KEY_F)
		buttons.heavy = Input.is_physical_key_pressed(KEY_G)
		buttons.special = Input.is_physical_key_pressed(KEY_H)
		buttons.throw = Input.is_physical_key_pressed(KEY_R)
	else:
		axis.x = float(Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_LEFT))
		axis.y = float(Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_UP))
		buttons.light = Input.is_physical_key_pressed(KEY_J)
		buttons.heavy = Input.is_physical_key_pressed(KEY_K)
		buttons.special = Input.is_physical_key_pressed(KEY_L)
		buttons.throw = Input.is_physical_key_pressed(KEY_I)

	var joy_x := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_X)
	var joy_y := Input.get_joy_axis(player_id, JOY_AXIS_LEFT_Y)
	if absf(joy_x) > 0.28:
		axis.x = joy_x
	if absf(joy_y) > 0.28:
		axis.y = joy_y
	buttons.light = buttons.light or Input.is_joy_button_pressed(player_id, JOY_BUTTON_X)
	buttons.heavy = buttons.heavy or Input.is_joy_button_pressed(player_id, JOY_BUTTON_Y)
	buttons.special = buttons.special or Input.is_joy_button_pressed(player_id, JOY_BUTTON_B)
	buttons.throw = buttons.throw or Input.is_joy_button_pressed(player_id, JOY_BUTTON_LEFT_SHOULDER)
	_commit_input(axis, buttons)


func apply_virtual_input(axis: Vector2, requested_buttons: Dictionary = {}) -> void:
	var buttons := sampled_buttons
	buttons.light = bool(requested_buttons.get("light", false))
	buttons.heavy = bool(requested_buttons.get("heavy", false))
	buttons.special = bool(requested_buttons.get("special", false))
	buttons.throw = bool(requested_buttons.get("throw", false))
	_commit_input(axis, buttons)


func clear_input() -> void:
	apply_virtual_input(Vector2.ZERO)


func _commit_input(raw_axis: Vector2, buttons: Dictionary) -> void:
	var axis := raw_axis

	axis.x = 0.0 if absf(axis.x) < 0.28 else signf(axis.x)
	axis.y = 0.0 if absf(axis.y) < 0.28 else signf(axis.y)

	var pressed: Dictionary = intent.pressed
	var committed_buttons: Dictionary = intent.buttons
	for button_name in buttons:
		pressed[button_name] = buttons[button_name] and not previous_buttons.get(button_name, false)
		previous_buttons[button_name] = buttons[button_name]
		committed_buttons[button_name] = buttons[button_name]
	intent.axis = axis

	input_history.push_front(Vector2(axis.x * facing, axis.y))
	if input_history.size() > 18:
		input_history.pop_back()


func _reset_sampled_buttons() -> void:
	for button_name in sampled_buttons:
		sampled_buttons[button_name] = false


func simulate(opponent: Fighter, accepting_input: bool) -> void:
	if state == &"hitstun" or state == &"blockstun":
		_step_stun()
	elif state == &"knockdown":
		_step_knockdown()
	elif ATTACKS.has(state):
		_step_attack()
	elif accepting_input:
		_step_neutral(opponent)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 55.0)

	_apply_physics()
	if is_on_ground() and _can_turn():
		facing = 1 if opponent.position.x >= position.x else -1
	_queue_visual_redraw_if_needed()


func _step_neutral(opponent: Fighter) -> void:
	if not is_on_ground():
		state = &"jump"
		if not air_attack_used and intent.pressed.light:
			air_attack_used = true
			change_state(&"jump_light")
			return
		if not air_attack_used and intent.pressed.heavy:
			air_attack_used = true
			change_state(&"jump_heavy")
			return
		velocity.x = intent.axis.x * WALK_SPEED * 0.72
		return

	if intent.pressed.throw:
		throw_backwards = intent.axis.x * float(facing) < -0.5
		change_state(&"throw")
		return
	if intent.pressed.special or (intent.pressed.heavy and _has_quarter_circle_forward()):
		change_state(&"special")
		return
	if intent.pressed.heavy:
		change_state(&"heavy")
		return
	if intent.pressed.light:
		change_state(&"light")
		return
	if intent.axis.y < -0.5:
		velocity.y = JUMP_SPEED
		velocity.x = intent.axis.x * WALK_SPEED * 0.78
		state = &"jump"
		state_frame = 0
		return
	if intent.axis.y > 0.5:
		state = &"crouch"
		velocity.x = 0.0
	elif absf(intent.axis.x) > 0.1:
		state = &"walk"
		velocity.x = intent.axis.x * WALK_SPEED
	else:
		state = &"idle"
		velocity.x = move_toward(velocity.x, 0.0, 70.0)

	if absf(opponent.position.x - position.x) < 2.0:
		velocity.x = 0.0


func _step_attack() -> void:
	state_frame += 1
	var data := current_attack()
	if bool(data.get("airborne", false)):
		var air_target_speed: float = intent.axis.x * WALK_SPEED * 0.62
		velocity.x = move_toward(velocity.x, air_target_speed, 18.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 48.0)
	if state == &"special" and state_frame >= 5 and state_frame <= 16 and is_on_ground():
		velocity.x = facing * 350.0
	var total: int = data.startup + data.active + data.recovery
	if state_frame >= total:
		state = &"idle" if is_on_ground() else &"jump"
		state_frame = 0
		attack_connected = false


func _step_stun() -> void:
	state_frame += 1
	velocity.x = move_toward(velocity.x, 0.0, 18.0)
	var duration := 1
	if state == &"hitstun":
		duration = int(last_hit_result.get_slice(":", 1)) if last_hit_result.begins_with("HIT:") else 16
	else:
		duration = int(last_hit_result.get_slice(":", 1)) if last_hit_result.begins_with("BLOCK:") else 10
	if state_frame >= duration:
		state = &"idle" if is_on_ground() else &"jump"
		state_frame = 0
		if state == &"idle":
			combo_received = 0


func _step_knockdown() -> void:
	state_frame += 1
	velocity.x = move_toward(velocity.x, 0.0, 12.0)
	if state_frame >= 48:
		state = &"idle"
		state_frame = 0
		combo_received = 0


func _apply_physics() -> void:
	if not is_on_ground() or velocity.y < 0.0:
		velocity.y += GRAVITY / 60.0
	position += velocity / 60.0
	position.x = clampf(position.x, ARENA_LEFT + BODY_WIDTH * 0.5, ARENA_RIGHT - BODY_WIDTH * 0.5)
	if position.y >= GROUND_Y:
		position.y = GROUND_Y
		velocity.y = 0.0
		if state == &"jump" or is_air_attack():
			state = &"idle"
			state_frame = 0
			attack_connected = false
			air_attack_used = false
			velocity.x = move_toward(velocity.x, 0.0, 90.0)


func change_state(next_state: StringName) -> void:
	state = next_state
	state_frame = 0
	attack_connected = false
	if next_state != &"throw":
		throw_backwards = false
	if ATTACKS.has(next_state) and not bool(ATTACKS[next_state].get("airborne", false)):
		velocity.x = 0.0


func is_attack_active() -> bool:
	if not ATTACKS.has(state) or attack_connected:
		return false
	var data: Dictionary = ATTACKS[state]
	return state_frame > int(data.startup) and state_frame <= int(data.startup + data.active)


func current_attack() -> Dictionary:
	if not ATTACKS.has(state):
		return {}
	var data: Dictionary = ATTACKS[state]
	if state == &"throw" and throw_backwards:
		var back_throw := data.duplicate()
		back_throw.label = "BACK THROW"
		back_throw.push = 150.0
		back_throw.launch_y = -390.0
		back_throw.back_throw = true
		return back_throw
	return data


func attack_rect() -> Rect2:
	var data := current_attack()
	if data.is_empty():
		return Rect2()
	var attack_range: float = data.range
	var attack_height: float = data.height
	var x := position.x + BODY_WIDTH * 0.32 if facing > 0 else position.x - BODY_WIDTH * 0.32 - attack_range
	var bottom_offset: float = float(data.get("bottom_offset", 22.0))
	var y := position.y - attack_height - bottom_offset
	return Rect2(x, y, attack_range, attack_height)


func hurt_rect() -> Rect2:
	var height := CROUCH_HEIGHT if state == &"crouch" else BODY_HEIGHT
	if state == &"knockdown":
		height = 44.0
	return Rect2(position.x - BODY_WIDTH * 0.5, position.y - height, BODY_WIDTH, height)


func receive_attack(data: Dictionary, attacker_x: float, forced_push_direction := 0.0) -> Dictionary:
	var unblockable: bool = data.get("unblockable", false)
	var blocked := not unblockable and _is_blocking(attacker_x)
	var damage: int = int(data.chip) if blocked else int(data.damage)
	health = maxi(0, health - damage)
	state_frame = 0
	attack_connected = false
	var push_direction := signf(position.x - attacker_x)
	if absf(forced_push_direction) > 0.1:
		push_direction = signf(forced_push_direction)
	velocity.x = push_direction * float(data.push) * (0.65 if blocked else 1.0)

	if blocked:
		state = &"blockstun"
		last_hit_result = "BLOCK:%d" % int(data.blockstun)
	else:
		combo_received += 1
		state = &"knockdown" if health <= 0 or bool(data.get("knockdown", false)) else &"hitstun"
		last_hit_result = "HIT:%d" % int(data.hitstun)
		if state == &"knockdown":
			velocity.y = float(data.get("launch_y", -330.0))

	_queue_visual_redraw_if_needed()
	return {
		"blocked": blocked,
		"damage": damage,
		"ko": health <= 0,
		"hitstop": int(data.hitstop),
		"combo": combo_received,
		"label": str(data.get("label", "HIT")),
		"back_throw": bool(data.get("back_throw", false))
	}


func mark_attack_connected() -> void:
	attack_connected = true


func set_debug_boxes(enabled: bool) -> void:
	debug_boxes = enabled
	_queue_visual_redraw_if_needed()


func _invalidate_visual_cache() -> void:
	last_visual_state = &""
	last_visual_frame = -1
	last_visual_facing = 0
	last_visual_height = -1
	last_visual_back_throw = not throw_backwards
	last_visual_debug = not debug_boxes
	last_visual_attack_active = false


func _queue_visual_redraw_if_needed() -> void:
	var animated_frame := state_frame if ATTACKS.has(state) else 0
	var height_step := roundi(position.y) if not is_on_ground() else roundi(GROUND_Y)
	var attack_active := debug_boxes and is_attack_active()
	var visual_changed := (
		last_visual_state != state
		or last_visual_frame != animated_frame
		or last_visual_facing != facing
		or last_visual_height != height_step
		or last_visual_back_throw != throw_backwards
		or last_visual_debug != debug_boxes
		or last_visual_attack_active != attack_active
	)
	if not visual_changed:
		return

	last_visual_state = state
	last_visual_frame = animated_frame
	last_visual_facing = facing
	last_visual_height = height_step
	last_visual_back_throw = throw_backwards
	last_visual_debug = debug_boxes
	last_visual_attack_active = attack_active
	queue_redraw()


func is_on_ground() -> bool:
	return position.y >= GROUND_Y - 0.1


func is_air_attack() -> bool:
	return ATTACKS.has(state) and bool(ATTACKS[state].get("airborne", false))


func _can_turn() -> bool:
	return state == &"idle" or state == &"walk" or state == &"crouch"


func _is_blocking(attacker_x: float) -> bool:
	if not is_on_ground() or ATTACKS.has(state) or state == &"hitstun" or state == &"knockdown":
		return false
	var attacker_is_left := attacker_x < position.x
	return intent.axis.x > 0.5 if attacker_is_left else intent.axis.x < -0.5


func _has_quarter_circle_forward() -> bool:
	var phase := 0
	for direction in input_history:
		if phase == 0 and direction.x > 0.5 and direction.y < 0.7:
			phase = 1
		elif phase == 1 and direction.x > 0.3 and direction.y > 0.3:
			phase = 2
		elif phase == 2 and direction.y > 0.5:
			return true
	return false


func frame_data_text() -> String:
	if ATTACKS.has(state):
		var data := current_attack()
		return "%s  %02d/%02d  S:%d A:%d R:%d" % [
			str(data.label), state_frame,
			int(data.startup + data.active + data.recovery),
			int(data.startup), int(data.active), int(data.recovery)
		]
	return "%s  frame:%02d" % [str(state).to_upper(), state_frame]


func _draw() -> void:
	# The shadow stays on the arena floor while the fighter jumps.
	var shadow_y := GROUND_Y - position.y - 2.0
	var shadow_scale := clampf(1.0 - absf(GROUND_Y - position.y) / 420.0, 0.48, 1.0)
	draw_set_transform(Vector2(0, shadow_y), 0.0, Vector2(1.45 * shadow_scale, 0.30 * shadow_scale))
	draw_circle(Vector2.ZERO, 30.0, Color(0.0, 0.0, 0.0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var crouch_offset := 30.0 if state == &"crouch" else 0.0
	var lean := 13.0 * facing if state == &"special" else 0.0
	if state == &"throw" and throw_backwards:
		lean = -9.0 * facing
	var body_rect := Rect2(-25.0 + lean, -98.0 + crouch_offset, 50.0, 80.0 - crouch_offset)
	if state == &"knockdown":
		body_rect = Rect2(-55.0, -30.0, 110.0, 28.0)
	draw_rect(body_rect, body_color, true)
	draw_rect(body_rect, accent_color, false, 3.0)

	if state != &"knockdown":
		draw_circle(Vector2(lean, -116.0 + crouch_offset), 22.0, body_color.lightened(0.18))
		draw_arc(Vector2(lean, -116.0 + crouch_offset), 22.0, 0.0, TAU, 24, accent_color, 3.0)
		draw_circle(Vector2(lean + facing * 8.0, -120.0 + crouch_offset), 3.2, Color("10202d"))

		var front_hand := Vector2(facing * 32.0 + lean, -77.0 + crouch_offset)
		if state == &"jump_light":
			var jab_extension := clampf(float(state_frame) / 6.0, 0.0, 1.0)
			front_hand = Vector2(facing * (34.0 + 50.0 * jab_extension), -88.0)
		elif ATTACKS.has(state) and state != &"jump_heavy":
			front_hand.x += facing * minf(48.0, state_frame * 7.0)
		draw_line(Vector2(lean, -80.0 + crouch_offset), front_hand, accent_color, 10.0)
		draw_circle(front_hand, 10.0, Color("fff4b8") if state == &"special" else body_color.lightened(0.35))

		if state == &"jump_heavy":
			var kick_extension := sin(clampf(float(state_frame) / 18.0, 0.0, 1.0) * PI)
			var kick_foot := Vector2(facing * (34.0 + 55.0 * kick_extension), -34.0 + 18.0 * kick_extension)
			draw_line(Vector2(facing * 10.0, -24.0), kick_foot, accent_color, 12.0)
			draw_circle(kick_foot, 9.0, Color("fff4b8"))
			draw_line(Vector2(-facing * 8.0, -24.0), Vector2(-facing * 25.0, -5.0), accent_color, 10.0)
		elif not is_on_ground():
			draw_line(Vector2(-12.0, -22.0), Vector2(-25.0, -4.0), accent_color, 10.0)
			draw_line(Vector2(12.0, -22.0), Vector2(27.0, -9.0), accent_color, 10.0)
		else:
			draw_line(Vector2(-12.0, -20.0), Vector2(-20.0, 0.0), accent_color, 10.0)
			draw_line(Vector2(12.0, -20.0), Vector2(20.0, 0.0), accent_color, 10.0)

	if state == &"blockstun":
		draw_arc(Vector2(facing * -29.0, -70.0), 42.0, -1.5, 1.5, 18, Color("9bf6ff"), 5.0)

	if debug_boxes:
		var local_hurt := hurt_rect()
		local_hurt.position -= position
		draw_rect(local_hurt, Color(0.2, 1.0, 0.35, 0.16), true)
		draw_rect(local_hurt, Color(0.2, 1.0, 0.35, 0.9), false, 2.0)
		if is_attack_active():
			var local_attack := attack_rect()
			local_attack.position -= position
			draw_rect(local_attack, Color(1.0, 0.18, 0.18, 0.22), true)
			draw_rect(local_attack, Color(1.0, 0.2, 0.2, 0.95), false, 2.0)
