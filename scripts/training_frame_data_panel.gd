class_name TrainingFrameDataPanel
extends Panel

const FighterScript := preload("res://scripts/fighter.gd")

const TABLE_TOP := 64.0
const TABLE_PADDING := 16.0
const HEADER_HEIGHT := 44.0
const SECTION_HEIGHT := 23.0
const ROW_HEIGHT := 29.0
const FONT_SIZE := 12
const HEADER_FONT_SIZE := 13
const SECTION_FONT_SIZE := 13
const FOOTER_FONT_SIZE := 11
const TEXT_COLOR := Color("edf7ff")
const MUTED_TEXT_COLOR := Color("a9c5d1")
const GRID_COLOR := Color("6331a5", 0.82)
const HEADER_COLOR := Color("3b087a", 0.98)
const ROW_COLOR := Color("13082c", 0.98)
const ROW_ALT_COLOR := Color("1a0b39", 0.98)
const CHARACTER_ACCENTS := {
	&"ren": Color("2cccf4"),
	&"vel": Color("ff4f86")
}

const COMMON_MOVES := [
	{"state": &"light", "command": "J / 弱", "name": "立ち弱 / STANDING LIGHT"},
	{"state": &"crouch_light", "command": "下 + J / 弱", "name": "しゃがみ弱 / CROUCH LIGHT"},
	{"state": &"heavy", "command": "K / 強", "name": "立ち強 / STANDING HEAVY"},
	{"state": &"forward_heavy", "command": "前 + K / 強", "name": "中段 / OVERHEAD"},
	{"state": &"crouch_heavy", "command": "下 + K / 強", "name": "対空 / ANTI-AIR"},
	{"state": &"throw", "command": "I / 後 + I", "name": "投げ / 後ろ投げ"},
	{"state": &"jump_light", "command": "空中 + J / 弱", "name": "ジャンプ弱 / JUMP LIGHT"},
	{"state": &"jump_heavy", "command": "空中 + K / 強", "name": "ジャンプ強 / JUMP HEAVY"}
]

const CHARACTER_MOVES := {
	&"ren": [
		{"state": &"ren_pulse", "command": "SP (L / B)", "name": "蒼波拳 / AZURE PULSE", "projectile": true},
		{"state": &"ren_palm", "command": "前 + SP", "name": "瞬閃掌 / FLASH PALM"},
		{"state": &"ren_rise", "command": "下 + SP", "name": "蒼天衝 / SKY BREAK"},
		{"state": &"ren_dive", "command": "空中 + SP", "name": "流星脚 / COMET DIVE"},
		{
			"state": &"ren_super",
			"command": "ゲージMAX + 弱 + 強",
			"name": "零式・蒼閃連舞 / AZURE ZERO"
		}
	],
	&"vel": [
		{
			"state": &"vel_rake",
			"command": "SP (L / B)",
			"name": "紅裂爪 / CRIMSON RAKE"
		},
		{"state": &"vel_pounce", "command": "前 + SP", "name": "獣牙跳 / PREDATOR POUNCE"},
		{"state": &"vel_rise", "command": "下 + SP", "name": "狩天爪 / HUNTER RISE"},
		{
			"state": &"vel_shadow",
			"command": "後ろ + SP",
			"name": "影狩り / SHADOW HUNT",
			"non_attack": true,
			"active_text": "移動"
		},
		{"state": &"vel_dive", "command": "空中 + SP", "name": "断頭爪 / REAPER DIVE"},
		{"state": &"vel_super", "command": "ゲージMAX + 弱 + 強", "name": "紅月・獣王裂 / RED ECLIPSE"}
	]
}

var character_id: StringName = &"ren"
var frame_rows: Array[Dictionary] = []
var last_drawn_row_count := 0
var last_table_bottom := 0.0


func _ready() -> void:
	set_character(character_id)


func set_character(next_character_id: StringName) -> void:
	character_id = next_character_id if CHARACTER_MOVES.has(next_character_id) else &"ren"
	frame_rows = build_rows(character_id)
	_apply_panel_style()
	queue_redraw()


func rows_copy() -> Array[Dictionary]:
	var copied_rows: Array[Dictionary] = []
	for row in frame_rows:
		copied_rows.append(row.duplicate(true))
	return copied_rows


static func build_rows(for_character_id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for descriptor_value in COMMON_MOVES:
		var descriptor: Dictionary = descriptor_value
		result.append(_build_row(descriptor, "通常技"))
	var character_moves: Array = CHARACTER_MOVES.get(for_character_id, CHARACTER_MOVES[&"ren"])
	for descriptor_value in character_moves:
		var descriptor: Dictionary = descriptor_value
		result.append(_build_row(descriptor, "固有技・必殺技"))
	return result


static func _build_row(descriptor: Dictionary, category: String) -> Dictionary:
	if bool(descriptor.get("non_attack", false)):
		var startup := 0
		var recovery := 0
		if StringName(descriptor["state"]) == &"vel_shadow":
			startup = FighterScript.VEL_SHADOW_PAUSE_END_FRAME
			recovery = FighterScript.VEL_SHADOW_END_FRAME - startup
		return {
			"category": category,
			"state": descriptor["state"],
			"command": descriptor["command"],
			"name": descriptor["name"],
			"startup": startup,
			"active": str(descriptor.get("active_text", "—")),
			"recovery": recovery,
			"hit_advantage": "—",
			"block_advantage": "—"
		}

	var attack_state: StringName = descriptor["state"]
	var attack: Dictionary = FighterScript.ATTACKS[attack_state]
	var startup := int(attack.get("startup", 0))
	var active := int(attack.get("active", 0))
	var recovery := int(attack.get("recovery", 0))
	return {
		"category": category,
		"state": attack_state,
		"command": descriptor["command"],
		"name": descriptor["name"],
		"startup": startup,
		"active": _active_text(descriptor, attack, startup, active),
		"recovery": recovery,
		"hit_advantage": _advantage_text(descriptor, attack, false),
		"block_advantage": _advantage_text(descriptor, attack, true)
	}


static func _active_text(
	descriptor: Dictionary,
	attack: Dictionary,
	startup: int,
	active: int
) -> String:
	if descriptor.has("active_text"):
		return str(descriptor["active_text"])
	if bool(descriptor.get("projectile", false)):
		return "飛び道具"
	var hit_frames: Array = attack.get("hit_frames", [])
	if not hit_frames.is_empty():
		var frame_texts := PackedStringArray()
		for hit_frame in hit_frames:
			frame_texts.append(str(int(hit_frame)))
		return ", ".join(frame_texts)
	return "%d-%d" % [startup + 1, startup + active]


static func _advantage_text(
	descriptor: Dictionary,
	attack: Dictionary,
	blocked: bool
) -> String:
	if bool(descriptor.get("projectile", false)):
		return "可変"
	if blocked and bool(attack.get("unblockable", false)):
		return "—"
	var final_attack: Dictionary = attack.get("final_attack", {})
	var causes_knockdown := bool(descriptor.get(
		"knockdown",
		final_attack.get("knockdown", attack.get("knockdown", false))
	))
	if not blocked and causes_knockdown:
		return "DOWN"

	var startup := int(attack.get("startup", 0))
	var active := int(attack.get("active", 0))
	var recovery := int(attack.get("recovery", 0))
	var contact_frame := int(descriptor.get(
		"contact_frame",
		attack.get("final_hit_frame", startup + 1)
	))
	var remaining_action_frames := maxi(0, startup + active + recovery - contact_frame)
	var stun_key := "blockstun" if blocked else "hitstun"
	var override_key := "blockstun_override" if blocked else "hitstun_override"
	var stun_frames := int(descriptor.get(
		override_key,
		final_attack.get(stun_key, attack.get(stun_key, 0))
	))
	var advantage := stun_frames - remaining_action_frames
	return "+%d" % advantage if advantage > 0 else str(advantage)


func _apply_panel_style() -> void:
	var accent: Color = CHARACTER_ACCENTS[character_id]
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.02, 0.045, 0.985)
	style.border_color = Color(accent, 0.86)
	style.set_border_width_all(2)
	style.border_width_top = 5
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.82)
	style.shadow_size = 22
	style.shadow_offset = Vector2(0.0, 8.0)
	add_theme_stylebox_override("panel", style)


func _draw() -> void:
	last_drawn_row_count = 0
	var font := ThemeDB.fallback_font
	var left := TABLE_PADDING
	var width := size.x - TABLE_PADDING * 2.0
	var columns := PackedFloat32Array([
		left,
		left + width * 0.49,
		left + width * 0.575,
		left + width * 0.69,
		left + width * 0.775,
		left + width * 0.885,
		left + width
	])
	var y := TABLE_TOP
	_draw_table_header(font, columns, y)
	y += HEADER_HEIGHT

	var current_category := ""
	var row_index := 0
	for row in frame_rows:
		var category := str(row["category"])
		if category != current_category:
			current_category = category
			_draw_section_header(font, columns, y, category)
			y += SECTION_HEIGHT
		_draw_frame_row(font, columns, y, row, row_index)
		y += ROW_HEIGHT
		row_index += 1
		last_drawn_row_count += 1

	last_table_bottom = y
	var footer := "硬直差は最速で当たった場合  •  DOWN＝ダウン  •  可変＝距離や着地タイミングで変化"
	draw_string(
		font,
		Vector2(left + 4.0, minf(size.y - 13.0, y + 20.0)),
		footer,
		HORIZONTAL_ALIGNMENT_LEFT,
		width,
		FOOTER_FONT_SIZE,
		MUTED_TEXT_COLOR
	)


func _draw_table_header(font: Font, columns: PackedFloat32Array, y: float) -> void:
	var header_rect := Rect2(columns[0], y, columns[6] - columns[0], HEADER_HEIGHT)
	draw_rect(header_rect, HEADER_COLOR, true)
	var headers := ["技名 / 入力", "発生", "持続", "硬直", "ヒット", "ガード"]
	for column_index in headers.size():
		_draw_cell_text(
			font,
			str(headers[column_index]),
			columns[column_index],
			columns[column_index + 1],
			y,
			HEADER_HEIGHT,
			HEADER_FONT_SIZE,
			TEXT_COLOR,
			HORIZONTAL_ALIGNMENT_LEFT if column_index == 0 else HORIZONTAL_ALIGNMENT_CENTER
		)
	_draw_grid(columns, y, HEADER_HEIGHT)


func _draw_section_header(
	font: Font,
	columns: PackedFloat32Array,
	y: float,
	category: String
) -> void:
	var accent: Color = CHARACTER_ACCENTS[character_id]
	draw_rect(
		Rect2(columns[0], y, columns[6] - columns[0], SECTION_HEIGHT),
		Color(accent.darkened(0.45), 0.92),
		true
	)
	draw_string(
		font,
		Vector2(columns[0] + 10.0, y + 17.0),
		category,
		HORIZONTAL_ALIGNMENT_LEFT,
		columns[6] - columns[0] - 20.0,
		SECTION_FONT_SIZE,
		Color("fff3c4")
	)
	draw_line(Vector2(columns[0], y + SECTION_HEIGHT), Vector2(columns[6], y + SECTION_HEIGHT), GRID_COLOR, 1.0)


func _draw_frame_row(
	font: Font,
	columns: PackedFloat32Array,
	y: float,
	row: Dictionary,
	row_index: int
) -> void:
	var fill := ROW_COLOR if row_index % 2 == 0 else ROW_ALT_COLOR
	draw_rect(Rect2(columns[0], y, columns[6] - columns[0], ROW_HEIGHT), fill, true)
	var name_text := "%s  ｜  %s" % [str(row["command"]), str(row["name"])]
	var values := [
		name_text,
		str(row["startup"]),
		str(row["active"]),
		str(row["recovery"]),
		str(row["hit_advantage"]),
		str(row["block_advantage"])
	]
	for column_index in values.size():
		var color := TEXT_COLOR
		if column_index >= 4:
			var value_text := str(values[column_index])
			if value_text.begins_with("+") or value_text == "DOWN":
				color = Color("78f2b6")
			elif value_text.begins_with("-"):
				color = Color("ff9ea7")
			else:
				color = Color("fff3c4")
		_draw_cell_text(
			font,
			str(values[column_index]),
			columns[column_index],
			columns[column_index + 1],
			y,
			ROW_HEIGHT,
			FONT_SIZE,
			color,
			HORIZONTAL_ALIGNMENT_LEFT if column_index == 0 else HORIZONTAL_ALIGNMENT_CENTER
		)
	_draw_grid(columns, y, ROW_HEIGHT)


func _draw_cell_text(
	font: Font,
	text: String,
	cell_left: float,
	cell_right: float,
	y: float,
	height: float,
	font_size: int,
	color: Color,
	alignment: HorizontalAlignment
) -> void:
	var inset := 9.0 if alignment == HORIZONTAL_ALIGNMENT_LEFT else 2.0
	var baseline_y := y + height * 0.5 + float(font_size) * 0.36
	draw_string(
		font,
		Vector2(cell_left + inset, baseline_y),
		text,
		alignment,
		cell_right - cell_left - inset * 2.0,
		font_size,
		color
	)


func _draw_grid(columns: PackedFloat32Array, y: float, height: float) -> void:
	for column_x in columns:
		draw_line(Vector2(column_x, y), Vector2(column_x, y + height), GRID_COLOR, 1.0)
	draw_line(Vector2(columns[0], y + height), Vector2(columns[6], y + height), GRID_COLOR, 1.0)
