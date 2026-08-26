class_name Fighter
extends Node2D

const GROUND_Y := 558.0
const ARENA_WIDTH := 2016.0
const ARENA_LEFT := 76.0
const ARENA_RIGHT := ARENA_WIDTH - 76.0
const GRAVITY := 2350.0
const WALK_SPEED := 275.0
const JUMP_SPEED := -850.0
const BASE_VISUAL_SIZE := 176.0
const VISUAL_SIZE := 288.0
const VISUAL_COLLISION_SCALE := VISUAL_SIZE / BASE_VISUAL_SIZE
const BODY_WIDTH := 58.0 * VISUAL_COLLISION_SCALE
const HURTBOX_WIDTH := VISUAL_SIZE * 0.48
const HURTBOX_HEIGHT := VISUAL_SIZE * 0.885
const CROUCH_HURTBOX_WIDTH := VISUAL_SIZE * 0.52
const CROUCH_HURTBOX_HEIGHT := VISUAL_SIZE * 0.64
const SPRITE_SHEET_CELL_SIZE := 256.0
const SPRITE_DRAW_OFFSET_Y := 8.0
const REN_ANIMATION_BASIC := 0
const REN_ANIMATION_GROUND := 1
const REN_ANIMATION_AIR_SPECIAL := 2
const REN_ANIMATION_SPECIAL := 3
const REN_ANIMATION_REACTION := 4
const MAX_METER := 100
const INPUT_BUFFER_FRAMES := 7
const SUPER_CHORD_BUFFER_FRAMES := 5
const AMBIENT_MOTION_SAMPLE_FRAMES := 2
const KEYBOARD_LIGHT_KEY := KEY_J
const KEYBOARD_HEAVY_KEY := KEY_K
const KEYBOARD_SPECIAL_KEY := KEY_L
const KEYBOARD_THROW_KEY := KEY_I

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
var character_animation_textures: Array[Texture2D] = []
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
var super_chord_buffer := {
	"light": 0,
	"heavy": 0
}
var input_history: Array[Vector2] = []
var debug_boxes := false
var combo_received := 0
var last_hit_result := ""
var block_stance_crouching := false
var throw_backwards := false
var air_attack_used := false
var motion_tick := 0
var landing_frames := 0
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
	texture: Texture2D = null,
	animation_sources: Variant = null
) -> void:
	player_id = id
	configure_character(
		StringName(display_name.to_lower()),
		display_name,
		color,
		texture,
		animation_sources
	)
	position = spawn_position
	facing = 1 if player_id == 0 else -1
	reset_for_round(spawn_position)


func configure_character(
	selected_character_id: StringName,
	display_name: String,
	color: Color,
	texture: Texture2D,
	animation_sources: Variant = null
) -> void:
	character_id = selected_character_id
	fighter_name = display_name
	body_color = color
	accent_color = color.lightened(0.55)
	character_texture = texture
	character_animation_textures.clear()
	if animation_sources is Texture2D:
		character_animation_textures.append(animation_sources as Texture2D)
	elif animation_sources is Array:
		for animation_texture in animation_sources:
			if animation_texture is Texture2D:
				character_animation_textures.append(animation_texture as Texture2D)
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
	motion_tick = 0
	landing_frames = 0
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
	for button_name in super_chord_buffer:
		super_chord_buffer[button_name] = 0
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
		buttons.light = Input.is_physical_key_pressed(KEYBOARD_LIGHT_KEY)
		buttons.heavy = Input.is_physical_key_pressed(KEYBOARD_HEAVY_KEY)
		buttons.special = Input.is_physical_key_pressed(KEYBOARD_SPECIAL_KEY)
		buttons.throw = Input.is_physical_key_pressed(KEYBOARD_THROW_KEY)

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
	for button_name in super_chord_buffer:
		super_chord_buffer[button_name] = 0


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
			if super_chord_buffer.has(button_name):
				super_chord_buffer[button_name] = SUPER_CHORD_BUFFER_FRAMES
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


func _is_super_chord_button_buffered(button_name: String) -> bool:
	return int(super_chord_buffer.get(button_name, 0)) > 0


func _consume_super_chord() -> void:
	for button_name in super_chord_buffer:
		super_chord_buffer[button_name] = 0


func _tick_input_buffer() -> void:
	for button_name in button_buffer:
		button_buffer[button_name] = maxi(0, int(button_buffer[button_name]) - 1)
	for button_name in super_chord_buffer:
		super_chord_buffer[button_name] = maxi(0, int(super_chord_buffer[button_name]) - 1)


func simulate(opponent: Fighter, accepting_input: bool) -> void:
	motion_tick = (motion_tick + 1) % 3600
	landing_frames = maxi(0, landing_frames - 1)
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
	if not _is_super_chord_button_buffered("light") or not _is_super_chord_button_buffered("heavy"):
		return false
	if meter < MAX_METER:
		return false
	_consume_button("light")
	_consume_button("heavy")
	_consume_super_chord()
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
		if _can_correct_normal_to_super() and _try_start_super():
			return true
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


func _can_correct_normal_to_super() -> bool:
	if state_frame >= SUPER_CHORD_BUFFER_FRAMES:
		return false
	return state in [&"light", &"crouch_light", &"heavy", &"forward_heavy", &"crouch_heavy"]


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
	var was_airborne := position.y < GROUND_Y - 0.1 or velocity.y < 0.0
	if not is_on_ground() or velocity.y < 0.0:
		velocity.y += GRAVITY / 60.0
	position += velocity / 60.0
	position.x = clampf(position.x, ARENA_LEFT + BODY_WIDTH * 0.5, ARENA_RIGHT - BODY_WIDTH * 0.5)
	if position.y >= GROUND_Y:
		if was_airborne and velocity.y > 0.0:
			landing_frames = 8
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
	var attack_range: float = float(data.range) * VISUAL_COLLISION_SCALE
	var attack_height: float = float(data.height) * VISUAL_COLLISION_SCALE
	var x := position.x + BODY_WIDTH * 0.32 if facing > 0 else position.x - BODY_WIDTH * 0.32 - attack_range
	var bottom_offset: float = float(data.get("bottom_offset", 22.0)) * VISUAL_COLLISION_SCALE
	var y := position.y - attack_height - bottom_offset
	return Rect2(x, y, attack_range, attack_height)


func hurt_rect() -> Rect2:
	var crouching := state == &"crouch" or state == &"crouch_light" or state == &"crouch_heavy"
	var height := CROUCH_HURTBOX_HEIGHT if crouching else HURTBOX_HEIGHT
	var width := CROUCH_HURTBOX_WIDTH if crouching else HURTBOX_WIDTH
	var center_x := position.x
	if state == &"knockdown":
		var fall_progress := 1.0
		if state_frame <= 14:
			fall_progress = clampf(float(state_frame) / 14.0, 0.0, 1.0)
		elif state_frame > 35:
			fall_progress = 1.0 - clampf(float(state_frame - 35) / 13.0, 0.0, 1.0)
		width = lerpf(HURTBOX_WIDTH, HURTBOX_HEIGHT, fall_progress)
		height = lerpf(HURTBOX_HEIGHT, HURTBOX_WIDTH, fall_progress)
		center_x -= float(facing) * 42.0 * fall_progress
	return Rect2(center_x - width * 0.5, position.y - height, width, height)


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
	var uses_gameplay_frames := (
		is_attacking()
		or state == &"vel_shadow"
		or state == &"hitstun"
		or state == &"blockstun"
		or state == &"knockdown"
	)
	var ambient_frame := floori(float(motion_tick) / float(AMBIENT_MOTION_SAMPLE_FRAMES))
	var animated_frame := state_frame if uses_gameplay_frames else ambient_frame
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


func _smooth_motion(value: float) -> float:
	var clamped := clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


func _attack_motion_factors() -> Dictionary:
	var data: Dictionary = ATTACKS[state]
	var startup := maxf(1.0, float(data.startup))
	var active := maxf(1.0, float(data.active))
	var recovery := maxf(1.0, float(data.recovery))
	var frame := float(state_frame)
	var active_end := startup + active
	var windup := 0.0
	var extension := 0.0
	var active_progress := 0.0
	var recovery_progress := 0.0

	if frame <= startup:
		windup = _smooth_motion(frame / startup)
	elif frame <= active_end:
		extension = 1.0
		active_progress = clampf((frame - startup) / active, 0.0, 1.0)
	else:
		recovery_progress = clampf((frame - active_end) / recovery, 0.0, 1.0)
		extension = 1.0 - _smooth_motion(recovery_progress)

	return {
		"windup": windup,
		"extension": extension,
		"active": active_progress,
		"recovery": recovery_progress
	}


func _basic_attack_sprite_frame() -> int:
	var data: Dictionary = ATTACKS[state]
	var startup := int(data.startup)
	var active_end := startup + int(data.active)
	var recovery := maxi(1, int(data.recovery))
	if state_frame <= 0:
		return 0
	if state_frame <= startup:
		return 1
	if state_frame <= active_end:
		return 2
	var recovery_progress := float(state_frame - active_end) / float(recovery)
	return 3 if recovery_progress < 0.55 else 4


func _animation_frame(sheet_index: int, column: int, row: int) -> Vector3i:
	if sheet_index < 0 or sheet_index >= character_animation_textures.size():
		return Vector3i(-1, -1, -1)
	return Vector3i(sheet_index, column, row)


func _stun_sprite_frame(default_duration: int, result_prefix: String) -> int:
	var duration := default_duration
	if last_hit_result.begins_with(result_prefix):
		duration = int(last_hit_result.get_slice(":", 1))
	var progress := float(state_frame) / float(maxi(1, duration))
	return clampi(floori(progress * 5.0), 0, 4)


func _knockdown_sprite_frame() -> int:
	if state_frame <= 5:
		return 0
	if state_frame <= 14:
		return 1
	if state_frame <= 35:
		return 2
	if state_frame <= 42:
		return 3
	return 4


func _ren_super_sprite_frame() -> int:
	var frame_thresholds := [0, 3, 6, 8, 12, 16, 20, 23, 26, 31, 35, 39, 43, 47]
	for sprite_frame in frame_thresholds.size():
		if state_frame <= int(frame_thresholds[sprite_frame]):
			return sprite_frame
	return 14


func _animated_sprite_frame() -> Vector3i:
	if character_animation_textures.is_empty():
		return Vector3i(-1, -1, -1)

	match state:
		&"idle":
			if landing_frames > 0:
				var landing_frame := clampi(
					floori(float(8 - landing_frames) * 5.0 / 8.0),
					0,
					4
				)
				return _animation_frame(REN_ANIMATION_REACTION, landing_frame, 4)
			return _animation_frame(
				REN_ANIMATION_BASIC,
				floori(float(motion_tick) / 10.0) % 5,
				0
			)
		&"walk":
			var walk_frame := floori(float(motion_tick) / 5.0) % 5
			if velocity.x * float(facing) < 0.0:
				walk_frame = 4 - walk_frame
			return _animation_frame(REN_ANIMATION_BASIC, walk_frame, 1)
		&"jump":
			if velocity.y < -700.0:
				return _animation_frame(REN_ANIMATION_BASIC, 0, 2)
			if velocity.y < -430.0:
				return _animation_frame(REN_ANIMATION_BASIC, 1, 2)
			if velocity.y < -100.0:
				return _animation_frame(REN_ANIMATION_BASIC, 2, 2)
			if velocity.y < 190.0:
				return _animation_frame(REN_ANIMATION_BASIC, 3, 2)
			return _animation_frame(REN_ANIMATION_BASIC, 4, 2)
		&"light":
			return _animation_frame(REN_ANIMATION_BASIC, _basic_attack_sprite_frame(), 3)
		&"heavy":
			return _animation_frame(REN_ANIMATION_BASIC, _basic_attack_sprite_frame(), 4)
		&"crouch":
			return _animation_frame(
				REN_ANIMATION_GROUND,
				floori(float(motion_tick) / 10.0) % 5,
				0
			)
		&"crouch_light":
			return _animation_frame(REN_ANIMATION_GROUND, _basic_attack_sprite_frame(), 1)
		&"forward_heavy":
			return _animation_frame(REN_ANIMATION_GROUND, _basic_attack_sprite_frame(), 2)
		&"crouch_heavy":
			return _animation_frame(REN_ANIMATION_GROUND, _basic_attack_sprite_frame(), 3)
		&"throw":
			if throw_backwards:
				return _animation_frame(
					REN_ANIMATION_AIR_SPECIAL,
					_basic_attack_sprite_frame(),
					0
				)
			return _animation_frame(REN_ANIMATION_GROUND, _basic_attack_sprite_frame(), 4)
		&"jump_light":
			return _animation_frame(REN_ANIMATION_AIR_SPECIAL, _basic_attack_sprite_frame(), 1)
		&"jump_heavy":
			return _animation_frame(REN_ANIMATION_AIR_SPECIAL, _basic_attack_sprite_frame(), 2)
		&"ren_pulse":
			return _animation_frame(REN_ANIMATION_AIR_SPECIAL, _basic_attack_sprite_frame(), 3)
		&"ren_palm":
			return _animation_frame(REN_ANIMATION_AIR_SPECIAL, _basic_attack_sprite_frame(), 4)
		&"ren_rise":
			return _animation_frame(REN_ANIMATION_SPECIAL, _basic_attack_sprite_frame(), 0)
		&"ren_dive":
			return _animation_frame(REN_ANIMATION_SPECIAL, _basic_attack_sprite_frame(), 1)
		&"ren_super":
			var super_frame := _ren_super_sprite_frame()
			return _animation_frame(
				REN_ANIMATION_SPECIAL,
				super_frame % 5,
				2 + floori(float(super_frame) / 5.0)
			)
		&"hitstun":
			return _animation_frame(
				REN_ANIMATION_REACTION,
				_stun_sprite_frame(16, "HIT:"),
				0
			)
		&"blockstun":
			return _animation_frame(
				REN_ANIMATION_REACTION,
				_stun_sprite_frame(10, "BLOCK:"),
				2 if block_stance_crouching else 1
			)
		&"knockdown":
			return _animation_frame(
				REN_ANIMATION_REACTION,
				_knockdown_sprite_frame(),
				3
			)
		_:
			return Vector3i(-1, -1, -1)


func _has_character_image() -> bool:
	return _animated_sprite_frame().x >= 0 or character_texture != null


func _draw_character_image(modulate: Color) -> bool:
	var sprite_frame := _animated_sprite_frame()
	if sprite_frame.x >= 0:
		var source_position := Vector2(
			float(sprite_frame.y) * SPRITE_SHEET_CELL_SIZE,
			float(sprite_frame.z) * SPRITE_SHEET_CELL_SIZE
		)
		draw_texture_rect_region(
			character_animation_textures[sprite_frame.x],
			Rect2(
				-VISUAL_SIZE * 0.5,
				-VISUAL_SIZE + SPRITE_DRAW_OFFSET_Y,
				VISUAL_SIZE,
				VISUAL_SIZE
			),
			Rect2(source_position, Vector2.ONE * SPRITE_SHEET_CELL_SIZE),
			modulate
		)
		return true
	if character_texture != null:
		draw_texture_rect(
			character_texture,
			Rect2(-VISUAL_SIZE * 0.5, -VISUAL_SIZE, VISUAL_SIZE, VISUAL_SIZE),
			false,
			modulate
		)
		return true
	return false


func _visual_pose() -> Dictionary:
	var visual_offset := Vector2.ZERO
	var visual_rotation := 0.0
	var visual_scale := Vector2(float(facing), 1.0)
	var visual_modulate := Color.WHITE
	var breath := sin(float(motion_tick) * 0.055 + float(player_id) * 0.7)

	if is_attacking():
		var motion := _attack_motion_factors()
		var windup: float = motion.windup
		var extension: float = motion.extension
		var active_progress: float = motion.active
		var rapid := sin(float(state_frame) * 1.55)
		match state:
			&"light":
				visual_offset = Vector2(facing * (-4.0 * windup + 15.0 * extension), -2.0 * extension)
				visual_rotation = facing * (0.055 * windup - 0.105 * extension)
				visual_scale *= Vector2(1.0 + 0.055 * extension, 1.0 - 0.035 * extension)
			&"crouch_light":
				visual_offset = Vector2(facing * (-2.0 * windup + 13.0 * extension), 3.0)
				visual_rotation = facing * (0.035 * windup - 0.09 * extension)
				visual_scale *= Vector2(1.06 + 0.04 * extension, 0.76 - 0.025 * extension)
			&"heavy":
				visual_offset = Vector2(facing * (-10.0 * windup + 21.0 * extension), 3.0 * windup - 5.0 * extension)
				visual_rotation = facing * (0.12 * windup - 0.205 * extension)
				visual_scale *= Vector2(1.0 + 0.09 * extension, 1.0 - 0.055 * extension)
			&"forward_heavy":
				visual_offset = Vector2(facing * (-13.0 * windup + 24.0 * extension), -8.0 * windup + 4.0 * extension)
				visual_rotation = facing * (0.16 * windup - 0.255 * extension)
				visual_scale *= Vector2(1.0 + 0.11 * extension, 1.0 - 0.07 * extension)
			&"crouch_heavy":
				visual_offset = Vector2(facing * (-5.0 * windup + 15.0 * extension), 4.0 * windup - 14.0 * extension)
				visual_rotation = facing * (0.09 * windup - 0.18 * extension)
				visual_scale *= Vector2(1.07 - 0.03 * extension, 0.76 + 0.33 * extension)
			&"throw":
				var grab_direction := -1.0 if throw_backwards else 1.0
				visual_offset = Vector2(facing * grab_direction * (-5.0 * windup + 18.0 * extension), -3.0 * extension)
				visual_rotation = facing * grab_direction * (0.08 * windup - 0.17 * extension)
				visual_scale *= Vector2(1.0 + 0.08 * extension, 1.0 - 0.04 * extension)
			&"jump_light":
				visual_offset = Vector2(facing * (-3.0 * windup + 16.0 * extension), -3.0 * extension)
				visual_rotation = facing * (0.08 * windup - 0.19 * extension)
				visual_scale *= Vector2(1.0 + 0.07 * extension, 1.0 - 0.05 * extension)
			&"jump_heavy":
				visual_offset = Vector2(facing * (-6.0 * windup + 18.0 * extension), 4.0 * extension)
				visual_rotation = facing * (-0.1 * windup + 0.38 * extension)
				visual_scale *= Vector2(1.08 + 0.03 * extension, 0.94 - 0.05 * extension)
			&"ren_pulse":
				visual_offset = Vector2(facing * (-9.0 * windup + 7.0 * extension), 2.0 * windup)
				visual_rotation = facing * (0.09 * windup - 0.065 * extension)
				visual_scale *= Vector2(1.0 - 0.045 * windup + 0.055 * extension, 1.0 - 0.06 * windup)
				visual_modulate = Color(0.82, 0.97, 1.0, 1.0)
			&"ren_palm":
				visual_offset = Vector2(facing * (-12.0 * windup + 25.0 * extension), 4.0 * windup - 4.0 * extension)
				visual_rotation = facing * (0.13 * windup - 0.24 * extension)
				visual_scale *= Vector2(1.0 + 0.14 * extension, 1.0 - 0.09 * extension)
				visual_modulate = Color(0.86, 0.98, 1.0, 1.0)
			&"ren_rise":
				visual_offset = Vector2(facing * (-5.0 * windup + 11.0 * extension), 5.0 * windup - 17.0 * extension)
				visual_rotation = facing * (0.11 * windup - 0.29 * extension)
				visual_scale *= Vector2(1.05 - 0.08 * extension, 0.92 + 0.22 * extension)
				visual_modulate = Color(0.8, 0.97, 1.0, 1.0)
			&"ren_dive":
				visual_offset = Vector2(facing * (-5.0 * windup + 20.0 * extension), -4.0 * windup + 8.0 * extension)
				visual_rotation = facing * (0.1 * windup + 0.43 * extension)
				visual_scale *= Vector2(1.0 + 0.12 * extension, 1.0 - 0.12 * extension)
				visual_modulate = Color(0.82, 0.96, 1.0, 1.0)
			&"ren_super":
				var combo_sway := rapid * extension * (0.35 + active_progress)
				visual_offset = Vector2(facing * (-15.0 * windup + 28.0 * extension + combo_sway * 6.0), -5.0 * extension + absf(combo_sway) * 3.0)
				visual_rotation = facing * (0.18 * windup - 0.24 * extension + combo_sway * 0.08)
				visual_scale *= Vector2(1.0 + 0.16 * extension, 1.0 - 0.1 * extension)
				visual_modulate = Color(0.72, 0.95, 1.0, 1.0)
			&"vel_rake":
				var claw_sway := rapid * extension
				visual_offset = Vector2(facing * (-8.0 * windup + 20.0 * extension + claw_sway * 4.0), -2.0 * extension + claw_sway * 2.0)
				visual_rotation = facing * (0.13 * windup - 0.19 * extension + claw_sway * 0.1)
				visual_scale *= Vector2(1.0 + 0.11 * extension, 1.0 - 0.07 * extension)
				visual_modulate = Color(1.0, 0.8, 0.84, 1.0)
			&"vel_pounce":
				visual_offset = Vector2(facing * (-14.0 * windup + 25.0 * extension), 9.0 * windup - 8.0 * extension)
				visual_rotation = facing * (0.17 * windup - 0.34 * extension)
				visual_scale *= Vector2(1.08 + 0.12 * extension, 0.86 + 0.04 * extension)
				visual_modulate = Color(1.0, 0.84, 0.87, 1.0)
			&"vel_rise":
				visual_offset = Vector2(facing * (-7.0 * windup + 14.0 * extension), 7.0 * windup - 19.0 * extension)
				visual_rotation = facing * (0.15 * windup - 0.39 * extension)
				visual_scale *= Vector2(1.08 - 0.09 * extension, 0.9 + 0.25 * extension)
				visual_modulate = Color(1.0, 0.78, 0.83, 1.0)
			&"vel_dive":
				visual_offset = Vector2(facing * (-7.0 * windup + 23.0 * extension), -4.0 * windup + 9.0 * extension)
				visual_rotation = facing * (0.14 * windup + 0.52 * extension)
				visual_scale *= Vector2(1.0 + 0.16 * extension, 1.0 - 0.15 * extension)
				visual_modulate = Color(1.0, 0.76, 0.82, 1.0)
			&"vel_super":
				visual_offset = Vector2(facing * (-18.0 * windup + 34.0 * extension), 8.0 * windup - 7.0 * extension)
				visual_rotation = facing * (0.21 * windup - 0.38 * extension + rapid * extension * 0.045)
				visual_scale *= Vector2(1.0 + 0.2 * extension, 1.0 - 0.13 * extension)
				visual_modulate = Color(1.0, 0.62, 0.7, 1.0)
	else:
		match state:
			&"idle":
				visual_offset.y = breath * 1.8
				visual_rotation = facing * sin(float(motion_tick) * 0.031) * 0.009
				visual_scale *= Vector2(1.0 - breath * 0.008, 1.0 + breath * 0.012)
			&"walk":
				var step_cycle := sin(float(motion_tick) * 0.39)
				var forward_motion := signf(velocity.x) * float(facing)
				visual_offset = Vector2(facing * step_cycle * 1.8, -absf(step_cycle) * 4.5)
				visual_rotation = facing * (-0.035 * forward_motion + step_cycle * 0.018)
				visual_scale *= Vector2(1.0 + absf(step_cycle) * 0.018, 1.0 - absf(step_cycle) * 0.025)
			&"crouch":
				visual_offset = Vector2(0.0, 3.0 + breath * 0.7)
				visual_rotation = facing * breath * 0.006
				visual_scale *= Vector2(1.06 - breath * 0.006, 0.76 + breath * 0.008)
			&"jump":
				var vertical_speed := clampf(velocity.y / JUMP_SPEED, -1.0, 1.0)
				var apex_tuck := 1.0 - clampf(absf(velocity.y) / absf(JUMP_SPEED), 0.0, 1.0)
				visual_offset = Vector2(facing * vertical_speed * 2.0, -apex_tuck * 5.0)
				visual_rotation = facing * (-0.075 - vertical_speed * 0.055)
				visual_scale *= Vector2(0.96 + apex_tuck * 0.08, 1.07 - apex_tuck * 0.13)
			&"vel_shadow":
				if state_frame <= 7:
					var retreat_t := _smooth_motion(float(state_frame) / 7.0)
					visual_offset = Vector2(-facing * (4.0 + retreat_t * 10.0), -retreat_t * 3.0)
					visual_rotation = facing * (0.05 + retreat_t * 0.13)
					visual_scale *= Vector2(1.0 + retreat_t * 0.08, 1.0 - retreat_t * 0.07)
				elif state_frame <= 10:
					visual_offset = Vector2(-facing * 5.0, 5.0)
					visual_rotation = facing * 0.08
					visual_scale *= Vector2(1.09, 0.87)
				else:
					var dash_t := _smooth_motion(float(state_frame - 10) / 16.0)
					visual_offset = Vector2(facing * (10.0 + dash_t * 11.0), -5.0)
					visual_rotation = -facing * (0.14 + dash_t * 0.06)
					visual_scale *= Vector2(1.13, 0.9)
				visual_modulate = Color(0.82, 0.68, 0.94, 0.88)
			&"hitstun":
				var hit_decay := 1.0 - clampf(float(state_frame) / 32.0, 0.0, 1.0)
				var hit_shake := sin(float(state_frame) * 2.45) * hit_decay
				visual_offset = Vector2(-facing * (9.0 + absf(hit_shake) * 4.0), hit_shake * 3.0)
				visual_rotation = facing * (0.13 + hit_shake * 0.035)
				visual_scale *= Vector2(0.95, 1.04)
				visual_modulate = Color(1.0, 0.58, 0.58, 1.0)
			&"blockstun":
				var guard_shake := sin(float(state_frame) * 2.1) * (1.0 - clampf(float(state_frame) / 24.0, 0.0, 1.0))
				visual_offset = Vector2(-facing * (6.0 + absf(guard_shake) * 2.5), guard_shake * 1.5)
				visual_rotation = facing * (0.07 + guard_shake * 0.018)
				visual_scale *= Vector2(1.04, 0.78 if block_stance_crouching else 0.96)
				visual_modulate = Color(0.72, 0.94, 1.0, 1.0)
			&"knockdown":
				if state_frame <= 14:
					var fall_t := _smooth_motion(float(state_frame) / 14.0)
					visual_offset = Vector2(-facing * 42.0 * fall_t, -8.0 * fall_t)
					visual_rotation = -facing * 1.25 * fall_t
					visual_scale *= Vector2(1.0 - fall_t * 0.14, 1.0 - fall_t * 0.1)
				elif state_frame <= 35:
					visual_offset = Vector2(-42.0 * facing, -8.0 + sin(float(state_frame) * 0.65) * 1.2)
					visual_rotation = -1.25 * facing
					visual_scale *= 0.86
				else:
					var rise_t := _smooth_motion(float(state_frame - 35) / 13.0)
					visual_offset = Vector2(-42.0 * facing * (1.0 - rise_t), -8.0 * (1.0 - rise_t))
					visual_rotation = -1.25 * facing * (1.0 - rise_t)
					visual_scale *= Vector2(0.86 + rise_t * 0.14, 0.86 + rise_t * 0.14)

	if landing_frames > 0 and (state == &"idle" or state == &"walk" or state == &"crouch"):
		var landing_strength := float(landing_frames) / 8.0
		visual_offset.y += landing_strength * 4.0
		visual_scale *= Vector2(1.0 + landing_strength * 0.09, 1.0 - landing_strength * 0.11)

	return {
		"offset": visual_offset,
		"rotation": visual_rotation,
		"scale": visual_scale,
		"modulate": visual_modulate
	}


func _uniform_character_draw_scale(suggested_scale: Vector2) -> Vector2:
	# Motion poses may suggest squash and stretch, but changing that scale makes
	# the fighter appear to grow or shrink between actions. Keep only the facing
	# direction and render every frame at the canonical character magnification.
	var horizontal_direction := -1.0 if suggested_scale.x < 0.0 else 1.0
	return Vector2(horizontal_direction, 1.0)


func _draw_motion_accents() -> void:
	if landing_frames > 0:
		var landing_strength := float(landing_frames) / 8.0
		var dust_color := Color(Color("d8c79d"), landing_strength * 0.42)
		for side in [-1.0, 1.0]:
			var dust_center := Vector2(side * (21.0 + 13.0 * (1.0 - landing_strength)), -3.0)
			draw_arc(dust_center, 7.0 + 8.0 * (1.0 - landing_strength), PI, TAU, 12, dust_color, 3.0, true)

	if state == &"walk":
		var step_cycle := sin(float(motion_tick) * 0.39)
		var footfall := clampf((absf(step_cycle) - 0.78) / 0.22, 0.0, 1.0)
		if footfall > 0.0:
			var foot_x := -18.0 if step_cycle > 0.0 else 18.0
			var walk_dust := Color(Color("c8b98f"), footfall * 0.2)
			draw_circle(Vector2(foot_x, -2.0), 3.0 + footfall * 3.0, walk_dust)

	if state == &"hitstun" and state_frame <= 8:
		var impact_alpha := 0.32 * (1.0 - float(state_frame) / 9.0)
		for mark in 3:
			var mark_y := -104.0 + float(mark) * 30.0
			draw_line(
				Vector2(facing * 15.0, mark_y),
				Vector2(facing * 34.0, mark_y - 7.0),
				Color(Color("fff0bd"), impact_alpha),
				3.0,
				true
			)


func _draw_motion_echoes(
	visual_offset: Vector2,
	visual_rotation: float,
	visual_scale: Vector2
) -> void:
	if not _has_character_image():
		return

	var echo_alpha := 0.0
	var echo_count := 2
	match state:
		&"heavy", &"forward_heavy", &"jump_heavy":
			echo_alpha = 0.075
		&"ren_palm", &"ren_rise", &"ren_dive":
			echo_alpha = 0.13
		&"vel_rake", &"vel_pounce", &"vel_rise", &"vel_dive":
			echo_alpha = 0.14
		&"vel_shadow":
			echo_alpha = 0.17
		&"ren_super", &"vel_super":
			echo_alpha = 0.2
			echo_count = 3
		_:
			return

	if is_attacking():
		var data: Dictionary = ATTACKS[state]
		var startup := maxf(1.0, float(data.startup))
		var visible_strength := clampf(float(state_frame) / startup, 0.2, 1.0)
		echo_alpha *= visible_strength

	var trail_direction := Vector2(-float(facing), 0.0)
	if velocity.length() > 90.0:
		trail_direction = -velocity.normalized()
	if state == &"vel_shadow" and state_frame <= 10:
		trail_direction = Vector2(float(facing), 0.0)

	var echo_color := body_color.lightened(0.32)
	for echo_index in range(echo_count, 0, -1):
		var distance := 11.0 * float(echo_index)
		var echo_offset := visual_offset + trail_direction * distance
		var alpha := echo_alpha * (1.0 - float(echo_index - 1) / float(echo_count + 1))
		draw_set_transform(echo_offset, visual_rotation, visual_scale)
		_draw_character_image(Color(echo_color, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	# The shadow stays on the arena floor while the fighter jumps.
	var shadow_y := GROUND_Y - position.y - 2.0
	var shadow_scale := clampf(1.0 - absf(GROUND_Y - position.y) / 420.0, 0.48, 1.0)
	draw_set_transform(Vector2(0, shadow_y), 0.0, Vector2(1.45 * shadow_scale, 0.30 * shadow_scale))
	draw_circle(Vector2.ZERO, 30.0 * VISUAL_COLLISION_SCALE, Color(0.0, 0.0, 0.0, 0.28))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	_draw_motion_accents()
	var pose := _visual_pose()
	var visual_offset: Vector2 = pose.offset
	var visual_rotation: float = pose.rotation
	var visual_scale: Vector2 = pose.scale
	var visual_modulate: Color = pose.modulate
	if _animated_sprite_frame().x >= 0:
		visual_offset *= 0.25
		visual_rotation *= 0.2
	visual_scale = _uniform_character_draw_scale(visual_scale)

	_draw_motion_echoes(visual_offset, visual_rotation, visual_scale)
	draw_set_transform(visual_offset, visual_rotation, visual_scale)
	if not _draw_character_image(visual_modulate):
		_draw_fallback_fighter()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

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
