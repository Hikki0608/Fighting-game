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
const VISUAL_SIZE := 176.0
const MAX_METER := 100
const INPUT_BUFFER_FRAMES := 7

const ATTACKS := {
	&"light": {
		"startup": 4, "active": 3, "recovery": 8,
		"damage": 42, "chip": 0, "hitstun": 15, "blockstun": 8,
		"range": 74.0, "height": 48.0, "push": 14.0,
		"hitstop": 7, "label": "STANDING LIGHT", "effect": &"jab",
		"meter_hit": 7, "meter_block": 3
	},
	&"crouch_light": {
		"startup": 5, "active": 3, "recovery": 9,
		"damage": 38, "chip": 0, "hitstun": 14, "blockstun": 8,
		"range": 72.0, "height": 34.0, "push": 12.0,
		"hitstop": 6, "label": "CROUCH LIGHT", "effect": &"low",
		"bottom_offset": 2.0, "block_type": &"low",
		"meter_hit": 6, "meter_block": 3
	},
	&"heavy": {
		"startup": 9, "active": 4, "recovery": 17,
		"damage": 88, "chip": 0, "hitstun": 23, "blockstun": 13,
		"range": 106.0, "height": 74.0, "push": 30.0,
		"hitstop": 11, "label": "STANDING HEAVY", "effect": &"arc",
		"bottom_offset": 25.0, "meter_hit": 10, "meter_block": 5
	},
	&"forward_heavy": {
		"startup": 18, "active": 4, "recovery": 22,
		"damage": 110, "chip": 0, "hitstun": 25, "blockstun": 15,
		"range": 116.0, "height": 70.0, "push": 38.0,
		"hitstop": 12, "label": "OVERHEAD", "effect": &"overhead",
		"bottom_offset": 55.0, "block_type": &"overhead",
		"meter_hit": 12, "meter_block": 6
	},
	&"crouch_heavy": {
		"startup": 8, "active": 5, "recovery": 20,
		"damage": 96, "chip": 0, "hitstun": 24, "blockstun": 14,
		"range": 88.0, "height": 112.0, "push": 26.0,
		"hitstop": 11, "label": "ANTI-AIR", "effect": &"rise",
		"bottom_offset": 8.0, "anti_air": true, "launch_y": -360.0,
		"meter_hit": 11, "meter_block": 5
	},
	&"throw": {
		"startup": 5, "active": 2, "recovery": 24,
		"damage": 135, "chip": 0, "hitstun": 32, "blockstun": 0,
		"range": 56.0, "height": 96.0, "push": 72.0,
		"hitstop": 15, "label": "THROW", "effect": &"throw",
		"unblockable": true, "grab": true, "knockdown": true,
		"launch_y": -330.0, "bottom_offset": 8.0,
		"meter_hit": 14, "meter_block": 0
	},
	&"jump_light": {
		"startup": 5, "active": 5, "recovery": 10,
		"damage": 58, "chip": 0, "hitstun": 17, "blockstun": 10,
		"range": 82.0, "height": 72.0, "push": 18.0,
		"hitstop": 8, "label": "JUMP LIGHT", "effect": &"air_jab",
		"airborne": true, "bottom_offset": -4.0,
		"meter_hit": 8, "meter_block": 4
	},
	&"jump_heavy": {
		"startup": 9, "active": 6, "recovery": 17,
		"damage": 104, "chip": 0, "hitstun": 25, "blockstun": 14,
		"range": 104.0, "height": 92.0, "push": 34.0,
		"hitstop": 12, "label": "JUMP HEAVY", "effect": &"air_arc",
		"airborne": true, "bottom_offset": -12.0,
		"meter_hit": 12, "meter_block": 6
	},
	&"ren_pulse": {
		"startup": 13, "active": 1, "recovery": 22,
		"damage": 0, "chip": 0, "hitstun": 0, "blockstun": 0,
		"range": 0.0, "height": 0.0, "push": 0.0, "hitstop": 0,
		"label": "AZURE PULSE", "effect": &"projectile_cast",
		"projectile": true, "projectile_frame": 13
	},
	&"ren_palm": {
		"startup": 8, "active": 4, "recovery": 17,
		"damage": 106, "chip": 8, "hitstun": 26, "blockstun": 15,
		"range": 118.0, "height": 76.0, "push": 42.0,
		"hitstop": 12, "label": "FLASH PALM", "effect": &"energy",
		"bottom_offset": 22.0, "meter_hit": 13, "meter_block": 7
	},
	&"ren_rise": {
		"startup": 5, "active": 8, "recovery": 25,
		"damage": 118, "chip": 0, "hitstun": 28, "blockstun": 16,
		"range": 78.0, "height": 128.0, "push": 30.0,
		"hitstop": 13, "label": "SKY BREAK", "effect": &"rise",
		"bottom_offset": 0.0, "airborne": true, "knockdown": true,
		"launch_y": -430.0, "invulnerable_until": 8,
		"meter_hit": 14, "meter_block": 7
	},
	&"ren_dive": {
		"startup": 7, "active": 10, "recovery": 16,
		"damage": 96, "chip": 4, "hitstun": 24, "blockstun": 14,
		"range": 82.0, "height": 80.0, "push": 32.0,
		"hitstop": 11, "label": "COMET DIVE", "effect": &"dive",
		"bottom_offset": -15.0, "airborne": true,
		"block_type": &"overhead", "meter_hit": 12, "meter_block": 6
	},
	&"ren_super": {
		"startup": 6, "active": 20, "recovery": 26,
		"damage": 46, "chip": 5, "hitstun": 13, "blockstun": 11,
		"range": 148.0, "height": 92.0, "push": 8.0,
		"hitstop": 7, "label": "AZURE ZERO", "effect": &"super_blue",
		"bottom_offset": 12.0, "hit_frames": [7, 11, 15, 19, 25],
		"super": true, "meter_hit": 0, "meter_block": 0
	},
	&"vel_rake": {
		"startup": 6, "active": 11, "recovery": 18,
		"damage": 42, "chip": 4, "hitstun": 12, "blockstun": 10,
		"range": 112.0, "height": 84.0, "push": 12.0,
		"hitstop": 6, "label": "CRIMSON RAKE", "effect": &"claw",
		"bottom_offset": 16.0, "hit_frames": [7, 11, 15],
		"meter_hit": 5, "meter_block": 3
	},
	&"vel_pounce": {
		"startup": 10, "active": 7, "recovery": 19,
		"damage": 112, "chip": 5, "hitstun": 27, "blockstun": 16,
		"range": 98.0, "height": 88.0, "push": 38.0,
		"hitstop": 12, "label": "PREDATOR POUNCE", "effect": &"pounce",
		"bottom_offset": -10.0, "airborne": true,
		"block_type": &"overhead", "meter_hit": 14, "meter_block": 7
	},
	&"vel_rise": {
		"startup": 7, "active": 8, "recovery": 23,
		"damage": 138, "chip": 0, "hitstun": 30, "blockstun": 18,
		"range": 82.0, "height": 132.0, "push": 34.0,
		"hitstop": 14, "label": "HUNTER RISE", "effect": &"claw_rise",
		"bottom_offset": 0.0, "airborne": true, "knockdown": true,
		"launch_y": -450.0, "meter_hit": 15, "meter_block": 7
	},
	&"vel_dive": {
		"startup": 8, "active": 10, "recovery": 18,
		"damage": 114, "chip": 5, "hitstun": 27, "blockstun": 16,
		"range": 92.0, "height": 88.0, "push": 42.0,
		"hitstop": 13, "label": "REAPER DIVE", "effect": &"claw_dive",
		"bottom_offset": -14.0, "airborne": true,
		"block_type": &"overhead", "knockdown": true,
		"launch_y": -260.0, "meter_hit": 14, "meter_block": 7
	},
	&"vel_super": {
		"startup": 7, "active": 5, "recovery": 34,
		"damage": 320, "chip": 0, "hitstun": 40, "blockstun": 0,
		"range": 150.0, "height": 104.0, "push": 92.0,
		"hitstop": 18, "label": "RED ECLIPSE", "effect": &"super_red",
		"bottom_offset": 4.0, "unblockable": true, "grab": true,
		"knockdown": true, "launch_y": -430.0,
		"super": true, "meter_hit": 0, "meter_block": 0
	}
}

const REN_PULSE_PROJECTILE := {
	"damage": 72, "chip": 8, "hitstun": 20, "blockstun": 13,
	"push": 24.0, "hitstop": 8, "label": "AZURE PULSE",
	"meter_hit": 10, "meter_block": 5, "projectile": true
}

var player_id := 0
var character_id: StringName = &"ren"
var fighter_name := "PLAYER 1"
var body_color := Color("4ed8ff")
var accent_color := Color("e9fbff")
var character_texture: Texture2D
var health := 1000
var meter := 0
var facing := 1
var velocity := Vector2.ZERO
var state: StringName = &"idle"
var state_frame := 0
var attack_connected := false
var attack_has_connected := false
var connected_hit_frames: Array[int] = []
var pending_projectile := false
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
var button_buffer := {
	"light": 0,
	"heavy": 0,
	"special": 0,
	"throw": 0
}
var input_history: Array[Vector2] = []
var debug_boxes := false
var combo_received := 0
var last_hit_result := ""
var block_stance_crouching := false
var throw_backwards := false
var air_attack_used := false
var last_visual_state: StringName = &""
var last_visual_frame := -1
var last_visual_facing := 0
var last_visual_height := -1
var last_visual_back_throw := false
var last_visual_debug := false
var last_visual_attack_active := false
var last_visual_meter := -1


func setup(
	id: int,
	display_name: String,
	color: Color,
	spawn_position: Vector2,
	texture: Texture2D = null
) -> void:
	player_id = id
	configure_character(StringName(display_name.to_lower()), display_name, color, texture)
	position = spawn_position
	facing = 1 if player_id == 0 else -1
	reset_for_round(spawn_position)


func configure_character(
	selected_character_id: StringName,
	display_name: String,
	color: Color,
	texture: Texture2D
) -> void:
	character_id = selected_character_id
	fighter_name = display_name
	body_color = color
	accent_color = color.lightened(0.55)
	character_texture = texture
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_invalidate_visual_cache()
	queue_redraw()


func reset_match_resources() -> void:
	meter = 0
	_invalidate_visual_cache()
	queue_redraw()


func gain_meter(amount: int) -> void:
	if amount <= 0:
		return
	meter = mini(MAX_METER, meter + amount)
	_queue_visual_redraw_if_needed()


func spend_meter(amount: int) -> bool:
	if amount <= 0 or meter < amount:
		return false
	meter -= amount
	_queue_visual_redraw_if_needed()
	return true


func reset_for_round(spawn_position: Vector2) -> void:
	position = spawn_position
	health = 1000
	velocity = Vector2.ZERO
	state = &"idle"
	state_frame = 0
	attack_connected = false
	attack_has_connected = false
	connected_hit_frames.clear()
	pending_projectile = false
	combo_received = 0
	last_hit_result = ""
	block_stance_crouching = false
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
	for button_name in button_buffer:
		button_buffer[button_name] = 0
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


func clear_action_buffer() -> void:
	for button_name in button_buffer:
		button_buffer[button_name] = 0


func _commit_input(raw_axis: Vector2, buttons: Dictionary) -> void:
	var axis := raw_axis

	axis.x = 0.0 if absf(axis.x) < 0.28 else signf(axis.x)
	axis.y = 0.0 if absf(axis.y) < 0.28 else signf(axis.y)

	var pressed: Dictionary = intent.pressed
	var committed_buttons: Dictionary = intent.buttons
	for button_name in buttons:
		var just_pressed: bool = buttons[button_name] and not previous_buttons.get(button_name, false)
		pressed[button_name] = just_pressed
		if just_pressed:
			button_buffer[button_name] = INPUT_BUFFER_FRAMES
		previous_buttons[button_name] = buttons[button_name]
		committed_buttons[button_name] = buttons[button_name]
	intent.axis = axis

	input_history.push_front(Vector2(axis.x * facing, axis.y))
	if input_history.size() > 18:
		input_history.pop_back()


func _reset_sampled_buttons() -> void:
	for button_name in sampled_buttons:
		sampled_buttons[button_name] = false


func _is_button_buffered(button_name: String) -> bool:
	return int(button_buffer.get(button_name, 0)) > 0


func _consume_button(button_name: String) -> void:
	button_buffer[button_name] = 0


func _tick_input_buffer() -> void:
	for button_name in button_buffer:
		button_buffer[button_name] = maxi(0, int(button_buffer[button_name]) - 1)


func simulate(opponent: Fighter, accepting_input: bool) -> void:
	if state == &"hitstun" or state == &"blockstun":
		_step_stun()
	elif state == &"knockdown":
		_step_knockdown()
	elif state == &"vel_shadow":
		_step_vel_shadow()
	elif is_attacking():
		_step_attack()
	elif accepting_input:
		_step_neutral(opponent)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 55.0)

	_apply_physics()
	if is_on_ground() and _can_turn():
		facing = 1 if opponent.position.x >= position.x else -1
	_tick_input_buffer()
	_queue_visual_redraw_if_needed()


func _step_neutral(opponent: Fighter) -> void:
	if not is_on_ground():
		state = &"jump"
		if not air_attack_used and _is_button_buffered("special"):
			_consume_button("special")
			air_attack_used = true
			change_state(&"ren_dive" if character_id == &"ren" else &"vel_dive")
			return
		if not air_attack_used and _is_button_buffered("light"):
			_consume_button("light")
			air_attack_used = true
			change_state(&"jump_light")
			return
		if not air_attack_used and _is_button_buffered("heavy"):
			_consume_button("heavy")
			air_attack_used = true
			change_state(&"jump_heavy")
			return
		velocity.x = intent.axis.x * WALK_SPEED * 0.72
		return

	if _try_start_super():
		return
	if _is_button_buffered("throw"):
		_consume_button("throw")
		throw_backwards = intent.axis.x * float(facing) < -0.5
		change_state(&"throw")
		return
	if _is_button_buffered("special"):
		_consume_button("special")
		_start_character_special()
		return
	if _is_button_buffered("heavy") and _has_quarter_circle_forward():
		_consume_button("heavy")
		_start_character_special(true)
		return
	if _is_button_buffered("heavy"):
		_consume_button("heavy")
		change_state(_selected_heavy_state())
		return
	if _is_button_buffered("light"):
		_consume_button("light")
		change_state(&"crouch_light" if intent.axis.y > 0.5 else &"light")
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


func _try_start_super() -> bool:
	if not _is_button_buffered("light") or not _is_button_buffered("heavy"):
		return false
	if meter < MAX_METER:
		return false
	_consume_button("light")
	_consume_button("heavy")
	spend_meter(MAX_METER)
	change_state(&"ren_super" if character_id == &"ren" else &"vel_super")
	return true


func _start_character_special(force_forward := false) -> void:
	var relative_x: float = intent.axis.x * float(facing)
	if intent.axis.y > 0.5:
		change_state(&"ren_rise" if character_id == &"ren" else &"vel_rise")
		return
	if force_forward or relative_x > 0.5:
		change_state(&"ren_palm" if character_id == &"ren" else &"vel_pounce")
		return
	if relative_x < -0.5 and character_id == &"vel":
		change_state(&"vel_shadow")
		return
	change_state(&"ren_pulse" if character_id == &"ren" else &"vel_rake")


func _selected_heavy_state() -> StringName:
	if intent.axis.y > 0.5:
		return &"crouch_heavy"
	if intent.axis.x * float(facing) > 0.5:
		return &"forward_heavy"
	return &"heavy"


func _step_attack() -> void:
	state_frame += 1
	var data := current_attack()
	if bool(data.get("projectile", false)) and state_frame == int(data.get("projectile_frame", -1)):
		pending_projectile = true

	if _try_attack_cancel():
		return

	var movement_handled := true
	match state:
		&"ren_palm":
			velocity.x = facing * 440.0 if state_frame >= 4 and state_frame <= 12 else move_toward(velocity.x, 0.0, 85.0)
		&"ren_rise", &"vel_rise":
			velocity.x = move_toward(velocity.x, facing * 90.0, 10.0)
		&"ren_dive":
			velocity.x = facing * 310.0
			velocity.y = maxf(velocity.y, 520.0)
		&"ren_super":
			velocity.x = facing * 520.0 if state_frame >= 3 and state_frame <= 26 else move_toward(velocity.x, 0.0, 120.0)
		&"vel_rake":
			velocity.x = facing * 190.0 if state_frame >= 4 and state_frame <= 16 else move_toward(velocity.x, 0.0, 80.0)
		&"vel_pounce":
			velocity.x = move_toward(velocity.x, facing * 410.0, 14.0)
		&"vel_dive":
			velocity.x = facing * 350.0
			velocity.y = maxf(velocity.y, 600.0)
		&"vel_super":
			velocity.x = facing * 610.0 if state_frame >= 3 and state_frame <= 12 else move_toward(velocity.x, 0.0, 130.0)
		_:
			movement_handled = false

	if not movement_handled:
		if bool(data.get("airborne", false)):
			var air_target_speed: float = intent.axis.x * WALK_SPEED * 0.62
			velocity.x = move_toward(velocity.x, air_target_speed, 18.0)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 48.0)

	var total: int = data.startup + data.active + data.recovery
	if state_frame >= total:
		state = &"idle" if is_on_ground() else &"jump"
		state_frame = 0
		attack_connected = false
		attack_has_connected = false
		connected_hit_frames.clear()


func _try_attack_cancel() -> bool:
	if not attack_has_connected:
		return false
	if not bool(current_attack().get("super", false)) and _try_start_super():
		return true
	if state == &"light" or state == &"crouch_light":
		if _is_button_buffered("heavy"):
			_consume_button("heavy")
			change_state(_selected_heavy_state())
			return true
	if state == &"heavy" or state == &"forward_heavy" or state == &"crouch_heavy":
		if _is_button_buffered("special"):
			_consume_button("special")
			_start_character_special()
			return true
	return false


func _step_vel_shadow() -> void:
	state_frame += 1
	if state_frame <= 7:
		velocity.x = -facing * 330.0
	elif state_frame <= 10:
		velocity.x = move_toward(velocity.x, 0.0, 120.0)
	elif state_frame <= 21:
		velocity.x = facing * 455.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 120.0)

	if state_frame >= 10:
		if _try_start_super():
			return
		if _is_button_buffered("heavy"):
			_consume_button("heavy")
			change_state(_selected_heavy_state())
			return
		if _is_button_buffered("light"):
			_consume_button("light")
			change_state(&"light")
			return

	if state_frame >= 26:
		state = &"idle"
		state_frame = 0


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
			attack_has_connected = false
			connected_hit_frames.clear()
			air_attack_used = false
			velocity.x = move_toward(velocity.x, 0.0, 90.0)


func change_state(next_state: StringName) -> void:
	state = next_state
	state_frame = 0
	attack_connected = false
	attack_has_connected = false
	connected_hit_frames.clear()
	pending_projectile = false
	if next_state != &"throw":
		throw_backwards = false
	if is_attack_state(next_state) and not bool(ATTACKS[next_state].get("airborne", false)):
		velocity.x = 0.0
	match next_state:
		&"ren_rise":
			velocity = Vector2(facing * 130.0, -760.0)
		&"ren_dive":
			velocity = Vector2(facing * 310.0, 260.0)
		&"vel_pounce":
			velocity = Vector2(facing * 410.0, -590.0)
		&"vel_rise":
			velocity = Vector2(facing * 155.0, -750.0)
		&"vel_dive":
			velocity = Vector2(facing * 350.0, 300.0)
		&"vel_shadow":
			velocity.x = 0.0


func is_attack_active() -> bool:
	if not is_attacking():
		return false
	var data: Dictionary = ATTACKS[state]
	if bool(data.get("projectile", false)):
		return false
	var hit_frames: Array = data.get("hit_frames", [])
	if not hit_frames.is_empty():
		return hit_frames.has(state_frame) and not connected_hit_frames.has(state_frame)
	if attack_connected:
		return false
	return state_frame > int(data.startup) and state_frame <= int(data.startup + data.active)


func current_attack() -> Dictionary:
	if not is_attacking():
		return {}
	var data: Dictionary = ATTACKS[state]
	if state == &"throw" and throw_backwards:
		var back_throw := data.duplicate()
		back_throw.label = "BACK THROW"
		back_throw.push = 150.0
		back_throw.launch_y = -390.0
		back_throw.back_throw = true
		return back_throw
	if state == &"ren_super" and state_frame >= 25:
		var azure_finish := data.duplicate()
		azure_finish.damage = 126
		azure_finish.chip = 12
		azure_finish.hitstun = 34
		azure_finish.blockstun = 18
		azure_finish.push = 74.0
		azure_finish.hitstop = 15
		azure_finish.knockdown = true
		azure_finish.launch_y = -390.0
		azure_finish.label = "AZURE ZERO FINISH"
		return azure_finish
	if state == &"vel_rake" and state_frame >= 15:
		var rake_finish := data.duplicate()
		rake_finish.damage = 54
		rake_finish.hitstun = 21
		rake_finish.blockstun = 13
		rake_finish.push = 34.0
		rake_finish.hitstop = 10
		return rake_finish
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
	var crouching := state == &"crouch" or state == &"crouch_light" or state == &"crouch_heavy"
	var height := CROUCH_HEIGHT if crouching else BODY_HEIGHT
	if state == &"knockdown":
		height = 44.0
	return Rect2(position.x - BODY_WIDTH * 0.5, position.y - height, BODY_WIDTH, height)


func receive_attack(data: Dictionary, attacker_x: float, forced_push_direction := 0.0) -> Dictionary:
	var unblockable: bool = data.get("unblockable", false)
	var blocked := not unblockable and _is_blocking(attacker_x, data)
	var damage: int = int(data.chip) if blocked else int(data.damage)
	health = maxi(0, health - damage)
	state_frame = 0
	attack_connected = false
	attack_has_connected = false
	connected_hit_frames.clear()
	pending_projectile = false
	var push_direction := signf(position.x - attacker_x)
	if absf(forced_push_direction) > 0.1:
		push_direction = signf(forced_push_direction)
	velocity.x = push_direction * float(data.push) * (0.65 if blocked else 1.0)

	if blocked:
		block_stance_crouching = intent.axis.y > 0.5
		state = &"blockstun"
		last_hit_result = "BLOCK:%d" % int(data.blockstun)
	else:
		combo_received += 1
		var anti_air_knockdown := bool(data.get("anti_air", false)) and not is_on_ground()
		var causes_knockdown := health <= 0 or bool(data.get("knockdown", false)) or anti_air_knockdown
		state = &"knockdown" if causes_knockdown else &"hitstun"
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
	attack_has_connected = true
	var data := current_attack()
	var hit_frames: Array = data.get("hit_frames", [])
	if hit_frames.is_empty():
		attack_connected = true
	elif not connected_hit_frames.has(state_frame):
		connected_hit_frames.append(state_frame)


func take_projectile_request() -> Dictionary:
	if not pending_projectile:
		return {}
	pending_projectile = false
	return {
		"owner_id": player_id,
		"position": position + Vector2(facing * 58.0, -78.0),
		"velocity": Vector2(facing * 510.0, 0.0),
		"frames": 105,
		"radius": 18.0,
		"color": body_color,
		"attack": REN_PULSE_PROJECTILE.duplicate()
	}


func is_invulnerable() -> bool:
	if not is_attacking():
		return false
	return state_frame <= int(current_attack().get("invulnerable_until", -1))


func can_be_grabbed() -> bool:
	return is_on_ground() and state != &"hitstun" and state != &"blockstun" and state != &"knockdown"


static func is_attack_state(check_state: StringName) -> bool:
	return ATTACKS.has(check_state)


func is_attacking() -> bool:
	return is_attack_state(state)


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
	last_visual_meter = -1


func _queue_visual_redraw_if_needed() -> void:
	var animated_frame := state_frame if is_attacking() or state == &"vel_shadow" else 0
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
		or last_visual_meter != meter
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
	last_visual_meter = meter
	queue_redraw()


func is_on_ground() -> bool:
	return position.y >= GROUND_Y - 0.1


func is_air_attack() -> bool:
	return is_attacking() and bool(ATTACKS[state].get("airborne", false))


func _can_turn() -> bool:
	return state == &"idle" or state == &"walk" or state == &"crouch"


func _is_blocking(attacker_x: float, attack_data: Dictionary) -> bool:
	if not is_on_ground() or is_attacking() or state == &"hitstun" or state == &"knockdown":
		return false
	var holding_back: bool = true
	var crouch_blocking: bool = block_stance_crouching
	if state != &"blockstun":
		var attacker_is_left := attacker_x < position.x
		holding_back = intent.axis.x > 0.5 if attacker_is_left else intent.axis.x < -0.5
		crouch_blocking = intent.axis.y > 0.5
	if not holding_back:
		return false
	var block_type: StringName = attack_data.get("block_type", &"mid")
	if block_type == &"low":
		return crouch_blocking
	if block_type == &"overhead":
		return not crouch_blocking
	return true


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
	if is_attacking():
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

	var visual_offset := Vector2.ZERO
	var visual_rotation := 0.0
	var visual_scale := Vector2(float(facing), 1.0)
	var visual_modulate := Color.WHITE
	match state:
		&"crouch":
			visual_scale.y = 0.76
		&"crouch_light":
			visual_scale.y = 0.76
			visual_offset.x = 5.0 * facing
			visual_rotation = -0.025 * facing
		&"crouch_heavy":
			visual_scale.y = 0.76
			visual_offset.x = 9.0 * facing
			visual_rotation = -0.07 * facing
		&"jump":
			visual_rotation = -0.035 * facing
		&"light":
			visual_offset.x = 5.0 * facing
			visual_rotation = -0.025 * facing
		&"heavy", &"forward_heavy":
			visual_offset.x = 9.0 * facing
			visual_rotation = -0.07 * facing
		&"ren_pulse":
			visual_offset.x = -3.0 * facing
			visual_rotation = 0.035 * facing
		&"ren_palm":
			visual_offset.x = 13.0 * facing
			visual_rotation = -0.09 * facing
		&"ren_rise", &"vel_rise":
			visual_offset.x = 6.0 * facing
			visual_rotation = -0.16 * facing
		&"ren_dive", &"vel_dive":
			visual_offset.x = 10.0 * facing
			visual_rotation = 0.32 * facing
		&"ren_super":
			visual_offset.x = 15.0 * facing
			visual_rotation = -0.13 * facing
			visual_modulate = Color(0.75, 0.96, 1.0, 1.0)
		&"vel_rake":
			visual_offset.x = 12.0 * facing
			visual_rotation = -0.12 * facing
		&"vel_pounce":
			visual_offset.x = 9.0 * facing
			visual_rotation = -0.22 * facing
		&"vel_shadow":
			visual_offset.x = -5.0 * facing if state_frame <= 9 else 11.0 * facing
			visual_rotation = 0.08 * facing if state_frame <= 9 else -0.12 * facing
			visual_modulate = Color(0.82, 0.70, 0.92, 0.88)
		&"vel_super":
			visual_offset.x = 16.0 * facing
			visual_rotation = -0.16 * facing
			visual_modulate = Color(1.0, 0.66, 0.72, 1.0)
		&"throw":
			visual_offset.x = (-7.0 if throw_backwards else 8.0) * facing
			visual_rotation = (0.06 if throw_backwards else -0.05) * facing
		&"jump_light":
			visual_offset.x = 6.0 * facing
			visual_rotation = -0.11 * facing
		&"jump_heavy":
			visual_offset.x = 8.0 * facing
			visual_rotation = 0.13 * facing
		&"hitstun":
			visual_offset.x = -7.0 * facing
			visual_rotation = 0.1 * facing
			visual_modulate = Color(1.0, 0.62, 0.62, 1.0)
		&"blockstun":
			visual_offset.x = -5.0 * facing
			visual_rotation = 0.055 * facing
			visual_modulate = Color(0.76, 0.95, 1.0, 1.0)
		&"knockdown":
			visual_offset = Vector2(-42.0 * facing, -8.0)
			visual_rotation = -1.25 * facing
			visual_scale *= 0.86

	if meter >= MAX_METER:
		var aura_color := Color("74e8ff") if character_id == &"ren" else Color("ff557d")
		draw_arc(Vector2(0.0, -88.0), 62.0, -2.7, -0.35, 24, Color(aura_color, 0.42), 3.0, true)
		draw_arc(Vector2(0.0, -88.0), 69.0, 0.35, 2.7, 24, Color(aura_color, 0.28), 2.0, true)

	draw_set_transform(visual_offset, visual_rotation, visual_scale)
	if character_texture != null:
		draw_texture_rect(
			character_texture,
			Rect2(-VISUAL_SIZE * 0.5, -VISUAL_SIZE, VISUAL_SIZE, VISUAL_SIZE),
			false,
			visual_modulate
		)
	else:
		_draw_fallback_fighter()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	_draw_attack_effects()

	if state == &"blockstun":
		var guard_points := PackedVector2Array()
		for step in 13:
			var guard_t := float(step) / 12.0
			var guard_angle := lerpf(-1.25, 1.25, guard_t)
			guard_points.append(Vector2(cos(guard_angle) * 40.0 * facing, -68.0 + sin(guard_angle) * 40.0))
		draw_polyline(guard_points, Color("9bf6ff"), 5.0, true)

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


func _draw_fallback_fighter() -> void:
	var body_rect := Rect2(-25.0, -102.0, 50.0, 82.0)
	draw_rect(body_rect, body_color, true)
	draw_rect(body_rect, accent_color, false, 3.0)
	draw_circle(Vector2(0.0, -122.0), 22.0, body_color.lightened(0.18))
	draw_arc(Vector2(0.0, -122.0), 22.0, 0.0, TAU, 24, accent_color, 3.0)
	draw_line(Vector2(-12.0, -22.0), Vector2(-21.0, 0.0), accent_color, 10.0)
	draw_line(Vector2(12.0, -22.0), Vector2(21.0, 0.0), accent_color, 10.0)


func _draw_attack_effects() -> void:
	if not is_attacking():
		return

	var data := current_attack()
	var active := state_frame > int(data.startup) and state_frame <= int(data.startup + data.active)
	var effect_color := body_color.lightened(0.55)
	effect_color.a = 0.9 if active else 0.38
	var attack_progress := clampf(
		float(state_frame) / maxf(1.0, float(data.startup + data.active)),
		0.0,
		1.0
	)
	var effect: StringName = data.get("effect", &"arc")

	if effect == &"projectile_cast":
		var charge_center := Vector2(facing * 42.0, -80.0)
		var charge_radius := 7.0 + 14.0 * attack_progress
		draw_circle(charge_center, charge_radius, Color(effect_color, 0.18))
		draw_arc(charge_center, charge_radius, 0.0, TAU, 24, effect_color, 4.0, true)
		return

	if effect == &"energy":
		var energy_center := Vector2(facing * (46.0 + attack_progress * 26.0), -78.0)
		var energy_radius := 14.0 + 12.0 * attack_progress
		draw_circle(energy_center, energy_radius, Color(effect_color, 0.2 if active else 0.1))
		draw_arc(energy_center, energy_radius, 0.0, TAU, 24, effect_color, 5.0, true)
		draw_arc(energy_center, energy_radius + 9.0, -1.0, 1.8, 16, Color("fff3c4"), 2.0, true)
		return

	if effect == &"throw":
		var throw_direction := -facing if throw_backwards else facing
		var grab_center := Vector2(throw_direction * 47.0, -76.0)
		draw_arc(grab_center, 22.0 + attack_progress * 8.0, -1.0, 2.1, 18, effect_color, 4.0, true)
		return

	if effect == &"jab" or effect == &"air_jab":
		var strike_y := -82.0 if effect == &"jab" else -74.0
		var strike_start := Vector2(facing * 29.0, strike_y)
		var strike_end := Vector2(facing * (52.0 + attack_progress * 34.0), strike_y - 8.0)
		draw_line(strike_start, strike_end, effect_color, 5.0, true)
		draw_circle(strike_end, 5.5, effect_color)
		return

	if effect == &"low":
		var low_start := Vector2(facing * 18.0, -24.0)
		var low_end := Vector2(facing * (56.0 + attack_progress * 24.0), -10.0)
		draw_line(low_start, low_end, effect_color, 5.0, true)
		draw_circle(low_end, 5.0, effect_color)
		return

	if effect == &"rise" or effect == &"claw_rise":
		var rise_points := PackedVector2Array()
		for step in 14:
			var rise_t := float(step) / 13.0
			rise_points.append(Vector2(facing * (24.0 + 48.0 * sin(rise_t * PI)), -18.0 - rise_t * 132.0))
		var rise_color := Color("ff6d93") if effect == &"claw_rise" else effect_color
		draw_polyline(rise_points, rise_color, 6.0, true)
		return

	if effect == &"dive" or effect == &"claw_dive":
		var dive_color := Color("ff5f89") if effect == &"claw_dive" else effect_color
		for trail in 3:
			var trail_offset := Vector2(-facing * float(trail) * 8.0, -float(trail) * 8.0)
			draw_line(Vector2(-facing * 18.0, -112.0) + trail_offset, Vector2(facing * 62.0, -20.0) + trail_offset, Color(dive_color, 0.78 - trail * 0.18), 5.0, true)
		return

	if effect == &"claw" or effect == &"pounce":
		var claw_color := Color("ff5b85")
		for slash in 3:
			var slash_y := -96.0 + slash * 25.0
			draw_line(Vector2(facing * 28.0, slash_y - 18.0), Vector2(facing * (82.0 + slash * 7.0), slash_y + 12.0), Color(claw_color, 0.86 - slash * 0.12), 5.0, true)
		return

	if effect == &"super_blue" or effect == &"super_red":
		var super_color := Color("75ebff") if effect == &"super_blue" else Color("ff416f")
		var super_reach := 74.0 + 50.0 * attack_progress
		for streak in 4:
			var streak_y := -112.0 + streak * 28.0
			draw_line(Vector2(-facing * 18.0, streak_y), Vector2(facing * super_reach, streak_y - 18.0), Color(super_color, 0.88 - streak * 0.13), 7.0 - streak, true)
		draw_arc(Vector2(facing * 52.0, -72.0), 42.0, -1.2, 1.3, 20, Color("fff3c4"), 4.0, true)
		return

	var arc_points := PackedVector2Array()
	var arc_center_y := -50.0 if effect == &"air_arc" else -62.0
	var arc_radius := 86.0 if effect == &"overhead" else (82.0 if effect == &"air_arc" else 74.0)
	for step in 14:
		var arc_t := float(step) / 13.0
		var arc_angle := lerpf(-1.15, 0.48, arc_t)
		arc_points.append(Vector2(cos(arc_angle) * arc_radius * facing, arc_center_y + sin(arc_angle) * arc_radius))
	draw_polyline(arc_points, effect_color, 6.0, true)
