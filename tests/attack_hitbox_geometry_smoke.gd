extends SceneTree

const MainScript := preload("res://scripts/main.gd")

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _prepare_fighter(fighter: Fighter, next_state: StringName, next_position: Vector2, next_facing: int) -> void:
	fighter.position = next_position
	fighter.state = next_state
	fighter.state_frame = 0
	fighter.motion_tick = 0
	fighter.landing_frames = 0
	fighter.sprite_transition_frames = 0
	fighter.facing = next_facing
	fighter.velocity = Vector2.ZERO
	fighter.attack_connected = false
	fighter.attack_has_connected = false
	fighter.connected_hit_frames.clear()


func _run() -> void:
	var game := MainScript.new()
	root.add_child(game)
	game.phase = &"fight"
	var ren: Fighter = game.fighters[0]
	var vel: Fighter = game.fighters[1]

	# Reproduce the reported case: Ren's visible jump kick is well above and to
	# the left of grounded Vel. The old root-anchored box reached Vel anyway.
	_prepare_fighter(ren, &"jump_heavy", Vector2(105.0, 258.0), 1)
	ren.state_frame = int(Fighter.ATTACKS[&"jump_heavy"].startup) + 1
	_prepare_fighter(vel, &"idle", Vector2(385.0, Fighter.GROUND_Y), -1)
	vel.health = 1000
	var jump_kick_box := ren.attack_rect()
	var jump_kick_sprite := ren.hurt_rect()
	var grounded_vel_box := vel.hurt_rect()
	_expect(jump_kick_box.has_area(), "the active jump kick must have an attack box")
	_expect(
		jump_kick_box.end.x <= jump_kick_sprite.end.x + 10.5,
		"the jump kick must not reach farther than the visible foot"
	)
	_expect(
		jump_kick_box.end.y < grounded_vel_box.position.y,
		"the airborne kick must not extend down into a distant grounded opponent"
	)
	game._resolve_attacks()
	_expect(vel.health == 1000, "the separated jump kick must whiff")

	# A close standing jab still connects when the visible hand reaches Vel.
	_prepare_fighter(ren, &"light", Vector2(500.0, Fighter.GROUND_Y), 1)
	ren.state_frame = int(Fighter.ATTACKS[&"light"].startup) + 1
	_prepare_fighter(vel, &"idle", Vector2(710.0, Fighter.GROUND_Y), -1)
	vel.health = 1000
	game._resolve_attacks()
	_expect(vel.health < 1000, "a visibly touching close jab must still connect")

	# Flash Palm uses its rendered energy core rather than the fighter origin.
	_prepare_fighter(ren, &"ren_palm", Vector2(500.0, Fighter.GROUND_Y), 1)
	ren.state_frame = int(Fighter.ATTACKS[&"ren_palm"].startup) + 1
	var palm_box := ren.attack_rect()
	_expect(
		palm_box.get_center().distance_to(ren.ren_palm_effect_world_position()) < 0.1,
		"Flash Palm's attack box must stay centered on its visible energy core"
	)

	if failures.is_empty():
		print("ATTACK_HITBOX_GEOMETRY_SMOKE_OK")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
