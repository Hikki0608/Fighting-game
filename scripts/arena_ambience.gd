class_name ArenaAmbience
extends Node2D

const TILE_WIDTH := 1152.0
const TILE_HALF_WIDTH := TILE_WIDTH * 0.5
const REDRAW_INTERVAL := 1.0 / 12.0
const DUST_X := [92.0, 238.0, 406.0, 586.0, 754.0, 932.0, 1080.0]
const DUST_Y := [512.0, 487.0, 536.0, 500.0, 528.0, 491.0, 542.0]

var arena_center_x := TILE_HALF_WIDTH
var animation_time := 0.0
var redraw_accumulator := 0.0
var celebration_seconds := 0.0
var super_pulse_seconds := 0.0
var first_visible_tile := 0
var last_visible_tile := 0


func configure(center_x: float) -> void:
	arena_center_x = center_x


func set_camera_view(center_x: float, visible_half_width: float) -> void:
	# Each background copy is wider than the viewport. Restrict procedural
	# flames, banners, and dust to copies that can actually be seen instead of
	# submitting all three copies to the renderer every frame.
	var center_tile_left := arena_center_x - TILE_HALF_WIDTH
	var visible_left := center_x - visible_half_width + 1.0
	var visible_right := center_x + visible_half_width - 1.0
	var next_first := clampi(
		floori((visible_left - center_tile_left) / TILE_WIDTH),
		-1,
		1
	)
	var next_last := clampi(
		floori((visible_right - center_tile_left) / TILE_WIDTH),
		-1,
		1
	)
	if next_first == first_visible_tile and next_last == last_visible_tile:
		return
	first_visible_tile = next_first
	last_visible_tile = next_last
	queue_redraw()


func celebrate(duration := 1.6) -> void:
	celebration_seconds = maxf(celebration_seconds, duration)
	queue_redraw()


func pulse_for_super(duration := 0.7) -> void:
	super_pulse_seconds = maxf(super_pulse_seconds, duration)
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta
	celebration_seconds = maxf(0.0, celebration_seconds - delta)
	super_pulse_seconds = maxf(0.0, super_pulse_seconds - delta)
	redraw_accumulator += delta
	if redraw_accumulator < REDRAW_INTERVAL:
		return
	redraw_accumulator = fmod(redraw_accumulator, REDRAW_INTERVAL)
	queue_redraw()


func _draw() -> void:
	var celebration_strength := clampf(celebration_seconds / 1.6, 0.0, 1.0)
	var super_strength := clampf(super_pulse_seconds / 0.7, 0.0, 1.0)
	for tile_index in range(first_visible_tile, last_visible_tile + 1):
		var tile_left := arena_center_x + float(tile_index) * TILE_WIDTH - TILE_HALF_WIDTH
		_draw_flame(Vector2(tile_left + 252.0, 364.0), 1.0, float(tile_index) + 0.2)
		_draw_flame(Vector2(tile_left + 900.0, 364.0), 1.0, float(tile_index) + 1.7)
		_draw_flame(Vector2(tile_left + 459.0, 324.0), 0.62, float(tile_index) + 2.8)
		_draw_flame(Vector2(tile_left + 693.0, 324.0), 0.62, float(tile_index) + 4.1)
		_draw_banner_shimmer(tile_left + 116.0, 154.0, Color("59d9f5"), float(tile_index))
		_draw_banner_shimmer(tile_left + 984.0, 154.0, Color("ff789b"), float(tile_index) + 1.4)
		_draw_dust(tile_left, tile_index)
		if celebration_strength > 0.0:
			_draw_crowd_celebration(tile_left, tile_index, celebration_strength)

		var gate_center := Vector2(tile_left + 576.0, 232.0)
		var gate_glow_alpha := 0.025 + super_strength * 0.12
		var gate_glow_radius := 58.0 + super_strength * 26.0
		draw_circle(gate_center, gate_glow_radius, Color(1.0, 0.76, 0.3, gate_glow_alpha))


func _draw_flame(point: Vector2, scale_factor: float, phase_offset: float) -> void:
	var flicker := 0.5 + 0.5 * sin(animation_time * 8.0 + phase_offset * 2.3)
	var sideways := sin(animation_time * 5.3 + phase_offset) * 2.2 * scale_factor
	var flame_height := (16.0 + flicker * 7.0) * scale_factor
	draw_circle(point, (25.0 + flicker * 5.0) * scale_factor, Color(1.0, 0.32, 0.08, 0.06 + flicker * 0.035))
	var outer_flame := PackedVector2Array([
		point + Vector2(-7.0 * scale_factor, 5.0 * scale_factor),
		point + Vector2(sideways, -flame_height),
		point + Vector2(7.0 * scale_factor, 5.0 * scale_factor),
		point + Vector2(0.0, 10.0 * scale_factor)
	])
	draw_colored_polygon(outer_flame, Color(1.0, 0.27 + flicker * 0.12, 0.05, 0.72))
	draw_circle(point + Vector2(sideways * 0.25, -2.0 * scale_factor), 3.4 * scale_factor, Color(1.0, 0.88, 0.48, 0.92))


func _draw_banner_shimmer(x: float, y: float, color: Color, phase_offset: float) -> void:
	var wave := sin(animation_time * 2.2 + phase_offset) * 2.4
	var shimmer := PackedVector2Array([
		Vector2(x + 8.0, y + 5.0),
		Vector2(x + 14.0 + wave, y + 5.0),
		Vector2(x + 13.0 - wave, y + 86.0),
		Vector2(x + 8.0, y + 94.0)
	])
	draw_colored_polygon(shimmer, Color(color, 0.075))


func _draw_dust(tile_left: float, tile_index: int) -> void:
	for mote_index in DUST_X.size():
		var phase := float(mote_index) * 1.37 + float(tile_index) * 0.91
		var drift_x := sin(animation_time * 0.42 + phase) * 14.0
		var drift_y := sin(animation_time * 0.67 + phase * 0.73) * 5.0
		var point := Vector2(tile_left + DUST_X[mote_index] + drift_x, DUST_Y[mote_index] + drift_y)
		var alpha := 0.07 + 0.035 * (0.5 + 0.5 * sin(animation_time + phase))
		draw_circle(point, 1.2 + float(mote_index % 3) * 0.35, Color(0.96, 0.79, 0.48, alpha))


func _draw_crowd_celebration(tile_left: float, tile_index: int, strength: float) -> void:
	for spark_index in 12:
		var phase := float(spark_index) * 0.83 + float(tile_index) * 1.9
		var local_x := 42.0 + float(spark_index) * 94.0
		var lift := fmod(animation_time * 48.0 + phase * 17.0, 62.0)
		var point := Vector2(tile_left + local_x + sin(animation_time * 3.0 + phase) * 7.0, 446.0 - lift)
		var sparkle_color := Color("8defff") if spark_index % 2 == 0 else Color("ffd27a")
		draw_circle(point, 1.8 + strength * 1.5, Color(sparkle_color, strength * 0.42))
