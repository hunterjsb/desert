extends ShieldProbe
## Radio probe 16: the Eye's drone. The Eye's frequency begins a run silent;
## after a silence of between eye_quiet_minutes, the seed's pick, its drone
## plays through once, falls silent again for another such pick, and plays
## again. Between drones there's nothing on its frequency, not even tones.
## At night, when the Eye comes down by sky wave, the drone is heard; in its
## silence, tuned to the Eye, it isn't.

const STEP := 1.0


func run() -> void:
	await load_storm(0.0)
	var tuning := Tuning.current()
	var radio := Scenarios.standing(world, &"radio", [&"battery"], [0.0, 2.0]) as Radio
	radio.freeze = true
	await physics_frames(2)
	var gods := Radio.gods_of(world)
	var length := Sounds.RADIO_EYE.get_length()
	var quiet := tuning.eye_quiet_minutes * 60.0

	var first := _first(0.0, func(t: float) -> bool: return gods.song(&"eye", t, length) >= 0.0)
	var ends := _first(first, func(t: float) -> bool: return gods.song(&"eye", t, length) < 0.0)
	var again := _first(ends, func(t: float) -> bool: return gods.song(&"eye", t, length) >= 0.0)
	print("the Eye's drone: first at %.0f s, %.0f s long, again at %.0f s" % [first, ends - first, again])
	check(first >= quiet.x - STEP and first <= quiet.y + STEP, "it begins silent, %.1f min, within eye_quiet_minutes" % (first / 60.0))
	check(absf(ends - first - length) <= STEP, "its drone plays through once")
	check(again - ends >= quiet.x - STEP and again - ends <= quiet.y + STEP, "then falls silent again for another pick")

	# At night, during a drone, tuned to the Eye: heard.
	var day := world.weather.day
	var lon := world.moon.longitude
	var night := _first(0.0, func(t: float) -> bool:
		return not day.is_day(t, lon) and gods.song(&"eye", t, length) > 2.0 and gods.song(&"eye", t, length) < length - 5.0)
	radio.on = true
	world.time = night
	radio.frequency = gods.carrier(&"eye", night)
	await physics_frames(5)
	print("at night, mid-drone (%.0f s): on air %s at %.1f dB, \"%s\"" % [night, radio.on_air(), radio.music.volume_db, radio.said])
	check(radio.tuned_to() == &"eye" and radio.on_air() == Sounds.RADIO_EYE and radio.music.volume_db > -20.0,
		"at night its drone comes down by sky wave")
	var silent := _first(night, func(t: float) -> bool: return gods.song(&"eye", t, length) < 0.0)
	world.time = silent + 1.0
	radio.frequency = gods.carrier(&"eye", world.time)
	await physics_frames(5)
	check(radio.on_air() == null and not radio.music.playing, "in its silence, nothing on its frequency")


func _first(from: float, wanted: Callable) -> float:
	var t := from
	while t < from + 3.0 * 24.0 * 3600.0:
		if wanted.call(t):
			return t
		t += STEP
	check(false, "found a moment")
	return from
