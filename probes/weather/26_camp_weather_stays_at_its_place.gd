extends ShieldProbe
## A retained camp samples its own day through scouting and an origin shift.

func run() -> void:
	await load_storm(0.0)
	world.set_physics_process(false)
	world.player.set_physics_process(false)
	world.time_warp = 0.0
	world.moon.place(20.0, 10.0)
	var camp := Node3D.new()
	world.content.add_child(camp)
	camp.global_position = world.player.global_position + Vector3.UP
	var x := world.world_x(camp.global_position.x)
	var z := world.world_z(camp.global_position.z)
	world.home._marked = true
	world.home.anchor = Sites.Anchor.new(x, z, Sphere.point(world.moon.latitude, world.moon.longitude), 1.0, world.moon.radius)
	world.home.bounds = Rect2(Vector2(x, z) - Vector2.ONE * 4.0, Vector2.ONE * 8.0)
	var day := world.weather.day
	world.time = fposmod(0.4 - day.time_of_day(0.0, world.moon.longitude), 1.0) * world.tuning.day_minutes * 60.0
	var nearby := _sample(camp.global_position)
	var legacy := world.weather.temperature_under(0.0)
	world.player.global_position.x += 2000.0
	world.moon.advance(2000.0, 0.0)
	var remote := _sample(camp.global_position)
	var player := _sample(world.player.global_position)
	print("camp near ", nearby, ", remote ", remote, "; player ", player)
	check(nearby.distance_to(remote) < 0.0001, "the camp's light and temperature stay at the camp while the player scouts")
	check(remote.distance_to(player) > 0.01 and absf(world.weather.temperature_under(0.0) - legacy) > 0.1,
		"the player's local day and legacy temperature query still follow the player")
	world.shift_origin(Vector2i(64, -32))
	var shifted := _sample(camp.global_position)
	print("after origin shift ", shifted)
	check(remote.distance_to(shifted) < 0.0001, "shifting the engine origin keeps the same camp weather")


func _sample(at: Vector3) -> Vector2:
	return Vector2(world.weather.felt_light(at), world.weather.field_temperature(at))
