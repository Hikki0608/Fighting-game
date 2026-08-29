extends Node2D

const FighterScene := preload("res://scripts/fighter.gd")
const CpuControllerScript := preload("res://scripts/cpu_controller.gd")
const MenuBackdropScript := preload("res://scripts/menu_backdrop.gd")
const ArenaAmbienceScript := preload("res://scripts/arena_ambience.gd")
const CombatEffectsScript := preload("res://scripts/combat_effects.gd")
const ArenaBackgroundTexture := preload("res://assets/arena_background.svg")
const TrainingStageTexture := preload("res://assets/training_stage.svg")
const RenFighterTexture := preload("res://assets/characters/ren_fighter.png")
const RenBasicSpriteSheet := preload("res://assets/characters/ren_basic_sprites_v1.png")
const RenGroundSpriteSheet := preload("res://assets/characters/ren_ground_sprites_v1.png")
const RenAirSpecialSpriteSheet := preload("res://assets/characters/ren_air_special_sprites_v1.png")
const RenSpecialSpriteSheet := preload("res://assets/characters/ren_special_sprites_v1.png")
const RenReactionSpriteSheet := preload("res://assets/characters/ren_reaction_sprites_v1.png")
const VelFighterTexture := preload("res://assets/characters/vel_fighter.png")
const VelBasicSpriteSheet := preload("res://assets/characters/vel_basic_sprites_v1.png")
const VelGroundSpriteSheet := preload("res://assets/characters/vel_ground_sprites_v1.png")
const VelAirSpecialSpriteSheet := preload("res://assets/characters/vel_air_special_sprites_v1.png")
const VelSpecialSpriteSheet := preload("res://assets/characters/vel_special_sprites_v1.png")
const VelReactionSpriteSheet := preload("res://assets/characters/vel_reaction_sprites_v1.png")
const SCREEN_SIZE := Vector2(1152.0, 648.0)
const SUPER_METER_SIZE := Vector2(144.0, 18.0)
const SUPER_METER_MARGIN := Vector2(48.0, 26.0)
const SUPER_METER_INSET := 3.0
const REN_EFFECT_CORE := Color("efffff")
const REN_EFFECT_LIGHT := Color("7defff")
const REN_EFFECT_BLUE := Color("209cff")
const REN_EFFECT_DEEP := Color("3151e8")
const ARENA_CENTER_X := Fighter.ARENA_WIDTH * 0.5
const CAMERA_HALF_WIDTH := SCREEN_SIZE.x * 0.5
const CAMERA_DEAD_ZONE := 28.0
const CAMERA_FOLLOW_WEIGHT := 0.14
const CAMERA_FIGHTER_MARGIN := Fighter.VISUAL_SIZE * 0.5 + 8.0
const CAMERA_MIN_ZOOM := 1.0
const CAMERA_MAX_ZOOM := 1.14
const CAMERA_ZOOM_NEAR_DISTANCE := 300.0
const CAMERA_ZOOM_FAR_DISTANCE := 820.0
const CAMERA_ZOOM_FOLLOW_WEIGHT := 0.08
const HITSTOP_TIME_SCALE := 0.7
const ROUND_START_DISTANCE := 492.0
const ROUND_SECONDS := 99
const ROUNDS_TO_WIN := 2
const MODE_SOLO: StringName = &"solo"
const MODE_VERSUS: StringName = &"versus"
const MODE_TRAINING: StringName = &"training"
const STAGE_ROYAL_COLOSSEUM := 0
const STAGE_TRAINING_GRID := 1
const STAGE_ROSTER := [
	{
		"id": &"royal_colosseum",
		"name": "ROYAL COLOSSEUM",
		"subtitle": "CROWN OF THE GRAND ARENA",
		"description": "A royal arena of banners, fire and a roaring crowd.",
		"texture": ArenaBackgroundTexture,
		"accent": Color("f5d77a")
	},
	{
		"id": &"training_grid",
		"name": "TRAINING GRID",
		"subtitle": "FRAME MEASUREMENT LAB",
		"description": "A neutral grid with clear center and distance guides.",
		"texture": TrainingStageTexture,
		"accent": Color("ef3340")
	}
]
const MODE_MENU_DETAILS := [
	"ENTER THE ARENA AGAINST A TACTICAL CPU",
	"LOCAL DUEL  •  KEYBOARD + GAMEPAD",
	"PRACTICE COMBOS WITH INFINITE RESOURCES"
]
const MODE_MENU_ACCENTS := [Color("2cccf4"), Color("f5d77a"), Color("ff4f86")]
const TRAINING_GUARD_OFF := 0
const TRAINING_GUARD_AFTER_HIT := 1
const TRAINING_GUARD_ALWAYS := 2
const TRAINING_HEALTH_RECOVERY_FRAMES := 45
const TRAINING_GUARD_RELEASE_FRAMES := 45
const TRAINING_INPUT_HISTORY_SIZE := 8
const CHARACTER_ROSTER := [
	{
		"id": &"ren",
		"name": "REN",
		"title": "AZURE TACTICIAN",
		"color": Color("2cccf4"),
		"texture": RenFighterTexture,
		"animation_textures": [
			RenBasicSpriteSheet,
			RenGroundSpriteSheet,
			RenAirSpecialSpriteSheet,
			RenSpecialSpriteSheet,
			RenReactionSpriteSheet
		]
	},
	{
		"id": &"vel",
		"name": "VEL",
		"title": "CRIMSON HUNTER",
		"color": Color("ff4f86"),
		"texture": VelFighterTexture,
		"animation_textures": [
			VelBasicSpriteSheet,
			VelGroundSpriteSheet,
			VelAirSpecialSpriteSheet,
			VelSpecialSpriteSheet,
			VelReactionSpriteSheet
		]
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
var stage_selection := STAGE_ROYAL_COLOSSEUM
var character_selection := [0, 1]
var selecting_player := 0
var cpu_controller: CpuController
var meta_key_state := {}
var training_guard_mode := TRAINING_GUARD_OFF
var training_guard_armed := false
var training_guard_release_frames := 0
var training_combo_active := false
var training_current_hits := 0
var training_current_damage := 0
var training_last_hits := 0
var training_last_damage := 0
var training_best_hits := 0
var training_best_damage := 0
var training_health_recovery_frames := 0
var training_input_history: Array[String] = []
var training_previous_axis := Vector2.ZERO
var camera_center_x := ARENA_CENTER_X
var camera_zoom := CAMERA_MIN_ZOOM
var camera_shake_offset := Vector2.ZERO

var world_root: Node2D
var arena_backgrounds: Array[Sprite2D] = []
var arena_ambience: ArenaAmbience
var combat_effects: CombatEffects
var announcement_label: Label
var subtitle_label: Label
var combo_labels: Array[Label] = []
var training_label: Label
var training_hud_label: Label
var training_input_label: Label
var mode_label: Label
var menu_layer: CanvasLayer
var menu_backdrop: Control
var menu_title_label: Label
var menu_selection_marker: Label
var menu_mode_index_label: Label
var menu_mode_description_label: Label
var menu_detail_panel: Panel
var menu_portraits: Array[TextureRect] = []
var menu_portrait_base_positions: Array[Vector2] = []
var menu_animation_time := 0.0
var stage_select_layer: CanvasLayer
var stage_mode_label: Label
var stage_summary_label: Label
var stage_hint_label: Label
var stage_buttons: Array[Button] = []
var stage_status_labels: Array[Label] = []
var character_select_layer: CanvasLayer
var solo_button: Button
var versus_button: Button
var training_button: Button
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
var last_drawn_p1_meter := -1
var last_drawn_p2_meter := -1
var last_drawn_screen_effect_active := false


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("071018"))
	cpu_controller = CpuControllerScript.new() as CpuController
	_create_world_root()
	_create_arena_background()
	_create_fighters()
	_create_combat_effects()
	_create_ui()
	_create_mode_menu()
	_create_stage_select_menu()
	_create_character_select_menu()
	_initialize_fullscreen_support()
	_show_mode_menu()
	_request_hud_redraw()


func _create_world_root() -> void:
	world_root = Node2D.new()
	world_root.name = "World"
	# Keep the complete stage layer below the screen-space HUD. The dedicated
	# combat-effect child is added after the fighters so its cached draw list
	# remains above their sprites without forcing the HUD to rebuild.
	world_root.z_index = -1
	add_child(world_root)


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
	# Keep the original artwork undistorted in the middle of the arena. Mirrored
	# copies extend both sides so scrolling never exposes an empty area.
	for tile_index in range(-1, 2):
		var background := Sprite2D.new()
		background.name = "ArenaBackground%d" % (tile_index + 2)
		background.texture = ArenaBackgroundTexture
		background.position = Vector2(
			ARENA_CENTER_X + float(tile_index) * SCREEN_SIZE.x,
			SCREEN_SIZE.y * 0.5
		)
		background.flip_h = tile_index != 0
		background.z_index = -100
		background.show_behind_parent = true
		background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		world_root.add_child(background)
		arena_backgrounds.append(background)
	arena_ambience = ArenaAmbienceScript.new() as ArenaAmbience
	arena_ambience.name = "ArenaAmbience"
	arena_ambience.z_index = -90
	arena_ambience.configure(ARENA_CENTER_X)
	world_root.add_child(arena_ambience)
	_apply_selected_stage()
	_apply_world_transform()


func _apply_selected_stage() -> void:
	var stage_data: Dictionary = STAGE_ROSTER[stage_selection]
	var stage_texture := stage_data["texture"] as Texture2D
	for background in arena_backgrounds:
		background.texture = stage_texture

	if arena_ambience != null:
		var uses_arena_ambience := stage_selection == STAGE_ROYAL_COLOSSEUM
		arena_ambience.visible = uses_arena_ambience
		arena_ambience.set_process(uses_arena_ambience)


func _create_fighters() -> void:
	var p1 := FighterScene.new() as Fighter
	var p2 := FighterScene.new() as Fighter
	world_root.add_child(p1)
	world_root.add_child(p2)
	var ren: Dictionary = CHARACTER_ROSTER[0]
	var vel: Dictionary = CHARACTER_ROSTER[1]
	p1.setup(
		0,
		ren.name,
		ren.color,
		_round_spawn_position(0),
		ren.texture,
		ren.animation_textures
	)
	p2.setup(
		1,
		vel.name,
		vel.color,
		_round_spawn_position(1),
		vel.texture,
		vel.animation_textures
	)
	fighters = [p1, p2]


func _create_combat_effects() -> void:
	combat_effects = CombatEffectsScript.new() as CombatEffects
	combat_effects.name = "CombatEffects"
	combat_effects.configure(projectiles, hit_sparks)
	# This child is added after the fighters, so its world-space effects render
	# above them while the parent HUD remains on the higher canvas layer.
	world_root.add_child(combat_effects)


func _round_spawn_position(player_index: int) -> Vector2:
	var side := -0.5 if player_index == 0 else 0.5
	return Vector2(ARENA_CENTER_X + ROUND_START_DISTANCE * side, Fighter.GROUND_Y)


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

	for player_index in 2:
		var combo_label := Label.new()
		combo_label.position = Vector2(42.0 if player_index == 0 else 770.0, 282.0)
		combo_label.size = Vector2(340.0, 44.0)
		combo_label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_LEFT
			if player_index == 0
			else HORIZONTAL_ALIGNMENT_RIGHT
		)
		combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		combo_label.add_theme_font_size_override("font_size", 22)
		combo_label.add_theme_color_override(
			"font_color",
			fighters[player_index].body_color.lightened(0.35)
		)
		combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		combo_label.add_theme_constant_override("shadow_offset_x", 2)
		combo_label.add_theme_constant_override("shadow_offset_y", 2)
		combo_label.visible = false
		add_child(combo_label)
		combo_labels.append(combo_label)

	mode_label = Label.new()
	mode_label.position = Vector2(426.0, 8.0)
	mode_label.size = Vector2(300.0, 24.0)
	mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mode_label.add_theme_font_size_override("font_size", 13)
	mode_label.add_theme_color_override("font_color", Color("91acb7"))
	add_child(mode_label)

	training_label = Label.new()
	training_label.position = Vector2(18.0, 290.0)
	training_label.size = Vector2(480.0, 98.0)
	training_label.add_theme_font_size_override("font_size", 13)
	training_label.add_theme_color_override("font_color", Color("d9f7ff"))
	training_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	training_label.add_theme_constant_override("shadow_offset_x", 2)
	training_label.add_theme_constant_override("shadow_offset_y", 2)
	training_label.visible = false
	add_child(training_label)

	training_hud_label = Label.new()
	training_hud_label.position = Vector2(18.0, 128.0)
	training_hud_label.size = Vector2(324.0, 146.0)
	training_hud_label.add_theme_font_size_override("font_size", 13)
	training_hud_label.add_theme_color_override("font_color", Color("d9f7ff"))
	training_hud_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	training_hud_label.add_theme_constant_override("shadow_offset_x", 1)
	training_hud_label.add_theme_constant_override("shadow_offset_y", 1)
	training_hud_label.add_theme_stylebox_override("normal", _make_training_panel_style(Color("2cccf4")))
	training_hud_label.visible = false
	add_child(training_hud_label)

	training_input_label = Label.new()
	training_input_label.position = Vector2(890.0, 128.0)
	training_input_label.size = Vector2(244.0, 194.0)
	training_input_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	training_input_label.add_theme_font_size_override("font_size", 13)
	training_input_label.add_theme_color_override("font_color", Color("d9f7ff"))
	training_input_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	training_input_label.add_theme_constant_override("shadow_offset_x", 1)
	training_input_label.add_theme_constant_override("shadow_offset_y", 1)
	training_input_label.add_theme_stylebox_override("normal", _make_training_panel_style(Color("ff4f86")))
	training_input_label.visible = false
	add_child(training_input_label)


func _create_mode_menu() -> void:
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 10
	add_child(menu_layer)

	menu_backdrop = MenuBackdropScript.new() as Control
	menu_backdrop.position = Vector2.ZERO
	menu_backdrop.size = SCREEN_SIZE
	menu_layer.add_child(menu_backdrop)

	_add_menu_portrait(
		RenFighterTexture,
		Vector2(-52.0, 114.0),
		Vector2(446.0, 522.0),
		Color("2cccf4")
	)
	_add_menu_portrait(
		VelFighterTexture,
		Vector2(758.0, 114.0),
		Vector2(446.0, 522.0),
		Color("ff4f86")
	)

	var brand_kicker := Label.new()
	brand_kicker.position = Vector2(376.0, 20.0)
	brand_kicker.size = Vector2(400.0, 22.0)
	brand_kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brand_kicker.text = "FB // GRAND ARENA SYSTEM"
	brand_kicker.add_theme_font_size_override("font_size", 12)
	brand_kicker.add_theme_color_override("font_color", Color("91ddea"))
	brand_kicker.add_theme_constant_override("letter_spacing", 3)
	menu_layer.add_child(brand_kicker)

	menu_title_label = Label.new()
	menu_title_label.position = Vector2(176.0, 39.0)
	menu_title_label.size = Vector2(800.0, 64.0)
	menu_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_title_label.text = "FRAMEBREAK"
	menu_title_label.add_theme_font_size_override("font_size", 54)
	menu_title_label.add_theme_color_override("font_color", Color("fff3c4"))
	menu_title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.04, 0.96))
	menu_title_label.add_theme_constant_override("outline_size", 8)
	menu_title_label.add_theme_color_override("font_shadow_color", Color("b87428", 0.55))
	menu_title_label.add_theme_constant_override("shadow_offset_x", 0)
	menu_title_label.add_theme_constant_override("shadow_offset_y", 5)
	menu_layer.add_child(menu_title_label)

	var subtitle := Label.new()
	subtitle.position = Vector2(326.0, 103.0)
	subtitle.size = Vector2(500.0, 24.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = "FIGHT BEYOND THE FRAME"
	subtitle.add_theme_font_size_override("font_size", 13)
	subtitle.add_theme_color_override("font_color", Color("d8edf1"))
	subtitle.add_theme_constant_override("letter_spacing", 5)
	menu_layer.add_child(subtitle)

	_add_menu_rule(Vector2(132.0, 92.0), Vector2(290.0, 2.0), Color("2cccf4"))
	_add_menu_rule(Vector2(730.0, 92.0), Vector2(290.0, 2.0), Color("ff4f86"))

	var menu_panel := Panel.new()
	menu_panel.position = Vector2(344.0, 150.0)
	menu_panel.size = Vector2(464.0, 346.0)
	menu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_panel.add_theme_stylebox_override("panel", _make_menu_panel_style())
	menu_layer.add_child(menu_panel)

	var section_label := Label.new()
	section_label.position = Vector2(376.0, 163.0)
	section_label.size = Vector2(400.0, 34.0)
	section_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	section_label.text = "CHOOSE YOUR BATTLE"
	section_label.add_theme_font_size_override("font_size", 20)
	section_label.add_theme_color_override("font_color", Color("fff3c4"))
	section_label.add_theme_constant_override("letter_spacing", 2)
	menu_layer.add_child(section_label)

	solo_button = _make_mode_button(
		"01   SOLO BATTLE",
		Vector2(366.0, 204.0),
		Vector2(420.0, 62.0),
		18,
		true,
		"VS CPU",
		MODE_MENU_ACCENTS[0]
	)
	versus_button = _make_mode_button(
		"02   VERSUS",
		Vector2(366.0, 278.0),
		Vector2(420.0, 62.0),
		18,
		true,
		"LOCAL DUEL",
		MODE_MENU_ACCENTS[1]
	)
	training_button = _make_mode_button(
		"03   TRAINING",
		Vector2(366.0, 352.0),
		Vector2(420.0, 62.0),
		18,
		true,
		"FREE PRACTICE",
		MODE_MENU_ACCENTS[2]
	)
	fullscreen_button = _make_mode_button(
		"◇   FULLSCREEN   •   ALT + ENTER",
		Vector2(446.0, 516.0),
		Vector2(260.0, 42.0),
		13,
		false,
		"",
		Color("668e9a")
	)
	solo_button.pressed.connect(_start_solo_mode)
	versus_button.pressed.connect(_start_versus_mode)
	training_button.pressed.connect(_start_training_mode)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	solo_button.mouse_entered.connect(_on_mode_button_hovered.bind(0))
	versus_button.mouse_entered.connect(_on_mode_button_hovered.bind(1))
	training_button.mouse_entered.connect(_on_mode_button_hovered.bind(2))
	fullscreen_button.tooltip_text = "Toggle fullscreen (Alt + Enter)"
	menu_layer.add_child(solo_button)
	menu_layer.add_child(versus_button)
	menu_layer.add_child(training_button)
	menu_layer.add_child(fullscreen_button)

	menu_selection_marker = Label.new()
	menu_selection_marker.position = Vector2(329.0, 204.0)
	menu_selection_marker.size = Vector2(32.0, 62.0)
	menu_selection_marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_selection_marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_selection_marker.text = "◆"
	menu_selection_marker.add_theme_font_size_override("font_size", 22)
	menu_selection_marker.add_theme_color_override("font_color", MODE_MENU_ACCENTS[0])
	menu_selection_marker.add_theme_color_override("font_shadow_color", Color(MODE_MENU_ACCENTS[0], 0.75))
	menu_selection_marker.add_theme_constant_override("shadow_offset_x", 0)
	menu_selection_marker.add_theme_constant_override("shadow_offset_y", 0)
	menu_layer.add_child(menu_selection_marker)

	menu_detail_panel = Panel.new()
	menu_detail_panel.position = Vector2(366.0, 428.0)
	menu_detail_panel.size = Vector2(420.0, 50.0)
	menu_detail_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_detail_panel.add_theme_stylebox_override(
		"panel",
		_make_menu_detail_style(Color("2cccf4"))
	)
	menu_layer.add_child(menu_detail_panel)

	menu_mode_index_label = Label.new()
	menu_mode_index_label.position = Vector2(380.0, 438.0)
	menu_mode_index_label.size = Vector2(72.0, 30.0)
	menu_mode_index_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_mode_index_label.text = "MODE 01"
	menu_mode_index_label.add_theme_font_size_override("font_size", 11)
	menu_mode_index_label.add_theme_color_override("font_color", Color("2cccf4"))
	menu_layer.add_child(menu_mode_index_label)

	menu_mode_description_label = Label.new()
	menu_mode_description_label.position = Vector2(452.0, 438.0)
	menu_mode_description_label.size = Vector2(320.0, 30.0)
	menu_mode_description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	menu_mode_description_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	menu_mode_description_label.text = MODE_MENU_DETAILS[0]
	menu_mode_description_label.add_theme_font_size_override("font_size", 11)
	menu_mode_description_label.add_theme_color_override("font_color", Color("c5dce2"))
	menu_layer.add_child(menu_mode_description_label)

	_add_menu_fighter_caption(
		"REN",
		"AZURE TACTICIAN",
		Vector2(36.0, 528.0),
		Vector2(280.0, 48.0),
		Color("2cccf4"),
		HORIZONTAL_ALIGNMENT_LEFT
	)
	_add_menu_fighter_caption(
		"VEL",
		"CRIMSON HUNTER",
		Vector2(836.0, 528.0),
		Vector2(280.0, 48.0),
		Color("ff4f86"),
		HORIZONTAL_ALIGNMENT_RIGHT
	)

	var hint := Label.new()
	hint.position = Vector2(226.0, 576.0)
	hint.size = Vector2(700.0, 44.0)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.text = "↑ ↓  /  W S   NAVIGATE        ENTER   CONFIRM        ALT + ENTER   FULLSCREEN"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color("8aa5af"))
	hint.add_theme_constant_override("letter_spacing", 1)
	menu_layer.add_child(hint)


func _make_mode_button(
	button_text: String,
	button_position: Vector2,
	button_size: Vector2 = Vector2(500.0, 68.0),
	font_size: int = 22,
	focusable: bool = true,
	badge_text: String = "",
	accent: Color = Color("2cccf4")
) -> Button:
	var button := Button.new()
	button.position = button_position
	button.size = button_size
	button.text = button_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_ALL if focusable else Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("d8f7ff"))
	button.add_theme_color_override("font_hover_color", Color("fff3c4"))
	button.add_theme_color_override("font_focus_color", Color("fff3c4"))
	button.add_theme_stylebox_override(
		"normal",
		_make_menu_button_style(Color(0.035, 0.085, 0.105, 0.94), Color(accent, 0.46), 1, accent)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_menu_button_style(Color(0.055, 0.14, 0.17, 0.98), Color(accent, 0.95), 2, accent)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_menu_button_style(Color(0.085, 0.18, 0.20, 1.0), Color("fff3c4"), 2, accent)
	)
	button.add_theme_stylebox_override(
		"focus",
		_make_menu_button_style(Color(0.055, 0.125, 0.145, 1.0), Color("fff3c4"), 2, accent)
	)

	if not badge_text.is_empty():
		var badge := Label.new()
		badge.position = Vector2(button_size.x - 142.0, 0.0)
		badge.size = Vector2(122.0, button_size.y)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.text = badge_text
		badge.add_theme_font_size_override("font_size", 11)
		badge.add_theme_color_override("font_color", Color(accent, 0.92))
		button.add_child(badge)
	return button


func _make_menu_button_style(
	fill: Color,
	border: Color,
	border_width: int,
	accent: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.border_width_left = maxi(border_width, 5)
	style.corner_radius_top_left = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 22.0
	style.content_margin_right = 18.0
	style.shadow_color = Color(accent, 0.12)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _make_menu_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.015, 0.035, 0.05, 0.91)
	style.border_color = Color("f5d77a", 0.44)
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.56)
	style.shadow_size = 18
	style.shadow_offset = Vector2(0.0, 8.0)
	return style


func _make_menu_detail_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.055, 0.07, 0.92)
	style.border_color = Color(accent, 0.32)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style


func _add_menu_portrait(
	texture: Texture2D,
	portrait_position: Vector2,
	portrait_size: Vector2,
	accent: Color
) -> void:
	var glow := TextureRect.new()
	glow.position = portrait_position + Vector2(0.0, 4.0)
	glow.size = portrait_size
	glow.texture = texture
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	glow.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.modulate = Color(accent, 0.16)
	menu_layer.add_child(glow)

	var portrait := TextureRect.new()
	portrait.position = portrait_position
	portrait.size = portrait_size
	portrait.texture = texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.modulate = Color(1.0, 1.0, 1.0, 0.82)
	menu_layer.add_child(portrait)
	menu_portraits.append(portrait)
	menu_portrait_base_positions.append(portrait_position)


func _add_menu_rule(rule_position: Vector2, rule_size: Vector2, color: Color) -> void:
	var rule := ColorRect.new()
	rule.position = rule_position
	rule.size = rule_size
	rule.color = Color(color, 0.5)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_layer.add_child(rule)


func _add_menu_fighter_caption(
	fighter_name: String,
	fighter_title: String,
	caption_position: Vector2,
	caption_size: Vector2,
	accent: Color,
	alignment: HorizontalAlignment
) -> void:
	var caption := Label.new()
	caption.position = caption_position
	caption.size = caption_size
	caption.horizontal_alignment = alignment
	caption.text = "%s\n%s" % [fighter_name, fighter_title]
	caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", accent)
	caption.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	caption.add_theme_constant_override("shadow_offset_x", 2)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	menu_layer.add_child(caption)


func _make_button_style(fill: Color, border: Color, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(8)
	return style


func _make_training_panel_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.065, 0.085, 0.88)
	style.border_color = Color(accent, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _create_stage_select_menu() -> void:
	stage_select_layer = CanvasLayer.new()
	stage_select_layer.layer = 11
	stage_select_layer.visible = false
	add_child(stage_select_layer)

	var backdrop := ColorRect.new()
	backdrop.position = Vector2.ZERO
	backdrop.size = SCREEN_SIZE
	backdrop.color = Color(0.01, 0.022, 0.032, 0.97)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_select_layer.add_child(backdrop)

	var upper_glow := ColorRect.new()
	upper_glow.position = Vector2(0.0, 0.0)
	upper_glow.size = Vector2(SCREEN_SIZE.x, 126.0)
	upper_glow.color = Color(0.06, 0.13, 0.15, 0.42)
	upper_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_select_layer.add_child(upper_glow)

	var header_line := ColorRect.new()
	header_line.position = Vector2(74.0, 89.0)
	header_line.size = Vector2(1004.0, 2.0)
	header_line.color = Color("f5d77a", 0.72)
	header_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_select_layer.add_child(header_line)

	var title := Label.new()
	title.position = Vector2(226.0, 24.0)
	title.size = Vector2(700.0, 62.0)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "SELECT STAGE"
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color("fff3c4"))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_select_layer.add_child(title)

	stage_mode_label = Label.new()
	stage_mode_label.position = Vector2(176.0, 101.0)
	stage_mode_label.size = Vector2(800.0, 32.0)
	stage_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_mode_label.add_theme_font_size_override("font_size", 16)
	stage_mode_label.add_theme_color_override("font_color", Color("91ddea"))
	stage_mode_label.add_theme_constant_override("letter_spacing", 2)
	stage_mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_select_layer.add_child(stage_mode_label)

	var card_positions := [Vector2(74.0, 146.0), Vector2(598.0, 146.0)]
	for index in STAGE_ROSTER.size():
		var card := _make_stage_card(index, card_positions[index])
		stage_buttons.append(card)
		stage_select_layer.add_child(card)

	stage_summary_label = Label.new()
	stage_summary_label.position = Vector2(126.0, 544.0)
	stage_summary_label.size = Vector2(900.0, 34.0)
	stage_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_summary_label.add_theme_font_size_override("font_size", 17)
	stage_summary_label.add_theme_color_override("font_color", Color("d8f7ff"))
	stage_summary_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_select_layer.add_child(stage_summary_label)

	stage_hint_label = Label.new()
	stage_hint_label.position = Vector2(126.0, 588.0)
	stage_hint_label.size = Vector2(900.0, 34.0)
	stage_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_hint_label.text = "A / D OR LEFT / RIGHT: CHOOSE    ENTER / SPACE / J: CONFIRM    ESC: BACK"
	stage_hint_label.add_theme_font_size_override("font_size", 14)
	stage_hint_label.add_theme_color_override("font_color", Color("91acb7"))
	stage_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage_select_layer.add_child(stage_hint_label)


func _make_stage_card(index: int, card_position: Vector2) -> Button:
	var stage_data: Dictionary = STAGE_ROSTER[index]
	var accent: Color = stage_data["accent"]
	var card := Button.new()
	card.position = card_position
	card.size = Vector2(480.0, 378.0)
	card.focus_mode = Control.FOCUS_NONE
	card.clip_contents = true
	card.tooltip_text = "Select %s" % str(stage_data["name"])
	card.add_theme_stylebox_override("normal", _make_button_style(Color("0d1c26"), Color("31505a"), 2))
	card.add_theme_stylebox_override("hover", _make_button_style(Color("132b36"), accent, 4))
	card.add_theme_stylebox_override("pressed", _make_button_style(Color("193944"), Color("fff3c4"), 4))
	card.pressed.connect(_on_stage_card_pressed.bind(index))
	card.mouse_entered.connect(_on_stage_card_hovered.bind(index))

	var preview := TextureRect.new()
	preview.position = Vector2(14.0, 14.0)
	preview.size = Vector2(452.0, 254.0)
	preview.texture = stage_data["texture"] as Texture2D
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(preview)

	var preview_tint := ColorRect.new()
	preview_tint.position = preview.position
	preview_tint.size = preview.size
	preview_tint.color = Color(accent, 0.06)
	preview_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(preview_tint)

	var accent_bar := ColorRect.new()
	accent_bar.position = Vector2(14.0, 268.0)
	accent_bar.size = Vector2(452.0, 4.0)
	accent_bar.color = accent
	accent_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(accent_bar)

	var name_label := Label.new()
	name_label.position = Vector2(18.0, 276.0)
	name_label.size = Vector2(444.0, 38.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text = str(stage_data["name"])
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color("fff3c4"))
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_label)

	var subtitle := Label.new()
	subtitle.position = Vector2(18.0, 311.0)
	subtitle.size = Vector2(444.0, 22.0)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.text = str(stage_data["subtitle"])
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", accent.lightened(0.22))
	subtitle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(subtitle)

	var status_label := Label.new()
	status_label.position = Vector2(18.0, 341.0)
	status_label.size = Vector2(444.0, 24.0)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color("91acb7"))
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(status_label)
	stage_status_labels.append(status_label)
	return card


func _show_stage_select(selected_mode: StringName) -> void:
	phase = &"stage_select"
	game_mode = selected_mode
	_reset_camera()
	menu_layer.visible = false
	stage_select_layer.visible = true
	character_select_layer.visible = false
	announcement_label.visible = false
	subtitle_label.visible = false
	for combo_label in combo_labels:
		combo_label.visible = false
	mode_label.visible = false
	training_label.visible = false
	training_hud_label.visible = false
	training_input_label.visible = false
	for fighter in fighters:
		fighter.visible = false
		fighter.clear_input()
	_refresh_stage_select()
	queue_redraw()


func _refresh_stage_select() -> void:
	var mode_name := "SOLO BATTLE" if game_mode == MODE_SOLO else "VERSUS"
	stage_mode_label.text = "%s  •  CHOOSE THE BATTLEFIELD" % mode_name
	for index in STAGE_ROSTER.size():
		var stage_data: Dictionary = STAGE_ROSTER[index]
		var accent: Color = stage_data["accent"]
		var is_current := stage_selection == index
		var fill := Color("0d1c26").lerp(accent.darkened(0.64), 0.22 if is_current else 0.06)
		var border := Color("fff3c4") if is_current else Color("31505a")
		var width := 5 if is_current else 2
		stage_buttons[index].add_theme_stylebox_override("normal", _make_button_style(fill, border, width))
		stage_buttons[index].add_theme_stylebox_override(
			"hover",
			_make_button_style(fill.lightened(0.07), Color("fff3c4") if is_current else accent, 5 if is_current else 4)
		)
		stage_status_labels[index].text = "◆ SELECTED" if is_current else "CHOOSE"
		stage_status_labels[index].add_theme_color_override(
			"font_color",
			Color("fff3c4") if is_current else accent.lightened(0.2)
		)

	var selected_stage: Dictionary = STAGE_ROSTER[stage_selection]
	var selected_accent: Color = selected_stage["accent"]
	stage_summary_label.text = "%s  •  %s" % [
		str(selected_stage["name"]),
		str(selected_stage["description"])
	]
	stage_summary_label.add_theme_color_override("font_color", selected_accent)


func _handle_stage_select_input() -> void:
	var previous_pressed := _key_just_pressed(KEY_LEFT)
	previous_pressed = _key_just_pressed(KEY_A) or previous_pressed
	previous_pressed = _key_just_pressed(KEY_UP) or previous_pressed
	previous_pressed = _key_just_pressed(KEY_W) or previous_pressed
	var next_pressed := _key_just_pressed(KEY_RIGHT)
	next_pressed = _key_just_pressed(KEY_D) or next_pressed
	next_pressed = _key_just_pressed(KEY_DOWN) or next_pressed
	next_pressed = _key_just_pressed(KEY_S) or next_pressed
	var confirm_pressed := _key_just_pressed(KEY_ENTER)
	confirm_pressed = _key_just_pressed(KEY_SPACE) or confirm_pressed
	confirm_pressed = _key_just_pressed(Fighter.KEYBOARD_LIGHT_KEY) or confirm_pressed

	if previous_pressed:
		stage_selection = wrapi(stage_selection - 1, 0, STAGE_ROSTER.size())
		_refresh_stage_select()
	elif next_pressed:
		stage_selection = wrapi(stage_selection + 1, 0, STAGE_ROSTER.size())
		_refresh_stage_select()
	if confirm_pressed:
		_confirm_stage_selection()


func _on_stage_card_hovered(index: int) -> void:
	if phase != &"stage_select" or index == stage_selection:
		return
	stage_selection = index
	_refresh_stage_select()


func _on_stage_card_pressed(index: int) -> void:
	stage_selection = index
	_refresh_stage_select()
	_confirm_stage_selection()


func _confirm_stage_selection() -> void:
	_apply_selected_stage()
	_show_character_select(game_mode)


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
	_reset_camera()
	menu_layer.visible = false
	stage_select_layer.visible = false
	character_select_layer.visible = true
	announcement_label.visible = false
	subtitle_label.visible = false
	for combo_label in combo_labels:
		combo_label.visible = false
	mode_label.visible = false
	training_label.visible = false
	training_hud_label.visible = false
	training_input_label.visible = false
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
		character_hint_label.text = "A / D OR LEFT / RIGHT: CHOOSE    ENTER / SPACE / J: CONFIRM    ESC: BACK"
	elif game_mode == MODE_TRAINING:
		character_prompt_label.text = (
			"PLAYER 1  -  CHOOSE YOUR FIGHTER"
			if selecting_player == 0
			else "TRAINING DUMMY  -  CHOOSE FIGHTER"
		)
		character_hint_label.text = (
			"A / D OR LEFT / RIGHT: CHOOSE    ENTER / SPACE / J: CONFIRM    ESC: BACK"
			if selecting_player == 0
			else "A / D OR LEFT / RIGHT: CHOOSE    ENTER / SPACE / J: CONFIRM    ESC: BACK"
		)
	else:
		character_prompt_label.text = "PLAYER %d  -  CHOOSE YOUR FIGHTER" % (selecting_player + 1)
		character_hint_label.text = (
			"A / D OR LEFT / RIGHT: CHOOSE    ENTER / SPACE / J: CONFIRM    ESC: BACK"
			if selecting_player == 0
			else "A / D OR LEFT / RIGHT: CHOOSE    ENTER / SPACE / J: CONFIRM    ESC: BACK"
		)

	var current_player_label := (
		"DUMMY" if game_mode == MODE_TRAINING and selecting_player == 1
		else "P%d" % (selecting_player + 1)
	)
	for index in CHARACTER_ROSTER.size():
		var character_data: Dictionary = CHARACTER_ROSTER[index]
		var accent: Color = character_data["color"]
		var is_current: bool = character_selection[selecting_player] == index
		var is_p1_locked: bool = (
			(game_mode == MODE_VERSUS or game_mode == MODE_TRAINING)
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
			character_status_labels[index].text = "P1 LOCKED  /  %s SELECTED" % current_player_label
		elif is_p1_locked:
			character_status_labels[index].text = "P1 LOCKED"
		elif is_current:
			character_status_labels[index].text = "%s SELECTED" % current_player_label
		else:
			character_status_labels[index].text = "CHOOSE"
		character_status_labels[index].add_theme_color_override(
			"font_color",
			Color("fff3c4") if is_current else accent.lightened(0.2)
		)

	var p1_data: Dictionary = CHARACTER_ROSTER[character_selection[0]]
	var p2_data: Dictionary = CHARACTER_ROSTER[character_selection[1]]
	var opponent_label := (
		"CPU" if game_mode == MODE_SOLO
		else ("DUMMY" if game_mode == MODE_TRAINING else "P2")
	)
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
	confirm_pressed = _key_just_pressed(Fighter.KEYBOARD_LIGHT_KEY) or confirm_pressed

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


func _physics_process(delta: float) -> void:
	_handle_system_input()
	if phase == &"menu" or phase == &"stage_select" or phase == &"character_select":
		if phase == &"menu":
			_update_menu_animation(delta)
		_update_ui()
		_request_hud_redraw()
		return

	fighters[0].capture_input()
	if game_mode == MODE_TRAINING:
		_capture_training_input()
	if game_mode == MODE_SOLO:
		if phase == &"fight":
			var cpu_intent := cpu_controller.build_intent(fighters[1], fighters[0])
			fighters[1].apply_virtual_input(cpu_intent.axis, cpu_intent.buttons)
		else:
			fighters[1].clear_input()
	elif game_mode == MODE_TRAINING:
		fighters[1].apply_virtual_input(_training_dummy_axis())
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
		if game_mode != MODE_TRAINING:
			round_frames = maxi(0, round_frames - 1)
		for i in fighters.size():
			fighters[i].simulate(fighters[1 - i], true)
		_constrain_fighters_to_camera()
		_spawn_pending_projectiles()
		_update_projectiles()
		_resolve_body_collision()
		_resolve_attacks()
		_resolve_projectiles()
		if game_mode == MODE_TRAINING:
			_update_training_state()
		elif fighters[0].health <= 0 or fighters[1].health <= 0 or round_frames <= 0:
			_finish_round()
	elif phase == &"round_over":
		phase_frames -= 1
		for i in fighters.size():
			fighters[i].simulate(fighters[1 - i], false)
		_constrain_fighters_to_camera()
		if phase_frames <= 0:
			round_number += 1
			_start_round()
	elif phase == &"match_over":
		# Keep post-KO movement active so the defeated fighter can finish falling.
		for i in fighters.size():
			fighters[i].simulate(fighters[1 - i], false)
		_constrain_fighters_to_camera()

	_update_effects()
	_update_ui()
	_request_hud_redraw()


func _handle_system_input() -> void:
	if phase == &"menu":
		_handle_mode_menu_input()
		return
	if phase == &"stage_select":
		var stage_back_pressed := _key_just_pressed(KEY_M)
		stage_back_pressed = _key_just_pressed(KEY_ESCAPE) or stage_back_pressed
		if stage_back_pressed:
			_show_mode_menu()
		else:
			_handle_stage_select_input()
		return
	if phase == &"character_select":
		var character_back_pressed := _key_just_pressed(KEY_M)
		character_back_pressed = _key_just_pressed(KEY_ESCAPE) or character_back_pressed
		if character_back_pressed:
			if game_mode == MODE_TRAINING:
				_show_mode_menu()
			else:
				_show_stage_select(game_mode)
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
	if game_mode == MODE_TRAINING:
		if _key_just_pressed(KEY_T):
			_cycle_training_guard()
		if _key_just_pressed(KEY_C):
			_clear_training_records()
	if _key_just_pressed(KEY_ENTER):
		if game_mode == MODE_TRAINING:
			_reset_training_position()
		elif phase == &"match_over":
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

	if up_pressed:
		mode_selection = wrapi(mode_selection - 1, 0, 3)
		_update_mode_selection()
	elif down_pressed:
		mode_selection = wrapi(mode_selection + 1, 0, 3)
		_update_mode_selection()
	if confirm_pressed:
		match mode_selection:
			0:
				_start_solo_mode()
			1:
				_start_versus_mode()
			_:
				_start_training_mode()


func _key_just_pressed(keycode: Key) -> bool:
	var down := Input.is_physical_key_pressed(keycode)
	var was_down := bool(meta_key_state.get(keycode, false))
	meta_key_state[keycode] = down
	return down and not was_down


func _show_mode_menu() -> void:
	phase = &"menu"
	screen_shake = 0.0
	_reset_camera()
	global_hitstop = 0
	hit_sparks.clear()
	projectiles.clear()
	training_visible = false
	training_label.visible = false
	training_hud_label.visible = false
	training_input_label.visible = false
	announcement_label.visible = false
	subtitle_label.visible = false
	for combo_label in combo_labels:
		combo_label.visible = false
	mode_label.visible = false
	menu_layer.visible = true
	stage_select_layer.visible = false
	character_select_layer.visible = false
	mode_selection = 0
	for fighter in fighters:
		fighter.visible = false
		fighter.clear_input()
		fighter.set_debug_boxes(false)
	_update_mode_selection()
	queue_redraw()


func _update_mode_selection() -> void:
	var mode_buttons: Array[Button] = [solo_button, versus_button, training_button]
	var selected_button := mode_buttons[mode_selection]
	selected_button.grab_focus()
	for index in mode_buttons.size():
		mode_buttons[index].modulate = (
			Color.WHITE if index == mode_selection else Color(0.68, 0.76, 0.80, 0.78)
		)

	var accent: Color = MODE_MENU_ACCENTS[mode_selection]
	menu_selection_marker.position.y = selected_button.position.y
	menu_selection_marker.add_theme_color_override("font_color", accent)
	menu_selection_marker.add_theme_color_override("font_shadow_color", Color(accent, 0.78))
	menu_mode_index_label.text = "MODE %02d" % (mode_selection + 1)
	menu_mode_index_label.add_theme_color_override("font_color", accent)
	menu_mode_description_label.text = MODE_MENU_DETAILS[mode_selection]
	menu_detail_panel.add_theme_stylebox_override("panel", _make_menu_detail_style(accent))


func _on_mode_button_hovered(index: int) -> void:
	if phase != &"menu" or index == mode_selection:
		return
	mode_selection = index
	_update_mode_selection()


func _update_menu_animation(delta: float) -> void:
	menu_animation_time = fmod(menu_animation_time + delta, 3600.0)
	for index in menu_portraits.size():
		var portrait := menu_portraits[index]
		var base_position := menu_portrait_base_positions[index]
		var phase_offset := float(index) * PI
		portrait.position = base_position + Vector2(
			sin(menu_animation_time * 0.55 + phase_offset) * 2.0,
			sin(menu_animation_time * 0.82 + phase_offset) * 3.5
		)
		portrait.modulate = Color(
			1.0,
			1.0,
			1.0,
			0.79 + sin(menu_animation_time * 0.9 + phase_offset) * 0.035
		)

	menu_selection_marker.position.x = 329.0 + sin(menu_animation_time * 3.2) * 3.0
	menu_selection_marker.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.82 + sin(menu_animation_time * 4.2) * 0.18
	)
	menu_title_label.modulate = Color(
		1.0,
		1.0,
		1.0,
		0.96 + sin(menu_animation_time * 1.4) * 0.04
	)


func _start_solo_mode() -> void:
	stage_selection = STAGE_ROYAL_COLOSSEUM
	_show_stage_select(MODE_SOLO)


func _start_versus_mode() -> void:
	stage_selection = STAGE_ROYAL_COLOSSEUM
	_show_stage_select(MODE_VERSUS)


func _start_training_mode() -> void:
	stage_selection = STAGE_TRAINING_GRID
	_apply_selected_stage()
	_show_character_select(MODE_TRAINING)


func _start_match(selected_mode: StringName) -> void:
	game_mode = selected_mode
	if game_mode == MODE_TRAINING:
		stage_selection = STAGE_TRAINING_GRID
	_apply_selected_stage()
	menu_layer.visible = false
	stage_select_layer.visible = false
	character_select_layer.visible = false
	announcement_label.visible = true
	subtitle_label.visible = true
	for combo_label in combo_labels:
		combo_label.visible = true
	mode_label.visible = true
	for fighter in fighters:
		fighter.visible = true

	for index in fighters.size():
		var character_data: Dictionary = CHARACTER_ROSTER[character_selection[index]]
		fighters[index].configure_character(
			StringName(character_data["id"]),
			str(character_data["name"]),
			character_data["color"],
			character_data["texture"] as Texture2D,
			character_data["animation_textures"]
		)
		combo_labels[index].add_theme_color_override(
			"font_color",
			fighters[index].body_color.lightened(0.35)
		)
		fighters[index].reset_match_resources()
	wins = [0, 0]
	round_number = 1
	training_visible = false
	training_label.visible = false
	training_hud_label.visible = game_mode == MODE_TRAINING
	training_input_label.visible = game_mode == MODE_TRAINING
	if game_mode == MODE_TRAINING:
		_reset_training_session()
	cpu_controller.reset()
	_invalidate_hud_cache()
	_start_round()


func _start_round() -> void:
	round_frames = ROUND_SECONDS * 60
	global_hitstop = 0
	hit_sparks.clear()
	projectiles.clear()
	combat_callout_frames = 0
	cpu_controller.reset()
	fighters[0].facing = 1
	fighters[1].facing = -1
	fighters[0].reset_for_round(_round_spawn_position(0))
	fighters[1].reset_for_round(_round_spawn_position(1))
	_reset_camera(true)
	if game_mode == MODE_TRAINING:
		phase = &"fight"
		phase_frames = 0
		fighters[0].gain_meter(Fighter.MAX_METER)
		fighters[1].gain_meter(Fighter.MAX_METER)
		announcement = ""
		announcement_sub = ""
		return
	phase = &"intro"
	phase_frames = 120
	announcement = "ROUND %d" % round_number
	announcement_sub = "FIRST TO %d ROUNDS" % ROUNDS_TO_WIN


func _reset_training_session() -> void:
	training_guard_mode = TRAINING_GUARD_OFF
	training_guard_armed = false
	training_guard_release_frames = 0
	training_combo_active = false
	training_current_hits = 0
	training_current_damage = 0
	training_last_hits = 0
	training_last_damage = 0
	training_best_hits = 0
	training_best_damage = 0
	training_health_recovery_frames = 0
	training_input_history.clear()
	training_previous_axis = Vector2.ZERO


func _reset_training_position() -> void:
	if game_mode != MODE_TRAINING:
		return
	phase = &"fight"
	phase_frames = 0
	round_frames = ROUND_SECONDS * 60
	global_hitstop = 0
	screen_shake = 0.0
	hit_sparks.clear()
	projectiles.clear()
	fighters[0].facing = 1
	fighters[1].facing = -1
	fighters[0].reset_for_round(_round_spawn_position(0))
	fighters[1].reset_for_round(_round_spawn_position(1))
	_reset_camera(true)
	fighters[0].gain_meter(Fighter.MAX_METER)
	fighters[1].gain_meter(Fighter.MAX_METER)
	training_guard_armed = false
	training_guard_release_frames = 0
	training_combo_active = false
	training_current_hits = 0
	training_current_damage = 0
	training_health_recovery_frames = 0
	training_input_history.clear()
	training_previous_axis = Vector2.ZERO
	announcement = ""
	announcement_sub = "POSITIONS RESET"
	combat_callout_frames = 45
	_invalidate_hud_cache()


func _clear_training_records() -> void:
	training_last_hits = 0
	training_last_damage = 0
	training_best_hits = 0
	training_best_damage = 0
	if not training_combo_active:
		training_current_hits = 0
		training_current_damage = 0
		training_health_recovery_frames = 0
		fighters[1].health = 1000
	announcement_sub = "COMBO RECORDS CLEARED"
	combat_callout_frames = 45


func _cycle_training_guard() -> void:
	training_guard_mode = (training_guard_mode + 1) % 3
	training_guard_armed = false
	training_guard_release_frames = 0
	fighters[1].clear_input()
	announcement_sub = "DUMMY GUARD: %s" % _training_guard_name()
	combat_callout_frames = 60


func _training_guard_name() -> String:
	match training_guard_mode:
		TRAINING_GUARD_AFTER_HIT:
			return "AFTER FIRST HIT"
		TRAINING_GUARD_ALWAYS:
			return "ALL"
		_:
			return "OFF"


func _training_dummy_axis() -> Vector2:
	var should_guard := (
		training_guard_mode == TRAINING_GUARD_ALWAYS
		or (training_guard_mode == TRAINING_GUARD_AFTER_HIT and training_guard_armed)
	)
	if not should_guard:
		return Vector2.ZERO
	var away := 1.0 if fighters[0].position.x < fighters[1].position.x else -1.0
	var block_type := _training_incoming_block_type()
	var crouch := 1.0 if block_type == &"low" else 0.0
	return Vector2(away, crouch)


func _training_incoming_block_type() -> StringName:
	if fighters[0].is_attacking():
		return StringName(fighters[0].current_attack().get("block_type", &"mid"))
	for projectile in projectiles:
		if int(projectile.get("owner_id", -1)) == 0:
			var projectile_attack: Dictionary = projectile.get("attack", {})
			return StringName(projectile_attack.get("block_type", &"mid"))
	return &"mid"


func _record_training_hit(result: Dictionary) -> void:
	if bool(result.get("blocked", false)):
		return
	var combo_hits := int(result.get("combo", 1))
	if not training_combo_active or combo_hits <= 1:
		training_current_hits = 0
		training_current_damage = 0
	training_combo_active = true
	training_current_hits = combo_hits
	training_current_damage += int(result.get("damage", 0))
	training_best_hits = maxi(training_best_hits, training_current_hits)
	training_best_damage = maxi(training_best_damage, training_current_damage)
	training_health_recovery_frames = 0
	if training_guard_mode == TRAINING_GUARD_AFTER_HIT:
		training_guard_armed = true
		training_guard_release_frames = 0


func _update_training_state() -> void:
	fighters[0].gain_meter(Fighter.MAX_METER)
	fighters[1].gain_meter(Fighter.MAX_METER)
	var dummy := fighters[1]
	var dummy_recovered := (
		dummy.combo_received == 0
		and dummy.state != &"hitstun"
		and dummy.state != &"knockdown"
	)
	if training_combo_active and dummy_recovered:
		training_combo_active = false
		training_last_hits = training_current_hits
		training_last_damage = training_current_damage
		training_best_hits = maxi(training_best_hits, training_current_hits)
		training_best_damage = maxi(training_best_damage, training_current_damage)
		training_current_hits = 0
		training_current_damage = 0
		training_health_recovery_frames = TRAINING_HEALTH_RECOVERY_FRAMES

	if not training_combo_active and training_health_recovery_frames > 0:
		training_health_recovery_frames -= 1
		if training_health_recovery_frames == 0:
			dummy.health = 1000

	if training_guard_mode != TRAINING_GUARD_AFTER_HIT or not training_guard_armed:
		return
	var player_pressure := fighters[0].is_attacking()
	if not player_pressure:
		for projectile in projectiles:
			if int(projectile.get("owner_id", -1)) == 0:
				player_pressure = true
				break
	if dummy_recovered and not player_pressure:
		training_guard_release_frames += 1
		if training_guard_release_frames >= TRAINING_GUARD_RELEASE_FRAMES:
			training_guard_armed = false
			training_guard_release_frames = 0
	else:
		training_guard_release_frames = 0


func _capture_training_input() -> void:
	var axis: Vector2 = fighters[0].intent.axis
	var pressed: Dictionary = fighters[0].intent.pressed
	var buttons: Array[String] = []
	if bool(pressed.get("light", false)):
		buttons.append("弱")
	if bool(pressed.get("heavy", false)):
		buttons.append("強")
	if bool(pressed.get("special", false)):
		buttons.append("SP")
	if bool(pressed.get("throw", false)):
		buttons.append("TH")

	var direction := _training_direction_text(axis)
	var direction_changed := axis != training_previous_axis
	var entry := ""
	if not buttons.is_empty():
		entry = " + ".join(buttons)
		if direction != "":
			entry = "%s + %s" % [direction, entry]
	elif direction_changed and direction != "":
		entry = direction
	if not entry.is_empty():
		training_input_history.push_front(entry)
		if training_input_history.size() > TRAINING_INPUT_HISTORY_SIZE:
			training_input_history.pop_back()
	training_previous_axis = axis


func _training_direction_text(axis: Vector2) -> String:
	match Vector2i(roundi(axis.x), roundi(axis.y)):
		Vector2i(-1, -1):
			return "↖"
		Vector2i(0, -1):
			return "↑"
		Vector2i(1, -1):
			return "↗"
		Vector2i(-1, 0):
			return "←"
		Vector2i(1, 0):
			return "→"
		Vector2i(-1, 1):
			return "↙"
		Vector2i(0, 1):
			return "↓"
		Vector2i(1, 1):
			return "↘"
		_:
			return ""


func _finish_round() -> void:
	if phase != &"fight" or game_mode == MODE_TRAINING:
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
	if arena_ambience != null and arena_ambience.visible:
		arena_ambience.celebrate()

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
	var body_half_width := Fighter.BODY_WIDTH * 0.5
	fighters[0].position.x = clampf(
		fighters[0].position.x,
		Fighter.ARENA_LEFT + body_half_width,
		Fighter.ARENA_RIGHT - body_half_width
	)
	fighters[1].position.x = clampf(
		fighters[1].position.x,
		Fighter.ARENA_LEFT + body_half_width,
		Fighter.ARENA_RIGHT - body_half_width
	)


func _resolve_attacks() -> void:
	for attacker_index in fighters.size():
		var attacker := fighters[attacker_index]
		var defender := fighters[1 - attacker_index]
		if not attacker.is_attack_active():
			continue
		if defender.is_invulnerable():
			continue
		var attack_hitbox := attacker.attack_rect()
		var defender_hurtbox := defender.hurt_rect()
		if not attack_hitbox.intersects(defender_hurtbox):
			continue

		var attack_data := attacker.current_attack()
		if bool(attack_data.get("grab", false)) and not defender.can_be_grabbed():
			continue
		attacker.mark_attack_connected()
		var forced_push_direction := 0.0
		if bool(attack_data.get("back_throw", false)):
			forced_push_direction = _perform_back_throw(attacker, defender)
		var spark_position := defender.hurt_rect().get_center()
		if attacker.state == &"ren_palm":
			# Flash Palm's impact belongs exactly on the outstretched hand, not
			# at the defender's waist.
			spark_position = attacker.ren_palm_effect_world_position()
		_apply_attack_hit(
			attacker,
			defender,
			attack_data,
			attacker.position.x,
			forced_push_direction,
			spark_position
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


func _scaled_hitstop_frames(base_frames: int) -> int:
	if base_frames <= 0:
		return 0
	return maxi(1, roundi(float(base_frames) * HITSTOP_TIME_SCALE))


func _apply_attack_hit(
	attacker: Fighter,
	defender: Fighter,
	attack_data: Dictionary,
	attacker_x: float,
	forced_push_direction: float,
	spark_position: Vector2
) -> void:
	var result := defender.receive_attack(attack_data, attacker_x, forced_push_direction)
	if game_mode == MODE_TRAINING and attacker == fighters[0] and defender == fighters[1]:
		_record_training_hit(result)
	var meter_gain := int(attack_data.get("meter_block", 0)) if result.blocked else int(attack_data.get("meter_hit", 0))
	attacker.gain_meter(meter_gain)
	defender.gain_meter(3 if result.blocked else 6)
	global_hitstop = _scaled_hitstop_frames(int(result.hitstop))
	var source_state: StringName = attack_data.get("source_state", attacker.state)
	var is_super := bool(attack_data.get("super", false))
	var is_ren_special := attacker.character_id == &"ren" and str(source_state).begins_with("ren_")
	if is_super:
		screen_shake = 11.0 if is_ren_special else 9.0
	elif is_ren_special and not result.blocked:
		screen_shake = 8.5
	else:
		screen_shake = 8.0 if not result.blocked else 3.0
	var spark_effect_duration := 24 if is_super and is_ren_special else (18 if is_ren_special else (16 if is_super else 12))
	var splash_duration := spark_effect_duration if result.blocked else 24
	if not result.blocked and int(result.damage) >= 100:
		splash_duration = 28
	if not result.blocked and is_super:
		splash_duration = 30
	var spark_duration := maxi(spark_effect_duration, splash_duration)
	hit_sparks.append({
		"position": spark_position,
		"frames": spark_duration,
		"max_frames": spark_duration,
		"effect_frames": spark_effect_duration,
		"splash_frames": splash_duration,
		"splash_seed": randi(),
		"impact_damage": int(result.damage),
		"splash_color": Color("ddf7fa"),
		"blocked": result.blocked,
		"color": attacker.body_color.lightened(0.35),
		"source_state": source_state,
		"ren_special": is_ren_special,
		"super": is_super,
		"facing": attacker.facing
	})
	if result.back_throw:
		announcement_sub = "BACK THROW"
		combat_callout_frames = 60
	elif result.combo > 1 and not result.blocked:
		# Combo counts use player-side labels; keep the center clear for round,
		# throw, and super callouts.
		announcement_sub = ""
		combat_callout_frames = 0
	elif is_super:
		announcement_sub = str(attack_data.get("label", "SUPER"))
		combat_callout_frames = 60
		if arena_ambience != null and arena_ambience.visible:
			arena_ambience.pulse_for_super()
	if result.ko:
		if game_mode == MODE_TRAINING:
			defender.revive_for_training()
		else:
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
	camera_shake_offset = Vector2(
		randf_range(-screen_shake, screen_shake),
		randf_range(-screen_shake * 0.4, screen_shake * 0.4)
	) if screen_shake > 0.1 else Vector2.ZERO
	_update_camera()
	if combat_callout_frames > 0:
		combat_callout_frames -= 1
		if combat_callout_frames == 0 and phase == &"fight":
			announcement_sub = ""


func _reset_camera(use_battle_zoom := false) -> void:
	camera_center_x = ARENA_CENTER_X
	camera_zoom = _target_camera_zoom() if use_battle_zoom else CAMERA_MIN_ZOOM
	camera_shake_offset = Vector2.ZERO
	_apply_world_transform()


func _target_camera_zoom() -> float:
	if fighters.size() < 2:
		return CAMERA_MIN_ZOOM
	var fighter_distance := absf(fighters[1].position.x - fighters[0].position.x)
	var distance_ratio := clampf(
		(fighter_distance - CAMERA_ZOOM_NEAR_DISTANCE)
		/ (CAMERA_ZOOM_FAR_DISTANCE - CAMERA_ZOOM_NEAR_DISTANCE),
		0.0,
		1.0
	)
	var eased_distance := distance_ratio * distance_ratio * (3.0 - 2.0 * distance_ratio)
	return lerpf(CAMERA_MAX_ZOOM, CAMERA_MIN_ZOOM, eased_distance)


func _update_camera() -> void:
	if fighters.size() < 2:
		_apply_world_transform()
		return

	var target_zoom := _target_camera_zoom()
	camera_zoom = lerpf(camera_zoom, target_zoom, CAMERA_ZOOM_FOLLOW_WEIGHT)
	if absf(target_zoom - camera_zoom) < 0.0005:
		camera_zoom = target_zoom

	var visible_half_width := CAMERA_HALF_WIDTH / camera_zoom
	var target_x := (fighters[0].position.x + fighters[1].position.x) * 0.5
	target_x = clampf(target_x, visible_half_width, Fighter.ARENA_WIDTH - visible_half_width)
	var target_delta := target_x - camera_center_x
	var follow_target := camera_center_x
	var camera_dead_zone := CAMERA_DEAD_ZONE / camera_zoom
	var target_is_stage_edge := (
		is_equal_approx(target_x, visible_half_width)
		or is_equal_approx(target_x, Fighter.ARENA_WIDTH - visible_half_width)
	)
	if target_is_stage_edge:
		follow_target = target_x
	elif absf(target_delta) > camera_dead_zone:
		follow_target = target_x - signf(target_delta) * camera_dead_zone
	if not is_equal_approx(follow_target, camera_center_x):
		camera_center_x = lerpf(camera_center_x, follow_target, CAMERA_FOLLOW_WEIGHT)
		if absf(follow_target - camera_center_x) < 0.25:
			camera_center_x = follow_target
	camera_center_x = clampf(
		camera_center_x,
		visible_half_width,
		Fighter.ARENA_WIDTH - visible_half_width
	)
	_apply_world_transform()


func _constrain_fighters_to_camera() -> void:
	var body_half_width := Fighter.BODY_WIDTH * 0.5
	var visible_half_width := CAMERA_HALF_WIDTH / camera_zoom
	var fighter_margin := CAMERA_FIGHTER_MARGIN / camera_zoom
	var visible_left := maxf(
		Fighter.ARENA_LEFT + body_half_width,
		camera_center_x - visible_half_width + fighter_margin
	)
	var visible_right := minf(
		Fighter.ARENA_RIGHT - body_half_width,
		camera_center_x + visible_half_width - fighter_margin
	)
	for fighter in fighters:
		fighter.position.x = clampf(fighter.position.x, visible_left, visible_right)


func _apply_world_transform() -> void:
	if world_root == null:
		return
	if arena_ambience != null:
		arena_ambience.set_camera_view(camera_center_x, CAMERA_HALF_WIDTH / camera_zoom)
	world_root.scale = Vector2.ONE * camera_zoom
	var screen_focus := Vector2(CAMERA_HALF_WIDTH, Fighter.GROUND_Y)
	var world_focus := Vector2(camera_center_x, Fighter.GROUND_Y)
	world_root.position = screen_focus - world_focus * camera_zoom + camera_shake_offset


func _update_ui() -> void:
	_set_label_text_if_changed(announcement_label, announcement)
	_set_label_text_if_changed(subtitle_label, announcement_sub)
	_update_combo_labels()
	if game_mode == MODE_SOLO:
		_set_label_text_if_changed(mode_label, "1 PLAYER  •  CPU STANDARD")
	elif game_mode == MODE_TRAINING:
		_set_label_text_if_changed(mode_label, "TRAINING MODE  •  FREE PRACTICE")
	else:
		_set_label_text_if_changed(mode_label, "2 PLAYERS  •  LOCAL VERSUS")
	if game_mode == MODE_TRAINING:
		var displayed_hits := training_current_hits if training_combo_active else training_last_hits
		var displayed_damage := training_current_damage if training_combo_active else training_last_damage
		var combo_label := "CURRENT COMBO" if training_combo_active else "LAST COMBO"
		var training_hud_text := "TRAINING DATA\n%s:  %d HIT / %d DMG\nBEST:  %d HIT / %d DMG\nDUMMY GUARD:  %s\nENTER: RESET   T: GUARD   C: CLEAR\nF1: FRAME DATA / HITBOX" % [
			combo_label,
			displayed_hits,
			displayed_damage,
			training_best_hits,
			training_best_damage,
			_training_guard_name()
		]
		_set_label_text_if_changed(training_hud_label, training_hud_text)
		var input_text := "INPUT HISTORY\n%s" % (
			"—" if training_input_history.is_empty() else "\n".join(training_input_history)
		)
		_set_label_text_if_changed(training_input_label, input_text)
	if training_visible:
		var training_text := "FRAME DATA / HITBOX VIEW\nP1  %s\nP2  %s\nDistance: %.1f px    Enter: reset round" % [
			fighters[0].frame_data_text(),
			fighters[1].frame_data_text(),
			absf(fighters[1].position.x - fighters[0].position.x)
		]
		_set_label_text_if_changed(training_label, training_text)


func _update_combo_labels() -> void:
	for attacker_index in combo_labels.size():
		var combo_text := ""
		if phase == &"fight":
			var defender_index := 1 - attacker_index
			var combo_hits := fighters[defender_index].combo_received
			if combo_hits > 1:
				combo_text = "%d HIT COMBO" % combo_hits
		_set_label_text_if_changed(combo_labels[attacker_index], combo_text)


func _set_label_text_if_changed(label: Label, next_text: String) -> void:
	if label.text != next_text:
		label.text = next_text


func _invalidate_hud_cache() -> void:
	last_drawn_p1_health = -1
	last_drawn_p2_health = -1
	last_drawn_timer = -1
	last_drawn_p1_wins = -1
	last_drawn_p2_wins = -1
	last_drawn_p1_meter = -1
	last_drawn_p2_meter = -1
	last_drawn_screen_effect_active = false
	queue_redraw()


func _request_hud_redraw() -> void:
	var timer_seconds := -1 if game_mode == MODE_TRAINING else ceili(float(round_frames) / 60.0)
	var screen_effects_need_animation := false
	for fighter in fighters:
		if fighter.character_id == &"ren" and fighter.state == &"ren_super":
			screen_effects_need_animation = true
			break
	var hud_changed: bool = (
		last_drawn_p1_health != fighters[0].health
		or last_drawn_p2_health != fighters[1].health
		or last_drawn_timer != timer_seconds
		or last_drawn_p1_wins != wins[0]
		or last_drawn_p2_wins != wins[1]
		or last_drawn_p1_meter != fighters[0].meter
		or last_drawn_p2_meter != fighters[1].meter
		or last_drawn_screen_effect_active != screen_effects_need_animation
	)
	if not hud_changed and not screen_effects_need_animation:
		return

	last_drawn_p1_health = fighters[0].health
	last_drawn_p2_health = fighters[1].health
	last_drawn_timer = timer_seconds
	last_drawn_p1_wins = wins[0]
	last_drawn_p2_wins = wins[1]
	last_drawn_p1_meter = fighters[0].meter
	last_drawn_p2_meter = fighters[1].meter
	last_drawn_screen_effect_active = screen_effects_need_animation
	queue_redraw()



func _draw_ren_super_screen_tint() -> void:
	for fighter in fighters:
		if fighter.character_id != &"ren" or fighter.state != &"ren_super":
			continue
		var charge := clampf(float(fighter.state_frame) / 6.0, 0.0, 1.0)
		var fade := 1.0 - clampf(float(fighter.state_frame - 31) / 20.0, 0.0, 1.0)
		var startup_flash := 1.0 - clampf(float(fighter.state_frame) / 8.0, 0.0, 1.0)
		var strength := maxf(0.24, charge) * fade
		var fighter_screen_position := world_root.position + fighter.position * world_root.scale
		draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), Color(REN_EFFECT_DEEP, 0.035 * strength + 0.065 * startup_flash), true)
		draw_circle(fighter_screen_position + Vector2(0.0, -92.0) * world_root.scale, 245.0 * world_root.scale.x, Color(REN_EFFECT_BLUE, 0.035 * strength))
		for line_index in 12:
			var line_angle := float(line_index) * TAU / 12.0 + float(fighter.state_frame) * 0.035
			var line_direction := Vector2.from_angle(line_angle)
			var line_center := fighter_screen_position + Vector2(0.0, -92.0) * world_root.scale
			draw_line(
				line_center + line_direction * (112.0 + float(line_index % 3) * 18.0),
				line_center + line_direction * (190.0 + float(line_index % 2) * 42.0),
				Color(REN_EFFECT_LIGHT, 0.075 * strength),
				2.0,
				true
			)
		draw_rect(Rect2(0.0, 0.0, SCREEN_SIZE.x, 4.0), Color(REN_EFFECT_LIGHT, 0.22 * strength), true)
		draw_rect(Rect2(0.0, SCREEN_SIZE.y - 4.0, SCREEN_SIZE.x, 4.0), Color(REN_EFFECT_BLUE, 0.18 * strength), true)
		return


func _draw() -> void:
	if phase == &"menu" or phase == &"stage_select" or phase == &"character_select":
		return

	_draw_ren_super_screen_tint()

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

	var font := ThemeDB.fallback_font
	# Compact super meters sit at the lower corners and fill toward center stage.
	var meter_y := SCREEN_SIZE.y - SUPER_METER_MARGIN.y - SUPER_METER_SIZE.y
	var p1_meter_rect := Rect2(
		Vector2(SUPER_METER_MARGIN.x, meter_y),
		SUPER_METER_SIZE
	)
	var p2_meter_rect := Rect2(
		Vector2(SCREEN_SIZE.x - SUPER_METER_MARGIN.x - SUPER_METER_SIZE.x, meter_y),
		SUPER_METER_SIZE
	)
	var meter_fill_capacity := SUPER_METER_SIZE.x - SUPER_METER_INSET * 2.0
	var meter_fill_height := SUPER_METER_SIZE.y - SUPER_METER_INSET * 2.0
	var p1_meter_width := meter_fill_capacity * float(fighters[0].meter) / float(Fighter.MAX_METER)
	var p2_meter_width := meter_fill_capacity * float(fighters[1].meter) / float(Fighter.MAX_METER)
	var p1_meter_color := Color("ffd45e") if fighters[0].meter >= Fighter.MAX_METER else p1_color.lightened(0.2)
	var p2_meter_color := Color("ffd45e") if fighters[1].meter >= Fighter.MAX_METER else p2_color.lightened(0.2)
	draw_rect(Rect2(p1_meter_rect.position + Vector2(0.0, 3.0), p1_meter_rect.size), Color(0, 0, 0, 0.5), true)
	draw_rect(Rect2(p2_meter_rect.position + Vector2(0.0, 3.0), p2_meter_rect.size), Color(0, 0, 0, 0.5), true)
	draw_rect(p1_meter_rect, Color(0.025, 0.055, 0.07, 0.94), true)
	draw_rect(p2_meter_rect, Color(0.025, 0.055, 0.07, 0.94), true)
	draw_rect(
		Rect2(
			p1_meter_rect.position + Vector2.ONE * SUPER_METER_INSET,
			Vector2(p1_meter_width, meter_fill_height)
		),
		p1_meter_color,
		true
	)
	draw_rect(
		Rect2(
			Vector2(
				p2_meter_rect.end.x - SUPER_METER_INSET - p2_meter_width,
				p2_meter_rect.position.y + SUPER_METER_INSET
			),
			Vector2(p2_meter_width, meter_fill_height)
		),
		p2_meter_color,
		true
	)
	draw_rect(p1_meter_rect, p1_accent, false, 2.0)
	draw_rect(p2_meter_rect, p2_accent, false, 2.0)
	draw_string(
		font,
		Vector2(p1_meter_rect.position.x, p1_meter_rect.position.y - 6.0),
		"SUPER",
		HORIZONTAL_ALIGNMENT_LEFT,
		SUPER_METER_SIZE.x,
		11,
		p1_accent
	)
	draw_string(
		font,
		Vector2(p2_meter_rect.position.x, p2_meter_rect.position.y - 6.0),
		"SUPER",
		HORIZONTAL_ALIGNMENT_RIGHT,
		SUPER_METER_SIZE.x,
		11,
		p2_accent
	)
	if fighters[0].meter >= Fighter.MAX_METER:
		draw_string(
			font,
			Vector2(p1_meter_rect.position.x + 4.0, p1_meter_rect.position.y + 14.0),
			"MAX",
			HORIZONTAL_ALIGNMENT_CENTER,
			SUPER_METER_SIZE.x - 8.0,
			10,
			Color("2a210b")
		)
	if fighters[1].meter >= Fighter.MAX_METER:
		draw_string(
			font,
			Vector2(p2_meter_rect.position.x + 4.0, p2_meter_rect.position.y + 14.0),
			"MAX",
			HORIZONTAL_ALIGNMENT_CENTER,
			SUPER_METER_SIZE.x - 8.0,
			10,
			Color("2a210b")
		)
	draw_string(font, Vector2(50, 111), fighters[0].fighter_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 19, p1_accent)
	draw_string(font, Vector2(654, 111), fighters[1].fighter_name, HORIZONTAL_ALIGNMENT_RIGHT, 448, 19, p2_accent)
	var timer_text := "∞" if game_mode == MODE_TRAINING else "%02d" % ceili(float(round_frames) / 60.0)
	draw_string(font, Vector2(516, 76), timer_text, HORIZONTAL_ALIGNMENT_CENTER, 120, 36, Color("fff3c4"))
	if game_mode != MODE_TRAINING:
		for i in wins[0]:
			draw_circle(Vector2(68.0 + i * 24.0, 126.0), 8.0, Color("fff3c4"))
		for i in wins[1]:
			draw_circle(Vector2(1084.0 - i * 24.0, 126.0), 8.0, Color("fff3c4"))
