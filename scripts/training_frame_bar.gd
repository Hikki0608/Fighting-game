class_name TrainingFrameBar
extends Panel

const FighterScript := preload("res://scripts/fighter.gd")
const FrameDataPanelScript := preload("res://scripts/training_frame_data_panel.gd")

const MAX_FRAMES := 72
const PANEL_PADDING := 14.0
const LABEL_WIDTH := 58.0
const HEADER_BASELINES := [42.0, 91.0]
const BAR_TOPS := [49.0, 98.0]
const BAR_HEIGHT := 19.0
const FONT_SIZE := 11
const SUMMARY_FONT_SIZE := 11
const TITLE_FONT_SIZE := 12
const GRID_COLOR := Color("446274", 0.72)
const EMPTY_COLOR := Color("080d14", 0.98)
const TEXT_COLOR := Color("e9f8ff")
const MUTED_TEXT_COLOR := Color("91acb7")
const PHASE_COLORS := {
	&"neutral": Color("18232b"),
	&"movement": Color("28c9ca"),
	&"startup": Color("f3d84a"),
	&"active": Color("ff4f86"),
	&"gap": Color("8d3db8"),
	&"recovery": Color("299ee8"),
	&"hitstop": Color("f4fbff"),
	&"hitstun": Color("ff754f"),
	&"blockstun": Color("bd68ff"),
	&"knockdown": Color("a82d45")
}
const ACTION_DISPLAY_NAMES := {
	&"light": "STANDING LIGHT",
	&"crouch_light": "CROUCH LIGHT",
	&"heavy": "STANDING HEAVY",
	&"forward_heavy": "OVERHEAD",
	&"crouch_heavy": "ANTI-AIR",
	&"throw": "THROW",
	&"jump_light": "JUMP LIGHT",
	&"jump_heavy": "JUMP HEAVY",
	&"ren_pulse": "AZURE PULSE",
	&"ren_palm": "FLASH PALM",
	&"ren_rise": "SKY BREAK",
	&"ren_dive": "COMET DIVE",
	&"ren_super": "AZURE ZERO",
	&"vel_rake": "CRIMSON RAKE",
	&"vel_pounce": "PREDATOR POUNCE",
	&"vel_rise": "HUNTER RISE",
	&"vel_shadow": "SHADOW HUNT",
	&"vel_dive": "REAPER DIVE",
	&"vel_super": "RED ECLIPSE"
}
const LEGEND_ENTRIES := [
	[&"startup", "START"],
	[&"active", "ACTIVE"],
	[&"recovery", "RECOV"],
	[&"hitstop", "STOP"],
	[&"hitstun", "HIT"]
]
const CAPTURE_ACTIVITY_STATES := [
	&"jump",
	&"forward_step",
	&"back_step",
	&"vel_shadow",
	&"hitstun",
	&"blockstun",
	&"knockdown"
]

var histories: Array = [[], []]
var last_action_summaries: Array[String] = ["NO ACTION RECORDED", "NO ACTION RECORDED"]
var row_cache: Dictionary = {}
var last_drawn_cell_count := 0
var last_drawn_run_labels := 0
var recording := false
var completed_capture := false


func _ready() -> void:
	_apply_panel_style()


func record_frame(fighters: Array, hitstop_active := false) -> void:
	if fighters.size() < 2:
		return
	var action_in_progress := hitstop_active or _fighters_have_capture_activity(fighters)
	if not recording:
		if not action_in_progress:
			return
		_begin_capture()
	for player_index in 2:
		var fighter = fighters[player_index]
		var snapshot := capture_fighter_frame(fighter, hitstop_active)
		var history: Array = histories[player_index]
		history.append(snapshot)
		while history.size() > MAX_FRAMES:
			history.pop_front()
		var action_row := _frame_row_for(fighter.character_id, fighter.state)
		if not action_row.is_empty():
			last_action_summaries[player_index] = _action_summary(action_row, fighter.state)
	if not action_in_progress:
		recording = false
		completed_capture = true
	if visible:
		queue_redraw()


func clear_history() -> void:
	histories = [[], []]
	last_action_summaries = ["NO ACTION RECORDED", "NO ACTION RECORDED"]
	recording = false
	completed_capture = false
	queue_redraw()


func is_recording() -> bool:
	return recording


func is_frozen() -> bool:
	return completed_capture and not recording


func capture_status_text() -> String:
	if recording:
		return "REC - RECORDING"
	if completed_capture:
		return "PAUSED - NEXT ACTION TO RESUME"
	return "WAITING FOR ACTION"


func history_size(player_index: int) -> int:
	if player_index < 0 or player_index >= histories.size():
		return 0
	return histories[player_index].size()


func latest_phase(player_index: int) -> StringName:
	if history_size(player_index) == 0:
		return &""
	var history: Array = histories[player_index]
	return StringName(history.back().get("phase", &""))


func _begin_capture() -> void:
	histories = [[], []]
	last_action_summaries = ["NO ACTION RECORDED", "NO ACTION RECORDED"]
	recording = true
	completed_capture = false


func _fighters_have_capture_activity(fighters: Array) -> bool:
	for fighter in fighters:
		if fighter.is_attacking() or fighter.state in CAPTURE_ACTIVITY_STATES:
			return true
	return false


static func capture_fighter_frame(fighter, hitstop_active := false) -> Dictionary:
	var state: StringName = fighter.state
	var state_frame: int = fighter.state_frame
	var frame_phase: StringName = &"neutral"
	if hitstop_active:
		frame_phase = &"hitstop"
	elif state == &"hitstun":
		frame_phase = &"hitstun"
	elif state == &"blockstun":
		frame_phase = &"blockstun"
	elif state == &"knockdown":
		frame_phase = &"knockdown"
	elif fighter.is_attacking():
		var attack: Dictionary = fighter.current_attack()
		var startup := int(attack.get("startup", 0))
		var active := int(attack.get("active", 0))
		var hit_frames: Array = attack.get("hit_frames", [])
		if state_frame <= startup:
			frame_phase = &"startup"
		elif not hit_frames.is_empty():
			if hit_frames.has(state_frame):
				frame_phase = &"active"
			elif state_frame < int(hit_frames.back()):
				frame_phase = &"gap"
			else:
				frame_phase = &"recovery"
		elif state_frame <= startup + active:
			frame_phase = &"active"
		else:
			frame_phase = &"recovery"
	elif state in [&"walk", &"jump", &"forward_step", &"back_step", &"vel_shadow"]:
		frame_phase = &"movement"
	return {
		"phase": frame_phase,
		"state": state,
		"state_frame": state_frame,
		"invulnerable": fighter.is_invulnerable()
	}


func _frame_row_for(character_id: StringName, state: StringName) -> Dictionary:
	if not row_cache.has(character_id):
		var character_rows: Dictionary = {}
		for row in FrameDataPanelScript.build_rows(character_id):
			character_rows[StringName(row["state"])] = row
		row_cache[character_id] = character_rows
	var cached_rows: Dictionary = row_cache[character_id]
	return cached_rows.get(state, {})


func _action_summary(row: Dictionary, state: StringName) -> String:
	var total_frames := int(row["startup"]) + int(row["recovery"])
	if FighterScript.ATTACKS.has(state):
		var attack: Dictionary = FighterScript.ATTACKS[state]
		total_frames = int(attack.startup + attack.active + attack.recovery)
	var hit_advantage := "VAR" if state == &"ren_pulse" else _ascii_advantage(row["hit_advantage"])
	var block_advantage := "VAR" if state == &"ren_pulse" else _ascii_advantage(row["block_advantage"])
	return "%s | START %sF / TOTAL %dF / HIT %s / GUARD %s" % [
		str(ACTION_DISPLAY_NAMES.get(state, "ACTION")),
		str(row["startup"]),
		total_frames,
		hit_advantage,
		block_advantage
	]


func _ascii_advantage(value: Variant) -> String:
	var text := str(value)
	if text == "DOWN":
		return text
	var unsigned_text := text.trim_prefix("+").trim_prefix("-")
	if unsigned_text.is_valid_int():
		return text
	return "N/A"


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.03, 0.045, 0.94)
	style.border_color = Color("6ec4d8", 0.76)
	style.set_border_width_all(1)
	style.border_width_top = 3
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.7)
	style.shadow_size = 12
	style.shadow_offset = Vector2(0.0, 5.0)
	add_theme_stylebox_override("panel", style)


func _draw() -> void:
	last_drawn_cell_count = 0
	last_drawn_run_labels = 0
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(PANEL_PADDING, 18.0),
		"FRAME BAR - LAST %d FRAMES" % MAX_FRAMES,
		HORIZONTAL_ALIGNMENT_LEFT,
		260.0,
		TITLE_FONT_SIZE,
		Color("f2fdff")
	)
	draw_string(
		font,
		Vector2(290.0, 18.0),
		capture_status_text(),
		HORIZONTAL_ALIGNMENT_LEFT,
		390.0,
		FONT_SIZE,
		Color("ffdc72") if recording else MUTED_TEXT_COLOR
	)
	_draw_legend(font)
	for player_index in 2:
		_draw_player_row(font, player_index)


func _draw_legend(font: Font) -> void:
	var x := size.x - PANEL_PADDING - 320.0
	for entry in LEGEND_ENTRIES:
		var phase: StringName = entry[0]
		draw_rect(Rect2(x, 8.0, 10.0, 10.0), PHASE_COLORS[phase], true)
		draw_string(
			font,
			Vector2(x + 14.0, 18.0),
			str(entry[1]),
			HORIZONTAL_ALIGNMENT_LEFT,
			42.0,
			FONT_SIZE,
			MUTED_TEXT_COLOR
		)
		x += 62.0


func _draw_player_row(font: Font, player_index: int) -> void:
	var accent := Color("2cccf4") if player_index == 0 else Color("ff4f86")
	var label := "P%d" % (player_index + 1)
	draw_string(
		font,
		Vector2(PANEL_PADDING, HEADER_BASELINES[player_index]),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		LABEL_WIDTH - 6.0,
		13,
		accent
	)
	draw_string(
		font,
		Vector2(PANEL_PADDING + LABEL_WIDTH, HEADER_BASELINES[player_index]),
		last_action_summaries[player_index],
		HORIZONTAL_ALIGNMENT_LEFT,
		size.x - PANEL_PADDING * 2.0 - LABEL_WIDTH,
		SUMMARY_FONT_SIZE,
		TEXT_COLOR
	)

	var timeline_left := PANEL_PADDING + LABEL_WIDTH
	var timeline_width := size.x - timeline_left - PANEL_PADDING
	var cell_width := timeline_width / float(MAX_FRAMES)
	var bar_y: float = BAR_TOPS[player_index]
	draw_rect(Rect2(timeline_left, bar_y, timeline_width, BAR_HEIGHT), EMPTY_COLOR, true)

	var history: Array = histories[player_index]
	var history_offset := MAX_FRAMES - history.size()
	for history_index in history.size():
		var snapshot: Dictionary = history[history_index]
		var frame_index := history_offset + history_index
		var phase: StringName = snapshot.get("phase", &"neutral")
		var cell_x := timeline_left + float(frame_index) * cell_width
		var cell_rect := Rect2(
			cell_x + 0.5,
			bar_y + 0.5,
			maxf(1.0, cell_width - 1.0),
			BAR_HEIGHT - 1.0
		)
		draw_rect(cell_rect, PHASE_COLORS.get(phase, PHASE_COLORS[&"neutral"]), true)
		if bool(snapshot.get("invulnerable", false)):
			draw_rect(Rect2(cell_rect.position, Vector2(cell_rect.size.x, 2.5)), Color("91ffcf"), true)
		last_drawn_cell_count += 1

	_draw_run_labels(font, history, history_offset, timeline_left, cell_width, bar_y)
	draw_rect(Rect2(timeline_left, bar_y, timeline_width, BAR_HEIGHT), GRID_COLOR, false, 1.0)


func _draw_run_labels(
	font: Font,
	history: Array,
	history_offset: int,
	timeline_left: float,
	cell_width: float,
	bar_y: float
) -> void:
	if history.is_empty():
		return
	var run_start := 0
	var run_key := _snapshot_run_key(history[0])
	for history_index in range(1, history.size() + 1):
		var next_key := ""
		if history_index < history.size():
			next_key = _snapshot_run_key(history[history_index])
		if history_index < history.size() and next_key == run_key:
			continue
		var run_length := history_index - run_start
		var run_phase := StringName(history[run_start].get("phase", &"neutral"))
		if (
			run_phase != &"neutral"
			and run_length >= 2
			and float(run_length) * cell_width >= 17.0
		):
			var frame_start := history_offset + run_start
			var run_x := timeline_left + float(frame_start) * cell_width
			var run_width := float(run_length) * cell_width
			var number_color := Color(0.02, 0.035, 0.05, 0.94)
			if run_phase in [&"gap", &"blockstun", &"knockdown"]:
				number_color = Color(0.96, 0.99, 1.0, 0.96)
			draw_string(
				font,
				Vector2(run_x, bar_y + 14.0),
				str(run_length),
				HORIZONTAL_ALIGNMENT_CENTER,
				run_width,
				10,
				number_color
			)
			last_drawn_run_labels += 1
		run_start = history_index
		run_key = next_key


func _snapshot_run_key(snapshot: Dictionary) -> String:
	return "%s:%s" % [str(snapshot.get("phase", &"")), str(snapshot.get("state", &""))]
