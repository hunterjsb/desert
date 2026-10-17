extends WeatherProbe
## Wind & storms probe 6: the wind moves things at the rate drag says. With
## gusts off and the clock stopped the wind is steady, so a floating box must
## follow the closed-form drag curve. On open sand, out of any dune's lee, a
## storm slides a box downwind and a breeze leaves it be, and the same goes
## for the player.


func run() -> void:
	var tuning := Tuning.current()
	tuning.gust_strength = 0.0
	tuning.gust_storm_strength = 0.0
	await load_weather()
	# Whichever way the wind swings, and the floater's ground upwind too.
	var open := open_sand(42.0, 350.0)
	teleport(open.x, open.y)
	await settle(true)
	var px := world.player_world_x()
	var pz := world.player_world_z()
	var deep := find_time(func(t: float) -> bool:
		var along := field.prevailing_at(t).normalized() * 80.0
		return player_storm_at(t) == 1.0 and field.storm_at(px - along.x, pz - along.y, t) == 1.0 \
			and field.storm_at(px + along.x, pz + along.y, t) == 1.0)
	var breeze := find_time(func(t: float) -> bool:
		return player_storm_at(t) == 0.0 and field.wind_at(px, pz, t).length() < 9.0)
	world.time_warp = 0.0

	world.time = deep
	var wind := world.weather.felt_wind(world.player.global_position)
	var downwind := wind.normalized()
	print("storm wind %.1f m/s, breeze %.1f m/s" % [wind.length(), field.wind_at(px, pz, breeze).length()])

	var floater := drop_box(px - downwind.x * 60.0, pz - downwind.z * 60.0, 15.0)
	floater.gravity_scale = 0.0
	var on_sand := drop_box(px + downwind.z * 10.0, pz - downwind.x * 10.0, 0.6)
	var player_from := world.player.global_position
	await get_tree().physics_frame
	var floater_from := floater.global_position
	var sand_from := on_sand.global_position
	var seconds := 4.0
	await physics_frames(roundi(seconds * Engine.physics_ticks_per_second))
	# Quadratic drag from rest in a steady wind w: x = w t - (m/c) ln(1 + c w t / m).
	var k := world.weather.catch_of(floater) / floater.mass
	var w := wind.length()
	var expected := w * seconds - log(1.0 + k * w * seconds) / k
	var moved := floater.global_position - floater_from
	var along := moved.dot(downwind)
	print("floater moved %.2f m downwind, drag says %.2f m" % [along, expected])
	check(absf(along - expected) < expected * 0.05, "a floating box drifts as drag says (%.2f of %.2f m)" % [along, expected])
	check(_sideways(moved, downwind) < along * 0.02, "and straight downwind")
	_pushed(on_sand.global_position - sand_from, downwind, 3.0, "a storm slides a box on the sand")
	var shove := (w - tuning.wind_resist_speed) * tuning.wind_push * seconds
	var player_moved := world.player.global_position - player_from
	_pushed(player_moved, downwind, shove * 0.75, "a storm shoves the player")
	check(player_moved.dot(downwind) < shove * 1.25, "by about what the wind is worth (%.2f of %.2f m)"
		% [player_moved.dot(downwind), shove])
	on_sand.queue_free()
	floater.queue_free()

	world.time = breeze
	teleport(px, pz)
	var calm := drop_box(px + 5.0, pz + 5.0, 0.6)
	await physics_frames(120)
	var calm_from := calm.global_position
	player_from = world.player.global_position
	await physics_frames(180)
	check(calm.global_position.distance_to(calm_from) < 0.05, "a breeze leaves a box on the sand alone (moved %.3f m)"
		% calm.global_position.distance_to(calm_from))
	check(world.player.global_position.distance_to(player_from) < 0.05, "and the player standing")


func _pushed(moved: Vector3, downwind: Vector3, at_least: float, what: String) -> void:
	var along := moved.dot(downwind)
	check(along > at_least, "%s (%.2f m downwind)" % [what, along])
	check(_sideways(moved, downwind) < along * 0.5, "%s, roughly downwind" % what)


func _sideways(moved: Vector3, downwind: Vector3) -> float:
	var flat := Vector3(moved.x, 0.0, moved.z)
	return (flat - downwind * flat.dot(downwind)).length()
