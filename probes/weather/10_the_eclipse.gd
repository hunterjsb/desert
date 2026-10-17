extends WeatherProbe
## Wind & storms probe 10: the eclipse. Over two days where a run begins, the
## sun goes behind Tu once a day, and totality lasts as long as Tu's size makes
## it, for each size under trial. Through it the felt light, which solar reads,
## is nothing, and the sky draws the sun behind Tu's disc; the air is cooler
## for it, and over again half a day on. Tu shows its dark face then, and is
## full half a day later, lighting the night.

const STEP := 0.25
## Totality is worked from the sizes alone; the nod moves it by about this.
const SLACK := 0.03


func run() -> void:
	await load_weather()
	world.time_warp = 0.0
	var tuning := world.tuning
	var day := world.weather.day
	var sky := world.weather.sky
	var player := world.player.global_position
	var seconds := tuning.day_minutes * 60.0
	for size: StringName in DayCycle.TU_ORBITS:
		tuning.tu_orbit_radii = DayCycle.TU_ORBITS[size]
		var spans: Array[Vector2] = []
		var t := 0.0
		while t < 2.0 * seconds:
			if day.sun_shown(t) == 0.0:
				if spans.is_empty() or t - spans[-1].y > STEP * 1.5:
					spans.append(Vector2(t, t))
				spans[-1].y = t
			t += STEP
		var across := 2.0 * asin(1.0 / tuning.tu_orbit_radii)
		var expected := (across - 2.0 * DayCycle.SUN_RADIUS) / TAU * seconds
		var lengths := spans.map(func(s: Vector2) -> float: return s.y - s.x + STEP)
		print("%s: Tu %.1f° across, totality %s s against %.1f" % [size, rad_to_deg(across), lengths, expected])
		check(spans.size() == 2, "%s: one eclipse a day (%d in two)" % [size, spans.size()])
		check(lengths.all(func(l: float) -> bool: return absf(l - expected) <= expected * SLACK + STEP),
			"%s: totality lasts what Tu's size makes it (%s s against %.1f)" % [size, lengths, expected])
		if spans.is_empty():
			continue
		var mid := (spans[0].x + spans[0].y) * 0.5
		var dark := 0.0
		for k in 5:
			dark = maxf(dark, world.weather.felt_light(player, lerpf(spans[0].x, spans[0].y, k / 4.0)))
		check(dark == 0.0, "%s: nothing for solar through totality (%.4f)" % [size, dark])

		world.time = mid
		await physics_frames(2)
		var sun: Vector3 = sky.material.get_shader_parameter("sun_dir")
		var tu: Vector3 = sky.material.get_shader_parameter("tu_dir")
		check(sun.angle_to(tu) < day.tu_radius() - DayCycle.SUN_RADIUS and sky.tu_seen < 1e-6,
			"%s: the sky draws the sun behind Tu, and Tu casts no light" % size)
		var full := mid + seconds * 0.5
		world.time = full
		await physics_frames(2)
		check(day.tu_lit(mid) < 0.001 and day.tu_lit(full) > 0.999 and sky.tu_seen > 0.0,
			"%s: Tu's dark face at the eclipse, full half a day on, lighting the night (%.3f, %.3f)"
			% [size, day.tu_lit(mid), day.tu_lit(full)])

		var cooled := world.weather.field_temperature(player, spans[0].y)
		var later := world.weather.field_temperature(player, spans[0].y + seconds * 0.5)
		var chill := tuning.eclipse_chill
		tuning.eclipse_chill = 0.0
		var dip := world.weather.field_temperature(player, spans[0].y) - cooled
		var left := world.weather.field_temperature(player, spans[0].y + seconds * 0.5) - later
		tuning.eclipse_chill = chill
		check(dip > 1.0 and absf(left) < 0.05, "%s: the air %.1f °C cooler at totality's end, %.2f half a day on"
			% [size, dip, left])
