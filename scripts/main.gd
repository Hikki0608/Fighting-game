extends Node2D

const FighterScene := preload("res://scripts/fighter.gd")
const CpuControllerScript := preload("res://scripts/cpu_controller.gd")
const ArenaBackgroundTexture := preload("res://assets/arena_background.svg")
const SCREEN_SIZE := Vector2(1152.0, 648.0)
const ROUND_SECONDS := 99
const ROUNDS_TO_WIN := 2
const MODE_SOLO: StringName = &"solo"
const MODE_VERSUS: StringName = &"versus"
const WEB_FULLSCREEN_HELPER := """
(() => {
	const helperName = "FramebreakFullscreen";
	if (window[helperName]) return;

	const canvas = document.getElementById("canvas");
	if (!canvas) {
		console.warn("Framebreak: the game canvas was not found.");
		return;
	}

	const originalCanvasStyle = canvas.getAttribute("style");
	const originalBodyStyle = document.body.getAttribute("style");
	const fullscreenElement = () => document.fullscreenElement || document.webkitFullscreenElement;
	const restoreStyle = (element, style) => {
		if (style === null) element.removeAttribute("style");
		else element.setAttribute("style", style);
	};
	const fitCanvas = () => {
		if (!fullscreenElement()) return;
		const aspectRatio = 16 / 9;
		let width = window.innerWidth;
		let height = width / aspectRatio;
		if (height > window.innerHeight) {
			height = window.innerHeight;
			width = height * aspectRatio;
		}
		Object.assign(document.body.style, {
			margin: "0",
			overflow: "hidden",
			background: "#000"
		});
		Object.assign(canvas.style, {
			position: "fixed",
			left: "50%",
			top: "50%",
			transform: "translate(-50%, -50%)",
			width: `${Math.floor(width)}px`,
			height: `${Math.floor(height)}px`,
			maxWidth: "none",
			maxHeight: "none"
		});
	};
	const syncCanvas = () => {
		if (fullscreenElement()) fitCanvas();
		else {
			restoreStyle(canvas, originalCanvasStyle);
			restoreStyle(document.body, originalBodyStyle);
		}
	};
	const toggle = () => {
		if (fullscreenElement()) {
			const exitFullscreen = document.exitFullscreen || document.webkitExitFullscreen;
			if (exitFullscreen) {
				const result = exitFullscreen.call(document);
				if (result && result.catch) result.catch((error) => console.warn("Framebreak: could not exit fullscreen.", error));
			}
			return;
		}

		const target = document.documentElement;
		const requestFullscreen = target.requestFullscreen || target.webkitRequestFullscreen;
		if (!requestFullscreen) {
			console.warn("Framebreak: fullscreen is not supported by this browser.");
			return;
		}
		try {
			const result = requestFullscreen.call(target);
			if (result && result.catch) result.catch((error) => console.warn("Framebreak: fullscreen request was rejected.", error));
		} catch (error) {
			console.warn("Framebreak: fullscreen request failed.", error);
		}
	};

	window[helperName] = Object.freeze({
		toggle,
		isActive: () => Boolean(fullscreenElement()),
		fit: fitCanvas
	});
	document.addEventListener("fullscreenchange", syncCanvas);
	document.addEventListener("webkitfullscreenchange", syncCanvas);
	window.addEventListener("resize", fitCanvas);
})();
"""

var fighters: Array[Fighter] = []
var wins := [0, 0]
var round_number := 1
var round_frames := ROUND_SECONDS * 60
var phase: StringName = &"menu"
var phase_frames := 120
var global_hitstop := 0
var training_visible := false
var screen_shake := 0.0
var hit_sparks: Array[Dictionary] = []
var announcement := "ROUND 1"
var announcement_sub := ""
var combat_callout_frames := 0
var game_mode: StringName = MODE_SOLO
var mode_selection := 0
var cpu_controller: CpuController
var meta_key_state := {}

var announcement_label: Label
var subtitle_label: Label
var help_label: Label
var training_label: Label
var mode_label: Label
var menu_layer: CanvasLayer
var solo_button: Button
var versus_button: Button
var fullscreen_button: Button
var last_drawn_p1_health := -1
var last_drawn_p2_health := -1
var last_drawn_timer := -1
var last_drawn_p1_wins := -1
var last_drawn_p2_wins := -1
var last_drawn_spark_count := -1


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("071018"))
	cpu_controller = CpuControllerScript.new() as CpuController
	_create_arena_background()
	_create_fighters()
	_create_ui()
	_create_mode_menu()
	_initialize_fullscreen_support()
	_show_mode_menu()
	_request_hud_redraw()


func _input(event: InputEvent) -> void:
	var key_event := event as InputEventKey
	if key_event == null or not _is_fullscreen_shortcut(key_event):
		return
	# Keep the menu's Enter polling from also starting a match on this frame.
	meta_key_state[KEY_ENTER] = true
	_toggle_fullscreen()
	get_viewport().set_input_as_handled()


func _is_fullscreen_shortcut(event: InputEventKey) -> bool:
	return (
		event.pressed
		and not event.echo
		and event.alt_pressed
		and (event.keycode == KEY_ENTER or event.physical_keycode == KEY_ENTER)
	)


func _initialize_fullscreen_support() -> void:
	if not OS.has_feature("web"):
		return
	print("Framebreak: initializing Web fullscreen support.")
	var bridge_probe = JavaScriptBridge.eval("globalThis.FramebreakFullscreenProbe = 'ready'; 42;", true)
	print("Framebreak: JavaScript bridge probe returned ", bridge_probe)
	JavaScriptBridge.eval(WEB_FULLSCREEN_HELPER, true)


func _toggle_fullscreen() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.FramebreakFullscreen && window.FramebreakFullscreen.toggle();", true)
		return

	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _create_arena_background() -> void:
	var background := Sprite2D.new()
	background.name = "ArenaBackground"
	background.texture = ArenaBackgroundTexture
	background.centered = false
	background.position = Vector2.ZERO
	background.z_index = -100
	background.show_behind_parent = true
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(background)


func _create_fighters() -> void:
	var p1 := FighterScene.new() as Fighter
	var p2 := FighterScene.new() as Fighter
	add_child(p1)
	add_child(p2)
	p1.setup(0, "PLAYER 1", Color("2cccf4"), Vector2(330.0, Fighter.GROUND_Y))
	p2.setup(1, "PLAYER 2", Color("ff4f86"), Vector2(822.0, Fighter.GROUND_Y))
	fighters = [p1, p2]


func _create_ui() -> void:
	announcement_label = Label.new()
	announcement_label.position = Vector2(276.0, 218.0)
	announcement_label.size = Vector2(600.0, 80.0)
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.add_theme_font_size_override("font_size", 48)
	announcement_label.add_theme_color_override("font_color", Color("fff3c4"))
	announcement_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	announcement_label.add_theme_constant_override("shadow_offset_x", 4)
	announcement_label.add_theme_constant_override("shadow_offset_y", 4)
	add_child(announcement_label)

	subtitle_label = Label.new()
	subtitle_label.position = Vector2(276.0, 282.0)
	subtitle_label.size = Vector2(600.0, 44.0)
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 20)
	subtitle_label.add_theme_color_override("font_color", Color("cae7f2"))
	add_child(subtitle_label)

	help_label = Label.new()
	help_label.position = Vector2(24.0, 600.0)
	help_label.size = Vector2(1104.0, 32.0)
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help_label.add_theme_font_size_override("font_size", 15)
	help_label.add_theme_color_override("font_color", Color("91acb7"))
	help_label.text = "P1  A/D move  W jump  S crouch  F light  G heavy  H special  R throw"
	add_child(help_label)

	mode_label = Label.new()
	mode_label.position = Vector2(426.0, 8.0)
	mode_label.size = Vector2(300.0, 24.0)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 13)
	mode_label.add_theme_color_override("font_color", Color("91acb7"))
	add_child(mode_label)

	training_label = Label.new()
	training_label.position = Vector2(24.0, 126.0)
	training_label.size = Vector2(460.0, 116.0)
	training_label.add_theme_font_size_override("font_size", 16)
	training_label.add_theme_color_override("font_color", Color("d9f7ff"))
	training_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	training_label.add_theme_constant_override("shadow_offset_x", 2)
	training_label.add_theme_constant_override("shadow_offset_y", 2)
	training_label.visible = false
	add_child(training_label)


func _create_mode_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 10
	add_child(menu_layer)

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = SCREEN_SIZE
	backdrop.color = Color(0.015, 0.035, 0.055, 0.88)
	menu_layer.add_child(backdrop)

	var title := Label.new()
	title.position = Vector2(226.0, 92.0)
	title.size = Vector2(700.0, 86.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "FRAMEBREAK"
	title.add_theme_font_size_override("font_size", 64)
	title.add_theme_color_override("font_color", Color("fff3c4"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 5)
	title.add_theme_constant_override("shadow_offset_y", 5)
	menu_layer.add_child(title)

	var subtitle := Label.new()
	subtitle.position = Vector2(326.0, 174.0)
	subtitle.size = Vector2(500.0, 42.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = "SELECT BATTLE MODE"
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color("91ddea"))
	menu_layer.add_child(subtitle)

	solo_button = _make_mode_button("1 PLAYER   •   VS CPU", Vector2(326.0, 250.0))
	versus_button = _make_mode_button("2 PLAYERS   •   LOCAL VERSUS", Vector2(326.0, 335.0))
	fullscreen_button = _make_mode_button(
		"FULLSCREEN   •   ALT + ENTER",
		Vector2(426.0, 430.0),
		Vector2(300.0, 52.0),
		18,
		false
	)
	solo_button.pressed.connect(_start_solo_mode)
	versus_button.pressed.connect(_start_versus_mode)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	fullscreen_button.tooltip_text = "Toggle fullscreen (Alt + Enter)"
	menu_layer.add_child(solo_button)
	menu_layer.add_child(versus_button)
	menu_layer.add_child(fullscreen_button)

	var hint := Label.new()
	hint.position = Vector2(226.0, 510.0)
	hint.size = Vector2(700.0, 70.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "UP / DOWN OR W / S TO CHOOSE    •    ENTER TO START\nM: MODE SELECT    •    ALT + ENTER: FULLSCREEN"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("91acb7"))
	menu_layer.add_child(hint)


func _make_mode_button(
	button_text: String,
	button_position: Vector2,
	button_size: Vector2 = Vector2(500.0, 68.0),
	font_size: int = 22,
	focusable: bool = true
) -> Button:
	var button := Button.new()
	button.position = button_position
	button.size = button_size
	button.text = button_text
	button.focus_mode = Control.FOCUS_ALL if focusable else Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("d8f7ff"))
	button.add_theme_color_override("font_hover_color", Color("fff3c4"))
	button.add_theme_color_override("font_focus_color", Color("fff3c4"))
	button.add_theme_stylebox_override("normal", _make_button_style(Color("102b35"), Color("2f6572"), 2))
	button.add_theme_stylebox_override("hover", _make_button_style(Color("16404c"), Color("61d5e3"), 3))
	button.add_theme_stylebox_override("pressed", _make_button_style(Color("1d4b57"), Color("fff3c4"), 3))
	button.add_theme_stylebox_override("focus", _make_button_style(Color("153945"), Color("fff3c4"), 4))
	return button


func _make_button_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	return style


func _physics_process(_delta: float) -> void:
	_handle_system_input()
	if phase == &"menu":
		_update_ui()
		_request_hud_redraw()
		return

	fighters[0].capture_input()
	if game_mode == MODE_SOLO:
		if phase == &"fight":
			var cpu_intent := cpu_controller.build_intent(fighters[1], fighters[0])
			fighters[1].apply_virtual_input(cpu_intent.axis, cpu_intent.buttons)
		else:
			fighters[1].clear_input()
	else:
		fighters[1].capture_input()

	if global_hitstop > 0:
		global_hitstop -= 1
		_update_effects()
		_update_ui()
		_request_hud_redraw()
		return

	if phase == &"intro":
		phase_frames -= 1
		if phase_frames == 60:
			announcement = "FIGHT"
		if phase_frames <= 0:
			phase = &"fight"
			announcement = ""
			announcement_sub = ""
	elif phase == &"fight":
		round_frames = maxi(0, round_frames - 1)
		for i in fighters.size():
			fighters[i].simulate(fighters[1 - i], true)
		_resolve_body_collision()
		_resolve_attacks()
		if fighters[0].health <= 0 or fighters[1].health <= 0 or round_frames <= 0:
			_finish_round()
	elif phase == &"round_over":
		phase_frames -= 1
		for i in fighters.size():
			fighters[i].simulate(fighters[1 - i], false)
		if phase_frames <= 0:
			round_number += 1
			_start_round()

	_update_effects()
	_update_ui()
	_request_hud_redraw()


func _handle_system_input() -> void:
	if phase == &"menu":
		_handle_mode_menu_input()
		return

	var menu_pressed := _key_just_pressed(KEY_M)
	menu_pressed = _key_just_pressed(KEY_ESCAPE) or menu_pressed
	if menu_pressed:
		_show_mode_menu()
		return

	if _key_just_pressed(KEY_F1):
		training_visible = not training_visible
		training_label.visible = training_visible
		for fighter in fighters:
			fighter.set_debug_boxes(training_visible)
	if _key_just_pressed(KEY_ENTER):
		if phase == &"match_over":
			wins = [0, 0]
			round_number = 1
			_start_round()
		elif training_visible:
			_start_round()


func _handle_mode_menu_input() -> void:
	var up_pressed := _key_just_pressed(KEY_UP)
	up_pressed = _key_just_pressed(KEY_W) or up_pressed
	var down_pressed := _key_just_pressed(KEY_DOWN)
	down_pressed = _key_just_pressed(KEY_S) or down_pressed
	var confirm_pressed := _key_just_pressed(KEY_ENTER)
	confirm_pressed = _key_just_pressed(KEY_SPACE) or confirm_pressed

	if up_pressed or down_pressed:
		mode_selection = 1 - mode_selection
		_update_mode_selection()
	if confirm_pressed:
		if mode_selection == 0:
			_start_solo_mode()
		else:
			_start_versus_mode()


func _key_just_pressed(keycode: Key) -> bool:
	var down := Input.is_physical_key_pressed(keycode)
	var was_down := bool(meta_key_state.get(keycode, false))
	meta_key_state[keycode] = down
	return down and not was_down


func _show_mode_menu() -> void:
	phase = &"menu"
	position = Vector2.ZERO
	screen_shake = 0.0
	global_hitstop = 0
	hit_sparks.clear()
	training_visible = false
	training_label.visible = false
	announcement_label.visible = false
	subtitle_label.visible = false
	help_label.visible = false
	mode_label.visible = false
	menu_layer.visible = true
	mode_selection = 0
	for fighter in fighters:
		fighter.visible = false
		fighter.clear_input()
		fighter.set_debug_boxes(false)
	_update_mode_selection()


func _update_mode_selection() -> void:
	if mode_selection == 0:
		solo_button.grab_focus()
	else:
		versus_button.grab_focus()


func _start_solo_mode() -> void:
	_start_match(MODE_SOLO)


func _start_versus_mode() -> void:
	_start_match(MODE_VERSUS)


func _start_match(selected_mode: StringName) -> void:
	game_mode = selected_mode
	menu_layer.visible = false
	announcement_label.visible = true
	subtitle_label.visible = true
	help_label.visible = true
	mode_label.visible = true
	for fighter in fighters:
		fighter.visible = true

	fighters[0].fighter_name = "PLAYER 1"
	fighters[1].fighter_name = "CPU" if game_mode == MODE_SOLO else "PLAYER 2"
	wins = [0, 0]
	round_number = 1
	training_visible = false
	training_label.visible = false
	cpu_controller.reset()
	_start_round()


func _start_round() -> void:
	phase = &"intro"
	phase_frames = 120
	round_frames = ROUND_SECONDS * 60
	global_hitstop = 0
	hit_sparks.clear()
	combat_callout_frames = 0
	cpu_controller.reset()
	fighters[0].facing = 1
	fighters[1].facing = -1
	fighters[0].reset_for_round(Vector2(330.0, Fighter.GROUND_Y))
	fighters[1].reset_for_round(Vector2(822.0, Fighter.GROUND_Y))
	announcement = "ROUND %d" % round_number
	announcement_sub = "FIRST TO %d ROUNDS" % ROUNDS_TO_WIN


func _finish_round() -> void:
	if phase != &"fight":
		return
	var winner := -1
	if fighters[0].health > fighters[1].health:
		winner = 0
	elif fighters[1].health > fighters[0].health:
		winner = 1

	if winner >= 0:
		wins[winner] += 1
		announcement = "K.O." if round_frames > 0 else "TIME UP"
		announcement_sub = "%s TAKES THE ROUND" % fighters[winner].fighter_name
	else:
		announcement = "DRAW"
		announcement_sub = "NO ROUND AWARDED"

	if winner >= 0 and wins[winner] >= ROUNDS_TO_WIN:
		phase = &"match_over"
		announcement = "%s WINS" % fighters[winner].fighter_name
		announcement_sub = "PRESS ENTER TO REMATCH  •  M FOR MODE SELECT"
	else:
		phase = &"round_over"
		phase_frames = 180


func _resolve_body_collision() -> void:
	# Airborne fighters do not push the opponent sideways. Their movement can
	# carry them across the opponent; ground collision resumes on landing.
	if not fighters[0].is_on_ground() or not fighters[1].is_on_ground():
		return
	var p1_hurt := fighters[0].hurt_rect()
	var p2_hurt := fighters[1].hurt_rect()
	var vertical_overlap := minf(p1_hurt.end.y, p2_hurt.end.y) - maxf(p1_hurt.position.y, p2_hurt.position.y)
	if vertical_overlap <= 22.0:
		return
	var delta_x := fighters[1].position.x - fighters[0].position.x
	var min_distance := Fighter.BODY_WIDTH * 0.92
	if absf(delta_x) >= min_distance:
		return
	var overlap := min_distance - absf(delta_x)
	var direction := signf(delta_x) if absf(delta_x) > 0.01 else 1.0
	fighters[0].position.x -= overlap * 0.5 * direction
	fighters[1].position.x += overlap * 0.5 * direction
	fighters[0].position.x = clampf(fighters[0].position.x, Fighter.ARENA_LEFT + 29.0, Fighter.ARENA_RIGHT - 29.0)
	fighters[1].position.x = clampf(fighters[1].position.x, Fighter.ARENA_LEFT + 29.0, Fighter.ARENA_RIGHT - 29.0)


func _resolve_attacks() -> void:
	for attacker_index in fighters.size():
		var attacker := fighters[attacker_index]
		var defender := fighters[1 - attacker_index]
		if not attacker.is_attack_active():
			continue
		if not attacker.attack_rect().intersects(defender.hurt_rect()):
			continue
		if attacker.state == &"throw" and (not defender.is_on_ground() or defender.state == &"hitstun" or defender.state == &"blockstun"):
			continue

		var attack_data := attacker.current_attack()
		attacker.mark_attack_connected()
		var forced_push_direction := 0.0
		if bool(attack_data.get("back_throw", false)):
			forced_push_direction = _perform_back_throw(attacker, defender)
		var result := defender.receive_attack(attack_data, attacker.position.x, forced_push_direction)
		global_hitstop = result.hitstop
		screen_shake = 8.0 if not result.blocked else 3.0
		hit_sparks.append({
			"position": defender.hurt_rect().get_center(),
			"frames": 12,
			"blocked": result.blocked
		})
		if result.back_throw:
			announcement_sub = "BACK THROW"
			combat_callout_frames = 60
		elif result.combo > 1 and not result.blocked:
			announcement_sub = "%d HIT COMBO" % result.combo
			combat_callout_frames = 45
		if result.ko:
			_finish_round()
		break


func _perform_back_throw(attacker: Fighter, defender: Fighter) -> float:
	var original_facing := float(attacker.facing)
	var toss_direction := -original_facing
	var attacker_x := attacker.position.x + original_facing * 30.0
	var defender_x := attacker.position.x + toss_direction * 72.0
	var left_limit := Fighter.ARENA_LEFT + Fighter.BODY_WIDTH * 0.5
	var right_limit := Fighter.ARENA_RIGHT - Fighter.BODY_WIDTH * 0.5
	var pair_min := minf(attacker_x, defender_x)
	var pair_max := maxf(attacker_x, defender_x)
	if pair_min < left_limit:
		var shift_right := left_limit - pair_min
		attacker_x += shift_right
		defender_x += shift_right
	elif pair_max > right_limit:
		var shift_left := pair_max - right_limit
		attacker_x -= shift_left
		defender_x -= shift_left

	attacker.position.x = attacker_x
	defender.position.x = defender_x
	attacker.facing = int(toss_direction)
	defender.facing = -attacker.facing
	return toss_direction


func _update_effects() -> void:
	for spark in hit_sparks:
		spark.frames -= 1
	for index in range(hit_sparks.size() - 1, -1, -1):
		if hit_sparks[index].frames <= 0:
			hit_sparks.remove_at(index)
	screen_shake = move_toward(screen_shake, 0.0, 1.35)
	position = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake * 0.4, screen_shake * 0.4)) if screen_shake > 0.1 else Vector2.ZERO
	if combat_callout_frames > 0:
		combat_callout_frames -= 1
		if combat_callout_frames == 0 and phase == &"fight":
			announcement_sub = ""


func _update_ui() -> void:
	if phase == &"fight" and announcement_sub.ends_with("HIT COMBO"):
		# The combo text is transient and clears when the defender recovers.
		if fighters[0].combo_received == 0 and fighters[1].combo_received == 0:
			announcement_sub = ""

	_set_label_text_if_changed(announcement_label, announcement)
	_set_label_text_if_changed(subtitle_label, announcement_sub)
	if game_mode == MODE_SOLO:
		_set_label_text_if_changed(mode_label, "1 PLAYER  •  CPU STANDARD")
		_set_label_text_if_changed(help_label, "P1 A/D move  W/S jump/crouch  F/G attack  H special  R throw  •  Air F/G  •  Back+R back throw  •  M menu  •  Alt+Enter fullscreen")
	else:
		_set_label_text_if_changed(mode_label, "2 PLAYERS  •  LOCAL VERSUS")
		_set_label_text_if_changed(help_label, "P1 A/D W/S F/G/H/R  •  P2 Arrows J/K/L/I  •  Air: light/heavy  •  Back+throw  •  M menu  •  Alt+Enter fullscreen")
	if training_visible:
		var training_text := "FRAME DATA / HITBOX VIEW\nP1  %s\nP2  %s\nDistance: %.1f px    Enter: reset round" % [
			fighters[0].frame_data_text(),
			fighters[1].frame_data_text(),
			absf(fighters[1].position.x - fighters[0].position.x)
		]
		_set_label_text_if_changed(training_label, training_text)


func _set_label_text_if_changed(label: Label, next_text: String) -> void:
	if label.text != next_text:
		label.text = next_text


func _request_hud_redraw() -> void:
	var timer_seconds := ceili(float(round_frames) / 60.0)
	var sparks_need_animation := not hit_sparks.is_empty()
	var hud_changed: bool = (
		last_drawn_p1_health != fighters[0].health
		or last_drawn_p2_health != fighters[1].health
		or last_drawn_timer != timer_seconds
		or last_drawn_p1_wins != wins[0]
		or last_drawn_p2_wins != wins[1]
		or last_drawn_spark_count != hit_sparks.size()
	)
	if not hud_changed and not sparks_need_animation:
		return

	last_drawn_p1_health = fighters[0].health
	last_drawn_p2_health = fighters[1].health
	last_drawn_timer = timer_seconds
	last_drawn_p1_wins = wins[0]
	last_drawn_p2_wins = wins[1]
	last_drawn_spark_count = hit_sparks.size()
	queue_redraw()


func _draw() -> void:
	# Health and round HUD.
	draw_rect(Rect2(48, 40, 450, 34), Color("101820"), true)
	draw_rect(Rect2(654, 40, 450, 34), Color("101820"), true)
	var p1_width := 442.0 * float(fighters[0].health) / 1000.0
	var p2_width := 442.0 * float(fighters[1].health) / 1000.0
	draw_rect(Rect2(52, 44, p1_width, 26), Color("2cccf4"), true)
	draw_rect(Rect2(1100.0 - p2_width, 44, p2_width, 26), Color("ff4f86"), true)
	draw_rect(Rect2(48, 40, 450, 34), Color("d6f7ff"), false, 2.0)
	draw_rect(Rect2(654, 40, 450, 34), Color("ffd5e2"), false, 2.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(50, 99), fighters[0].fighter_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("d6f7ff"))
	draw_string(font, Vector2(654, 99), fighters[1].fighter_name, HORIZONTAL_ALIGNMENT_RIGHT, 448, 19, Color("ffd5e2"))
	var timer_text := "%02d" % ceili(float(round_frames) / 60.0)
	draw_string(font, Vector2(516, 76), timer_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 36, Color("fff3c4"))
	for i in wins[0]:
		draw_circle(Vector2(68.0 + i * 24.0, 116.0), 8.0, Color("fff3c4"))
	for i in wins[1]:
		draw_circle(Vector2(1084.0 - i * 24.0, 116.0), 8.0, Color("fff3c4"))

	for spark in hit_sparks:
		var spark_color := Color("8defff") if spark.blocked else Color("fff19a")
		var radius := float(spark.frames) * 2.5
		for ray in 8:
			var angle := TAU * float(ray) / 8.0
			draw_line(spark.position, spark.position + Vector2.from_angle(angle) * radius, spark_color, 4.0)
		draw_circle(spark.position, radius * 0.28, spark_color)
