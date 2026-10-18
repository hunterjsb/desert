extends WeatherProbe
## Radio probe 9: a god is useful only in its window. Over two moon days,
## each god says something worth hearing exactly when its window is open, and
## the rest of the time only noise in its own voice: the Quartermaster through
## the eclipse, the Eye at night, Mother Cistern at dawn, the Almanac at
## sunrise and sunset, the Ledger about midnight and the Stoker through the
## hot hours. The Walker, the weather station, always gives the forecast, the
## radio's own reading of the storm field. What a god says in its window is
## read from the world: the Eye's fix is where the radio is, the Ledger's
## bearings are the landmarks', the Stoker's countdown is the next eclipse's.

## The clock is sampled this often, s.
const STEP := 3.0


func run() -> void:
	await load_weather()
	world.player.set_physics_process(false)
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	var day := world.weather.day
	var x := world.world_x(radio.global_position.x)
	var z := world.world_z(radio.global_position.z)
	var p := radio.point_at(x, z)
	var longitude := Sphere.longitude(p)
	var span := Tuning.current().day_minutes * 60.0 * 2.0
	var windows := {
		&"quartermaster": func(t: float) -> bool: return day.sun_shown(t) < 0.999,
		&"eye": func(t: float) -> bool: return not day.is_day(t, longitude),
		&"cistern": func(t: float) -> bool: return _within(day.time_of_day(t, longitude), Transmissions.DAWN),
		&"almanac": func(t: float) -> bool:
			var local := day.time_of_day(t, longitude)
			return _within(local, Transmissions.SUNRISE) or _within(local, Transmissions.SUNSET),
		&"ledger": func(t: float) -> bool:
			var local := day.time_of_day(t, longitude)
			return local < Transmissions.MIDNIGHT or local > 1.0 - Transmissions.MIDNIGHT,
		&"stoker": func(t: float) -> bool: return _within(day.time_of_day(t, longitude), Transmissions.HOT),
	}
	for id: StringName in windows:
		var open := 0
		var shut := 0
		var wrong := 0
		var sample := ""
		var t := world.time
		while t < world.time + span:
			var said := Transmissions.say(id, radio, gods, p, x, z, t)
			var in_window: bool = windows[id].call(t)
			if said.useful != in_window:
				wrong += 1
			if in_window:
				open += 1
				if sample == "":
					sample = said.text
			else:
				shut += 1
			t += STEP
		print("%s: useful in %d samples, noise in %d; \"%s\"" % [Gods.title(id), open, shut, sample])
		check(open > 0 and shut > 0 and wrong == 0, "%s is useful exactly in its window" % Gods.title(id))

	# What they say in their windows comes from the world.
	var night := _first(func(t: float) -> bool: return not day.is_day(t, longitude))
	var lat := absf(rad_to_deg(Sphere.latitude(p)))
	check(Transmissions.say(&"eye", radio, gods, p, x, z, night).text.contains("%.1f" % lat),
		"the Eye's fix is where the radio stands (%.1f°)" % lat)
	var midnight := _first(func(t: float) -> bool:
		return day.time_of_day(t, longitude) > 1.0 - Transmissions.MIDNIGHT)
	var halloran: Dictionary = gods.history.landmark(&"halloran")
	var brg := roundi(rad_to_deg(fposmod(Sphere.bearing(p, halloran.p), TAU)))
	check(Transmissions.say(&"ledger", radio, gods, p, x, z, midnight).text.contains("BRG %03d" % brg),
		"the Ledger gives Halloran's bearing, %03d" % brg)
	var hot := _first(func(t: float) -> bool: return _within(day.time_of_day(t, longitude), Transmissions.HOT))
	check(Transmissions.say(&"stoker", radio, gods, p, x, z, hot).text.contains(
		"DARK IN %d S" % roundi(day.next_eclipse(hot) - hot)), "the Stoker counts down to the next eclipse")

	radio.on = true
	radio.frequency = gods.carrier(&"walker", world.time)
	await physics_frames(2)
	var walker := Transmissions.say(&"walker", radio, gods, p, x, z, world.time)
	check(walker.useful and walker.text.begins_with(radio.weather_words(world.time)),
		"the Walker always gives the station's forecast: \"%s\"" % walker.text)


func _within(local: float, window: Vector2) -> bool:
	return local >= window.x and local <= window.y


func _first(wanted: Callable) -> float:
	var t := world.time
	while not wanted.call(t):
		t += STEP
	return t
