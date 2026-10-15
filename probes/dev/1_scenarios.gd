extends WeatherProbe
## Dev probe 1: every scenario drops you where it says. A storm 100 m away is
## 100 m upwind and you face it; deep is deep; dusk is dusk; the test kit lands
## in front of you. Checked against the field itself and against what the game
## then shows.

const SLACK := 1.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	for scenario in Scenarios.LIST:
		var place := Scenarios.find(world, scenario)
		check(not place.is_empty(), "%s: found in this run's weather" % scenario.key)
		if place.is_empty():
			continue
		world.respawn(place.x, place.z, place.yaw, place.time)
		world.time_warp = 0.0
		await physics_frames(3)
		var at := Vector2(world.player_world_x(), world.player_world_z())
		var t := world.time
		var facing := -world.player.global_basis.z
		var ahead := Vector2(facing.x, facing.z).normalized()
		var upwind := -field.prevailing_at(t).normalized()
		var hour := world.weather.day.time_of_day(t)
		var stormy := field.raw_storm_at(at.x, at.y, t) > 0.0
		var what: String = scenario.key
		check(world.weather.in_storm == stormy, "%s: the game agrees about the storm" % what)
		if scenario.has("day"):
			check(hour >= scenario.day[0] and hour <= scenario.day[1], "%s: at the right time of day (%.3f)" % [what, hour])
		match scenario.kind:
			"spawn":
				check(at.distance_to(Vector2.ONE * Tuning.current().chunk_size * 0.5) < 0.01 and t == 0.0,
					"spawn: where and when the run began")
			"clear", "kit":
				check(not stormy and field.next_change(at.x, at.y, t, 600.0, 5.0) == INF,
					"%s: no storm for 10 minutes" % what)
				if scenario.kind == "kit":
					check(field.wind_at(at.x, at.y, t).length() < scenario.calm, "kit: a calm spell")
					await _kit_lands_near_you()
			"front", "back":
				check(stormy == (scenario.kind == "back"), "%s: on the right side of the edge" % what)
				check(ahead.dot(upwind) > 0.999, "%s: facing upwind, where it comes from" % what)
				var edge := _edge(at, upwind, t, stormy)
				check(absf(edge - scenario.distance) < SLACK,
					"%s: the edge is %.0f m upwind (%.2f m)" % [what, scenario.distance, edge])
			"deep":
				check(field.storm_at(at.x, at.y, t) == 1.0, "deep: full storm")
				check(_edge(at, upwind, t, true) > 250.0 and _edge(at, -upwind, t, true) > 250.0,
					"deep: far from either edge")
			"sky":
				var sun := world.weather.day.sun_direction(t, world.moon.latitude).y
				check(not stormy, "%s: a clear sky" % what)
				check((sun > 0.0 and sun < 0.12) if what == "dusk" else sun < 0.0,
					"%s: the sun is where it should be (%.2f)" % [what, sun])


## Metres along `along` until the storm state differs from `inside`.
func _edge(from: Vector2, along: Vector2, t: float, inside: bool) -> float:
	var d := 0.0
	while d < 6000.0:
		d += 0.1
		var p := from + along * d
		if (field.raw_storm_at(p.x, p.y, t) > 0.0) != inside:
			return d
	return INF


## Two devices and every kit part land on the sand in front of you, within a
## few steps. Light parts may then slide off on the wind, which is real.
func _kit_lands_near_you() -> void:
	await settle(true)
	var kit := Scenarios.kit(world)
	await physics_frames(30)
	var player := world.player
	var ahead := -player.global_basis.z
	var devices := 0
	var parts := 0
	var strays := PackedStringArray()
	for body in kit:
		if body is Cable:
			continue
		var off := body.global_position - player.global_position
		var c := clearance(body)
		devices += 1 if body is Device else 0
		parts += 1 if body is Part else 0
		if off.dot(ahead) < 1.0 or Vector2(off.x, off.z).length() > 5.0 or c < -0.05 or c > 0.6:
			strays.append("%s %.1fm %.2fm up" % [body.get("label"), Vector2(off.x, off.z).length(), c])
	# Every part, plus both cables' plugs.
	check(devices == Scenarios.KIT_DEVICES.size() and parts == Scenarios.KIT_PARTS.size() + 4,
		"kit: every device and part dropped")
	check(strays.is_empty(), "kit: all of it on the sand within 5 m in front of you (%s)" % ", ".join(strays))
	for body in kit:
		body.free()
