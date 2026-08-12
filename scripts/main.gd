extends Node2D

const FighterScene := preload("res://scripts/fighter.gd")
const CpuControllerScript := preload("res://scripts/cpu_controller.gd")
const ArenaBackgroundTexture := preload("res://assets/arena_background.svg")
const RenFighterTexture := preload("res://assets/characters/ren_fighter.png")
const VelFighterTexture := preload("res://assets/characters/vel_fighter.png")
const SCREEN_SIZE := Vector2(1152.0, 648.0)
const ROUND_SECONDS := 99
const ROUNDS_TO_WIN := 2
const MODE_SOLO: StringName = &"solo"
const MODE_VERSUS: StringName = &"versus"
const CHARACTER_ROSTER := [
	{
		"id": &"ren",
		"name": "REN",
		"title": "AZURE TACTICIAN",
		"color": Color("2cccf4"),
		"texture": RenFighterTexture
	},
	{
		"id": &"vel",
		"name": "VEL",
		"title": "CRIMSON HUNTER",
		"color": Color("ff4f86"),
		"texture": VelFighterTexture
	}
]
const WEB_FULLSCREEN_HELPER := """
(() => {
	const helperName = "FramebreakFullscreen";
	if (window[helperName]) return;
	const styleId = "framebreak-fullscreen-style";
	const fullscreenElement = () => document.fullscreenElement || document.webkitFullscreenElement;
	const setState = (state) => {
		document.documentElement.dataset.framebreakFullscreen = state;
	};
	const syncState = () => setState(fullscreenElement() ? "active" : "windowed");

	if (!document.getElementById(styleId)) {
		const style = document.createElement("style");
		style.id = styleId;
		style.textContent = `
			:fullscreen, :-webkit-full-screen {
				background: #000;
			}
			:fullscreen body, :-webkit-full-screen body {
				margin: 0;
				overflow: hidden;
				background: #000;
			}
			:fullscreen #canvas, :-webkit-full-screen #canvas {
				position: fixed !important;
				left: 50% !important;
				top: 50% !important;
				transform: translate(-50%, -50%) !important;
				width: min(100vw, 177.7777778vh) !important;
				height: min(56.25vw, 100vh) !important;
				max-width: none !important;
				max-height: none !important;
			}
		`;
		document.head.appendChild(style);
	}

	const toggle = () => {
		if (fullscreenElement()) {
			const exitFullscreen = document.exitFullscreen || document.webkitExitFullscreen;
			if (exitFullscreen) {
				setState("exiting");
				const result = exitFullscreen.call(document);
				if (result && result.catch) {
					result.catch((error) => {
						syncState();
						console.warn("Framebreak: could not exit fullscreen.", error);
					});
				}
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
			setState("requesting");
			const result = requestFullscreen.call(target);
			if (result && result.catch) {
				result.catch((error) => {
					syncState();
					console.warn("Framebreak: fullscreen request was rejected.", error);
				});
			}
		} catch (error) {
			syncState();
			console.warn("Framebreak: fullscreen request failed.", error);
		}
	};

	window[helperName] = Object.freeze({
		toggle,
		isActive: () => Boolean(fullscreenElement())
	});
	document.addEventListener("fullscreenchange", syncState);
	document.addEventListener("webkitfullscreenchange", syncState);
	syncState();
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
var projectiles: Array[Dictionary] = []
var announcement := "ROUND 1"
var announcement_sub := ""
var combat_callout_frames := 0
var game_mode: StringName = MODE_SOLO
var mode_selection := 0
var character_selection := [0, 1]
var selecting_player := 0
var cpu_controller: CpuController
var meta_key_state := {}

var announcement_label: Label
var subtitle_label: Label
var training_label: Label
var mode_label: Label
var menu_layer: CanvasLayer
var character_select_layer: CanvasLayer
var solo_button: Button
var versus_button: Button
var fullscreen_button: Button
var character_prompt_label: Label
var character_summary_label: Label
var character_hint_label: Label
var character_buttons: Array[Button] = []
var character_status_labels: Array[Label] = []
var last_drawn_p1_health := -1
var last_drawn_p2_health := -1
var last_drawn_timer := -1
var last_drawn_p1_wins := -1
var last_drawn_p2_wins := -1
var last_drawn_spark_count := -1
var last_drawn_p1_meter := -1
var last_drawn_p2_meter := -1
var last_drawn_projectile_count := -1


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("071018"))
	cpu_controller = CpuControllerScript.new() as CpuController
	_create_arena_background()
	_create_fighters()
	_create_ui()
	_create_mode_menu()
	_create_character_select_menu()
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
	var ren: Dictionary = CHARACTER_ROSTER[0]
	var vel: Dictionary = CHARACTER_ROSTER[1]
	p1.setup(0, ren.name, ren.color, Vector2(330.0, Fighter.GROUND_Y), ren.texture)
	p2.setup(1, vel.name, vel.color, Vector2(822.0, Fighter.GROUND_Y), vel.texture)
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


func _create_character_select_menu() -> void:
	character_select_layer = CanvasLayer.new()
	character_select_layer.layer = 11
	character_select_layer.visible = false
	add_child(character_select_layer)

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = SCREEN_SIZE
	backdrop.color = Color(0.012, 0.027, 0.043, 0.95)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_select_layer.add_child(backdrop)

	var header_line := ColorRect.new()
	header_line.position = Vector2(112.0, 88.0)
	header_line.size = Vector2(928.0, 2.0)
	header_line.color = Color("3a8ca0")
	header_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_select_layer.add_child(header_line)

	var title := Label.new()
	title.position = Vector2(226.0, 28.0)
	title.size = Vector2(700.0, 58.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "SELECT YOUR FIGHTER"
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("fff3c4"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_select_layer.add_child(title)

	character_prompt_label = Label.new()
	character_prompt_label.position = Vector2(176.0, 98.0)
	character_prompt_label.size = Vector2(800.0, 42.0)
	character_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_prompt_label.add_theme_font_size_override("font_size", 20)
	character_prompt_label.add_theme_color_override("font_color", Color("91ddea"))
	character_prompt_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_select_layer.add_child(character_prompt_label)

	var card_positions := [Vector2(128.0, 148.0), Vector2(612.0, 148.0)]
	for index in CHARACTER_ROSTER.size():
		var card := _make_character_card(index, card_positions[index])
		character_buttons.append(card)
		character_select_layer.add_child(card)

	var versus_mark := Label.new()
	versus_mark.position = Vector2(526.0, 298.0)
	versus_mark.size = Vector2(100.0, 64.0)
	versus_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	versus_mark.text = "VS"
	versus_mark.add_theme_font_size_override("font_size", 34)
	versus_mark.add_theme_color_override("font_color", Color("fff3c4"))
	versus_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_select_layer.add_child(versus_mark)

	character_summary_label = Label.new()
	character_summary_label.position = Vector2(126.0, 538.0)
	character_summary_label.size = Vector2(900.0, 32.0)
	character_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_summary_label.add_theme_font_size_override("font_size", 18)
	character_summary_label.add_theme_color_override("font_color", Color("d8f7ff"))
	character_summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_select_layer.add_child(character_summary_label)

	character_hint_label = Label.new()
	character_hint_label.position = Vector2(126.0, 578.0)
	character_hint_label.size = Vector2(900.0, 44.0)
	character_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_hint_label.add_theme_font_size_override("font_size", 15)
	character_hint_label.add_theme_color_override("font_color", Color("91acb7"))
	character_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_select_layer.add_child(character_hint_label)


func _make_character_card(index: int, card_position: Vector2) -> Button:
	var character_data: Dictionary = CHARACTER_ROSTER[index]
	var accent: Color = character_data["color"]
	var card := Button.new()
	card.position = card_position
	card.size = Vector2(412.0, 374.0)
	card.focus_mode = Control.FOCUS_NONE
	card.clip_contents = true
	card.tooltip_text = "Select %s" % str(character_data["name"])
	card.add_theme_stylebox_override("normal", _make_button_style(Color("0d1c26"), Color("31505a"), 2))
	card.add_theme_stylebox_override("hover", _make_button_style(Color("132b36"), accent, 4))
	card.add_theme_stylebox_override("pressed", _make_button_style(Color("193944"), Color("fff3c4"), 4))
	card.add_theme_stylebox_override("focus", _make_button_style(Color("132b36"), accent, 4))
	card.pressed.connect(_on_character_card_pressed.bind(index))

	var color_bar := ColorRect.new()
	color_bar.position = Vector2(0.0, 0.0)
	color_bar.size = Vector2(8.0, card.size.y)
	color_bar.color = accent
	color_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(color_bar)

	var portrait := TextureRect.new()
	portrait.position = Vector2(76.0, 14.0)
	portrait.size = Vector2(260.0, 258.0)
	portrait.texture = character_data["texture"] as Texture2D
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(portrait)

	var name_label := Label.new()
	name_label.position = Vector2(22.0, 268.0)
	name_label.size = Vector2(368.0, 48.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = str(character_data["name"])
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", Color("fff3c4"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	var title_label := Label.new()
	title_label.position = Vector2(22.0, 310.0)
	title_label.size = Vector2(368.0, 26.0)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.text = str(character_data["title"])
	title_label.add_theme_font_size_override("font_size", 14)
	title_label.add_theme_color_override("font_color", accent.lightened(0.25))
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(title_label)

	var status_label := Label.new()
	status_label.position = Vector2(22.0, 340.0)
	status_label.size = Vector2(368.0, 26.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 14)
	status_label.add_theme_color_override("font_color", Color("91acb7"))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(status_label)
	character_status_labels.append(status_label)
	return card


func _show_character_select(selected_mode: StringName) -> void:
	phase = &"character_select"
	game_mode = selected_mode
	position = Vector2.ZERO
	menu_layer.visible = false
	character_select_layer.visible = true
	announcement_label.visible = false
	subtitle_label.visible = false
	mode_label.visible = false
	training_label.visible = false
	selecting_player = 0
	character_selection = [0, 1]
	for fighter in fighters:
		fighter.visible = false
		fighter.clear_input()
	_refresh_character_select()
	queue_redraw()


func _refresh_character_select() -> void:
	if game_mode == MODE_SOLO:
		character_selection[1] = (character_selection[0] + 1) % CHARACTER_ROSTER.size()
		character_prompt_label.text = "PLAYER 1  -  CHOOSE YOUR FIGHTER"
		character_hint_label.text = "A / D OR LEFT / RIGHT: CHOOSE    ENTER / SPACE / F: CONFIRM    ESC: BACK"
	else:
		character_prompt_label.text = "PLAYER %d  -  CHOOSE YOUR FIGHTER" % (selecting_player + 1)
		character_hint_label.text = (
			"A / D OR LEFT / RIGHT: CHOOSE    ENTER / SPACE / F: CONFIRM    ESC: BACK"
			if selecting_player == 0
			else "LEFT / RIGHT OR A / D: CHOOSE    ENTER / SPACE / J: CONFIRM    ESC: BACK"
		)

	for index in CHARACTER_ROSTER.size():
		var character_data: Dictionary = CHARACTER_ROSTER[index]
		var accent: Color = character_data["color"]
		var is_current: bool = character_selection[selecting_player] == index
		var is_p1_locked: bool = (
			game_mode == MODE_VERSUS
			and selecting_player == 1
			and character_selection[0] == index
		)
		var fill := Color("0d1c26").lerp(accent.darkened(0.55), 0.18 if is_current else 0.06)
		var border := Color("fff3c4") if is_current else Color("31505a")
		var width := 5 if is_current else 2
		character_buttons[index].add_theme_stylebox_override("normal", _make_button_style(fill, border, width))
		character_buttons[index].add_theme_stylebox_override(
			"hover",
			_make_button_style(fill.lightened(0.07), Color("fff3c4") if is_current else accent, 5 if is_current else 4)
		)
		if is_p1_locked and is_current:
			character_status_labels[index].text = "P1 LOCKED  /  P2 SELECTED"
		elif is_p1_locked:
			character_status_labels[index].text = "P1 LOCKED"
		elif is_current:
			character_status_labels[index].text = "P%d SELECTED" % (selecting_player + 1)
		else:
			character_status_labels[index].text = "CHOOSE"
		character_status_labels[index].add_theme_color_override(
			"font_color",
			Color("fff3c4") if is_current else accent.lightened(0.2)
		)

	var p1_data: Dictionary = CHARACTER_ROSTER[character_selection[0]]
	var p2_data: Dictionary = CHARACTER_ROSTER[character_selection[1]]
	var opponent_label := "CPU" if game_mode == MODE_SOLO else "P2"
	character_summary_label.text = "P1  %s        VS        %s  %s" % [
		str(p1_data["name"]),
		opponent_label,
		str(p2_data["name"])
	]


func _handle_character_select_input() -> void:
	var left_pressed := _key_just_pressed(KEY_LEFT)
	left_pressed = _key_just_pressed(KEY_A) or left_pressed
	var right_pressed := _key_just_pressed(KEY_RIGHT)
	right_pressed = _key_just_pressed(KEY_D) or right_pressed
	var confirm_pressed := _key_just_pressed(KEY_ENTER)
	confirm_pressed = _key_just_pressed(KEY_SPACE) or confirm_pressed
	if selecting_player == 0:
		confirm_pressed = _key_just_pressed(KEY_F) or confirm_pressed
	else:
		confirm_pressed = _key_just_pressed(KEY_J) or confirm_pressed

	if left_pressed:
		character_selection[selecting_player] = wrapi(
			character_selection[selecting_player] - 1,
			0,
			CHARACTER_ROSTER.size()
		)
		_refresh_character_select()
	elif right_pressed:
		character_selection[selecting_player] = wrapi(
			character_selection[selecting_player] + 1,
			0,
			CHARACTER_ROSTER.size()
		)
		_refresh_character_select()

	if confirm_pressed:
		_confirm_character_selection()


func _on_character_card_pressed(index: int) -> void:
	character_selection[selecting_player] = index
	_refresh_character_select()
	_confirm_character_selection()


func _confirm_character_selection() -> void:
	if game_mode == MODE_SOLO:
		_start_match(game_mode)
		return
	if selecting_player == 0:
		selecting_player = 1
		character_selection[1] = (character_selection[0] + 1) % CHARACTER_ROSTER.size()
		_refresh_character_select()
		return
	_start_match(game_mode)


func _physics_process(_delta: float) -> void:
	_handle_system_input()
	if phase == &"menu" or phase == &"character_select":
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
		for fighter in fighters:
			fighter.clear_action_buffer()
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
		_spawn_pending_projectiles()
		_update_projectiles()
		_resolve_body_collision()
		_resolve_attacks()
		_resolve_projectiles()
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
	if phase == &"character_select":
		var back_pressed := _key_just_pressed(KEY_M)
		back_pressed = _key_just_pressed(KEY_ESCAPE) or back_pressed
		if back_pressed:
			_show_mode_menu()
		else:
			_handle_character_select_input()
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
			for fighter in fighters:
				fighter.reset_match_resources()
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
	projectiles.clear()
	training_visible = false
	training_label.visible = false
	announcement_label.visible = false
	subtitle_label.visible = false
	mode_label.visible = false
	menu_layer.visible = true
	character_select_layer.visible = false
	mode_selection = 0
	for fighter in fighters:
		fighter.visible = false
		fighter.clear_input()
		fighter.set_debug_boxes(false)
	_update_mode_selection()
	queue_redraw()


func _update_mode_selection() -> void:
	if mode_selection == 0:
		solo_button.grab_focus()
	else:
		versus_button.grab_focus()


func _start_solo_mode() -> void:
	_show_character_select(MODE_SOLO)


func _start_versus_mode() -> void:
	_show_character_select(MODE_VERSUS)


func _start_match(selected_mode: StringName) -> void:
	game_mode = selected_mode
	menu_layer.visible = false
	character_select_layer.visible = false
	announcement_label.visible = true
	subtitle_label.visible = true
	mode_label.visible = true
	for fighter in fighters:
		fighter.visible = true

	for index in fighters.size():
		var character_data: Dictionary = CHARACTER_ROSTER[character_selection[index]]
		fighters[index].configure_character(
			StringName(character_data["id"]),
			str(character_data["name"]),
			character_data["color"],
			character_data["texture"] as Texture2D
		)
		fighters[index].reset_match_resources()
	wins = [0, 0]
	round_number = 1
	training_visible = false
	training_label.visible = false
	cpu_controller.reset()
	_invalidate_hud_cache()
	_start_round()


func _start_round() -> void:
	phase = &"intro"
	phase_frames = 120
	round_frames = ROUND_SECONDS * 60
	global_hitstop = 0
	hit_sparks.clear()
	projectiles.clear()
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
	projectiles.clear()
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
		if defender.is_invulnerable():
			continue
		if not attacker.attack_rect().intersects(defender.hurt_rect()):
			continue

		var attack_data := attacker.current_attack()
		if bool(attack_data.get("grab", false)) and not defender.can_be_grabbed():
			continue
		attacker.mark_attack_connected()
		var forced_push_direction := 0.0
		if bool(attack_data.get("back_throw", false)):
			forced_push_direction = _perform_back_throw(attacker, defender)
		_apply_attack_hit(
			attacker,
			defender,
			attack_data,
			attacker.position.x,
			forced_push_direction,
			defender.hurt_rect().get_center()
		)
		break


func _spawn_pending_projectiles() -> void:
	for fighter in fighters:
		var projectile_data := fighter.take_projectile_request()
		if not projectile_data.is_empty():
			projectiles.append(projectile_data)


func _update_projectiles() -> void:
	for index in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[index]
		projectile.frames = int(projectile.frames) - 1
		projectile.position += projectile.velocity / 60.0
		if (
			int(projectile.frames) <= 0
			or projectile.position.x < Fighter.ARENA_LEFT - 50.0
			or projectile.position.x > Fighter.ARENA_RIGHT + 50.0
		):
			projectiles.remove_at(index)


func _resolve_projectiles() -> void:
	for index in range(projectiles.size() - 1, -1, -1):
		var projectile: Dictionary = projectiles[index]
		var owner_id := int(projectile.owner_id)
		var owner := fighters[owner_id]
		var defender := fighters[1 - owner_id]
		if defender.is_invulnerable():
			continue
		var radius := float(projectile.radius)
		var projectile_rect := Rect2(projectile.position - Vector2.ONE * radius, Vector2.ONE * radius * 2.0)
		if not projectile_rect.intersects(defender.hurt_rect()):
			continue
		var attack_data: Dictionary = projectile.attack
		projectiles.remove_at(index)
		_apply_attack_hit(
			owner,
			defender,
			attack_data,
			float(projectile.position.x),
			0.0,
			projectile.position
		)
		if phase != &"fight":
			return


func _apply_attack_hit(
	attacker: Fighter,
	defender: Fighter,
	attack_data: Dictionary,
	attacker_x: float,
	forced_push_direction: float,
	spark_position: Vector2
) -> void:
	var result := defender.receive_attack(attack_data, attacker_x, forced_push_direction)
	var meter_gain := int(attack_data.get("meter_block", 0)) if result.blocked else int(attack_data.get("meter_hit", 0))
	attacker.gain_meter(meter_gain)
	defender.gain_meter(3 if result.blocked else 6)
	global_hitstop = result.hitstop
	screen_shake = 9.0 if bool(attack_data.get("super", false)) else (8.0 if not result.blocked else 3.0)
	hit_sparks.append({
		"position": spark_position,
		"frames": 16 if bool(attack_data.get("super", false)) else 12,
		"blocked": result.blocked,
		"color": attacker.body_color.lightened(0.35)
	})
	if result.back_throw:
		announcement_sub = "BACK THROW"
		combat_callout_frames = 60
	elif result.combo > 1 and not result.blocked:
		announcement_sub = "%d HIT COMBO" % result.combo
		combat_callout_frames = 45
	elif bool(attack_data.get("super", false)):
		announcement_sub = str(attack_data.get("label", "SUPER"))
		combat_callout_frames = 60
	if result.ko:
		_finish_round()


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
	else:
		_set_label_text_if_changed(mode_label, "2 PLAYERS  •  LOCAL VERSUS")
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


func _invalidate_hud_cache() -> void:
	last_drawn_p1_health = -1
	last_drawn_p2_health = -1
	last_drawn_timer = -1
	last_drawn_p1_wins = -1
	last_drawn_p2_wins = -1
	last_drawn_spark_count = -1
	last_drawn_p1_meter = -1
	last_drawn_p2_meter = -1
	last_drawn_projectile_count = -1
	queue_redraw()


func _request_hud_redraw() -> void:
	var timer_seconds := ceili(float(round_frames) / 60.0)
	var effects_need_animation := not hit_sparks.is_empty() or not projectiles.is_empty()
	var hud_changed: bool = (
		last_drawn_p1_health != fighters[0].health
		or last_drawn_p2_health != fighters[1].health
		or last_drawn_timer != timer_seconds
		or last_drawn_p1_wins != wins[0]
		or last_drawn_p2_wins != wins[1]
		or last_drawn_spark_count != hit_sparks.size()
		or last_drawn_p1_meter != fighters[0].meter
		or last_drawn_p2_meter != fighters[1].meter
		or last_drawn_projectile_count != projectiles.size()
	)
	if not hud_changed and not effects_need_animation:
		return

	last_drawn_p1_health = fighters[0].health
	last_drawn_p2_health = fighters[1].health
	last_drawn_timer = timer_seconds
	last_drawn_p1_wins = wins[0]
	last_drawn_p2_wins = wins[1]
	last_drawn_spark_count = hit_sparks.size()
	last_drawn_p1_meter = fighters[0].meter
	last_drawn_p2_meter = fighters[1].meter
	last_drawn_projectile_count = projectiles.size()
	queue_redraw()


func _draw() -> void:
	if phase == &"menu" or phase == &"character_select":
		return

	# Health and round HUD.
	draw_rect(Rect2(48, 40, 450, 34), Color("101820"), true)
	draw_rect(Rect2(654, 40, 450, 34), Color("101820"), true)
	var p1_width := 442.0 * float(fighters[0].health) / 1000.0
	var p2_width := 442.0 * float(fighters[1].health) / 1000.0
	var p1_color := fighters[0].body_color
	var p2_color := fighters[1].body_color
	var p1_accent := fighters[0].accent_color
	var p2_accent := fighters[1].accent_color
	draw_rect(Rect2(52, 44, p1_width, 26), p1_color, true)
	draw_rect(Rect2(1100.0 - p2_width, 44, p2_width, 26), p2_color, true)
	draw_rect(Rect2(48, 40, 450, 34), p1_accent, false, 2.0)
	draw_rect(Rect2(654, 40, 450, 34), p2_accent, false, 2.0)

	# Super meters fill toward the center of the screen.
	draw_rect(Rect2(48, 80, 450, 10), Color("101820"), true)
	draw_rect(Rect2(654, 80, 450, 10), Color("101820"), true)
	var p1_meter_width := 446.0 * float(fighters[0].meter) / float(Fighter.MAX_METER)
	var p2_meter_width := 446.0 * float(fighters[1].meter) / float(Fighter.MAX_METER)
	var p1_meter_color := Color("ffd45e") if fighters[0].meter >= Fighter.MAX_METER else p1_color.lightened(0.2)
	var p2_meter_color := Color("ffd45e") if fighters[1].meter >= Fighter.MAX_METER else p2_color.lightened(0.2)
	draw_rect(Rect2(50, 82, p1_meter_width, 6), p1_meter_color, true)
	draw_rect(Rect2(1102.0 - p2_meter_width, 82, p2_meter_width, 6), p2_meter_color, true)
	draw_rect(Rect2(48, 80, 450, 10), p1_accent, false, 1.0)
	draw_rect(Rect2(654, 80, 450, 10), p2_accent, false, 1.0)

	var font := ThemeDB.fallback_font
	if fighters[0].meter >= Fighter.MAX_METER:
		draw_string(font, Vector2(50, 89), "SUPER READY", HORIZONTAL_ALIGNMENT_RIGHT, 446, 9, Color("2a210b"))
	if fighters[1].meter >= Fighter.MAX_METER:
		draw_string(font, Vector2(656, 89), "SUPER READY", HORIZONTAL_ALIGNMENT_LEFT, 446, 9, Color("2a210b"))
	draw_string(font, Vector2(50, 111), fighters[0].fighter_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, p1_accent)
	draw_string(font, Vector2(654, 111), fighters[1].fighter_name, HORIZONTAL_ALIGNMENT_RIGHT, 448, 19, p2_accent)
	var timer_text := "%02d" % ceili(float(round_frames) / 60.0)
	draw_string(font, Vector2(516, 76), timer_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 36, Color("fff3c4"))
	for i in wins[0]:
		draw_circle(Vector2(68.0 + i * 24.0, 126.0), 8.0, Color("fff3c4"))
	for i in wins[1]:
		draw_circle(Vector2(1084.0 - i * 24.0, 126.0), 8.0, Color("fff3c4"))

	for projectile in projectiles:
		var projectile_color: Color = projectile.color
		var projectile_position: Vector2 = projectile.position
		var projectile_radius := float(projectile.radius)
		draw_circle(projectile_position, projectile_radius + 9.0, Color(projectile_color, 0.12))
		draw_circle(projectile_position, projectile_radius, Color(projectile_color.lightened(0.38), 0.88))
		draw_arc(projectile_position, projectile_radius + 4.0, 0.0, TAU, 22, Color("d9fbff"), 3.0, true)
		for trail in 3:
			var trail_length := 22.0 + trail * 12.0
			var trail_direction := -signf(float(projectile.velocity.x))
			draw_line(
				projectile_position + Vector2(trail_direction * 12.0, (trail - 1) * 7.0),
				projectile_position + Vector2(trail_direction * trail_length, (trail - 1) * 7.0),
				Color(projectile_color, 0.55 - trail * 0.12),
				4.0 - trail * 0.6,
				true
			)

	for spark in hit_sparks:
		var spark_color := Color("8defff") if spark.blocked else Color(spark.get("color", Color("fff19a")))
		var radius := float(spark.frames) * 2.5
		for ray in 8:
			var angle := TAU * float(ray) / 8.0
			draw_line(spark.position, spark.position + Vector2.from_angle(angle) * radius, spark_color, 4.0)
		draw_circle(spark.position, radius * 0.28, spark_color)
