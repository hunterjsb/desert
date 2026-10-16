extends MovementProbe
## Movement probe 12: crouching makes you smaller to the wind. In a steady
## storm wind, standing, the wind shoves you as it always has; crouched, it
## catches less of you and shoves you much less. It goes through the felt
## wind, so inside a bubble neither moves you. Crouched, you're lower and
## slower too.

const STORM := 24.0
const SECONDS := 3.0


func run() -> void:
	await load_moving()
	set_rate(60, 4)
	var t := world.tuning
	var flat := flat_place(world.player_world_x(), world.player_world_z(), 150.0, 4.0)
	var downwind := Vector2(0.6, -0.8)
	blow(downwind * STORM)

	var stood := await _shoved(flat, [])
	var eye := player.camera.position.y
	var crouched := await _shoved(flat, ["crouch"])
	var low := player.camera.position.y
	var force := func(catch: float) -> float:
		return maxf(0.0, STORM * sqrt(catch) - t.wind_resist_speed) * t.wind_push * SECONDS
	print("a %.0f m/s wind shoves you %.2f m standing (%.2f expected), %.2f m crouched (%.2f)" % [STORM, stood,
		force.call(1.0), crouched, force.call(t.crouch_catch)])
	check(absf(stood - force.call(1.0)) < 0.1, "standing, the wind shoves you as it always has (%.2f m)" % stood)
	check(crouched < stood * 0.5, "crouched, it shoves you far less (%.2f of %.2f m)" % [crouched, stood])
	check(absf(crouched - force.call(t.crouch_catch)) < 0.1, "by what your smaller catch is worth (%.2f m)" % crouched)
	check(eye - low > t.crouch_drop * 0.8, "crouched, your eyes are %.2f m lower (%.2f)" % [t.crouch_drop, eye - low])

	var shelter := Shelter.new()
	world.content.add_child(shelter)
	shelter.global_position = Vector3(world.engine_x(flat.x), world.height_at(flat.x, flat.z) + 0.25,
		world.engine_z(flat.z))
	shelter.radius = t.shield_radius
	var calm_stood := await _shoved(flat, [])
	var calm_crouched := await _shoved(flat, ["crouch"])
	check(calm_stood < 0.01 and calm_crouched < 0.01, "inside a bubble the wind moves you not at all (%.3f, %.3f m)"
		% [calm_stood, calm_crouched])
	shelter.radius = 0.0

	blow(Vector2.ZERO)
	await place(flat.x, flat.z, Vector2(1.0, 0.0))
	hold(["crouch", "move_forward"])
	await simulate(1.0)
	check(absf(flat_speed() - t.crouch_speed) < 0.1, "crouched, you walk at %.1f m/s (%.2f)" % [t.crouch_speed,
		flat_speed()])
	set_rate(60)


## How far the wind moves you downwind in SECONDS, holding these keys.
func _shoved(flat: Dictionary, keys: Array) -> float:
	await place(flat.x, flat.z, Vector2(1.0, 0.0))
	hold(keys)
	await simulate(0.5)
	var from := where()
	await simulate(SECONDS)
	var moved := where() - from
	return Vector2(moved.x, moved.z).dot(wind.override.call(0.0, 0.0, 0.0).normalized()) if moved != Vector3.ZERO \
		else 0.0
