class_name Fighter
extends Node2D

const SpriteAlphaBoundsData := preload("res://scripts/sprite_alpha_bounds.gd")

const GROUND_Y := 558.0
const ARENA_WIDTH := 2016.0
const ARENA_LEFT := 76.0
const ARENA_RIGHT := ARENA_WIDTH - 76.0
const GRAVITY := 2350.0
const WALK_SPEED := 275.0
const FORWARD_WALK_SPEED := 320.0
const AIR_MOVE_SPEED := 470.0
const AIR_ATTACK_MOVE_SPEED := 420.0
const AIR_ATTACK_CONTROL_ACCELERATION := 78.0
const AIR_ATTACK_DRAG := 10.0
# Tuned against the closest battle-camera zoom so the neutral jump pose reaches
# the space just below the health HUD without entering it.
const JUMP_SPEED := -1100.0
const BASE_VISUAL_SIZE := 176.0
const VISUAL_SIZE := 288.0
const VISUAL_COLLISION_SCALE := VISUAL_SIZE / BASE_VISUAL_SIZE
const BODY_WIDTH := 58.0 * VISUAL_COLLISION_SCALE
const HURTBOX_WIDTH := VISUAL_SIZE * 0.48
const HURTBOX_HEIGHT := VISUAL_SIZE * 0.885
const CROUCH_HURTBOX_WIDTH := VISUAL_SIZE * 0.52
const CROUCH_HURTBOX_HEIGHT := VISUAL_SIZE * 0.64
const SPRITE_HURTBOX_SOURCE_INSET := 3.0
const SPRITE_SHEET_CELL_SIZE := 256.0
const SPRITE_DRAW_OFFSET_Y := 8.0
const STATIC_SPRITE_DRAW_OFFSET_Y := 7.0
const REN_ANIMATION_BASIC := 0
const REN_ANIMATION_GROUND := 1
const REN_ANIMATION_AIR_SPECIAL := 2
const REN_ANIMATION_SPECIAL := 3
const REN_ANIMATION_REACTION := 4
const SPRITE_TRANSITION_FRAMES := 1
# Vel's generated sheets use slightly different apparent body scales between
# action rows. These restrained multipliers align his head and limb proportions
# to the idle row without flattening intentional crouched or airborne poses.
const VEL_SPRITE_ROW_SCALES := [
	[1.0, 1.16, 1.08, 1.12, 1.1],
	[1.02, 1.0, 1.0, 1.0, 0.98],
	[1.0, 1.0, 1.05, 1.06, 1.0],
	[1.06, 1.14, 1.08, 1.07, 1.07],
	[1.0, 1.02, 1.07, 1.12, 1.07]
]
const REN_GROUNDED_TARGET_BOTTOM_GAP := 7.0
const REN_BASIC_BOTTOM_GAPS := [
	[11, 11, 11, 11, 11],
	[11, 11, 7, 11, 11],
	[11, 11, 11, 11, 10],
	[11, 11, 11, 11, 11],
	[11, 11, 11, 11, 11]
]
const REN_GROUND_BOTTOM_GAPS := [
	[23, 22, 21, 22, 22],
	[54, 53, 53, 53, 54],
	[38, 40, 40, 43, 38],
	[62, 65, 58, 57, 62],
	[54, 56, 55, 56, 54]
]
const REN_AIR_SPECIAL_BOTTOM_GAPS := [
	[0, 0, 0, 0, 0],
	[5, 2, 2, 2, 2],
	[25, 52, 52, 44, 24],
	[34, 34, 34, 34, 34],
	[33, 33, 34, 33, 33]
]
const REN_SPECIAL_BOTTOM_GAPS := [
	[1, 1, 1, 12, 0],
	[46, 20, 3, 3, 0],
	[18, 18, 24, 18, 18],
	[32, 31, 30, 27, 29],
	[45, 40, 33, 32, 32]
]
const REN_REACTION_BOTTOM_GAPS := [
	[0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0],
	[0, 2, 1, 1, 0],
	[41, 41, 38, 41, 45],
	[33, 33, 32, 23, 23]
]
const MAX_METER := 100
const INPUT_BUFFER_FRAMES := 7
const SUPER_CHORD_BUFFER_FRAMES := 5
const DOUBLE_TAP_WINDOW_FRAMES := 15
const STEP_INPUT_BUFFER_FRAMES := 4
const FORWARD_STEP_DURATION_FRAMES := 13
const BACK_STEP_DURATION_FRAMES := 15
const FORWARD_STEP_PEAK_SPEED := 880.0
const BACK_STEP_PEAK_SPEED := 720.0
const VEL_SHADOW_RETREAT_END_FRAME := 7
const VEL_SHADOW_PAUSE_END_FRAME := 10
const VEL_SHADOW_ADVANCE_END_FRAME := 27
const VEL_SHADOW_END_FRAME := 34
const VEL_SHADOW_RETREAT_SPEED := 330.0
const VEL_SHADOW_ADVANCE_SPEED := 920.0
const VEL_SHADOW_DECELERATION := 120.0
const KNOCKOUT_PRONE_FRAME := 35
const DEFAULT_KNOCKDOWN_RECOVERY_FRAMES := 48
const ACTION_MOTION_SAMPLE_FRAMES := 2
const AMBIENT_MOTION_SAMPLE_FRAMES := 3
const KEYBOARD_LIGHT_KEY := KEY_J
const KEYBOARD_HEAVY_KEY := KEY_K
const KEYBOARD_SPECIAL_KEY := KEY_L
const KEYBOARD_THROW_KEY := KEY_I
const REN_EFFECT_CORE := Color("efffff")
const REN_EFFECT_LIGHT := Color("7defff")
const REN_EFFECT_BLUE := Color("209cff")
const REN_EFFECT_DEEP := Color("3151e8")
const REN_PULSE_EFFECT_Y := -214.0
const REN_PULSE_PROJECTILE_SPEED := 680.0
const REN_PALM_EFFECT_OFFSET := Vector2(80.0, -240.0)
const ATTACK_HITBOX_VERTICAL_MARGIN := 4.0
const REN_PALM_HITBOX_HALF_SIZE := Vector2(42.0, 38.0)

# front start, top, bottom, front margin. The first three values are ratios of
# the currently visible sprite bounds, so attack boxes follow every animation
# frame instead of extending from an invisible fixed rectangle.
const ATTACK_HITBOX_PROFILES := {
	&"light": [0.50, 0.16, 0.58, 8.0],
	&"crouch_light": [0.44, 0.28, 0.82, 8.0],
	&"heavy": [0.46, 0.12, 0.66, 10.0],
	&"forward_heavy": [0.42, 0.0, 0.64, 10.0],
	&"crouch_heavy": [0.38, 0.0, 0.74, 10.0],
	&"throw": [0.48, 0.14, 0.74, 6.0],
	&"jump_light": [0.48, 0.14, 0.64, 8.0],
	&"jump_heavy": [0.44, 0.16, 0.66, 10.0],
	&"ren_rise": [0.40, 0.0, 0.78, 10.0],
	&"ren_dive": [0.38, 0.16, 0.86, 10.0],
	&"ren_super": [0.34, 0.06, 0.82, 16.0],
	&"vel_rake": [0.40, 0.10, 0.76, 12.0],
	&"vel_pounce": [0.38, 0.16, 0.86, 10.0],
	&"vel_rise": [0.38, 0.0, 0.80, 12.0],
	&"vel_dive": [0.36, 0.14, 0.88, 12.0],
	&"vel_super": [0.32, 0.04, 0.86, 16.0]
}

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
		"bottom_offset": 108.0, "meter_hit": 13, "meter_block": 7
	},
	&"ren_rise": {
		"startup": 5, "active": 8, "recovery": 25,
		"damage": 118, "chip": 0, "hitstun": 20, "blockstun": 16,
		"range": 78.0, "height": 128.0, "push": 30.0,
		"hitstop": 13, "label": "SKY BREAK", "effect": &"rise",
		"bottom_offset": 0.0, "airborne": true, "knockdown": true,
		"launch_y": -430.0, "knockdown_frames": 38, "invulnerable_until": 8,
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
		"bottom_offset": -10.0, "airborne": true, "knockdown": true,
		"launch_y": -300.0, "knockdown_frames": 44,
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
		"damage": 114, "chip": 5, "hitstun": 20, "blockstun": 16,
		"range": 92.0, "height": 88.0, "push": 42.0,
		"hitstop": 13, "label": "REAPER DIVE", "effect": &"claw_dive",
		"bottom_offset": -14.0, "airborne": true,
		"block_type": &"overhead", "knockdown": true,
		"launch_y": -260.0, "knockdown_frames": 36,
		"meter_hit": 14, "meter_block": 7
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
	"meter_hit": 10, "meter_block": 5, "projectile": true,
	"effect": &"azure_pulse_hit", "source_state": &"ren_pulse"
}

var player_id := 0
var character_id: StringName = &"ren"
var fighter_name := "PLAYER 1"
var body_color := Color("4ed8ff")
var accent_color := Color("e9fbff")
var character_texture: Texture2D
var character_animation_textures: Array[Texture2D] = []
var health := 1000
var knocked_out := false
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
var last_horizontal_tap_direction := 0
var horizontal_tap_window_frames := 0
var step_buffer_direction := 0
var step_buffer_frames := 0
var input_history: Array[Vector2] = []
var debug_boxes := false
var combo_received := 0
var last_hit_result := ""
var block_stance_crouching := false
var throw_backwards := false
var air_attack_used := false
var motion_tick := 0
var landing_frames := 0
var knockdown_recovery_frames := DEFAULT_KNOCKDOWN_RECOVERY_FRAMES
var sprite_transition_from := Vector3i(-1, -1, -1)
var sprite_transition_target: StringName = &""
var sprite_transition_frames := 0
var last_visual_state: StringName = &""
var last_visual_frame := -1
var last_visual_facing := 0
var last_visual_height := -1
var last_visual_back_throw := false
var last_visual_debug := false
var last_visual_attack_active := false
var last_visual_meter := -1
var last_visual_transition_frames := -1


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
	_clear_sprite_transition()
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
	knocked_out = false
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
	knockdown_recovery_frames = DEFAULT_KNOCKDOWN_RECOVERY_FRAMES
	_clear_sprite_transition()
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
	_clear_step_input()
	input_history.clear()
	_invalidate_visual_cache()
	_queue_visual_redraw_if_needed()


func revive_for_training() -> void:
	health = maxi(1, health)
	knocked_out = false


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
	_clear_step_input()


func _commit_input(raw_axis: Vector2, buttons: Dictionary) -> void:
	var axis := raw_axis

	axis.x = 0.0 if absf(axis.x) < 0.28 else signf(axis.x)
	axis.y = 0.0 if absf(axis.y) < 0.28 else signf(axis.y)
	_capture_horizontal_tap(axis, float(intent.axis.x))

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


func _capture_horizontal_tap(axis: Vector2, previous_axis_x: float) -> void:
	# A tap begins only when a horizontal direction is pressed from neutral.
	# Requiring neutral between taps prevents a held stick from repeatedly
	# starting steps and keeps diagonals available for jumps and crouch inputs.
	if absf(axis.y) > 0.5 or absf(axis.x) < 0.5 or absf(previous_axis_x) > 0.5:
		return
	var tap_direction := int(signf(axis.x))
	if tap_direction == last_horizontal_tap_direction and horizontal_tap_window_frames > 0:
		step_buffer_direction = tap_direction
		step_buffer_frames = STEP_INPUT_BUFFER_FRAMES
		last_horizontal_tap_direction = 0
		horizontal_tap_window_frames = 0
		return
	last_horizontal_tap_direction = tap_direction
	horizontal_tap_window_frames = DOUBLE_TAP_WINDOW_FRAMES


func _clear_step_input() -> void:
	last_horizontal_tap_direction = 0
	horizontal_tap_window_frames = 0
	step_buffer_direction = 0
	step_buffer_frames = 0


func _consume_step_input() -> int:
	var requested_direction := step_buffer_direction
	step_buffer_direction = 0
	step_buffer_frames = 0
	return requested_direction


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
	horizontal_tap_window_frames = maxi(0, horizontal_tap_window_frames - 1)
	if horizontal_tap_window_frames == 0:
		last_horizontal_tap_direction = 0
	step_buffer_frames = maxi(0, step_buffer_frames - 1)
	if step_buffer_frames == 0:
		step_buffer_direction = 0


func simulate(opponent: Fighter, accepting_input: bool) -> void:
	if sprite_transition_frames > 0:
		sprite_transition_frames -= 1
		if sprite_transition_frames == 0:
			sprite_transition_from = Vector3i(-1, -1, -1)
			sprite_transition_target = &""
	motion_tick = (motion_tick + 1) % 3600
	landing_frames = maxi(0, landing_frames - 1)
	if state == &"hitstun" or state == &"blockstun":
		_step_stun()
	elif state == &"knockdown":
		_step_knockdown()
	elif state == &"vel_shadow":
		_step_vel_shadow()
	elif state == &"forward_step" or state == &"back_step":
		_step_ground_step()
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
		_set_state_with_visual_transition(&"jump")
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
		velocity.x = intent.axis.x * AIR_MOVE_SPEED
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
	if step_buffer_frames > 0 and step_buffer_direction != 0:
		_start_ground_step(_consume_step_input())
		return
	if intent.axis.y < -0.5:
		velocity.y = JUMP_SPEED
		velocity.x = intent.axis.x * AIR_MOVE_SPEED
		_set_state_with_visual_transition(&"jump")
		return
	if intent.axis.y > 0.5:
		_set_state_with_visual_transition(&"crouch")
		velocity.x = 0.0
	elif absf(intent.axis.x) > 0.1:
		_set_state_with_visual_transition(&"walk")
		velocity.x = intent.axis.x * _walk_speed_for_axis(intent.axis.x)
	else:
		_set_state_with_visual_transition(&"idle")
		velocity.x = move_toward(velocity.x, 0.0, 70.0)

	if absf(opponent.position.x - position.x) < 2.0:
		velocity.x = 0.0


func _walk_speed_for_axis(axis_x: float) -> float:
	if axis_x * float(facing) > 0.0:
		return FORWARD_WALK_SPEED
	return WALK_SPEED


func _start_ground_step(input_direction: int) -> void:
	var is_forward := input_direction * facing > 0
	_set_state_with_visual_transition(&"forward_step" if is_forward else &"back_step")
	var peak_speed := FORWARD_STEP_PEAK_SPEED if is_forward else BACK_STEP_PEAK_SPEED
	velocity.x = float(input_direction) * peak_speed


func _step_ground_step() -> void:
	state_frame += 1
	var is_forward := state == &"forward_step"
	var duration := FORWARD_STEP_DURATION_FRAMES if is_forward else BACK_STEP_DURATION_FRAMES
	if state_frame >= duration:
		velocity.x = 0.0
		_set_state_with_visual_transition(&"idle")
		return

	# Start with a responsive burst, then ease to a stop before the recovery
	# frame so the movement feels deliberate instead of ending abruptly.
	var progress := clampf(float(state_frame) / float(duration - 1), 0.0, 1.0)
	var speed_curve := cos(progress * PI * 0.5)
	var movement_direction := facing if is_forward else -facing
	var peak_speed := FORWARD_STEP_PEAK_SPEED if is_forward else BACK_STEP_PEAK_SPEED
	velocity.x = float(movement_direction) * peak_speed * speed_curve


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
			var has_air_input := absf(intent.axis.x) > 0.1
			var air_target_speed: float = intent.axis.x * AIR_ATTACK_MOVE_SPEED
			var air_acceleration: float = (
				AIR_ATTACK_CONTROL_ACCELERATION if has_air_input
				else AIR_ATTACK_DRAG
			)
			velocity.x = move_toward(velocity.x, air_target_speed, air_acceleration)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 48.0)

	var total: int = data.startup + data.active + data.recovery
	if state_frame >= total:
		_set_state_with_visual_transition(&"idle" if is_on_ground() else &"jump")
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
	if state_frame <= VEL_SHADOW_RETREAT_END_FRAME:
		velocity.x = -facing * VEL_SHADOW_RETREAT_SPEED
	elif state_frame <= VEL_SHADOW_PAUSE_END_FRAME:
		velocity.x = move_toward(velocity.x, 0.0, VEL_SHADOW_DECELERATION)
	elif state_frame <= VEL_SHADOW_ADVANCE_END_FRAME:
		velocity.x = facing * VEL_SHADOW_ADVANCE_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, VEL_SHADOW_DECELERATION)

	if state_frame >= VEL_SHADOW_PAUSE_END_FRAME:
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

	if state_frame >= VEL_SHADOW_END_FRAME:
		_set_state_with_visual_transition(&"idle")


func _step_stun() -> void:
	state_frame += 1
	velocity.x = move_toward(velocity.x, 0.0, 18.0)
	var duration := 1
	if state == &"hitstun":
		duration = int(last_hit_result.get_slice(":", 1)) if last_hit_result.begins_with("HIT:") else 16
	else:
		duration = int(last_hit_result.get_slice(":", 1)) if last_hit_result.begins_with("BLOCK:") else 10
	if state_frame >= duration:
		_set_state_with_visual_transition(&"idle" if is_on_ground() else &"jump")
		if state == &"idle":
			combo_received = 0


func _step_knockdown() -> void:
	state_frame += 1
	velocity.x = move_toward(velocity.x, 0.0, 12.0)
	if knocked_out:
		state_frame = mini(state_frame, KNOCKOUT_PRONE_FRAME)
		return
	if state_frame >= knockdown_recovery_frames:
		_set_state_with_visual_transition(&"idle")
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
		if state == &"jump" or is_air_attack():
			_set_state_with_visual_transition(&"idle")
			attack_connected = false
			attack_has_connected = false
			connected_hit_frames.clear()
			air_attack_used = false
			velocity.x = move_toward(velocity.x, 0.0, 90.0)
		velocity.y = 0.0


func _clear_sprite_transition() -> void:
	sprite_transition_from = Vector3i(-1, -1, -1)
	sprite_transition_target = &""
	sprite_transition_frames = 0


func _begin_sprite_transition(next_state: StringName) -> void:
	var previous_frame := _animated_sprite_frame()
	if previous_frame.x < 0:
		_clear_sprite_transition()
		return
	sprite_transition_from = previous_frame
	sprite_transition_target = next_state
	sprite_transition_frames = SPRITE_TRANSITION_FRAMES


func _set_state_with_visual_transition(next_state: StringName) -> void:
	if state == next_state:
		return
	_begin_sprite_transition(next_state)
	state = next_state
	state_frame = 0


func change_state(next_state: StringName) -> void:
	_begin_sprite_transition(next_state)
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
	if state == &"ren_palm":
		var palm_center := ren_palm_effect_world_position()
		return Rect2(
			palm_center - REN_PALM_HITBOX_HALF_SIZE,
			REN_PALM_HITBOX_HALF_SIZE * 2.0
		)
	if ATTACK_HITBOX_PROFILES.has(state):
		return _profiled_attack_rect(ATTACK_HITBOX_PROFILES[state])

	# Projectiles and future attacks without an authored profile retain the
	# legacy data-driven rectangle as a safe fallback.
	var attack_range: float = float(data.range) * VISUAL_COLLISION_SCALE
	var attack_height: float = float(data.height) * VISUAL_COLLISION_SCALE
	var x := position.x + BODY_WIDTH * 0.32 if facing > 0 else position.x - BODY_WIDTH * 0.32 - attack_range
	var bottom_offset: float = float(data.get("bottom_offset", 22.0)) * VISUAL_COLLISION_SCALE
	var y := position.y - attack_height - bottom_offset + _current_sprite_grounding_offset_y()
	return Rect2(x, y, attack_range, attack_height)


func _profiled_attack_rect(profile: Array) -> Rect2:
	var visible_bounds := hurt_rect()
	if not visible_bounds.has_area():
		return Rect2()
	var front_start_ratio := clampf(float(profile[0]), 0.0, 1.0)
	var top_ratio := clampf(float(profile[1]), 0.0, 1.0)
	var bottom_ratio := clampf(float(profile[2]), top_ratio, 1.0)
	var front_margin := maxf(0.0, float(profile[3]))
	var attack_top := visible_bounds.position.y + visible_bounds.size.y * top_ratio
	var attack_bottom := visible_bounds.position.y + visible_bounds.size.y * bottom_ratio
	attack_top -= ATTACK_HITBOX_VERTICAL_MARGIN
	attack_bottom += ATTACK_HITBOX_VERTICAL_MARGIN

	if facing > 0:
		var attack_left := visible_bounds.position.x + visible_bounds.size.x * front_start_ratio
		var attack_right := visible_bounds.end.x + front_margin
		return Rect2(
			Vector2(attack_left, attack_top),
			Vector2(attack_right - attack_left, attack_bottom - attack_top)
		)
	var attack_right := visible_bounds.end.x - visible_bounds.size.x * front_start_ratio
	var attack_left := visible_bounds.position.x - front_margin
	return Rect2(
		Vector2(attack_left, attack_top),
		Vector2(attack_right - attack_left, attack_bottom - attack_top)
	)


func hurt_rect() -> Rect2:
	var sprite_frame := _displayed_sprite_frame()
	var source_bounds := SpriteAlphaBoundsData.rect_for(character_id, sprite_frame)
	if source_bounds.has_area():
		return _sprite_hurt_rect(sprite_frame, source_bounds)

	# Keep a stable fallback for characters that do not provide sprite-bound
	# metadata. Ren and Vel use the frame-accurate path above.
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
		center_x += _knockdown_horizontal_offset(fall_progress)
	return Rect2(center_x - width * 0.5, position.y - height, width, height)


func _sprite_hurt_rect(sprite_frame: Vector3i, source_bounds: Rect2) -> Rect2:
	var safe_inset := minf(
		SPRITE_HURTBOX_SOURCE_INSET,
		minf(source_bounds.size.x, source_bounds.size.y) * 0.1
	)
	var fitted_source_bounds := source_bounds.grow(-safe_inset)
	var render_scale := _sprite_render_scale(sprite_frame)
	var rendered_size := VISUAL_SIZE * render_scale
	var source_to_local := rendered_size / SPRITE_SHEET_CELL_SIZE
	var grounding_offset_y := _sprite_grounding_offset_y(sprite_frame)
	var sprite_origin := Vector2(
		-rendered_size * 0.5,
		(-VISUAL_SIZE + SPRITE_DRAW_OFFSET_Y + grounding_offset_y) * render_scale
	)
	var local_rect := Rect2(
		sprite_origin + fitted_source_bounds.position * source_to_local,
		fitted_source_bounds.size * source_to_local
	)

	# Match the exact transform used by _draw(): animated sprites retain only a
	# quarter of the procedural offset and a fifth of its rotation.
	var pose := _visual_pose()
	var visual_offset: Vector2 = pose.offset * 0.25
	var visual_rotation: float = float(pose.rotation) * 0.2
	var visual_direction := -1.0 if float(pose.scale.x) < 0.0 else 1.0
	var local_corners := [
		local_rect.position,
		Vector2(local_rect.end.x, local_rect.position.y),
		local_rect.end,
		Vector2(local_rect.position.x, local_rect.end.y)
	]
	var world_min := Vector2(INF, INF)
	var world_max := Vector2(-INF, -INF)
	for local_corner in local_corners:
		var transformed_corner := Vector2(
			local_corner.x * visual_direction,
			local_corner.y
		).rotated(visual_rotation)
		transformed_corner += position + visual_offset
		world_min.x = minf(world_min.x, transformed_corner.x)
		world_min.y = minf(world_min.y, transformed_corner.y)
		world_max.x = maxf(world_max.x, transformed_corner.x)
		world_max.y = maxf(world_max.y, transformed_corner.y)
	return Rect2(world_min, world_max - world_min)


func _knockdown_horizontal_offset(progress: float) -> float:
	if knocked_out:
		# Center a rotated single-image fighter around the point where they fell.
		return float(facing) * VISUAL_SIZE * 0.47 * progress
	return -float(facing) * 42.0 * progress


func receive_attack(data: Dictionary, attacker_x: float, forced_push_direction := 0.0) -> Dictionary:
	_clear_sprite_transition()
	var unblockable: bool = data.get("unblockable", false)
	var blocked := not unblockable and _is_blocking(attacker_x, data)
	var damage: int = int(data.chip) if blocked else int(data.damage)
	health = maxi(0, health - damage)
	var is_ko := health <= 0
	state_frame = 0
	attack_connected = false
	attack_has_connected = false
	connected_hit_frames.clear()
	pending_projectile = false
	var push_direction := signf(position.x - attacker_x)
	if absf(forced_push_direction) > 0.1:
		push_direction = signf(forced_push_direction)
	velocity.x = push_direction * float(data.push) * (0.65 if blocked else 1.0)

	if is_ko:
		knocked_out = true
		block_stance_crouching = false
		if not blocked:
			combo_received += 1
		state = &"knockdown"
		last_hit_result = "HIT:%d" % int(data.hitstun)
		velocity.y = float(data.get("launch_y", -330.0))
	elif blocked:
		knocked_out = false
		block_stance_crouching = intent.axis.y > 0.5
		state = &"blockstun"
		last_hit_result = "BLOCK:%d" % int(data.blockstun)
	else:
		knocked_out = false
		combo_received += 1
		var anti_air_knockdown := bool(data.get("anti_air", false)) and not is_on_ground()
		var causes_knockdown := bool(data.get("knockdown", false)) or anti_air_knockdown
		state = &"knockdown" if causes_knockdown else &"hitstun"
		last_hit_result = "HIT:%d" % int(data.hitstun)
		if state == &"knockdown":
			knockdown_recovery_frames = int(data.get(
				"knockdown_frames",
				DEFAULT_KNOCKDOWN_RECOVERY_FRAMES
			))
			velocity.y = float(data.get("launch_y", -330.0))

	_queue_visual_redraw_if_needed()
	return {
		"blocked": blocked,
		"damage": damage,
		"ko": is_ko,
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
	var grounding_offset_y := _current_sprite_grounding_offset_y()
	return {
		"owner_id": player_id,
		"position": position + Vector2(facing * 62.0, REN_PULSE_EFFECT_Y + grounding_offset_y),
		"velocity": Vector2(facing * REN_PULSE_PROJECTILE_SPEED, 0.0),
		"frames": 105,
		"max_frames": 105,
		"radius": 18.0,
		"color": body_color,
		"effect": &"ren_pulse",
		"attack": REN_PULSE_PROJECTILE.duplicate()
	}


func ren_palm_effect_world_position() -> Vector2:
	return position + Vector2(
		float(facing) * REN_PALM_EFFECT_OFFSET.x,
		REN_PALM_EFFECT_OFFSET.y + _current_sprite_grounding_offset_y()
	)


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
	last_visual_transition_frames = -1


func _queue_visual_redraw_if_needed() -> void:
	var uses_gameplay_frames := (
		is_attacking()
		or state == &"vel_shadow"
		or state == &"forward_step"
		or state == &"back_step"
		or state == &"hitstun"
		or state == &"blockstun"
		or state == &"knockdown"
	)
	var ambient_frame := floori(float(motion_tick) / float(AMBIENT_MOTION_SAMPLE_FRAMES))
	var action_frame := floori(float(state_frame) / float(ACTION_MOTION_SAMPLE_FRAMES))
	var animated_frame := action_frame if uses_gameplay_frames else ambient_frame
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
		or last_visual_transition_frames != sprite_transition_frames
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
	last_visual_transition_frames = sprite_transition_frames
	queue_redraw()


func is_on_ground() -> bool:
	return position.y >= GROUND_Y - 0.1


func is_air_attack() -> bool:
	return is_attacking() and bool(ATTACKS[state].get("airborne", false))


func _can_turn() -> bool:
	return state == &"idle" or state == &"walk" or state == &"crouch"


func _is_blocking(attacker_x: float, attack_data: Dictionary) -> bool:
	if (
		not is_on_ground()
		or is_attacking()
		or state == &"forward_step"
		or state == &"back_step"
		or state == &"hitstun"
		or state == &"knockdown"
	):
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
	# Every attack row begins with a neutral or anticipation drawing. Hold it
	# briefly so the pose reads as an action starting from neutral rather than a
	# fighter popping directly into the windup image.
	if state_frame <= 2:
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
	if knocked_out:
		return 0 if state_frame <= 5 else 1
	if state_frame <= 5:
		return 0
	if state_frame <= 14:
		return 1
	if state_frame <= 35:
		return 2
	if state_frame <= 42:
		return 3
	return 4


func _super_sprite_frame() -> int:
	if state_frame <= 2:
		return 0
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
		&"forward_step", &"back_step":
			var duration := (
				FORWARD_STEP_DURATION_FRAMES
				if state == &"forward_step"
				else BACK_STEP_DURATION_FRAMES
			)
			var step_frame := clampi(
				floori(float(state_frame) * 5.0 / float(duration)),
				0,
				4
			)
			if state == &"back_step":
				step_frame = 4 - step_frame
			return _animation_frame(REN_ANIMATION_BASIC, step_frame, 1)
		&"vel_shadow":
			if state_frame <= VEL_SHADOW_PAUSE_END_FRAME:
				return _animation_frame(
					REN_ANIMATION_BASIC,
					clampi(floori(float(state_frame) / 2.0), 0, 4),
					1
				)
			var advance_frames := VEL_SHADOW_ADVANCE_END_FRAME - VEL_SHADOW_PAUSE_END_FRAME
			return _animation_frame(
				REN_ANIMATION_AIR_SPECIAL,
				clampi(
					floori(
						float(state_frame - VEL_SHADOW_PAUSE_END_FRAME)
						* 5.0
						/ float(advance_frames)
					),
					0,
					4
				),
				4
			)
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
		&"vel_rake":
			return _animation_frame(REN_ANIMATION_AIR_SPECIAL, _basic_attack_sprite_frame(), 3)
		&"vel_pounce":
			return _animation_frame(REN_ANIMATION_AIR_SPECIAL, _basic_attack_sprite_frame(), 4)
		&"ren_rise", &"vel_rise":
			return _animation_frame(REN_ANIMATION_SPECIAL, _basic_attack_sprite_frame(), 0)
		&"ren_dive", &"vel_dive":
			return _animation_frame(REN_ANIMATION_SPECIAL, _basic_attack_sprite_frame(), 1)
		&"ren_super", &"vel_super":
			var super_frame := _super_sprite_frame()
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
	return _displayed_sprite_frame().x >= 0 or character_texture != null


func _displayed_sprite_frame() -> Vector3i:
	var sprite_frame := _animated_sprite_frame()
	var transition_active := (
		sprite_transition_frames > 0
		and sprite_transition_target == state
		and sprite_transition_from.x >= 0
		and sprite_transition_from != sprite_frame
	)
	return sprite_transition_from if transition_active else sprite_frame


func _ren_sprite_bottom_gap_table(sheet_index: int) -> Array:
	match sheet_index:
		REN_ANIMATION_BASIC:
			return REN_BASIC_BOTTOM_GAPS
		REN_ANIMATION_GROUND:
			return REN_GROUND_BOTTOM_GAPS
		REN_ANIMATION_AIR_SPECIAL:
			return REN_AIR_SPECIAL_BOTTOM_GAPS
		REN_ANIMATION_SPECIAL:
			return REN_SPECIAL_BOTTOM_GAPS
		REN_ANIMATION_REACTION:
			return REN_REACTION_BOTTOM_GAPS
	return []


func _sprite_grounding_offset_y(sprite_frame: Vector3i) -> float:
	if character_id != &"ren" or sprite_frame.x < 0 or not is_on_ground():
		return 0.0
	# Knockdown rotates around a deliberately offset center and must retain its
	# authored placement rather than being foot-anchored like upright poses.
	if state == &"knockdown":
		return 0.0
	var gap_table := _ren_sprite_bottom_gap_table(sprite_frame.x)
	if sprite_frame.z < 0 or sprite_frame.z >= gap_table.size():
		return 0.0
	var row: Array = gap_table[sprite_frame.z]
	if sprite_frame.y < 0 or sprite_frame.y >= row.size():
		return 0.0
	var bottom_gap := float(row[sprite_frame.y])
	return (bottom_gap - REN_GROUNDED_TARGET_BOTTOM_GAP) * VISUAL_SIZE / SPRITE_SHEET_CELL_SIZE


func _current_sprite_grounding_offset_y() -> float:
	return _sprite_grounding_offset_y(_animated_sprite_frame())


func _sprite_render_scale(sprite_frame: Vector3i) -> float:
	if character_id != &"vel" or sprite_frame.x < 0:
		return 1.0
	if sprite_frame.x >= VEL_SPRITE_ROW_SCALES.size():
		return 1.0
	var sheet_scales: Array = VEL_SPRITE_ROW_SCALES[sprite_frame.x]
	if sprite_frame.z < 0 or sprite_frame.z >= sheet_scales.size():
		return 1.0
	return float(sheet_scales[sprite_frame.z])


func _draw_animated_sprite_frame(sprite_frame: Vector3i, modulate: Color) -> bool:
	if sprite_frame.x < 0 or sprite_frame.x >= character_animation_textures.size():
		return false
	var source_position := Vector2(
		float(sprite_frame.y) * SPRITE_SHEET_CELL_SIZE,
		float(sprite_frame.z) * SPRITE_SHEET_CELL_SIZE
	)
	var grounding_offset_y := _sprite_grounding_offset_y(sprite_frame)
	var render_scale := _sprite_render_scale(sprite_frame)
	var rendered_size := VISUAL_SIZE * render_scale
	draw_texture_rect_region(
		character_animation_textures[sprite_frame.x],
		Rect2(
			-rendered_size * 0.5,
			(-VISUAL_SIZE + SPRITE_DRAW_OFFSET_Y + grounding_offset_y) * render_scale,
			rendered_size,
			rendered_size
		),
		Rect2(source_position, Vector2.ONE * SPRITE_SHEET_CELL_SIZE),
		modulate
	)
	return true


func _draw_character_image(modulate: Color) -> bool:
	var sprite_frame := _displayed_sprite_frame()
	if sprite_frame.x >= 0:
		return _draw_animated_sprite_frame(sprite_frame, modulate)
	if character_texture != null:
		draw_texture_rect(
			character_texture,
			Rect2(
				-VISUAL_SIZE * 0.5,
				-VISUAL_SIZE + STATIC_SPRITE_DRAW_OFFSET_Y,
				VISUAL_SIZE,
				VISUAL_SIZE
			),
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
			&"forward_step", &"back_step":
				var duration := (
					FORWARD_STEP_DURATION_FRAMES
					if state == &"forward_step"
					else BACK_STEP_DURATION_FRAMES
				)
				var step_progress := clampf(float(state_frame) / float(duration), 0.0, 1.0)
				var step_surge := sin(step_progress * PI)
				var step_direction := 1.0 if state == &"forward_step" else -1.0
				visual_offset = Vector2(
					facing * step_direction * (3.0 + step_surge * 10.0),
					-step_surge * 5.0
				)
				visual_rotation = -facing * step_direction * (0.055 + step_surge * 0.075)
				visual_scale *= Vector2(1.0 + step_surge * 0.055, 1.0 - step_surge * 0.045)
			&"crouch":
				visual_offset = Vector2(0.0, 3.0 + breath * 0.7)
				visual_rotation = facing * breath * 0.006
				visual_scale *= Vector2(1.06 - breath * 0.006, 0.76 + breath * 0.008)
			&"jump":
				var vertical_speed := clampf(velocity.y / JUMP_SPEED, -1.0, 1.0)
				var apex_tuck := 1.0 - clampf(absf(velocity.y) / absf(JUMP_SPEED), 0.0, 1.0)
				visual_offset = Vector2(facing * vertical_speed * 2.0, -apex_tuck * 5.0)
				var jump_rotation := facing * (-0.075 - vertical_speed * 0.055)
				visual_rotation = jump_rotation
				visual_scale *= Vector2(0.96 + apex_tuck * 0.08, 1.07 - apex_tuck * 0.13)
			&"vel_shadow":
				if state_frame <= VEL_SHADOW_RETREAT_END_FRAME:
					var retreat_t := _smooth_motion(
						float(state_frame) / float(VEL_SHADOW_RETREAT_END_FRAME)
					)
					visual_offset = Vector2(-facing * (4.0 + retreat_t * 10.0), -retreat_t * 3.0)
					visual_rotation = facing * (0.05 + retreat_t * 0.13)
					visual_scale *= Vector2(1.0 + retreat_t * 0.08, 1.0 - retreat_t * 0.07)
				elif state_frame <= VEL_SHADOW_PAUSE_END_FRAME:
					visual_offset = Vector2(-facing * 5.0, 5.0)
					visual_rotation = facing * 0.08
					visual_scale *= Vector2(1.09, 0.87)
				else:
					var dash_frames := VEL_SHADOW_ADVANCE_END_FRAME - VEL_SHADOW_PAUSE_END_FRAME
					var dash_t := _smooth_motion(
						float(state_frame - VEL_SHADOW_PAUSE_END_FRAME) / float(dash_frames)
					)
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
				var prone_offset_x := _knockdown_horizontal_offset(1.0)
				if state_frame <= 14:
					var fall_t := _smooth_motion(float(state_frame) / 14.0)
					visual_offset = Vector2(_knockdown_horizontal_offset(fall_t), -8.0 * fall_t)
					visual_rotation = -facing * 1.25 * fall_t
					visual_scale *= Vector2(1.0 - fall_t * 0.14, 1.0 - fall_t * 0.1)
				elif state_frame <= 35:
					visual_offset = Vector2(prone_offset_x, -8.0 + sin(float(state_frame) * 0.65) * 1.2)
					visual_rotation = -1.25 * facing
					visual_scale *= 0.86
				else:
					var rise_t := _smooth_motion(float(state_frame - 35) / 13.0)
					visual_offset = Vector2(prone_offset_x * (1.0 - rise_t), -8.0 * (1.0 - rise_t))
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


func _draw_segmented_energy_ring(
	center: Vector2,
	radius: float,
	phase: float,
	color: Color,
	width: float,
	segment_count := 3
) -> void:
	for segment in segment_count:
		var segment_start := phase + float(segment) * TAU / float(segment_count)
		draw_arc(
			center,
			radius,
			segment_start,
			segment_start + TAU * 0.19,
			10,
			color,
			width,
			true
		)


func _draw_ren_slash_crescent(
	center: Vector2,
	radius: float,
	strength: float,
	vertical_shift := 0.0
) -> void:
	var outer_points := PackedVector2Array()
	var inner_points := PackedVector2Array()
	for step in 13:
		var slash_t := float(step) / 12.0
		var angle := lerpf(-1.18, 1.18, slash_t)
		var curve_offset := Vector2(
			cos(angle) * radius * float(facing),
			sin(angle) * radius + vertical_shift
		)
		outer_points.append(center + curve_offset)
		inner_points.append(center + curve_offset * 0.82)
	draw_polyline(outer_points, Color(REN_EFFECT_BLUE, 0.18 * strength), 14.0, true)
	draw_polyline(outer_points, Color(REN_EFFECT_LIGHT, 0.72 * strength), 4.0, true)
	draw_polyline(inner_points, Color(REN_EFFECT_CORE, 0.68 * strength), 2.0, true)


func _draw_ren_pulse_charge() -> void:
	var charge := clampf(float(state_frame) / 13.0, 0.0, 1.0)
	var release := clampf(float(state_frame - 13) / 9.0, 0.0, 1.0)
	var flicker := 0.88 + sin(float(state_frame) * 1.7) * 0.12
	# The sprite gathers energy between both hands near the upper chest, then
	# extends it forward. Follow that hand position instead of the fighter origin.
	var center_x := lerpf(10.0, 64.0, release)
	var center := Vector2(float(facing) * center_x, REN_PULSE_EFFECT_Y)
	var phase := float(state_frame) * 0.22 * float(facing)
	draw_circle(center, 34.0 + charge * 17.0, Color(REN_EFFECT_DEEP, 0.07 * charge))
	draw_circle(center, 20.0 + charge * 9.0, Color(REN_EFFECT_BLUE, 0.14 * charge))
	for ring_index in 3:
		_draw_segmented_energy_ring(
			center,
			14.0 + charge * 8.0 + float(ring_index) * 10.0,
			phase * (1.0 if ring_index % 2 == 0 else -1.0),
			Color(REN_EFFECT_LIGHT if ring_index < 2 else REN_EFFECT_BLUE, (0.28 - float(ring_index) * 0.055) * charge),
			3.0 - float(ring_index) * 0.45,
			4
		)
	for ray_index in 8:
		var angle := phase + float(ray_index) * TAU / 8.0
		var ray_direction := Vector2.from_angle(angle)
		var ray_start := center + ray_direction * (24.0 + charge * 8.0)
		var ray_end := center + ray_direction * (32.0 + charge * (13.0 + float(ray_index % 2) * 8.0))
		draw_line(ray_start, ray_end, Color(REN_EFFECT_CORE, 0.28 * charge * flicker), 2.0, true)
	if release > 0.0:
		var release_alpha := 1.0 - release
		draw_arc(center, 24.0 + release * 78.0, 0.0, TAU, 36, Color(REN_EFFECT_LIGHT, 0.52 * release_alpha), 5.0, true)
		draw_arc(center, 17.0 + release * 58.0, 0.0, TAU, 30, Color(REN_EFFECT_CORE, 0.4 * release_alpha), 2.0, true)


func _ren_palm_effect_strength() -> float:
	var palm_data: Dictionary = ATTACKS[&"ren_palm"]
	var active_start := int(palm_data.startup)
	var active_end := active_start + int(palm_data.active)
	if state_frame <= active_start:
		return 0.0
	if state_frame <= active_end:
		return 1.0
	# The sprite pulls its hand back early in recovery. Fade and retract the
	# effect over five frames so the light never floats ahead of the hand.
	return 1.0 - clampf(float(state_frame - active_end) / 5.0, 0.0, 1.0)


func _draw_ren_palm_trail() -> void:
	var extension := _ren_palm_effect_strength()
	if extension <= 0.01:
		return
	var pulse := 0.85 + sin(float(state_frame) * 1.25) * 0.15
	# Track the outstretched palm in the animation cell. At full extension the
	# hand sits about 80 px forward and 240 px above the fighter's feet.
	var palm_x := lerpf(40.0, REN_PALM_EFFECT_OFFSET.x, extension)
	var palm_center := Vector2(float(facing) * palm_x, REN_PALM_EFFECT_OFFSET.y)
	var tail_start := Vector2(-float(facing) * (82.0 + 28.0 * extension), -220.0)
	var plume := PackedVector2Array([
		tail_start + Vector2(0.0, -24.0),
		palm_center + Vector2(-float(facing) * 13.0, -19.0),
		palm_center + Vector2(float(facing) * 24.0, 0.0),
		palm_center + Vector2(-float(facing) * 13.0, 19.0),
		tail_start + Vector2(0.0, 27.0)
	])
	draw_colored_polygon(plume, Color(REN_EFFECT_DEEP, 0.12 * extension))
	for trail_index in 5:
		var lane_y := -272.0 + float(trail_index) * 18.0
		var start := Vector2(-float(facing) * (104.0 + float(trail_index % 2) * 19.0), lane_y)
		var finish := palm_center + Vector2(-float(facing) * (4.0 + float(trail_index) * 3.0), (float(trail_index) - 2.0) * 5.0)
		draw_line(start, finish, Color(REN_EFFECT_BLUE, (0.12 + float(trail_index % 2) * 0.05) * extension), 5.0 - float(trail_index) * 0.55, true)
	draw_circle(palm_center, 31.0, Color(REN_EFFECT_BLUE, 0.11 * extension))
	draw_circle(palm_center, 16.0 + pulse * 3.0, Color(REN_EFFECT_LIGHT, 0.22 * extension))
	_draw_segmented_energy_ring(palm_center, 25.0 + pulse * 4.0, float(state_frame) * -0.32, Color(REN_EFFECT_CORE, 0.62 * extension), 3.5, 3)


func _draw_ren_rise_trail() -> void:
	var motion := _attack_motion_factors()
	var strength := clampf(float(motion.windup) + float(motion.extension), 0.0, 1.0)
	var phase := float(state_frame) * 0.3
	var ground_y := GROUND_Y - position.y - 2.0
	for ring_index in 3:
		var ground_radius := 34.0 + float(ring_index) * 25.0 + strength * 9.0
		draw_arc(Vector2(0.0, ground_y), ground_radius, PI + 0.18, TAU - 0.18, 22, Color(REN_EFFECT_BLUE, (0.19 - float(ring_index) * 0.045) * strength), 4.0 - float(ring_index) * 0.7, true)
	for lane in 3:
		var trail_points := PackedVector2Array()
		for step in 12:
			var trail_t := float(step) / 11.0
			var sway := sin(trail_t * TAU * 1.4 + phase + float(lane) * 1.8)
			trail_points.append(Vector2(
				float(facing) * (-27.0 + trail_t * 58.0) + sway * (8.0 + float(lane) * 2.0),
				18.0 - trail_t * (190.0 + float(lane) * 21.0)
			))
		draw_polyline(trail_points, Color(REN_EFFECT_BLUE, (0.22 - float(lane) * 0.035) * strength), 10.0 - float(lane) * 2.0, true)
		draw_polyline(trail_points, Color(REN_EFFECT_LIGHT, (0.58 - float(lane) * 0.1) * strength), 2.5, true)
	for shard_index in 6:
		var shard_x := float(facing) * (-54.0 + float(shard_index) * 20.0)
		var shard_y := 6.0 - float((shard_index * 31 + state_frame * 13) % 128)
		draw_line(Vector2(shard_x, shard_y + 18.0), Vector2(shard_x + float(facing) * 7.0, shard_y), Color(REN_EFFECT_CORE, 0.34 * strength), 2.0, true)


func _draw_ren_dive_trail() -> void:
	var motion := _attack_motion_factors()
	var strength := clampf(float(motion.windup) + float(motion.extension), 0.0, 1.0)
	var core := Vector2(float(facing) * 30.0, -43.0)
	var tail_direction := Vector2(-float(facing), -0.82).normalized()
	var side_direction := Vector2(-tail_direction.y, tail_direction.x)
	var tail_length := 105.0 + clampf(velocity.length() / 9.0, 0.0, 70.0)
	var tail := core + tail_direction * tail_length
	var plume := PackedVector2Array([
		core + side_direction * 20.0,
		core + Vector2(float(facing) * 26.0, 12.0),
		core - side_direction * 20.0,
		tail
	])
	draw_colored_polygon(plume, Color(REN_EFFECT_DEEP, 0.14 * strength))
	for trail_index in 5:
		var lane := float(trail_index) - 2.0
		var start := core + side_direction * lane * 8.0
		var end := tail + side_direction * lane * 3.0 + tail_direction * float(trail_index % 2) * 17.0
		draw_line(start, end, Color(REN_EFFECT_BLUE, (0.3 - absf(lane) * 0.035) * strength), 7.0 - absf(lane) * 1.2, true)
	draw_circle(core, 27.0, Color(REN_EFFECT_BLUE, 0.13 * strength))
	_draw_segmented_energy_ring(core, 24.0, float(state_frame) * 0.38, Color(REN_EFFECT_LIGHT, 0.65 * strength), 3.5, 4)


func _ren_super_hit_pulse() -> float:
	var hit_pulse := 0.0
	for hit_frame in [7, 11, 15, 19, 25]:
		hit_pulse = maxf(hit_pulse, 1.0 - absf(float(state_frame - hit_frame)) / 3.0)
	return clampf(hit_pulse, 0.0, 1.0)


func _draw_ren_super_backdrop() -> void:
	var charge := clampf(float(state_frame) / 6.0, 0.0, 1.0)
	var fade := 1.0 - clampf(float(state_frame - 28) / 23.0, 0.0, 1.0)
	var strength := maxf(charge, 0.2) * fade
	var phase := float(state_frame) * 0.18
	var halo_center := Vector2(0.0, -102.0)
	draw_circle(halo_center, 112.0, Color(REN_EFFECT_DEEP, 0.065 * strength))
	for ring_index in 4:
		_draw_segmented_energy_ring(
			halo_center,
			48.0 + float(ring_index) * 20.0 + sin(phase + float(ring_index)) * 4.0,
			phase * (1.0 if ring_index % 2 == 0 else -1.35),
			Color(REN_EFFECT_LIGHT if ring_index < 2 else REN_EFFECT_BLUE, (0.3 - float(ring_index) * 0.05) * strength),
			4.5 - float(ring_index) * 0.65,
			4 + ring_index
		)
	for ray_index in 16:
		var angle := phase * 0.35 + float(ray_index) * TAU / 16.0
		var direction := Vector2.from_angle(angle)
		var inner := 73.0 + float(ray_index % 3) * 7.0
		var outer := inner + 21.0 + float(ray_index % 2) * 17.0
		draw_line(halo_center + direction * inner, halo_center + direction * outer, Color(REN_EFFECT_CORE, 0.19 * strength), 2.0, true)
	if state_frame >= 3 and state_frame <= 31:
		for speed_line in 9:
			var line_y := -176.0 + float(speed_line) * 19.0
			var stagger := float((speed_line * 29 + state_frame * 17) % 74)
			var line_start := Vector2(-float(facing) * (126.0 + stagger), line_y)
			var line_end := Vector2(float(facing) * (46.0 + stagger * 0.15), line_y + sin(float(speed_line) + phase) * 7.0)
			draw_line(line_start, line_end, Color(REN_EFFECT_BLUE, 0.17 * fade), 3.0 + float(speed_line % 3), true)
	var hit_pulse := _ren_super_hit_pulse()
	if hit_pulse > 0.0:
		var strike_center := Vector2(float(facing) * 78.0, -94.0 + sin(float(state_frame) * 1.4) * 12.0)
		draw_circle(strike_center, 52.0 + hit_pulse * 24.0, Color(REN_EFFECT_BLUE, 0.15 * hit_pulse))
		_draw_ren_slash_crescent(strike_center, 58.0 + hit_pulse * 23.0, hit_pulse)
		_draw_ren_slash_crescent(strike_center + Vector2(0.0, 8.0), 43.0 + hit_pulse * 15.0, hit_pulse * 0.75, 4.0)


func _draw_ren_special_backdrop() -> void:
	if character_id != &"ren":
		return
	match state:
		&"ren_pulse":
			_draw_ren_pulse_charge()
		&"ren_palm":
			_draw_ren_palm_trail()
		&"ren_rise":
			_draw_ren_rise_trail()
		&"ren_dive":
			_draw_ren_dive_trail()
		&"ren_super":
			_draw_ren_super_backdrop()


func _draw_ren_special_foreground() -> void:
	if character_id != &"ren":
		return
	var center := Vector2.ZERO
	var strength := 0.0
	match state:
		&"ren_pulse":
			strength = clampf(float(state_frame) / 13.0, 0.0, 1.0) * (1.0 - clampf(float(state_frame - 17) / 11.0, 0.0, 1.0))
			var pulse_release := clampf(float(state_frame - 13) / 9.0, 0.0, 1.0)
			center = Vector2(float(facing) * lerpf(10.0, 64.0, pulse_release), REN_PULSE_EFFECT_Y)
		&"ren_palm":
			strength = _ren_palm_effect_strength()
			if strength <= 0.01:
				return
			center = Vector2(
				float(facing) * lerpf(40.0, REN_PALM_EFFECT_OFFSET.x, strength),
				REN_PALM_EFFECT_OFFSET.y
			)
		&"ren_rise":
			strength = clampf(float(_attack_motion_factors().extension) + 0.25, 0.0, 1.0)
			center = Vector2(float(facing) * 29.0, -139.0)
		&"ren_dive":
			strength = clampf(float(_attack_motion_factors().extension) + 0.2, 0.0, 1.0)
			center = Vector2(float(facing) * 31.0, -43.0)
		&"ren_super":
			strength = maxf(0.35, _ren_super_hit_pulse()) * (1.0 - clampf(float(state_frame - 33) / 18.0, 0.0, 1.0))
			center = Vector2(float(facing) * 76.0, -94.0 + sin(float(state_frame) * 1.4) * 12.0)
		_:
			return
	var core_pulse := 0.86 + sin(float(state_frame) * 1.8) * 0.14
	draw_circle(center, 20.0 + core_pulse * 7.0, Color(REN_EFFECT_BLUE, 0.13 * strength))
	draw_circle(center, 9.0 + core_pulse * 4.0, Color(REN_EFFECT_LIGHT, 0.54 * strength))
	draw_circle(center, 3.5 + core_pulse * 2.0, Color(REN_EFFECT_CORE, 0.92 * strength))
	for mote_index in 4:
		var mote_angle := float(state_frame) * 0.28 + float(mote_index) * TAU / 4.0
		var mote_distance := 25.0 + float(mote_index % 2) * 9.0
		var mote_position := center + Vector2.from_angle(mote_angle) * mote_distance
		draw_circle(mote_position, 2.4, Color(REN_EFFECT_CORE, 0.55 * strength))
	match state:
		&"ren_palm":
			_draw_ren_slash_crescent(center + Vector2(float(facing) * 7.0, 0.0), 38.0, strength * 0.72)
			for ray_index in 5:
				var ray_y := (float(ray_index) - 2.0) * 10.0
				draw_line(
					center - Vector2(float(facing) * 74.0, -ray_y),
					center + Vector2(float(facing) * (20.0 + float(ray_index % 2) * 12.0), ray_y * 0.28),
					Color(REN_EFFECT_LIGHT, 0.42 * strength),
					3.5,
					true
				)
		&"ren_rise":
			draw_line(center + Vector2(-float(facing) * 10.0, 72.0), center + Vector2(float(facing) * 13.0, -54.0), Color(REN_EFFECT_CORE, 0.48 * strength), 5.0, true)
		&"ren_dive":
			var dive_tail := Vector2(-float(facing), -0.82).normalized()
			for lane in 3:
				var lane_offset := Vector2(-dive_tail.y, dive_tail.x) * (float(lane) - 1.0) * 7.0
				draw_line(center + lane_offset, center + dive_tail * (92.0 + float(lane) * 18.0) + lane_offset, Color(REN_EFFECT_LIGHT, (0.5 - float(lane) * 0.08) * strength), 5.0 - float(lane) * 0.7, true)
		&"ren_super":
			var super_pulse := maxf(0.3, _ren_super_hit_pulse()) * strength
			_draw_ren_slash_crescent(center, 72.0 + super_pulse * 27.0, super_pulse)
			_draw_ren_slash_crescent(center + Vector2(-float(facing) * 12.0, 8.0), 54.0 + super_pulse * 19.0, super_pulse * 0.82, 6.0)
			for ray_index in 8:
				var ray_angle := float(ray_index) * TAU / 8.0 + float(state_frame) * 0.17
				var ray_direction := Vector2.from_angle(ray_angle)
				draw_line(center + ray_direction * 18.0, center + ray_direction * (64.0 + float(ray_index % 2) * 22.0), Color(REN_EFFECT_CORE, 0.42 * super_pulse), 3.0, true)


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
	elif state == &"forward_step" or state == &"back_step":
		var duration := (
			FORWARD_STEP_DURATION_FRAMES
			if state == &"forward_step"
			else BACK_STEP_DURATION_FRAMES
		)
		var step_progress := clampf(float(state_frame) / float(duration), 0.0, 1.0)
		var dust_strength := sin(step_progress * PI)
		var movement_direction := 1.0 if state == &"forward_step" else -1.0
		var dust_origin_x := -facing * movement_direction * 25.0
		for dust_index in 3:
			var dust_offset := float(dust_index) * 13.0
			draw_circle(
				Vector2(dust_origin_x - facing * movement_direction * dust_offset, -3.0),
				3.0 + float(2 - dust_index) * 1.8,
				Color(Color("d8c79d"), dust_strength * (0.2 - float(dust_index) * 0.045))
			)

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
		&"forward_step", &"back_step":
			echo_alpha = 0.105
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
		var visible_strength := clampf(float(state_frame - 1) / startup, 0.0, 1.0)
		echo_alpha *= visible_strength
		if echo_alpha <= 0.001:
			return

	var trail_direction := Vector2(-float(facing), 0.0)
	if velocity.length() > 90.0:
		trail_direction = -velocity.normalized()
	if state == &"vel_shadow" and state_frame <= VEL_SHADOW_PAUSE_END_FRAME:
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
	var grounding_offset_y := _current_sprite_grounding_offset_y()

	draw_set_transform(Vector2(0.0, grounding_offset_y), 0.0, Vector2.ONE)
	_draw_ren_special_backdrop()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_motion_echoes(visual_offset, visual_rotation, visual_scale)
	draw_set_transform(visual_offset, visual_rotation, visual_scale)
	if not _draw_character_image(visual_modulate):
		_draw_fallback_fighter()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	draw_set_transform(Vector2(0.0, grounding_offset_y), 0.0, Vector2.ONE)
	_draw_ren_special_foreground()
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
