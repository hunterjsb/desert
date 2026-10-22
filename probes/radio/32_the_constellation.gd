extends ShieldProbe
## Radio probe 32: the constellation. Many satellites orbit Zan, each from
## its era with its own band, and each distinct in the sky: its colour, its
## shape and size, and its route, a plane of its own. Over a few hours the dial's
## satellites keep changing as they rise, set and come and go on the air, and
## every one that comes over the horizon is heard some time. What each sends follows the world: the
## thermal survey's pitch rises with the heat, the timing beacon's tick
## quickens toward the eclipse. Tuned to one overhead, the radio plays it;
## the night sky draws them all, those up and lit. Under clear skies everywhere.

## Sampled this often over this long, s.
const STEP := 30.0
const SPAN := 6.0 * 3600.0


func run() -> void:
	await load_storm(0.0)
	# The sky is above the ceiling: heard on shortwave, through its converter.
	var radio := Scenarios.standing(world, &"radio", [&"battery", &"sw_converter"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var sky := Radio.constellation_of(world)
	var voiced := Constellation.voiced()
	check(voiced.size() >= 8, "many satellites broadcast: %d" % voiced.size())

	# Each its own in the sky.
	var looks := {}
	var laps := {}
	for id in voiced:
		var look: Dictionary = sky.rows[id].look
		looks[[look.color.to_html(), look.shape, look.size]] = id
		var orbit: Satellite = sky.orbits[id]
		laps[[orbit._node.snapped(Vector3.ONE * 0.001), orbit._across.snapped(Vector3.ONE * 0.001),
			orbit._pole.snapped(Vector3.ONE * 0.001),
			orbit._around.snapped(Vector3.ONE * 0.001)]] = id
	check(looks.size() == voiced.size(), "each looks its own: colour, shape and size")
	check(laps.size() == voiced.size(), "each on a route of its own")
	var colours := {}
	var shapes := {}
	for id in voiced:
		colours[sky.rows[id].look.color.to_html()] = true
		shapes[sky.rows[id].look.shape] = true
	check(colours.size() == voiced.size() and shapes.size() >= 5, "every colour its own, %d shapes" % shapes.size())

	# Each home frequency wanders, never more than carrier_drift_khz a day (a hop, for one that hops).
	var day_s := Tuning.current().day_minutes * 60.0
	var drifts := true
	var moved := 0
	for id in voiced:
		if sky.rows[id].get("behave", {}).has("hop"):
			continue
		var last := sky.carrier(id, world.time)
		for k in range(1, 400):
			var now := sky.carrier(id, world.time + k * day_s * 0.25)
			drifts = drifts and absf(now - last) <= Tuning.current().carrier_drift_khz
			moved += int(now != last)
			last = now
	check(drifts and moved > 50, "home frequencies wander, never more than %d kHz at a time (%d moves)" % [
		roundi(Tuning.current().carrier_drift_khz), moved])
	var hops := true
	var ghost_last := sky.carrier(&"ghost", world.time)
	for k in range(1, 2000):
		var now := sky.carrier(&"ghost", world.time + k * 2.0)
		hops = hops and absf(now - ghost_last) <= Tuning.current().carrier_drift_khz
		ghost_last = now
	check(hops, "the ghost's hops too")

	# The band keeps changing, and every one that comes up is heard some time.
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var heard := {}
	var came_up := {}
	var changes := 0
	var last := []
	var t := world.time
	while t < world.time + SPAN:
		var now := []
		for each in sky.carriers(p, t):
			now.append(each[1])
			heard[each[1]] = true
		for id in voiced:
			if sky.orbits[id].seen_from(p, t).elevation > 0.0:
				came_up[id] = true
		if now != last:
			changes += 1
		last = now
		t += STEP
	print("over %d h the satellites on the dial changed %d times; heard %d of the %d that came up, of %d" % [
		roundi(SPAN / 3600.0), changes, heard.size(), came_up.size(), voiced.size()])
	check(changes > 40, "what's on the dial keeps changing")
	check(heard.size() == came_up.size() and came_up.size() >= voiced.size() - 2,
		"and every satellite that comes up is heard some time")

	# What they send follows the world.
	var seen := {"elevation": 0.5}
	var cold := _first(world.time, func(u: float) -> bool: return _temperature(radio, u) < 5.0)
	var hot := _first(world.time, func(u: float) -> bool: return _temperature(radio, u) > 35.0)
	var low: float = sky.shaped(&"thermal", radio, seen, x, z, cold).pitch
	var high: float = sky.shaped(&"thermal", radio, seen, x, z, hot).pitch
	print("the thermal survey: pitch %.2f at %.0f °C, %.2f at %.0f °C" % [low, _temperature(radio, cold), high,
		_temperature(radio, hot)])
	check(high > low, "the thermal survey's pitch rises with the heat")
	var day := world.weather.day
	var soon := day.next_eclipse(world.time) - 20.0
	var later := soon + 120.0
	var tick_soon: float = sky.shaped(&"pendulum", radio, seen, x, z, soon).pulse
	var tick_after: float = sky.shaped(&"pendulum", radio, seen, x, z, later).pulse
	print("the timing beacon ticks every %.2f s just before the eclipse, %.2f s after" % [tick_soon, tick_after])
	check(tick_soon < tick_after, "the timing beacon's tick quickens toward the eclipse")

	# Tuned to one overhead, it plays.
	var up := _first(world.time, func(u: float) -> bool:
		return sky.on_air(&"thermal", u) and sky.orbits[&"thermal"].seen_from(p, u).elevation > deg_to_rad(30.0))
	world.time = up
	radio.on = true
	while radio.band != Radio.SW_BAND and radio.switch_band():
		pass
	radio.frequency = sky.carrier(&"thermal", up)
	await physics_frames(5)
	var voice := radio.sky.voice_of(&"thermal")
	print("the thermal survey overhead: level %.2f, %.1f dB, pitch %.2f" % [radio.sky.levels[&"thermal"],
		voice.volume_db, voice.pitch_scale])
	check(radio.sky.levels[&"thermal"] > 0.5 and voice.playing, "tuned to it overhead, the radio plays it")
	radio.on = false
	await physics_frames(3)
	check(not voice.playing, "switched off, it's gone")

	# The night sky draws them.
	var material := world.weather.sky.material
	check(material.get_shader_parameter("sat_count") == voiced.size(), "the sky has every satellite to draw")
	var night := _first(world.time, func(u: float) -> bool:
		return not day.is_day(u, world.moon.longitude) and _lit(sky, p, u) >= 2)
	world.time = night
	await physics_frames(3)
	var shown := 0
	for color: Color in material.get_shader_parameter("sat_color"):
		if color.a > 0.0:
			shown += 1
	print("at night (%.0f s): %d satellites shown" % [night, shown])
	check(shown >= 2, "at night it shows those up and lit")


func _temperature(radio: Radio, t: float) -> float:
	return world.weather.field_temperature(radio.global_position, t)


func _lit(sky: Constellation, p: Vector3, t: float) -> int:
	var sun := world.weather.day.sun_toward(t)
	var n := 0
	for id in Constellation.voiced():
		if sky.orbits[id].seen_from(p, t).elevation > deg_to_rad(10.0) and sky.orbits[id].sunlit(t, sun):
			n += 1
	return n


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += 10.0
	check(false, "found a moment")
	return from
