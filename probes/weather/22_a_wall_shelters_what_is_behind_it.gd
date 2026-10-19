extends DeckProbe
## Wind & storms probe 22: a wall shelters what's behind it, as a small dune
## does. A camp's wall stands broadside to a steady wind in a storm, on open
## sand: just behind it the wind is cut by about a full lee's share, and the
## storm's wear and harm by theirs; beside it, upwind of it and seven of its
## heights behind it, nothing is. Edge-on to the wind it shelters nothing. A
## light box resting behind it stays put where the same box in the open slides.

const WIND := 12.0


func run() -> void:
	await load_lines()
	var tuning := world.tuning
	var defaults := Tuning.new()
	tuning.lee_wind = defaults.lee_wind
	tuning.lee_storm = defaults.lee_storm
	tuning.storm_threshold = -2.0
	wind = RopeWind.new(world.run_seed, tuning)
	world.weather.field = wind
	var open := open_sand(0.0, 40.0)
	check(not is_nan(open.x), "open sand near where the run began")
	if is_nan(open.x):
		return
	teleport(open.x, open.y)
	await settle(true)
	var down := Vector2.from_angle(WeatherField.mean_heading(world.run_seed))
	var along := Vector3(down.x, 0.0, down.y)
	# Three pieces across the wind, laden, a frame on the middle one walled on its windward face.
	var steps := [[&"piece", Vector2i(1, 0)], [&"piece", Vector2i(2, 0)], [&"frame", Vector2i(1, 0), 0]]
	for cell in [Vector2i(0, 0), Vector2i(2, 0)]:
		for x in [-0.3, 0.0, 0.3]:
			steps.append([&"stick", cell, &"top", Vector2(x, 0.0), 0.0, &"big_battery"])
	var deck := Rig.build(world.content, steps).deck
	deck.global_transform = Transform3D(Basis(Vector3.UP, atan2(-down.x, -down.y)), world.player.global_position + Vector3.UP * 0.2)
	var windward: Socket = null
	for side: StringName in [&"front", &"back", &"left", &"right"]:
		var face := Rig.face_of(deck, Vector2i(1, 0), side)
		if windward == null or (deck.global_basis * face.transform.basis.z).dot(-along) > (deck.global_basis * windward.transform.basis.z).dot(-along):
			windward = face
	deck.join(Catalog.device(&"chassis") as Chassis, windward)
	blow(down * WIND)
	await simulate(1.0)
	var wall := deck.global_transform * (deck.plates()[0][0] as Vector3)
	var across := along.cross(Vector3.UP)
	var behind := wall + along * 1.5
	check(absf(_cut(behind) - tuning.lee_wind) < tuning.lee_wind * 0.1,
		"just behind it the wind is cut by about a full lee's %d%% (%.3f)" % [roundi(tuning.lee_wind * 100.0), _cut(behind)])
	var storm := 1.0 - world.weather.felt_storm(behind) / world.weather.field_storm(behind)
	check(absf(storm - tuning.lee_storm) < tuning.lee_storm * 0.1, "and the storm by about its %d%% (%.3f)" % [roundi(tuning.lee_storm * 100.0), storm])
	for spot: Array in [[wall + across * 2.5 + along * 1.5, "beside it"], [wall - along * 1.5, "upwind of it"],
			[wall + along * 8.0, "seven heights behind it"]]:
		check(_cut(spot[0]) == 0.0, "%s, nothing (%.3f)" % [spot[1], _cut(spot[0])])

	var sand := func(p: Vector3) -> Vector3: return Vector3(p.x, world.height_under(p) + 0.26, p.z)
	var sheltered := await _slide(sand.call(wall + along * 2.0))
	var exposed := await _slide(sand.call(wall + across * 4.0 + along * 2.0))
	check(exposed > 0.5 and sheltered < 0.05, "a box behind it stays put (%.2f m) where one in the open slides (%.2f m)"
		% [sheltered, exposed])

	blow(Vector2(-down.y, down.x) * WIND)
	await simulate(3.0 / 60.0)
	check(_cut(behind) == 0.0 and _cut(wall + across * 1.5) == 0.0, "edge-on to the wind it shelters nothing (%.3f, %.3f)"
		% [_cut(behind), _cut(wall + across * 1.5)])


## The share of the wind kept from a place.
func _cut(at: Vector3) -> float:
	return 1.0 - world.weather.felt_wind(at).length() / world.weather.field_wind(at).length()


## How far a light box resting at a place slides in two seconds of the wind.
func _slide(at: Vector3) -> float:
	var box := RigidBody3D.new()
	var shape := CollisionShape3D.new()
	shape.shape = BoxShape3D.new()
	(shape.shape as BoxShape3D).size = Vector3.ONE * 0.5
	box.add_child(shape)
	box.mass = 3.0
	world.content.add_child(box)
	box.global_position = at
	await simulate(0.5)
	var from := box.global_position
	await simulate(2.0)
	var moved := flat(box.global_position - from).length()
	box.queue_free()
	return moved
