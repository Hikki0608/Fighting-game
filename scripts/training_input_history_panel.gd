class_name TrainingInputHistoryPanel
extends Panel

const FONT_SIZE := 13
const PANEL_PADDING := 12.0
const TITLE_BASELINE_Y := 20.0
const ENTRY_BASELINE_Y := 46.0
const ENTRY_LINE_HEIGHT := 18.0
const ARROW_BOX_WIDTH := 16.0
const ARROW_HALF_LENGTH := 5.5
const ARROW_HEAD_LENGTH := 4.2
const ARROW_HEAD_HALF_WIDTH := 2.9
const TEXT_COLOR := Color("d9f7ff")
const TITLE_COLOR := Color("f2fdff")
const ARROW_COLOR := Color("9becff")
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.82)

var history: Array[Dictionary] = []
var last_rendered_arrow_count := 0


func set_history(next_history: Array[Dictionary]) -> void:
	if history == next_history:
		return
	var copied_history: Array[Dictionary] = []
	for entry in next_history:
		copied_history.append(entry.duplicate(true))
	history = copied_history
	queue_redraw()


func history_size() -> int:
	return history.size()


static func arrow_segments(
	direction: Vector2i,
	center := Vector2.ZERO
) -> PackedVector2Array:
	if direction == Vector2i.ZERO:
		return PackedVector2Array()
	var unit_direction := Vector2(direction).normalized()
	var tail := center - unit_direction * ARROW_HALF_LENGTH
	var tip := center + unit_direction * ARROW_HALF_LENGTH
	var head_base := tip - unit_direction * ARROW_HEAD_LENGTH
	var side_direction := Vector2(-unit_direction.y, unit_direction.x)
	return PackedVector2Array([
		tail,
		tip,
		tip,
		head_base + side_direction * ARROW_HEAD_HALF_WIDTH,
		tip,
		head_base - side_direction * ARROW_HEAD_HALF_WIDTH
	])


func _draw() -> void:
	last_rendered_arrow_count = 0
	var font := ThemeDB.fallback_font
	_draw_right_aligned_text(font, "INPUT HISTORY", TITLE_BASELINE_Y, size.x - PANEL_PADDING, TITLE_COLOR)
	if history.is_empty():
		_draw_right_aligned_text(font, "-", ENTRY_BASELINE_Y, size.x - PANEL_PADDING, TEXT_COLOR)
		return

	for index in history.size():
		var entry: Dictionary = history[index]
		var baseline_y := ENTRY_BASELINE_Y + float(index) * ENTRY_LINE_HEIGHT
		var right_edge := size.x - PANEL_PADDING
		var buttons := PackedStringArray(entry.get("buttons", []))
		var button_text := " + ".join(buttons)
		if not button_text.is_empty():
			right_edge = _draw_right_aligned_text(
				font,
				button_text,
				baseline_y,
				right_edge,
				TEXT_COLOR
			)

		var direction: Vector2i = entry.get("direction", Vector2i.ZERO)
		if direction == Vector2i.ZERO:
			continue
		if not button_text.is_empty():
			right_edge = _draw_right_aligned_text(
				font,
				" + ",
				baseline_y,
				right_edge,
				TEXT_COLOR
			)
		var arrow_center := Vector2(
			right_edge - ARROW_BOX_WIDTH * 0.5,
			baseline_y - float(FONT_SIZE) * 0.36
		)
		_draw_direction_arrow(direction, arrow_center)
		last_rendered_arrow_count += 1


func _draw_right_aligned_text(
	font: Font,
	text: String,
	baseline_y: float,
	right_edge: float,
	color: Color
) -> float:
	var text_width := font.get_string_size(
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		FONT_SIZE
	).x
	var text_position := Vector2(right_edge - text_width, baseline_y)
	draw_string(
		font,
		text_position + Vector2.ONE,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		FONT_SIZE,
		SHADOW_COLOR
	)
	draw_string(
		font,
		text_position,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		FONT_SIZE,
		color
	)
	return text_position.x


func _draw_direction_arrow(direction: Vector2i, center: Vector2) -> void:
	var segments := arrow_segments(direction, center)
	for segment_index in range(0, segments.size(), 2):
		draw_line(
			segments[segment_index] + Vector2.ONE,
			segments[segment_index + 1] + Vector2.ONE,
			SHADOW_COLOR,
			3.5,
			true
		)
	for segment_index in range(0, segments.size(), 2):
		draw_line(
			segments[segment_index],
			segments[segment_index + 1],
			ARROW_COLOR,
			2.0,
			true
		)
