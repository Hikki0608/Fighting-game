class_name MenuBackdrop
extends Control

const DESIGN_SIZE := Vector2(1152.0, 648.0)
const LEFT_ACCENT := Color("2cccf4")
const RIGHT_ACCENT := Color("ff4f86")
const GOLD_ACCENT := Color("f5d77a")
const REDRAW_INTERVAL := 1.0 / 30.0

var animation_time := 0.0
var redraw_accumulator := 0.0
var motes: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in 34:
		motes.append({
			"position": Vector2(
				fmod(73.0 + float(index * 193), DESIGN_SIZE.x),
				fmod(41.0 + float(index * 107), DESIGN_SIZE.y)
			),
			"speed": 7.0 + float(index % 6) * 2.1,
			"drift": 0.45 + float(index % 5) * 0.13,
			"phase": float(index) * 0.79,
			"radius": 0.8 + float(index % 3) * 0.55,
			"side": index % 2
		})


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	animation_time = fmod(animation_time + delta, 3600.0)
	redraw_accumulator += delta
	if redraw_accumulator < REDRAW_INTERVAL:
		return
	redraw_accumulator = fmod(redraw_accumulator, REDRAW_INTERVAL)
	queue_redraw()


func _draw() -> void:
	var canvas_size := size if size.x > 0.0 and size.y > 0.0 else DESIGN_SIZE
	draw_rect(Rect2(Vector2.ZERO, canvas_size), Color("071019"), true)

	# Layered bands give the arena backdrop a polished, deep-blue grade.
	for band in 8:
		var ratio := float(band) / 7.0
		var band_color := Color(
			0.018 + ratio * 0.012,
			0.052 + ratio * 0.008,
			0.076 + ratio * 0.018,
			0.82
		)
		var band_height := canvas_size.y / 8.0 + 1.0
		draw_rect(
			Rect2(0.0, float(band) * canvas_size.y / 8.0, canvas_size.x, band_height),
			band_color,
			true
		)

	# Cyan and crimson spotlights visually connect the menu to both fighters.
	for layer in 5:
		var glow_radius := 520.0 - float(layer) * 86.0
		var glow_alpha := 0.014 + float(layer) * 0.006
		draw_circle(Vector2(-86.0, 352.0), glow_radius, Color(LEFT_ACCENT, glow_alpha))
		draw_circle(
			Vector2(canvas_size.x + 86.0, 352.0),
			glow_radius,
			Color(RIGHT_ACCENT, glow_alpha)
		)

	var spotlight := PackedVector2Array([
		Vector2(canvas_size.x * 0.5 - 238.0, 0.0),
		Vector2(canvas_size.x * 0.5 + 238.0, 0.0),
		Vector2(canvas_size.x * 0.5 + 82.0, canvas_size.y),
		Vector2(canvas_size.x * 0.5 - 82.0, canvas_size.y)
	])
	draw_colored_polygon(spotlight, Color(GOLD_ACCENT, 0.018))

	# Slow diagonal light sweeps make the static screen feel alive.
	for streak in 5:
		var sweep := fmod(animation_time * 22.0 + float(streak) * 238.0, 1380.0) - 180.0
		draw_line(
			Vector2(sweep, 138.0),
			Vector2(sweep - 180.0, canvas_size.y - 72.0),
			Color(LEFT_ACCENT if streak % 2 == 0 else RIGHT_ACCENT, 0.045),
			2.0,
			true
		)

	for mote in motes:
		var base_position: Vector2 = mote["position"]
		var mote_y := fposmod(
			base_position.y - animation_time * float(mote["speed"]) + 20.0,
			canvas_size.y + 40.0
		) - 20.0
		var mote_x := base_position.x + sin(
			animation_time * float(mote["drift"]) + float(mote["phase"])
		) * 12.0
		var mote_color := LEFT_ACCENT if int(mote["side"]) == 0 else RIGHT_ACCENT
		var pulse := 0.16 + 0.10 * sin(animation_time * 1.4 + float(mote["phase"]))
		draw_circle(
			Vector2(mote_x, mote_y),
			float(mote["radius"]),
			Color(mote_color, maxf(0.04, pulse))
		)

	# Cinematic bars, a horizon glow, and corner brackets finish the frame.
	draw_rect(Rect2(0.0, 0.0, canvas_size.x, 18.0), Color(0.0, 0.0, 0.0, 0.72), true)
	draw_rect(
		Rect2(0.0, canvas_size.y - 18.0, canvas_size.x, 18.0),
		Color(0.0, 0.0, 0.0, 0.78),
		true
	)
	draw_line(
		Vector2(0.0, 132.0),
		Vector2(canvas_size.x, 132.0),
		Color(GOLD_ACCENT, 0.16),
		1.0,
		true
	)
	draw_line(Vector2(26.0, 32.0), Vector2(132.0, 32.0), Color(LEFT_ACCENT, 0.42), 2.0)
	draw_line(Vector2(26.0, 32.0), Vector2(26.0, 92.0), Color(LEFT_ACCENT, 0.42), 2.0)
	draw_line(
		Vector2(canvas_size.x - 26.0, 32.0),
		Vector2(canvas_size.x - 132.0, 32.0),
		Color(RIGHT_ACCENT, 0.42),
		2.0
	)
	draw_line(
		Vector2(canvas_size.x - 26.0, 32.0),
		Vector2(canvas_size.x - 26.0, 92.0),
		Color(RIGHT_ACCENT, 0.42),
		2.0
	)

	for edge in 5:
		var edge_alpha := 0.035 + float(edge) * 0.024
		draw_rect(
			Rect2(float(edge) * 18.0, 0.0, 19.0, canvas_size.y),
			Color(0.0, 0.0, 0.0, edge_alpha),
			true
		)
		draw_rect(
			Rect2(canvas_size.x - float(edge + 1) * 18.0, 0.0, 19.0, canvas_size.y),
			Color(0.0, 0.0, 0.0, edge_alpha),
			true
		)
