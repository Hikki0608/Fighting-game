extends SceneTree

const CombatEffectsScript := preload("res://scripts/combat_effects.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _sample_spark(blocked := false) -> Dictionary:
	return {
		"position": Vector2(640.0, 330.0),
		"frames": 30,
		"max_frames": 30,
		"effect_frames": 12,
		"splash_frames": 30,
		"splash_seed": 24681357,
		"impact_damage": 110,
		"splash_color": Color("ddf7fa"),
		"blocked": blocked,
		"color": Color("fff19a"),
		"source_state": &"heavy",
		"ren_special": false,
		"super": false,
		"facing": 1
	}


func _run() -> void:
	var effects := CombatEffectsScript.new() as CombatEffects
	root.add_child(effects)
	var projectiles: Array[Dictionary] = []
	var sparks: Array[Dictionary] = [_sample_spark()]
	effects.configure(projectiles, sparks)

	var hit_count := effects._splash_particle_count(sparks[0])
	var blocked_spark := _sample_spark(true)
	var blocked_count := effects._splash_particle_count(blocked_spark)
	_expect(hit_count >= 10, "a clean hit must create a visible droplet spray")
	_expect(blocked_count < hit_count, "guarded attacks must create fewer droplets than clean hits")

	var initial_particle := effects._splash_particle_state(sparks[0], 0)
	var advanced_spark := sparks[0].duplicate(true)
	advanced_spark.frames = 18
	var advanced_particle := effects._splash_particle_state(advanced_spark, 0)
	_expect(not initial_particle.is_empty(), "the first splash particle must exist on impact")
	_expect(not advanced_particle.is_empty(), "a splash particle must survive long enough to arc")
	if not initial_particle.is_empty() and not advanced_particle.is_empty():
		_expect(
			Vector2(initial_particle.position).distance_to(Vector2(advanced_particle.position)) > 10.0,
			"splash particles must travel away from the impact point"
		)
		_expect(
			float(advanced_particle.alpha) < float(initial_particle.alpha),
			"splash particles must fade over their lifetime"
		)

	# Let CanvasItem process and execute the actual draw path as part of the
	# smoke test, catching invalid drawing calls in both native and Web builds.
	sparks[0].frames = 18
	effects.queue_redraw()
	await process_frame
	await process_frame

	if failures.is_empty():
		print("COMBAT_EFFECTS_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
