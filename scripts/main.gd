extends Node2D

const FighterScene := preload("res://scripts/fighter.gd")
const CpuControllerScript := preload("res://scripts/cpu_controller.gd")
const SCREEN_SIZE := Vector2(1152.0, 648.0)
const ROUND_SECONDS := 99
const ROUNDS_TO_WIN := 2
const MODE_SOLO: StringName = &"solo"
const MODE_VERSUS: StringName = &"versus"

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


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("071018"))
	cpu_controller = CpuControllerScript.new() as CpuController
	_create_fighters()
	_create_ui()
	_create_mode_menu()
	_show_mode_menu()
	queue_redraw()


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
	backdrop.color = Color(0.015, 0.045, 0.07, 0.94)
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

	solo_button = _make_mode_button("1 PLAYER   •   VS CPU", Vector2(326.0, 260.0))
	versus_button = _make_mode_button("2 PLAYERS   •   LOCAL VERSUS", Vector2(326.0, 350.0))
	solo_button.pressed.connect(_start_solo_mode)
	versus_button.pressed.connect(_start_versus_mode)
	menu_layer.add_child(solo_button)
	menu_layer.add_child(versus_button)

	var hint := Label.new()
	hint.position = Vector2(226.0, 475.0)
	hint.size = Vector2(700.0, 70.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "UP / DOWN OR W / S TO CHOOSE    •    ENTER TO START\nPRESS M DURING A MATCH TO RETURN HERE"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color("91acb7"))
	menu_layer.add_child(hint)


func _make_mode_button(button_text: String, button_position: Vector2) -> Button:
	var button := Button.new()
	button.position = button_position
	button.size = Vector2(500.0, 68.0)
	button.text = button_text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 22)
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
		queue_redraw()
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
		queue_redraw()
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
	queue_redraw()


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

		attacker.mark_attack_connected()
		var result := defender.receive_attack(attacker.current_attack(), attacker.position.x)
		global_hitstop = result.hitstop
		screen_shake = 8.0 if not result.blocked else 3.0
		hit_sparks.append({
			"position": defender.hurt_rect().get_center(),
			"frames": 12,
			"blocked": result.blocked
		})
		if result.combo > 1 and not result.blocked:
			announcement_sub = "%d HIT COMBO" % result.combo
		if result.ko:
			_finish_round()
		break


func _update_effects() -> void:
	for spark in hit_sparks:
		spark.frames -= 1
	for index in range(hit_sparks.size() - 1, -1, -1):
		if hit_sparks[index].frames <= 0:
			hit_sparks.remove_at(index)
	screen_shake = move_toward(screen_shake, 0.0, 1.35)
	position = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake * 0.4, screen_shake * 0.4)) if screen_shake > 0.1 else Vector2.ZERO


func _update_ui() -> void:
	announcement_label.text = announcement
	subtitle_label.text = announcement_sub
	if game_mode == MODE_SOLO:
		mode_label.text = "1 PLAYER  •  CPU STANDARD"
		help_label.text = "P1  A/D move  W/S jump/crouch  F light  G heavy  H special  R throw     |     F1 frame data  •  M mode select"
	else:
		mode_label.text = "2 PLAYERS  •  LOCAL VERSUS"
		help_label.text = "P1  A/D W/S F/G/H/R     |     P2  Arrows J/K/L/I     |     F1 frame data  •  M mode select"
	if phase == &"fight" and announcement_sub.ends_with("HIT COMBO"):
		# The combo text is transient and clears when the defender recovers.
		if fighters[0].combo_received == 0 and fighters[1].combo_received == 0:
			announcement_sub = ""
	if training_visible:
		training_label.text = "FRAME DATA / HITBOX VIEW\nP1  %s\nP2  %s\nDistance: %.1f px    Enter: reset round" % [
			fighters[0].frame_data_text(),
			fighters[1].frame_data_text(),
			absf(fighters[1].position.x - fighters[0].position.x)
		]


func _draw() -> void:
	# Arena backdrop.
	draw_rect(Rect2(0, 0, SCREEN_SIZE.x, SCREEN_SIZE.y), Color("071018"), true)
	for i in 12:
		var x := float(i) * 104.0 - 40.0
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, 0), Vector2(x + 120.0, 0),
			Vector2(x - 110.0, 558.0), Vector2(x - 230.0, 558.0)
		]), Color(0.04, 0.12, 0.17, 0.48))
	draw_rect(Rect2(0, 460, SCREEN_SIZE.x, 98), Color("102b35"), true)
	draw_line(Vector2(Fighter.ARENA_LEFT, Fighter.GROUND_Y), Vector2(Fighter.ARENA_RIGHT, Fighter.GROUND_Y), Color("41c6cf"), 4.0)
	for x in range(int(Fighter.ARENA_LEFT), int(Fighter.ARENA_RIGHT) + 1, 50):
		draw_line(Vector2(x, Fighter.GROUND_Y), Vector2(576.0 + (x - 576.0) * 1.15, 648.0), Color(0.12, 0.34, 0.4, 0.45), 1.0)

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
