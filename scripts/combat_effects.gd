class_name CombatEffects
extends Node2D

const REN_EFFECT_CORE := Color("efffff")
const REN_EFFECT_LIGHT := Color("7defff")
const REN_EFFECT_BLUE := Color("209cff")
const REN_EFFECT_DEEP := Color("3151e8")

var projectiles: Array[Dictionary] = []
var hit_sparks: Array[Dictionary] = []
var had_visible_effects := false


func configure(
	projectile_source: Array[Dictionary],
	spark_source: Array[Dictionary]
) -> void:
	projectiles = projectile_source
	hit_sparks = spark_source


func _process(_delta: float) -> void:
	var has_visible_effects := not projectiles.is_empty() or not hit_sparks.is_empty()
	if not has_visible_effects:
		if had_visible_effects:
			had_visible_effects = false
			queue_redraw()
		return
	had_visible_effects = true
	queue_redraw()


func _draw() -> void:
	for projectile in projectiles:
		if StringName(projectile.get("effect", &"")) == &"ren_pulse":
			_draw_ren_pulse_projectile(projectile)
			continue
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
		if bool(spark.get("ren_special", false)):
			_draw_ren_special_hit_spark(spark)
			continue
		var spark_color := Color("8defff") if spark.blocked else Color(spark.get("color", Color("fff19a")))
		var radius := float(spark.frames) * 2.5
		draw_circle(spark.position, radius * 0.5, Color(spark_color, 0.16))
		draw_circle(spark.position, radius * 0.24, spark_color)


func _draw_ren_pulse_projectile(projectile: Dictionary) -> void:
	var projectile_position: Vector2 = projectile.position
	var projectile_velocity: Vector2 = projectile.velocity
	var projectile_radius := float(projectile.radius)
	var max_frames := maxi(1, int(projectile.get("max_frames", 105)))
	var age := float(max_frames - int(projectile.frames))
	var phase := age * 0.31
	var direction_x := signf(projectile_velocity.x)
	if is_zero_approx(direction_x):
		direction_x = 1.0
	var forward := Vector2(direction_x, 0.0)
	var side := Vector2(0.0, 1.0)

	var tail_length := 82.0 + sin(phase * 0.7) * 8.0
	var tail_points := PackedVector2Array([
		projectile_position + side * 18.0 - forward * 4.0,
		projectile_position + forward * 18.0,
		projectile_position - side * 18.0 - forward * 4.0,
		projectile_position - forward * tail_length
	])
	draw_colored_polygon(tail_points, Color(REN_EFFECT_DEEP, 0.16))
	for echo_index in range(5, 0, -1):
		var echo_distance := 14.0 + float(echo_index) * 15.0
		var echo_position := projectile_position - forward * echo_distance + side * sin(phase - float(echo_index)) * 3.5
		var echo_scale := 1.0 - float(echo_index) * 0.12
		draw_circle(echo_position, projectile_radius * echo_scale + 7.0, Color(REN_EFFECT_BLUE, 0.035 + float(5 - echo_index) * 0.012))
		draw_circle(echo_position, maxf(2.0, projectile_radius * echo_scale * 0.48), Color(REN_EFFECT_LIGHT, 0.11))
	for lane in 3:
		var lane_offset := (float(lane) - 1.0) * 8.0
		var line_start := projectile_position - forward * (24.0 + float(lane) * 9.0) + side * lane_offset
		var line_end := projectile_position - forward * (72.0 + float(lane) * 15.0) + side * lane_offset * 0.35
		draw_line(line_start, line_end, Color(REN_EFFECT_LIGHT, 0.34 - float(lane) * 0.055), 4.5 - float(lane) * 0.65, true)

	draw_circle(projectile_position, projectile_radius + 18.0, Color(REN_EFFECT_DEEP, 0.1))
	draw_circle(projectile_position, projectile_radius + 10.0, Color(REN_EFFECT_BLUE, 0.16))
	for arc_index in 4:
		var arc_start := phase * (1.0 if arc_index % 2 == 0 else -1.25) + float(arc_index) * TAU * 0.25
		draw_arc(
			projectile_position,
			projectile_radius + 5.0 + float(arc_index % 2) * 7.0,
			arc_start,
			arc_start + 0.9,
			10,
			Color(REN_EFFECT_LIGHT, 0.82 - float(arc_index) * 0.1),
			3.2,
			true
		)
	draw_circle(projectile_position, projectile_radius, Color(REN_EFFECT_LIGHT, 0.88))
	draw_circle(projectile_position + forward * 4.0, projectile_radius * 0.48, Color(REN_EFFECT_CORE, 0.96))
	for mote_index in 4:
		var mote_angle := phase + float(mote_index) * TAU / 4.0
		var mote_offset := Vector2(cos(mote_angle), sin(mote_angle) * 0.7) * (projectile_radius + 14.0)
		draw_circle(projectile_position + mote_offset, 2.6, Color(REN_EFFECT_CORE, 0.78))


func _draw_ren_special_hit_spark(spark: Dictionary) -> void:
	var spark_position: Vector2 = spark.position
	var max_frames := maxi(1, int(spark.get("max_frames", 18)))
	var remaining := clampf(float(spark.frames) / float(max_frames), 0.0, 1.0)
	var progress := 1.0 - remaining
	var is_super := bool(spark.get("super", false))
	var blocked := bool(spark.get("blocked", false))
	var facing_direction := float(int(spark.get("facing", 1)))
	var source_state: StringName = spark.get("source_state", &"")
	var radius := lerpf(22.0, 92.0 if is_super else 68.0, progress)
	var strength := remaining * (0.7 if blocked else 1.0)
	var rotation_phase := progress * (2.4 if is_super else 1.45) * facing_direction

	draw_circle(spark_position, radius * 0.8, Color(REN_EFFECT_DEEP, 0.12 * strength))
	draw_circle(spark_position, radius * 0.38, Color(REN_EFFECT_BLUE, 0.18 * strength))
	var ray_count := 18 if is_super else 12
	for ray_index in ray_count:
		var angle := rotation_phase + float(ray_index) * TAU / float(ray_count)
		var ray_direction := Vector2.from_angle(angle)
		var inner_radius := 5.0 + radius * (0.12 + float(ray_index % 3) * 0.025)
		var outer_radius := radius * (0.72 + float(ray_index % 2) * 0.28)
		draw_line(
			spark_position + ray_direction * inner_radius,
			spark_position + ray_direction * outer_radius,
			Color(REN_EFFECT_LIGHT if ray_index % 3 else REN_EFFECT_CORE, (0.62 - float(ray_index % 3) * 0.09) * strength),
			5.0 if ray_index % 4 == 0 else 2.5,
			true
		)
	for ring_index in 3:
		var ring_radius := radius * (0.42 + float(ring_index) * 0.22)
		var ring_alpha := (0.52 - float(ring_index) * 0.12) * strength
		draw_arc(spark_position, ring_radius, rotation_phase + float(ring_index), rotation_phase + float(ring_index) + PI * 1.35, 24, Color(REN_EFFECT_LIGHT, ring_alpha), 4.0 - float(ring_index), true)

	var impact_axis := Vector2(facing_direction, 0.0)
	match source_state:
		&"ren_rise":
			impact_axis = Vector2(facing_direction * 0.3, -1.0).normalized()
		&"ren_dive":
			impact_axis = Vector2(facing_direction * 0.72, 0.7).normalized()
		&"ren_super":
			impact_axis = Vector2(facing_direction, sin(progress * PI * 3.0) * 0.35).normalized()
	var impact_side := Vector2(-impact_axis.y, impact_axis.x)
	for lane in 3:
		var lane_offset := (float(lane) - 1.0) * 13.0
		var start := spark_position - impact_axis * radius * 0.95 + impact_side * lane_offset
		var finish := spark_position + impact_axis * radius * (0.7 + float(lane % 2) * 0.22) + impact_side * lane_offset * 0.25
		draw_line(start, finish, Color(REN_EFFECT_CORE, (0.62 - float(lane) * 0.11) * strength), 4.0 - float(lane) * 0.65, true)

	if is_super:
		for slash_index in 2:
			var slash_points := PackedVector2Array()
			var slash_radius := radius * (0.78 - float(slash_index) * 0.18)
			for step in 13:
				var slash_t := float(step) / 12.0
				var angle := lerpf(-1.12, 1.12, slash_t) + float(slash_index) * 0.32
				slash_points.append(spark_position + Vector2(cos(angle) * slash_radius * facing_direction, sin(angle) * slash_radius))
			draw_polyline(slash_points, Color(REN_EFFECT_BLUE, 0.22 * strength), 13.0 - float(slash_index) * 3.0, true)
			draw_polyline(slash_points, Color(REN_EFFECT_CORE, 0.74 * strength), 2.5, true)
	draw_circle(spark_position, 12.0 + remaining * 9.0, Color(REN_EFFECT_CORE, 0.9 * strength))
