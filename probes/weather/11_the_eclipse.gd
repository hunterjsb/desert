extends WeatherProbe
## Wind & storms probe 11: the eclipse. Over two days where a run begins, the
## sun goes behind Tu once a day, and totality lasts as long as Tu's size makes
## it, for each size under trial. Through it the felt light, which solar reads,
## is nothing, and the sky draws the sun behind Tu's disc; the ring of fire's
## light reaches a storm's dust then, and never outside an eclipse. The air is
## cooler for it, and over again half a day on. Tu shows its dark face then,
## and is full half a day later, lighting the night. At the Rim, where Tu sits
## half-risen, the eclipse takes next to nothing, at the default size.

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
	var default_size := tuning.tu_degrees
	for size: float in DayCycle.TU_SIZES:
		tuning.tu_degrees = size
		var spans: Array[Vector2] = []
		var t := 0.0
		while t < 2.0 * seconds:
			if day.sun_shown(t) == 0.0:
				if spans.is_empty() or t - spans[-1].y > STEP * 1.5:
					spans.append(Vector2(t, t))
				spans[-1].y = t
			t += STEP
		var across := deg_to_rad(size)
		var expected := (across - 2.0 * DayCycle.SUN_RADIUS) / TAU * seconds
		var lengths := spans.map(func(s: Vector2) -> float: return s.y - s.x + STEP)
		print("%d°: totality %s s against %.1f" % [size, lengths, expected])
		check(spans.size() == 2, "%d°: one eclipse a day (%d in two)" % [size, spans.size()])
		check(lengths.all(func(l: float) -> bool: return absf(l - expected) <= expected * SLACK + STEP),
			"%d°: totality lasts what Tu's size makes it (%s s against %.1f)" % [size, lengths, expected])
		if spans.is_empty():
			continue
		var mid := (spans[0].x + spans[0].y) * 0.5
		var dark := 0.0
		for k in 5:
			dark = maxf(dark, world.weather.felt_light(player, lerpf(spans[0].x, spans[0].y, k / 4.0)))
		check(dark == 0.0, "%d°: nothing for solar through totality (%.4f)" % [size, dark])

		world.time = mid
		await physics_frames(2)
		var sun: Vector3 = sky.material.get_shader_parameter("sun_dir")
		var tu: Vector3 = sky.material.get_shader_parameter("tu_dir")
		check(sun.angle_to(tu) < day.tu_radius() - DayCycle.SUN_RADIUS and sky.tu_seen < 1e-6,
			"%d°: the sky draws the sun behind Tu, and Tu casts no light" % size)
		var ring_mid: Vector3 = world.weather.face.material.get_shader_parameter("ring_light")
		var full := mid + seconds * 0.5
		world.time = full
		await physics_frames(2)
		check(day.tu_lit(mid) < 0.001 and day.tu_lit(full) > 0.999 and sky.tu_seen > 0.0,
			"%d°: Tu's dark face at the eclipse, full half a day on, lighting the night (%.3f, %.3f)"
			% [size, day.tu_lit(mid), day.tu_lit(full)])
		var ring_full: Vector3 = world.weather.face.material.get_shader_parameter("ring_light")
		check(ring_mid.x > ring_mid.y and ring_mid.y > 0.0 and ring_full == Vector3.ZERO,
			"%d°: the ring's red light reaches a storm's dust through totality, and none half a day on (%s, %s)"
			% [size, ring_mid, ring_full])

		var cooled := world.weather.field_temperature(player, spans[0].y)
		var later := world.weather.field_temperature(player, spans[0].y + seconds * 0.5)
		var chill := tuning.eclipse_chill
		tuning.eclipse_chill = 0.0
		var dip := world.weather.field_temperature(player, spans[0].y) - cooled
		var left := world.weather.field_temperature(player, spans[0].y + seconds * 0.5) - later
		tuning.eclipse_chill = chill
		check(dip > 1.0 and absf(left) < 0.05, "%d°: the air %.1f °C cooler at totality's end, %.2f half a day on"
			% [size, dip, left])

	# The Rim: the light the eclipse takes there, against where a run begins.
	tuning.tu_degrees = default_size
	var eclipse := day.next_eclipse(0.0)
	var lost := func(longitude: float) -> float:
		var sum := 0.0
		var u := eclipse - 60.0
		while u < eclipse + 60.0:
			sum += maxf(day.sun_direction(u, 0.0, longitude).y, 0.0) * (1.0 - day.sun_shown(u)) * STEP
			u += STEP
		return sum
	var rim: float = lost.call(deg_to_rad(tuning.tu_longitude_degrees + 90.0))
	var start: float = lost.call(world.moon.longitude)
	check(rim < start * 0.1, "at the Rim the eclipse takes next to nothing (%.0f%% of where a run begins)"
		% (rim / start * 100.0))
